# frozen_string_literal: true

require 'resolv'

module QA
  module Service
    module DockerRun
      class GitlabRunner < Base
        attr_reader :tags
        attr_accessor :token, :address, :image, :run_untagged
        attr_writer :config, :executor, :executor_image

        CONFLICTING_VARIABLES_MESSAGE = <<~MSG
          There are conflicting options preventing the runner from starting.
          %s cannot be specified if %s is %s
        MSG

        def initialize(name)
          @image = "#{QA::Runtime::Env.container_registry_host}/gitlab-org/#{QA::Runtime::Env.runner_container_image}"
          @name = name || "qa-runner-#{SecureRandom.hex(4)}"
          @run_untagged = true
          @executor = :shell
          @executor_image = "#{QA::Runtime::Env.container_registry_host}/
            gitlab-org/gitlab-build-images:gitlab-qa-alpine-ruby-2.7"

          super()
        end

        def config
          @config ||= <<~CONFIG
            concurrent = 1
            check_interval = 0

            [session_server]
              session_timeout = 1800
          CONFIG
        end

        def register!
          raise("Missing runner token value!") unless token

          cmd = <<~CMD.tr("\n", ' ')
            docker run -d --rm --network #{network} --name #{@name}
            #{'-v /var/run/docker.sock:/var/run/docker.sock' if @executor == :docker}
            --privileged
            #{"--add-host gdk.test:#{gdk_host_ip}" if gdk_network}
            #{@image}  #{add_gitlab_tls_cert if @address.include? 'https'}
            && docker exec --detach #{@name} sh -c "#{register_command}"
          CMD
          shell(cmd, mask_secrets: [@token])

          wait_until_running_and_configured

          # Prove airgappedness
          shell("docker exec #{@name} sh -c '#{prove_airgap}'") if network == 'airgapped'
        end

        def tags=(tags)
          @tags = tags
          @run_untagged = false
        end

        def restart
          super

          wait_until_shell_command_matches("docker logs #{@name}", /Configuration loaded/)
        end

        private

        def register_command
          args = []
          args << '--non-interactive'
          args << "--name #{@name}"
          args << "--url #{@address}"
          args << "--registration-token #{@token}"

          args << if run_untagged
                    raise format(CONFLICTING_VARIABLES_MESSAGE, :tags=, :run_untagged, run_untagged) if @tags&.any?

                    '--run-untagged=true'
                  else
                    raise 'You must specify tags to run!' unless @tags&.any?

                    "--tag-list #{@tags.join(',')}"
                  end

          args << "--executor #{@executor}"

          if @executor == :docker
            args << "--docker-image #{@executor_image}"
            args << '--docker-tlsverify=false'
            args << '--docker-privileged=true'
            args << "--docker-network-mode=#{network}"
            args << "--docker-volumes=/certs/client"
          end

          <<~CMD.strip
            printf '#{config.chomp.gsub(/\n/, '\\n').gsub('"', '\"')}' > /etc/gitlab-runner/config.toml &&
            gitlab-runner register \
              #{args.join(' ')} &&
            gitlab-runner run
          CMD
        end

        # Ping Cloudflare DNS, should fail
        # Ping Registry, should fail to resolve
        def prove_airgap
          begin
            gitlab_ip = Resolv.getaddress 'registry.gitlab.com'
          rescue Resolv::ResolvError => e
            Runtime::Logger.debug("prove_airgap unable to get ip address for endpoint - #{e.message}")
            # If Resolv.getaddress fails, it implies we cannot access the URL in question
            # This may occur in offline-environment/airgapped testing
            return 'true'
          end

          <<~CMD
            echo "Checking airgapped connectivity..."
            nc -zv -w 10 #{gitlab_ip} 80 && (echo "Airgapped network faulty. Connectivity netcat check failed." && exit 1) || (echo "Connectivity netcat check passed." && exit 0)
            wget --retry-connrefused --waitretry=1 --read-timeout=15 --timeout=10 -t 2 http://registry.gitlab.com > /dev/null 2>&1 && (echo "Airgapped network faulty. Connectivity wget check failed." && exit 1) || (echo "Airgapped network confirmed. Connectivity wget check passed." && exit 0)
          CMD
        end

        def add_gitlab_tls_cert
          gitlab_tls_certificate = Tempfile.new('gitlab-cert')
          gitlab_tls_certificate.write(Runtime::Env.gitlab_tls_certificate)
          gitlab_tls_certificate.close

          <<~CMD
            && docker cp #{gitlab_tls_certificate.path} #{@name}:/etc/gitlab-runner/certs/gitlab.test.crt
          CMD
        end

        def wait_until_running_and_configured
          wait_until_shell_command_matches("docker logs #{@name}", /Configuration loaded/)
        end
      end
    end
  end
end

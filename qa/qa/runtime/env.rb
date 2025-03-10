# frozen_string_literal: true

require 'active_support/deprecation'
require 'uri'

module QA
  module Runtime
    module Env
      extend self

      attr_writer :personal_access_token, :admin_personal_access_token
      attr_accessor :dry_run

      ENV_VARIABLES = Gitlab::QA::Runtime::Env::ENV_VARIABLES

      # The environment variables used to indicate if the environment under test
      # supports the given feature
      SUPPORTED_FEATURES = {
        git_protocol_v2: 'QA_CAN_TEST_GIT_PROTOCOL_V2',
        admin: 'QA_CAN_TEST_ADMIN_FEATURES',
        praefect: 'QA_CAN_TEST_PRAEFECT'
      }.freeze

      def supported_features
        SUPPORTED_FEATURES
      end

      def gitlab_url
        @gitlab_url ||= ENV["QA_GITLAB_URL"] || "http://127.0.0.1:3000" # default to GDK
      end

      # Retrieves the value of the gitlab_canary cookie if set or returns an empty hash.
      #
      # @return [Hash]
      def canary_cookie
        canary = ENV['QA_COOKIES']&.scan(/gitlab_canary=(true|false)/)&.dig(0, 0)

        canary ? { gitlab_canary: canary } : {}
      end

      def additional_repository_storage
        ENV['QA_ADDITIONAL_REPOSITORY_STORAGE']
      end

      def non_cluster_repository_storage
        ENV['QA_GITALY_NON_CLUSTER_STORAGE'] || 'gitaly'
      end

      def praefect_repository_storage
        ENV['QA_PRAEFECT_REPOSITORY_STORAGE']
      end

      def interception_enabled?
        enabled?(ENV['QA_INTERCEPT_REQUESTS'], default: false)
      end

      def can_intercept?
        browser == :chrome && interception_enabled?
      end

      def release
        ENV['RELEASE']
      end

      def release_registry_url
        ENV['RELEASE_REGISTRY_URL']
      end

      def release_registry_username
        ENV['RELEASE_REGISTRY_USERNAME']
      end

      def release_registry_password
        ENV['RELEASE_REGISTRY_PASSWORD']
      end

      def ci_job_url
        ENV['CI_JOB_URL']
      end

      def ci_job_name
        ENV['CI_JOB_NAME']
      end

      def ci_project_name
        ENV['CI_PROJECT_NAME']
      end

      def schedule_type
        ENV['SCHEDULE_TYPE']
      end

      def generate_allure_report?
        enabled?(ENV['QA_GENERATE_ALLURE_REPORT'], default: false)
      end

      def default_branch
        ENV['QA_DEFAULT_BRANCH'] || 'main'
      end

      def colorized_logs?
        enabled?(ENV['COLORIZED_LOGS'], default: false)
      end

      # set to 'false' to have the browser run visibly instead of headless
      def webdriver_headless?
        if ENV.key?('CHROME_HEADLESS')
          ActiveSupport::Deprecation.warn("CHROME_HEADLESS is deprecated. Use WEBDRIVER_HEADLESS instead.")
        end

        return enabled?(ENV['WEBDRIVER_HEADLESS']) unless ENV['WEBDRIVER_HEADLESS'].nil?

        enabled?(ENV['CHROME_HEADLESS'])
      end

      # set to 'true' to have Chrome use a fixed profile directory
      def reuse_chrome_profile?
        enabled?(ENV['CHROME_REUSE_PROFILE'], default: false)
      end

      # Disable /dev/shm use in CI. See https://gitlab.com/gitlab-org/gitlab/issues/4252
      def disable_dev_shm?
        running_in_ci? || enabled?(ENV['CHROME_DISABLE_DEV_SHM'], default: false)
      end

      def accept_insecure_certs?
        enabled?(ENV['ACCEPT_INSECURE_CERTS'])
      end

      def running_on_dot_com?
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        uri.host.include?('.com')
      end

      def running_on_dev?
        uri = URI.parse(Runtime::Scenario.gitlab_address)
        uri.port != 80 && uri.port != 443
      end

      def running_on_dev_or_dot_com?
        running_on_dev? || running_on_dot_com?
      end

      def running_in_ci?
        ENV['CI'] || ENV['CI_SERVER']
      end

      def qa_cookies
        ENV['QA_COOKIES'] && ENV['QA_COOKIES'].split(';')
      end

      def signup_disabled?
        enabled?(ENV['SIGNUP_DISABLED'], default: false)
      end

      # PATs are disabled for FedRamp
      def personal_access_tokens_disabled?
        enabled?(ENV['PERSONAL_ACCESS_TOKENS_DISABLED'], default: false)
      end

      def admin_password
        ENV['GITLAB_ADMIN_PASSWORD']
      end

      def admin_username
        ENV['GITLAB_ADMIN_USERNAME']
      end

      def admin_personal_access_token
        @admin_personal_access_token ||= ENV['GITLAB_QA_ADMIN_ACCESS_TOKEN']
      end

      # specifies token that can be used for the api
      def personal_access_token
        @personal_access_token ||= ENV['GITLAB_QA_ACCESS_TOKEN']
      end

      def remote_grid
        # if username specified, password/auth token is required
        # can be
        # - "http://user:pass@somehost.com/wd/hub"
        # - "https://user:pass@somehost.com:443/wd/hub"
        # - "http://localhost:4444/wd/hub"

        return if (ENV['QA_REMOTE_GRID'] || '').empty?

        "#{remote_grid_protocol}://#{remote_grid_credentials}#{ENV['QA_REMOTE_GRID']}/wd/hub"
      end

      def remote_grid_username
        ENV['QA_REMOTE_GRID_USERNAME']
      end

      def remote_grid_access_key
        ENV['QA_REMOTE_GRID_ACCESS_KEY']
      end

      def remote_grid_protocol
        ENV['QA_REMOTE_GRID_PROTOCOL'] || 'http'
      end

      def remote_tunnel_id
        ENV['QA_REMOTE_TUNNEL_ID'] || 'gitlab-sl_tunnel_id'
      end

      def browser
        ENV['QA_BROWSER'].nil? ? :chrome : ENV['QA_BROWSER'].to_sym
      end

      def selenoid_browser_version
        ENV['QA_SELENOID_BROWSER_VERSION']
      end

      def selenoid_browser_image
        ENV['QA_SELENOID_BROWSER_IMAGE']
      end

      def video_recorder_image
        ENV['QA_VIDEO_RECORDER_IMAGE']
      end

      def remote_mobile_device_name
        ENV['QA_REMOTE_MOBILE_DEVICE_NAME']&.downcase
      end

      def layout
        ENV['QA_LAYOUT']&.downcase || ''
      end

      def tablet_layout?
        return true if remote_mobile_device_name && !phone_layout?

        layout.include?('tablet')
      end

      def phone_layout?
        return true if layout.include?('phone')

        return false unless remote_mobile_device_name

        !(remote_mobile_device_name.include?('ipad') || remote_mobile_device_name.include?('tablet'))
      end

      def mobile_layout?
        phone_layout? || tablet_layout? || remote_mobile_device_name
      end

      def record_video?
        enabled?(ENV['QA_RECORD_VIDEO'], default: false)
      end

      def use_selenoid?
        enabled?(ENV['USE_SELENOID'], default: false)
      end

      def save_all_videos?
        enabled?(ENV['QA_SAVE_ALL_VIDEOS'], default: false)
      end

      def require_video_variables!
        docs_link = 'https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/running_against_remote_grid.md#testing-with-selenoid'
        use_selenoid? || (raise ArgumentError, "USE_SELENOID is required! See docs: #{docs_link}")
        remote_grid || (raise ArgumentError, "QA_REMOTE_GRID is required! See docs: #{docs_link}")
        video_recorder_image || (raise ArgumentError, "QA_VIDEO_RECORDER_IMAGE is required! See docs: #{docs_link}")
        selenoid_browser_image || (raise ArgumentError, "QA_SELENOID_BROWSER_IMAGE is required! See docs: #{docs_link}")
        selenoid_browser_version || (raise ArgumentError, "QA_SELENOID_BROWSER_VERSION is required! See docs: #{docs_link}")
      end

      def user_username
        ENV['GITLAB_USERNAME']
      end

      def user_password
        ENV['GITLAB_PASSWORD']
      end

      def initial_root_password
        ENV['GITLAB_INITIAL_ROOT_PASSWORD']
      end

      def github_username
        ENV['QA_GITHUB_USERNAME']
      end

      def github_password
        ENV['QA_GITHUB_PASSWORD']
      end

      def facebook_username
        ENV['QA_FACEBOOK_USERNAME']
      end

      def facebook_password
        ENV['QA_FACEBOOK_PASSWORD']
      end

      def forker?
        !!(forker_username && forker_password)
      end

      def forker_username
        ENV['GITLAB_FORKER_USERNAME']
      end

      def forker_password
        ENV['GITLAB_FORKER_PASSWORD']
      end

      def gitlab_qa_username_1
        ENV['GITLAB_QA_USERNAME_1'] || 'gitlab-qa-user1'
      end

      def gitlab_qa_password_1
        ENV['GITLAB_QA_PASSWORD_1']
      end

      def gitlab_qa_access_token_1
        ENV['GITLAB_QA_ACCESS_TOKEN_1']
      end

      def gitlab_qa_username_2
        ENV['GITLAB_QA_USERNAME_2'] || 'gitlab-qa-user2'
      end

      def gitlab_qa_password_2
        ENV['GITLAB_QA_PASSWORD_2']
      end

      def gitlab_qa_username_3
        ENV['GITLAB_QA_USERNAME_3'] || 'gitlab-qa-user3'
      end

      def gitlab_qa_password_3
        ENV['GITLAB_QA_PASSWORD_3']
      end

      def gitlab_qa_username_4
        ENV['GITLAB_QA_USERNAME_4'] || 'gitlab-qa-user4'
      end

      def gitlab_qa_password_4
        ENV['GITLAB_QA_PASSWORD_4']
      end

      def gitlab_qa_username_5
        ENV['GITLAB_QA_USERNAME_5'] || 'gitlab-qa-user5'
      end

      def gitlab_qa_password_5
        ENV['GITLAB_QA_PASSWORD_5']
      end

      def gitlab_qa_username_6
        ENV['GITLAB_QA_USERNAME_6'] || 'gitlab-qa-user6'
      end

      def gitlab_qa_password_6
        ENV['GITLAB_QA_PASSWORD_6']
      end

      def jira_admin_username
        ENV['QA_JIRA_ADMIN_USERNAME']
      end

      def jira_admin_password
        ENV['QA_JIRA_ADMIN_PASSWORD']
      end

      def jira_hostname
        ENV['JIRA_HOSTNAME']
      end

      def slack_workspace
        ENV['QA_SLACK_WORKSPACE']
      end

      def slack_email
        ENV['QA_SLACK_EMAIL']
      end

      def slack_password
        ENV['QA_SLACK_PASSWORD']
      end

      def jenkins_admin_username
        ENV.fetch('QA_JENKINS_USER', 'administrator')
      end

      def jenkins_admin_password
        ENV.fetch('QA_JENKINS_PASS', 'password')
      end

      # this is set by the integrations job
      # which will allow bidirectional communication
      # between the app and the specs container
      # should the specs container spin up a server
      def qa_hostname
        ENV['QA_HOSTNAME']
      end

      def cache_namespace_name?
        enabled?(ENV['CACHE_NAMESPACE_NAME'], default: true)
      end

      def knapsack?
        ENV['CI_NODE_TOTAL'].to_i > 1 && ENV['NO_KNAPSACK'] != "true"
      end

      def ldap_username
        @ldap_username ||= ENV['GITLAB_LDAP_USERNAME']
      end

      def ldap_username=(ldap_username)
        @ldap_username = ldap_username # rubocop:disable Gitlab/ModuleWithInstanceVariables
        ENV['GITLAB_LDAP_USERNAME'] = ldap_username
      end

      def ldap_password
        @ldap_password ||= ENV['GITLAB_LDAP_PASSWORD']
      end

      def sandbox_name
        ENV['GITLAB_SANDBOX_NAME']
      end

      def namespace_name
        ENV['GITLAB_NAMESPACE_NAME']
      end

      def auto_devops_project_name
        ENV['GITLAB_AUTO_DEVOPS_PROJECT_NAME']
      end

      def gcloud_account_key
        ENV.fetch("GCLOUD_ACCOUNT_KEY")
      end

      def gcloud_account_email
        ENV.fetch("GCLOUD_ACCOUNT_EMAIL")
      end

      def gcloud_region
        ENV['GCLOUD_REGION']
      end

      def gcloud_num_nodes
        ENV.fetch('GCLOUD_NUM_NODES', 1)
      end

      def has_gcloud_credentials?
        %w[GCLOUD_ACCOUNT_KEY GCLOUD_ACCOUNT_EMAIL].none? { |var| ENV[var].to_s.empty? }
      end

      # Specifies the token that can be used for the GitHub API
      def github_access_token
        ENV['QA_GITHUB_ACCESS_TOKEN'].to_s.strip
      end

      def github_additional_access_tokens
        ENV['QA_ADDITIONAL_GITHUB_ACCESS_TOKENS']
      end

      def require_github_access_token!
        return unless github_access_token.empty?

        raise ArgumentError, "Please provide QA_GITHUB_ACCESS_TOKEN"
      end

      def require_admin_access_token!
        admin_personal_access_token || (raise ArgumentError, "GITLAB_QA_ADMIN_ACCESS_TOKEN is required!")
      end

      # Returns true if there is an environment variable that indicates that
      # the feature is supported in the environment under test.
      # All features are supported by default.
      def can_test?(feature)
        raise ArgumentError, %(Unknown feature "#{feature}") unless SUPPORTED_FEATURES.include? feature

        enabled?(ENV[SUPPORTED_FEATURES[feature]], default: true)
      end

      def runtime_scenario_attributes
        ENV['QA_RUNTIME_SCENARIO_ATTRIBUTES']
      end

      def disable_rspec_retry?
        enabled?(ENV['QA_DISABLE_RSPEC_RETRY'], default: false)
      end

      def simulate_slow_connection?
        enabled?(ENV['QA_SIMULATE_SLOW_CONNECTION'], default: false)
      end

      def slow_connection_latency
        ENV.fetch('QA_SLOW_CONNECTION_LATENCY_MS', 2000).to_i
      end

      def slow_connection_throughput
        ENV.fetch('QA_SLOW_CONNECTION_THROUGHPUT_KBPS', 32).to_i
      end

      def gitlab_qa_loop_runner_minutes
        ENV.fetch('GITLAB_QA_LOOP_RUNNER_MINUTES', 1).to_i
      end

      def mailhog_hostname
        ENV['MAILHOG_HOSTNAME']
      end

      # Get the version of GitLab currently being tested against
      # @return String Version
      # @example
      #   > Env.deploy_version
      #   #=> 13.3.4-ee.0
      def deploy_version
        ENV['DEPLOY_VERSION']
      end

      def user_agent
        ENV['GITLAB_QA_USER_AGENT']
      end

      def geo_environment?
        QA::Runtime::Scenario.attributes.include?(:geo_secondary_address)
      end

      def gitlab_agentk_version
        ENV.fetch('GITLAB_AGENTK_VERSION', 'fe716ea')
      end

      def transient_trials
        ENV.fetch('GITLAB_QA_TRANSIENT_TRIALS', 10).to_i
      end

      def gitlab_tls_certificate
        ENV['GITLAB_TLS_CERTIFICATE']
      end

      def export_metrics?
        enabled?(ENV['QA_EXPORT_TEST_METRICS'], default: false)
      end

      def save_metrics_json?
        enabled?(ENV['QA_SAVE_TEST_METRICS'], default: false)
      end

      def ee_license
        return ENV["QA_EE_LICENSE"] if ENV["QA_EE_LICENSE"]

        ENV["EE_LICENSE"].tap do |license|
          next unless license

          Runtime::Logger.warn("EE_LICENSE environment variable is deprecated, please use QA_EE_LICENSE instead!")
        end
      end

      def ee_activation_code
        ENV['QA_EE_ACTIVATION_CODE']
      end

      def quarantine_disabled?
        enabled?(ENV['DISABLE_QUARANTINE'], default: false)
      end

      def validate_resource_reuse?
        enabled?(ENV['QA_VALIDATE_RESOURCE_REUSE'], default: false)
      end

      def skip_smoke_reliable?
        enabled?(ENV['QA_SKIP_SMOKE_RELIABLE'], default: false)
      end

      def container_registry_host
        ENV.fetch('QA_CONTAINER_REGISTRY_HOST', 'registry.gitlab.com')
      end

      def runner_container_image
        ENV.fetch('QA_RUNNER_CONTAINER_IMAGE', 'gitlab-runner:alpine')
      end

      # ENV variables for authenticating against a private container registry
      # These need to be set if using the
      # Service::DockerRun::Mixins::ThirdPartyDocker module
      def third_party_docker_registry
        ENV['QA_THIRD_PARTY_DOCKER_REGISTRY']
      end

      def third_party_docker_repository
        ENV['QA_THIRD_PARTY_DOCKER_REPOSITORY']
      end

      def third_party_docker_user
        ENV['QA_THIRD_PARTY_DOCKER_USER']
      end

      def third_party_docker_password
        ENV['QA_THIRD_PARTY_DOCKER_PASSWORD']
      end

      def max_capybara_wait_time
        ENV.fetch('MAX_CAPYBARA_WAIT_TIME', 10).to_i
      end

      def use_public_ip_api?
        enabled?(ENV['QA_USE_PUBLIC_IP_API'], default: false)
      end

      def allow_local_requests?
        enabled?(ENV['QA_ALLOW_LOCAL_REQUESTS'], default: false)
      end

      def chrome_default_download_path
        ENV['DEFAULT_CHROME_DOWNLOAD_PATH'] || Dir.tmpdir
      end

      def super_sidebar_enabled?
        enabled?(ENV['QA_SUPER_SIDEBAR_ENABLED'], default: true)
      end

      def require_slack_env!
        missing_env = %i[slack_workspace slack_email slack_password].select do |method|
          ::QA::Runtime::Env.public_send(method).nil?
        end
        return unless missing_env.any?

        raise "Missing Slack env: #{missing_env.map(&:upcase).join(', ')}"
      end

      def one_p_email
        ENV['QA_1P_EMAIL']
      end

      def one_p_password
        ENV['QA_1P_PASSWORD']
      end

      def one_p_secret
        ENV['QA_1P_SECRET']
      end

      def one_p_github_uuid
        ENV['QA_1P_GITHUB_UUID']
      end

      def gdk_url
        ENV['GDK_URL']
      end

      private

      def remote_grid_credentials
        if remote_grid_username
          unless remote_grid_access_key
            raise ArgumentError, %(Please provide an access key for user "#{remote_grid_username}")
          end

          return "#{remote_grid_username}:#{remote_grid_access_key}@"
        end

        ''
      end

      def enabled?(value, default: true)
        return default if value.nil?

        (value =~ /^(false|no|0)$/i) != 0
      end
    end
  end
end

QA::Runtime::Env.extend_mod_with('Runtime::Env', namespace: QA)

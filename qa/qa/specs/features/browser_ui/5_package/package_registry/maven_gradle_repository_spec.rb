# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :object_storage, :external_api_calls,
    quarantine: {
      only: { condition: -> { QA::Support::FIPS.enabled? } },
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/417600',
      type: :investigating
    }, product_group: :package_registry do
    describe 'Maven Repository with Gradle' do
      using RSpec::Parameterized::TableSyntax
      include Runtime::Fixtures
      include Support::Helpers::MaskToken

      let(:group_id) { 'com.gitlab.qa' }
      let(:artifact_id) { "maven_gradle-#{SecureRandom.hex(8)}" }
      let(:package_name) { "#{group_id}/#{artifact_id}".tr('.', '/') }
      let(:package_version) { '1.3.7' }
      let(:package_type) { 'maven_gradle' }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = "#{package_type}_project"
          project.initialize_with_readme = true
          project.visibility = :private
        end
      end

      let(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.name}"]
          runner.executor = :docker
          runner.project = project
        end
      end

      let(:gitlab_address_with_port) do
        Support::GitlabAddress.address_with_port
      end

      let(:project_deploy_token) do
        Resource::ProjectDeployToken.fabricate_via_api! do |deploy_token|
          deploy_token.name = 'package-deploy-token'
          deploy_token.project = project
          deploy_token.scopes = %w[
            read_repository
            read_package_registry
            write_package_registry
          ]
        end
      end

      let(:project_inbound_job_token_disabled) do
        Resource::CICDSettings.fabricate_via_api! do |settings|
          settings.project_path = project.full_path
          settings.inbound_job_token_scope_enabled = false
        end
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        runner
      end

      where(:case_name, :authentication_token_type, :maven_header_name, :testcase) do
        'using personal access token' | :personal_access_token | 'Private-Token' | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347601'
        'using ci job token'          | :ci_job_token          | 'Job-Token'     | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347603'
        'using project deploy token'  | :project_deploy_token  | 'Deploy-Token'  | 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347602'
      end

      with_them do
        let(:token) do
          case authentication_token_type
          when :personal_access_token
            use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: Runtime::Env.personal_access_token, project: project)
          when :ci_job_token
            project_inbound_job_token_disabled
            '${CI_JOB_TOKEN}'
          when :project_deploy_token
            use_ci_variable(name: 'PROJECT_DEPLOY_TOKEN', value: project_deploy_token.token, project: project)
          end
        end

        it 'pushes and pulls a maven package via gradle', testcase: params[:testcase] do
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              gradle_publish_install_yaml = ERB.new(read_fixture('package_managers/maven/gradle', 'gradle_upload_install_package.yaml.erb')).result(binding)
              build_gradle = ERB.new(read_fixture('package_managers/maven/gradle', 'build.gradle.erb')).result(binding)

              commit.project = project
              commit.commit_message = 'Add .gitlab-ci.yml'
              commit.add_files(
                [
                  { file_path: '.gitlab-ci.yml', content: gradle_publish_install_yaml },
                  { file_path: 'build.gradle', content: build_gradle }
                ])
            end
          end

          project.visit!

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('publish')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)

            job.click_element(:pipeline_path)
          end

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('install')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 800)
          end

          Page::Project::Menu.perform(&:go_to_package_registry)

          Page::Project::Packages::Index.perform do |index|
            expect(index).to have_package(package_name)

            index.click_package(package_name)
          end

          Page::Project::Packages::Show.perform do |show|
            expect(show).to have_package_info(package_name, package_version)
          end
        end
      end
    end
  end
end

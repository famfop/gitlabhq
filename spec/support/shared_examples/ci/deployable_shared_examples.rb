# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# rubocop:disable RSpec/ContextWording
RSpec.shared_examples 'a deployable job' do
  it { is_expected.to have_one(:deployment) }

  shared_examples 'calling proper BuildFinishedWorker' do
    it 'calls Ci::BuildFinishedWorker' do
      skip unless described_class == ::Ci::Build

      expect(Ci::BuildFinishedWorker).to receive(:perform_async)

      subject
    end
  end

  describe '#outdated_deployment?' do
    subject { job.outdated_deployment? }

    let(:job) { create(factory_type, :created, :with_deployment, project: project, pipeline: pipeline, environment: 'production') }

    context 'when job has no environment' do
      let(:job) { create(factory_type, :created, pipeline: pipeline, environment: nil) }

      it { expect(subject).to be_falsey }
    end

    context 'when project has forward deployment disabled' do
      before do
        project.ci_cd_settings.update!(forward_deployment_enabled: false)
      end

      it { expect(subject).to be_falsey }
    end

    context 'when job is not an outdated deployment' do
      before do
        allow(job.deployment).to receive(:older_than_last_successful_deployment?).and_return(false)
      end

      it { expect(subject).to be_falsey }
    end

    context 'when job is older than the latest deployment and still pending status' do
      before do
        allow(job.deployment).to receive(:older_than_last_successful_deployment?).and_return(true)
      end

      it { expect(subject).to be_truthy} # rubocop: disable Layout/SpaceInsideBlockBraces
    end

    context 'when job is older than the latest deployment but succeeded once' do
      let(:job) { create(factory_type, :success, :with_deployment, project: project, pipeline: pipeline, environment: 'production') }

      before do
        allow(job.deployment).to receive(:older_than_last_successful_deployment?).and_return(true)
      end

      it 'returns false for allowing rollback' do
        expect(subject).to be_falsey
      end

      context 'when forward_deployment_rollback_allowed option is disabled' do
        before do
          project.ci_cd_settings.update!(forward_deployment_rollback_allowed: false)
        end

        it 'returns true for disallowing rollback' do
          expect(subject).to eq(true)
        end
      end
    end
  end

  describe 'state transition as a deployable' do
    subject { job.send(event) }

    let!(:job) { create(factory_type, :with_deployment, :start_review_app, status: :pending, pipeline: pipeline) }
    let(:deployment) { job.deployment }
    let(:environment) { deployment.environment }

    before do
      allow(Deployments::LinkMergeRequestWorker).to receive(:perform_async)
      allow(Deployments::HooksWorker).to receive(:perform_async)
    end

    it 'has deployments record with created status' do
      expect(deployment).to be_created
      expect(environment.name).to eq('review/master')
    end

    shared_examples_for 'avoid deadlock' do
      it 'executes UPDATE in the right order' do
        recorded = with_cross_database_modification_prevented do
          ActiveRecord::QueryRecorder.new { subject }
        end

        index_for_build = recorded.log.index { |l| l.include?("UPDATE #{Ci::Build.quoted_table_name}") }
        index_for_deployment = recorded.log.index { |l| l.include?("UPDATE \"deployments\"") }

        expect(index_for_build).to be < index_for_deployment
      end
    end

    context 'when transits to running' do
      let(:event) { :run! }

      it_behaves_like 'avoid deadlock'

      it 'transits deployment status to running' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_running
      end

      context 'when deployment is already running state' do
        before do
          job.deployment.success!
        end

        it 'does not change deployment status and tracks an error' do
          expect(Gitlab::ErrorTracking)
            .to receive(:track_exception).with(
              instance_of(Deployment::StatusSyncError), deployment_id: deployment.id, build_id: job.id)

          with_cross_database_modification_prevented do
            expect { subject }.not_to change { deployment.reload.status }
          end
        end
      end
    end

    context 'when transits to success' do
      let(:event) { :success! }

      before do
        allow(Deployments::UpdateEnvironmentWorker).to receive(:perform_async)
        allow(Deployments::HooksWorker).to receive(:perform_async)
      end

      it_behaves_like 'avoid deadlock'
      it_behaves_like 'calling proper BuildFinishedWorker'

      it 'transits deployment status to success' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_success
      end
    end

    context 'when transits to failed' do
      let(:event) { :drop! }

      it_behaves_like 'avoid deadlock'
      it_behaves_like 'calling proper BuildFinishedWorker'

      it 'transits deployment status to failed' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_failed
      end
    end

    context 'when transits to skipped' do
      let(:event) { :skip! }

      it_behaves_like 'avoid deadlock'

      it 'transits deployment status to skipped' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_skipped
      end
    end

    context 'when transits to canceled' do
      let(:event) { :cancel! }

      it_behaves_like 'avoid deadlock'
      it_behaves_like 'calling proper BuildFinishedWorker'

      it 'transits deployment status to canceled' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_canceled
      end
    end

    # Mimic playing a manual job that needs another job.
    # `needs + when:manual` scenario, see: https://gitlab.com/gitlab-org/gitlab/-/issues/347502
    context 'when transits from skipped to created to running' do
      before do
        job.skip!
      end

      context 'during skipped to created' do
        let(:event) { :process! }

        it 'transitions to created' do
          subject

          expect(deployment).to be_created
        end
      end

      context 'during created to running' do
        let(:event) { :run! }

        before do
          job.process!
          job.enqueue!
        end

        it 'transitions to running and calls webhook' do
          freeze_time do
            expect(Deployments::HooksWorker)
              .to receive(:perform_async).with(hash_including({ 'deployment_id' => deployment.id, 'status' => 'running', 'status_changed_at' => Time.current.to_s }))

            subject
          end

          expect(deployment).to be_running
        end
      end
    end
  end

  describe '#on_stop' do
    subject { job.on_stop }

    context 'when a job has a specification that it can be stopped from the other job' do
      let(:job) { create(factory_type, :start_review_app, pipeline: pipeline) }

      it 'returns the other job name' do
        is_expected.to eq('stop_review_app')
      end
    end

    context 'when a job does not have environment information' do
      let(:job) { create(factory_type, pipeline: pipeline) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#environment_tier_from_options' do
    subject { job.environment_tier_from_options }

    let(:job) { Ci::Build.new(options: options) }
    let(:options) { { environment: { deployment_tier: 'production' } } }

    it { is_expected.to eq('production') }

    context 'when options does not include deployment_tier' do
      let(:options) { { environment: { name: 'production' } } }

      it { is_expected.to be_nil }
    end
  end

  describe '#environment_tier' do
    subject { job.environment_tier }

    let(:options) { { environment: { deployment_tier: 'production' } } }
    let!(:environment) { create(:environment, name: 'production', tier: 'development', project: project) }
    let(:job) { Ci::Build.new(options: options, environment: 'production', project: project) }

    it { is_expected.to eq('production') }

    context 'when options does not include deployment_tier' do
      let(:options) { { environment: { name: 'production' } } }

      it 'uses tier from environment' do
        is_expected.to eq('development')
      end

      context 'when persisted environment is absent' do
        let(:environment) { nil }

        it { is_expected.to be_nil }
      end
    end
  end

  describe 'environment' do
    describe '#has_environment_keyword?' do
      subject { job.has_environment_keyword? }

      context 'when environment is defined' do
        before do
          job.update!(environment: 'review')
        end

        it { is_expected.to be_truthy }
      end

      context 'when environment is not defined' do
        before do
          job.update!(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#expanded_environment_name' do
      subject { job.expanded_environment_name }

      context 'when environment uses $CI_COMMIT_REF_NAME' do
        let(:job) do
          create(
            factory_type,
            ref: 'master',
            environment: 'review/$CI_COMMIT_REF_NAME',
            pipeline: pipeline
          )
        end

        it { is_expected.to eq('review/master') }
      end

      context 'when environment uses yaml_variables containing symbol keys' do
        let(:job) do
          create(
            factory_type,
            yaml_variables: [{ key: :APP_HOST, value: 'host' }],
            environment: 'review/$APP_HOST',
            pipeline: pipeline
          )
        end

        it 'returns an expanded environment name with a list of variables' do
          is_expected.to eq('review/host')
        end

        context 'when job metadata has already persisted the expanded environment name' do
          before do
            job.metadata.expanded_environment_name = 'review/foo'
          end

          it 'returns a persisted expanded environment name without a list of variables' do
            expect(job).not_to receive(:simple_variables)

            is_expected.to eq('review/foo')
          end
        end
      end

      context 'when using persisted variables' do
        let(:job) do
          create(factory_type, environment: 'review/x$CI_JOB_ID', pipeline: pipeline)
        end

        it { is_expected.to eq('review/x') }
      end

      context 'when environment name uses a nested variable' do
        let(:yaml_variables) do
          [
            { key: 'ENVIRONMENT_NAME', value: '${CI_COMMIT_REF_NAME}' }
          ]
        end

        let(:job) do
          create(
            factory_type,
            ref: 'master',
            yaml_variables: yaml_variables,
            environment: 'review/$ENVIRONMENT_NAME',
            pipeline: pipeline
          )
        end

        it { is_expected.to eq('review/master') }
      end
    end

    describe '#expanded_kubernetes_namespace' do
      let(:job) { create(factory_type, environment: environment, options: options, pipeline: pipeline) }

      subject { job.expanded_kubernetes_namespace }

      context 'environment and namespace are not set' do
        let(:environment) { nil }
        let(:options) { nil }

        it { is_expected.to be_nil }
      end

      context 'environment is specified' do
        let(:environment) { 'production' }

        context 'namespace is not set' do
          let(:options) { nil }

          it { is_expected.to be_nil }
        end

        context 'namespace is provided' do
          let(:options) do
            {
              environment: {
                name: environment,
                kubernetes: {
                  namespace: namespace
                }
              }
            }
          end

          context 'with a static value' do
            let(:namespace) { 'production' }

            it { is_expected.to eq namespace }
          end

          context 'with a dynamic value' do
            let(:namespace) { 'deploy-$CI_COMMIT_REF_NAME' }

            it { is_expected.to eq 'deploy-master' }
          end
        end
      end
    end

    describe '#deployment_job?' do
      subject { job.deployment_job? }

      context 'when environment is defined' do
        before do
          job.update!(environment: 'review')
        end

        context 'no action is defined' do
          it { is_expected.to be_truthy }
        end

        context 'and start action is defined' do
          before do
            job.update!(options: { environment: { action: 'start' } })
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'when environment is not defined' do
        before do
          job.update!(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#stops_environment?' do
      subject { job.stops_environment? }

      context 'when environment is defined' do
        before do
          job.update!(environment: 'review')
        end

        context 'no action is defined' do
          it { is_expected.to be_falsey }
        end

        context 'and stop action is defined' do
          before do
            job.update!(options: { environment: { action: 'stop' } })
          end

          it { is_expected.to be_truthy }
        end
      end

      context 'when environment is not defined' do
        before do
          job.update!(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#persisted_environment' do
    let!(:environment) do
      create(:environment, project: project, name: "foo-#{project.default_branch}")
    end

    subject { job.persisted_environment }

    context 'when referenced literally' do
      let(:job) do
        create(factory_type, pipeline: pipeline, environment: "foo-#{project.default_branch}")
      end

      it { is_expected.to eq(environment) }
    end

    context 'when referenced with a variable' do
      let(:job) do
        create(factory_type, pipeline: pipeline, environment: "foo-$CI_COMMIT_REF_NAME")
      end

      it { is_expected.to eq(environment) }
    end

    context 'when there is no environment' do
      it { is_expected.to be_nil }
    end

    context 'when job has a stop environment' do
      let(:job) { create(factory_type, :stop_review_app, pipeline: pipeline, environment: "foo-#{project.default_branch}") }

      it 'expands environment name' do
        expect(job).to receive(:expanded_environment_name).and_call_original

        is_expected.to eq(environment)
      end
    end
  end

  describe '#deployment_status' do
    before do
      allow_any_instance_of(Ci::Build).to receive(:create_deployment) # rubocop:disable RSpec/AnyInstanceOf
    end

    context 'when job is a last deployment' do
      let(:job) { create(factory_type, :success, environment: 'production', pipeline: pipeline) }
      let(:environment) { create(:environment, name: 'production', project: job.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: job) }

      it { expect(job.deployment_status).to eq(:last) }
    end

    context 'when there is a newer job with deployment' do
      let(:job) { create(factory_type, :success, environment: 'production', pipeline: pipeline) }
      let(:environment) { create(:environment, name: 'production', project: job.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: job) }
      let!(:last_deployment) { create(:deployment, :success, environment: environment, project: environment.project) }

      it { expect(job.deployment_status).to eq(:out_of_date) }
    end

    context 'when job with deployment has failed' do
      let(:job) { create(factory_type, :failed, environment: 'production', pipeline: pipeline) }
      let(:environment) { create(:environment, name: 'production', project: job.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: job) }

      it { expect(job.deployment_status).to eq(:failed) }
    end

    context 'when job with deployment is running' do
      let(:job) { create(factory_type, environment: 'production', pipeline: pipeline) }
      let(:environment) { create(:environment, name: 'production', project: job.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: job) }

      it { expect(job.deployment_status).to eq(:creating) }
    end
  end

  def factory_type
    described_class.name.underscore.tr('/', '_')
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable RSpec/ContextWording

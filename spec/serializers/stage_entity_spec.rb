# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StageEntity, feature_category: :continuous_integration do
  let(:pipeline) { create(:ci_pipeline) }
  let(:request) { double('request') }
  let(:user) { create(:user) }

  let(:entity) do
    described_class.new(stage, request: request)
  end

  let(:stage) do
    create(:ci_stage, pipeline: pipeline, status: :success)
  end

  before do
    allow(request).to receive(:current_user).and_return(user)
    create(:ci_build, :success, pipeline: pipeline, stage_id: stage.id)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains relevant fields' do
      expect(subject).to include :name, :status, :path
    end

    it 'contains detailed status' do
      expect(subject[:status]).to include :text, :label, :group, :icon, :tooltip
      expect(subject[:status][:label]).to eq s_('CiStatusLabel|passed')
    end

    it 'contains valid name' do
      expect(subject[:name]).to eq 'test'
    end

    it 'contains path to the stage' do
      expect(subject[:path])
        .to include "pipelines/#{pipeline.id}##{stage.name}"
    end

    it 'contains path to the stage dropdown' do
      expect(subject[:dropdown_path])
        .to include "pipelines/#{pipeline.id}/stage.json?stage=test"
    end

    it 'contains stage title' do
      expect(subject[:title]).to eq "test: #{s_('CiStatusLabel|passed')}"
    end

    it 'does not contain play_details info' do
      expect(subject[:status][:action]).not_to be_present
    end

    context 'when the jobs should be grouped' do
      let(:entity) { described_class.new(stage, request: request, grouped: true) }

      it 'exposes the group key' do
        expect(subject).to include :groups
      end

      context 'and contains commit status' do
        before do
          create(:generic_commit_status, pipeline: pipeline, ci_stage: stage)
        end

        it 'contains commit status' do
          groups = subject[:groups].map { |group| group[:name] }
          expect(groups).to include('generic')
        end
      end
    end

    context 'with a skipped stage ' do
      let(:stage) { create(:ci_stage, status: 'skipped') }

      it 'does not contain play_all_manual' do
        expect(subject[:status][:action]).not_to be_present
      end
    end

    context 'with a scheduled stage ' do
      let(:stage) { create(:ci_stage, status: 'scheduled') }

      it 'contains play_all_manual' do
        expect(subject[:status][:action]).to be_present
      end
    end

    context 'with a manual stage ' do
      let(:stage) { create(:ci_stage, status: 'manual') }

      it 'contains play_all_manual' do
        expect(subject[:status][:action]).to be_present
      end
    end
  end
end

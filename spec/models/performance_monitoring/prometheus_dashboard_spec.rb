# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PerformanceMonitoring::PrometheusDashboard do
  let(:json_content) do
    {
      "dashboard" => "Dashboard Title",
      "templating" => {
        "variables" => {
          "variable1" => %w(value1 value2 value3)
        }
      },
      "panel_groups" => [{
        "group" => "Group Title",
        "panels" => [{
          "type" => "area-chart",
          "title" => "Chart Title",
          "y_label" => "Y-Axis",
          "metrics" => [{
            "id" => "metric_of_ages",
            "unit" => "count",
            "label" => "Metric of Ages",
            "query_range" => "http_requests_total"
          }]
        }]
      }]
    }
  end

  describe '.from_json' do
    subject { described_class.from_json(json_content) }

    it 'creates a PrometheusDashboard object' do
      expect(subject).to be_a described_class
      expect(subject.dashboard).to eq(json_content['dashboard'])
      expect(subject.panel_groups).to all(be_a PerformanceMonitoring::PrometheusPanelGroup)
    end

    describe 'validations' do
      shared_examples 'validation failed' do |errors_messages|
        it 'raises error with corresponding messages', :aggregate_failures do
          expect { subject }.to raise_error do |error|
            expect(error).to be_kind_of(ActiveModel::ValidationError)
            expect(error.model.errors.messages).to eq(errors_messages)
          end
        end
      end

      context 'dashboard content is missing' do
        let(:json_content) { nil }

        it_behaves_like 'validation failed', panel_groups: ["should be an array of panel_groups objects"], dashboard: ["can't be blank"]
      end

      context 'dashboard content is NOT a hash' do
        let(:json_content) { YAML.safe_load("'test'") }

        it_behaves_like 'validation failed', panel_groups: ["should be an array of panel_groups objects"], dashboard: ["can't be blank"]
      end

      context 'content is an array' do
        let(:json_content) { [{ "dashboard" => "Dashboard Title" }] }

        it_behaves_like 'validation failed', panel_groups: ["should be an array of panel_groups objects"], dashboard: ["can't be blank"]
      end

      context 'dashboard definition is missing panels_groups and dashboard keys' do
        let(:json_content) do
          {
            "dashboard" => nil
          }
        end

        it_behaves_like 'validation failed', panel_groups: ["should be an array of panel_groups objects"], dashboard: ["can't be blank"]
      end

      context 'group definition is missing panels and group keys' do
        let(:json_content) do
          {
            "dashboard" => "Dashboard Title",
            "templating" => {
              "variables" => {
                "variable1" => %w(value1 value2 value3)
              }
            },
            "panel_groups" => [{ "group" => nil }]
          }
        end

        it_behaves_like 'validation failed', panels: ["should be an array of panels objects"], group: ["can't be blank"]
      end

      context 'panel definition is missing metrics and title keys' do
        let(:json_content) do
          {
            "dashboard" => "Dashboard Title",
            "templating" => {
              "variables" => {
                "variable1" => %w(value1 value2 value3)
              }
            },
            "panel_groups" => [{
              "group" => "Group Title",
              "panels" => [{
                "type" => "area-chart",
                "y_label" => "Y-Axis"
              }]
            }]
          }
        end

        it_behaves_like 'validation failed', metrics: ["should be an array of metrics objects"], title: ["can't be blank"]
      end

      context 'metrics definition is missing unit, query and query_range keys' do
        let(:json_content) do
          {
            "dashboard" => "Dashboard Title",
            "templating" => {
              "variables" => {
                "variable1" => %w(value1 value2 value3)
              }
            },
            "panel_groups" => [{
              "group" => "Group Title",
              "panels" => [{
                "type" => "area-chart",
                "title" => "Chart Title",
                "y_label" => "Y-Axis",
                "metrics" => [{
                  "id" => "metric_of_ages",
                  "label" => "Metric of Ages",
                  "query_range" => nil
                }]
              }]
            }]
          }
        end

        it_behaves_like 'validation failed', unit: ["can't be blank"], query_range: ["can't be blank"], query: ["can't be blank"]
      end

      # for each parent entry validation first is done to its children,
      # whole execution is stopped on first encountered error
      # which is the one that is reported
      context 'multiple offences on different levels' do
        let(:json_content) do
          {
            "dashboard" => nil,
            "panel_groups" => [{
              "group" => nil,
              "panels" => [{
                "type" => "area-chart",
                "title" => nil,
                "y_label" => "Y-Axis",
                "metrics" => [{
                  "id" => "metric_of_ages",
                  "label" => "Metric of Ages",
                  "query_range" => 'query'
                }, {
                  "id" => "metric_of_ages",
                  "unit" => "count",
                  "label" => "Metric of Ages",
                  "query_range" => nil
                }]
              }]
            }, {
              "group" => 'group',
              "panels" => nil
            }]
          }
        end

        it_behaves_like 'validation failed', unit: ["can't be blank"]
      end
    end
  end

  describe '.find_for' do
    let(:project) { build_stubbed(:project) }
    let(:user) { build_stubbed(:user) }
    let(:environment) { build_stubbed(:environment, project: project) }
    let(:path) { ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH }

    context 'dashboard has been found' do
      it 'uses dashboard finder to find and load dashboard data and returns dashboard instance', :aggregate_failures do
        expect(Gitlab::Metrics::Dashboard::Finder).to receive(:find).with(project, user, { environment: environment, dashboard_path: path }).and_return(status: :success, dashboard: json_content)

        dashboard_instance = described_class.find_for(project: project, user: user, path: path, options: { environment: environment })

        expect(dashboard_instance).to be_instance_of described_class
        expect(dashboard_instance.environment).to eq environment
        expect(dashboard_instance.path).to eq path
      end
    end

    context 'dashboard has NOT been found' do
      it 'returns nil' do
        allow(Gitlab::Metrics::Dashboard::Finder).to receive(:find).and_return(http_status: :not_found)

        dashboard_instance = described_class.find_for(project: project, user: user, path: path, options: { environment: environment })

        expect(dashboard_instance).to be_nil
      end
    end

    context 'dashboard has invalid schema', :aggregate_failures do
      it 'still returns dashboard object' do
        expect(Gitlab::Metrics::Dashboard::Finder).to receive(:find).and_return(http_status: :unprocessable_entity)

        dashboard_instance = described_class.find_for(project: project, user: user, path: path, options: { environment: environment })

        expect(dashboard_instance).to be_instance_of described_class
        expect(dashboard_instance.environment).to eq environment
        expect(dashboard_instance.path).to eq path
      end
    end
  end

  describe '#schema_validation_warnings' do
    let(:environment) { create(:environment, project: project) }
    let(:path) { '.gitlab/dashboards/test.yml' }
    let(:project) { create(:project, :repository, :custom_repo, files: { path => dashboard_schema.to_yaml }) }

    subject(:schema_validation_warnings) { described_class.new(dashboard_schema.merge(path: path, environment: environment)).schema_validation_warnings }

    before do
      allow(Gitlab::Metrics::Dashboard::Finder).to receive(:find_raw).with(project, dashboard_path: path).and_call_original
    end

    context 'when schema is invalid' do
      let(:dashboard_schema) { YAML.safe_load(fixture_file('lib/gitlab/metrics/dashboard/dashboard_missing_panel_groups.yml')) }

      it 'returns array with errors messages' do
        instance = described_class.new
        instance.errors.add(:test, 'test error')

        expect(described_class).to receive(:from_json).and_raise(ActiveModel::ValidationError.new(instance))
        expect(described_class.new.schema_validation_warnings).to eq ['test: test error']
      end
    end
  end
end

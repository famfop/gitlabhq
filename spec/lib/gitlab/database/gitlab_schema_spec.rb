# frozen_string_literal: true
require 'spec_helper'

RSpec.shared_examples 'validate path globs' do |path_globs|
  it 'returns an array of path globs' do
    expect(path_globs).to be_an(Array)
    expect(path_globs).to all(be_an(Pathname))
  end
end

RSpec.shared_examples 'validate schema data' do |tables_and_views|
  it 'all tables and views have assigned a known gitlab_schema' do
    expect(tables_and_views).to all(
      match([be_a(String), be_in(Gitlab::Database.schemas_to_base_models.keys.map(&:to_sym))])
    )
  end
end

RSpec.describe Gitlab::Database::GitlabSchema, feature_category: :database do
  shared_examples 'maps table name to table schema' do
    using RSpec::Parameterized::TableSyntax

    where(:name, :classification) do
      'ci_builds'                                    | :gitlab_ci
      'my_schema.ci_builds'                          | :gitlab_ci
      'my_schema.ci_runner_machine_builds_100'       | :gitlab_ci
      'my_schema._test_gitlab_main_table'            | :gitlab_main
      'information_schema.columns'                   | :gitlab_internal
      'audit_events_part_5fc467ac26'                 | :gitlab_main
      '_test_gitlab_main_table'                      | :gitlab_main
      '_test_gitlab_ci_table'                        | :gitlab_ci
      '_test_gitlab_main_clusterwide_table'          | :gitlab_main_clusterwide
      '_test_gitlab_main_cell_table'                 | :gitlab_main_cell
      '_test_gitlab_pm_table'                        | :gitlab_pm
      '_test_my_table'                               | :gitlab_shared
      'pg_attribute'                                 | :gitlab_internal
    end

    with_them do
      it { is_expected.to eq(classification) }
    end
  end

  describe '.deleted_views_and_tables_to_schema' do
    include_examples 'validate schema data', described_class.deleted_views_and_tables_to_schema
  end

  describe '.views_and_tables_to_schema' do
    include_examples 'validate schema data', described_class.views_and_tables_to_schema

    # group configurations by db_docs_dir, since then we expect all sharing this
    # to contain exactly those tables
    Gitlab::Database.all_database_connections.values.group_by(&:db_docs_dir).each do |db_docs_dir, db_infos|
      context "for #{db_docs_dir}" do
        let(:all_gitlab_schemas) { db_infos.flat_map(&:gitlab_schemas).to_set }

        let(:tables_for_gitlab_schemas) do
          described_class.views_and_tables_to_schema.select do |_, gitlab_schema|
            all_gitlab_schemas.include?(gitlab_schema)
          end
        end

        db_infos.to_h { |db_info| [db_info.name, db_info.connection_class] }
          .compact.each do |db_config_name, connection_class|
          context "validates '#{db_config_name}' using '#{connection_class}'" do
            let(:data_sources) { connection_class.connection.data_sources }

            it 'new data sources are added' do
              missing_data_sources = data_sources.to_set - tables_for_gitlab_schemas.keys

              expect(missing_data_sources).to be_empty, \
                "Missing table/view(s) #{missing_data_sources.to_a} not found in " \
                "#{described_class}.views_and_tables_to_schema. " \
                "Any new tables or views must be added to the database dictionary. " \
                "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
            end

            it 'non-existing data sources are removed' do
              extra_data_sources = tables_for_gitlab_schemas.keys.to_set - data_sources

              expect(extra_data_sources).to be_empty, \
                "Extra table/view(s) #{extra_data_sources.to_a} found in " \
                "#{described_class}.views_and_tables_to_schema. " \
                "Any removed or renamed tables or views must be removed from the database dictionary. " \
                "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
            end
          end
        end
      end
    end

    it 'all tables and views are unique' do
      table_and_view_names = described_class.build_dictionary('')
      table_and_view_names += described_class.build_dictionary('views')

      # ignore gitlab_internal due to `ar_internal_metadata`, `schema_migrations`
      table_and_view_names = table_and_view_names
        .reject { |_, gitlab_schema| gitlab_schema == :gitlab_internal }

      duplicated_tables = table_and_view_names
        .group_by(&:first)
        .select { |_, schemas| schemas.count > 1 }
        .keys

      expect(duplicated_tables).to be_empty, \
        "Duplicated table(s) #{duplicated_tables.to_a} found in #{described_class}.views_and_tables_to_schema. " \
        "Any duplicated table must be removed from db/docs/ or ee/db/docs/. " \
        "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
    end
  end

  describe '.dictionary_path_globs' do
    include_examples 'validate path globs', described_class.dictionary_path_globs('')
    include_examples 'validate path globs', described_class.dictionary_path_globs('views')
    include_examples 'validate path globs', described_class.dictionary_path_globs('deleted_views')
    include_examples 'validate path globs', described_class.dictionary_path_globs('deleted_tables')
  end

  describe '.tables_to_schema' do
    let(:database_models) { Gitlab::Database.database_base_models.except(:geo) }
    let(:views) { database_models.flat_map { |_, m| m.connection.views }.sort.uniq }

    subject { described_class.tables_to_schema }

    it 'returns only tables' do
      tables = subject.keys

      expect(tables).not_to include(views.to_set)
    end
  end

  describe '.views_to_schema' do
    let(:database_models) { Gitlab::Database.database_base_models.except(:geo) }
    let(:tables) { database_models.flat_map { |_, m| m.connection.tables }.sort.uniq }

    subject { described_class.views_to_schema }

    it 'returns only views' do
      views = subject.keys

      expect(views).not_to include(tables.to_set)
    end
  end

  describe '.table_schemas!' do
    let(:tables) { %w[projects issues ci_builds] }

    subject { described_class.table_schemas!(tables) }

    it 'returns the matched schemas' do
      expect(subject).to match_array %i[gitlab_main gitlab_ci].to_set
    end

    context 'when one of the tables does not have a matching table schema' do
      let(:tables) { %w[namespaces projects unknown ci_builds] }

      it 'raises error' do
        expect { subject }.to raise_error(/Could not find gitlab schema for table unknown/)
      end
    end
  end

  describe '.table_schema' do
    subject { described_class.table_schema(name) }

    it_behaves_like 'maps table name to table schema'

    context 'when mapping fails' do
      let(:name) { 'unknown_table' }

      it { is_expected.to be_nil }
    end

    context 'when an index name is used as the table name' do
      before do
        ApplicationRecord.connection.execute(<<~SQL)
          CREATE INDEX index_on_projects ON public.projects USING gin (name gin_trgm_ops)
        SQL
      end

      let(:name) { 'index_on_projects' }

      it { is_expected.to be_nil }
    end
  end

  describe '.table_schema!' do
    subject { described_class.table_schema!(name) }

    it_behaves_like 'maps table name to table schema'

    context 'when mapping fails' do
      let(:name) { 'non_existing_table' }

      it "raises error" do
        expect { subject }.to raise_error(
          Gitlab::Database::GitlabSchema::UnknownSchemaError,
          "Could not find gitlab schema for table #{name}: " \
          "Any new or deleted tables must be added to the database dictionary " \
          "See https://docs.gitlab.com/ee/development/database/database_dictionary.html"
        )
      end
    end
  end

  context 'when testing cross schema access' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(Gitlab::Database).to receive(:all_gitlab_schemas).and_return(
        [
          Gitlab::Database::GitlabSchemaInfo.new(
            name: "gitlab_main_clusterwide",
            allow_cross_joins: %i[gitlab_shared gitlab_main],
            allow_cross_transactions: %i[gitlab_internal gitlab_shared gitlab_main],
            allow_cross_foreign_keys: %i[gitlab_main]
          ),
          Gitlab::Database::GitlabSchemaInfo.new(
            name: "gitlab_main",
            allow_cross_joins: %i[gitlab_shared],
            allow_cross_transactions: %i[gitlab_internal gitlab_shared],
            allow_cross_foreign_keys: %i[]
          ),
          Gitlab::Database::GitlabSchemaInfo.new(
            name: "gitlab_ci",
            allow_cross_joins: %i[gitlab_shared],
            allow_cross_transactions: %i[gitlab_internal gitlab_shared],
            allow_cross_foreign_keys: %i[]
          )
        ].index_by(&:name)
      )
    end

    describe '.cross_joins_allowed?' do
      where(:schemas, :result) do
        %i[] | true
        %i[gitlab_main_clusterwide gitlab_main] | true
        %i[gitlab_main_clusterwide gitlab_ci] | false
        %i[gitlab_main_clusterwide gitlab_main gitlab_ci] | false
        %i[gitlab_main_clusterwide gitlab_internal] | false
        %i[gitlab_main gitlab_ci] | false
        %i[gitlab_main_clusterwide gitlab_main gitlab_shared] | true
        %i[gitlab_main_clusterwide gitlab_shared] | true
      end

      with_them do
        it { expect(described_class.cross_joins_allowed?(schemas)).to eq(result) }
      end
    end

    describe '.cross_transactions_allowed?' do
      where(:schemas, :result) do
        %i[] | true
        %i[gitlab_main_clusterwide gitlab_main] | true
        %i[gitlab_main_clusterwide gitlab_ci] | false
        %i[gitlab_main_clusterwide gitlab_main gitlab_ci] | false
        %i[gitlab_main_clusterwide gitlab_internal] | true
        %i[gitlab_main gitlab_ci] | false
        %i[gitlab_main_clusterwide gitlab_main gitlab_shared] | true
        %i[gitlab_main_clusterwide gitlab_shared] | true
      end

      with_them do
        it { expect(described_class.cross_transactions_allowed?(schemas)).to eq(result) }
      end
    end

    describe '.cross_foreign_key_allowed?' do
      where(:schemas, :result) do
        %i[] | false
        %i[gitlab_main_clusterwide gitlab_main] | true
        %i[gitlab_main_clusterwide gitlab_ci] | false
        %i[gitlab_main_clusterwide gitlab_internal] | false
        %i[gitlab_main gitlab_ci] | false
        %i[gitlab_main_clusterwide gitlab_shared] | false
      end

      with_them do
        it { expect(described_class.cross_foreign_key_allowed?(schemas)).to eq(result) }
      end
    end
  end
end

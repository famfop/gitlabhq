# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Namespace::PackageSettings::Update, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }

  let(:params) { { namespace_path: namespace.full_path } }

  specify { expect(described_class).to require_graphql_authorizations(:admin_package) }

  describe '#resolve' do
    subject { described_class.new(object: namespace, context: { current_user: user }, field: nil).resolve(**params) }

    RSpec.shared_examples 'returning a success' do
      it 'returns the namespace package setting with no errors' do
        expect(subject).to eq(
          package_settings: package_settings,
          errors: []
        )
      end
    end

    RSpec.shared_examples 'updating the namespace package setting' do
      it_behaves_like 'updating the namespace package setting attributes',
        from: {
          maven_duplicates_allowed: true,
          maven_duplicate_exception_regex: 'SNAPSHOT',
          generic_duplicates_allowed: true,
          generic_duplicate_exception_regex: 'foo',
          maven_package_requests_forwarding: nil,
          lock_maven_package_requests_forwarding: false,
          npm_package_requests_forwarding: nil,
          lock_npm_package_requests_forwarding: false,
          pypi_package_requests_forwarding: nil,
          lock_pypi_package_requests_forwarding: false
        }, to: {
          maven_duplicates_allowed: false,
          maven_duplicate_exception_regex: 'RELEASE',
          generic_duplicates_allowed: false,
          generic_duplicate_exception_regex: 'bar',
          maven_package_requests_forwarding: true,
          lock_maven_package_requests_forwarding: true,
          npm_package_requests_forwarding: true,
          lock_npm_package_requests_forwarding: true,
          pypi_package_requests_forwarding: true,
          lock_pypi_package_requests_forwarding: true
        }

      it_behaves_like 'returning a success'

      context 'with invalid params' do
        let_it_be(:params) { { namespace_path: namespace.full_path, maven_duplicate_exception_regex: '[' } }

        it_behaves_like 'not creating the namespace package setting'

        it 'doesn\'t update the maven_duplicates_allowed' do
          expect { subject }
            .not_to change { package_settings.reload.maven_duplicates_allowed }
        end

        it 'returns an error' do
          expect(subject).to eq(
            package_settings: nil,
            errors: ['Maven duplicate exception regex not valid RE2 syntax: missing ]: [']
          )
        end
      end
    end

    RSpec.shared_examples 'denying access to namespace package setting' do
      it 'raises Gitlab::Graphql::Errors::ResourceNotAvailable' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    # To be removed when raise_group_admin_package_permission_to_owner FF is removed
    RSpec.shared_examples 'disabling admin_package feature flag' do |action:|
      before do
        stub_feature_flags(raise_group_admin_package_permission_to_owner: false)
      end

      it_behaves_like "#{action} the namespace package setting"
    end

    context 'with existing namespace package setting' do
      let_it_be(:package_settings) { create(:namespace_package_setting, namespace: namespace) }
      let_it_be(:params) do
        {
          namespace_path: namespace.full_path,
          maven_duplicates_allowed: false,
          maven_duplicate_exception_regex: 'RELEASE',
          generic_duplicates_allowed: false,
          generic_duplicate_exception_regex: 'bar',
          maven_package_requests_forwarding: true,
          lock_maven_package_requests_forwarding: true,
          npm_package_requests_forwarding: true,
          lock_npm_package_requests_forwarding: true,
          pypi_package_requests_forwarding: true,
          lock_pypi_package_requests_forwarding: true
        }
      end

      where(:user_role, :shared_examples_name) do
        :owner      | 'updating the namespace package setting'
        :maintainer | 'denying access to namespace package setting'
        :developer  | 'denying access to namespace package setting'
        :reporter   | 'denying access to namespace package setting'
        :guest      | 'denying access to namespace package setting'
        :anonymous  | 'denying access to namespace package setting'
      end

      with_them do
        before do
          namespace.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
        it_behaves_like 'disabling admin_package feature flag', action: :updating if params[:user_role] == :maintainer
      end
    end

    context 'without existing namespace package setting' do
      let_it_be(:package_settings) { namespace.package_settings }

      where(:user_role, :shared_examples_name) do
        :owner      | 'creating the namespace package setting'
        :maintainer | 'denying access to namespace package setting'
        :developer  | 'denying access to namespace package setting'
        :reporter   | 'denying access to namespace package setting'
        :guest      | 'denying access to namespace package setting'
        :anonymous  | 'denying access to namespace package setting'
      end

      with_them do
        before do
          namespace.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
        it_behaves_like 'disabling admin_package feature flag', action: :creating if params[:user_role] == :maintainer
      end
    end
  end
end

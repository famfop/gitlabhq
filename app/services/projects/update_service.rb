# frozen_string_literal: true

module Projects
  class UpdateService < BaseService
    include UpdateVisibilityLevel
    include ValidatesClassificationLabel

    ValidationError = Class.new(StandardError)

    def execute
      build_topics
      remove_unallowed_params
      add_pages_unique_domain

      validate!

      ensure_wiki_exists if enabling_wiki?

      if changing_repository_storage?
        storage_move = project.repository_storage_moves.build(
          source_storage_name: project.repository_storage,
          destination_storage_name: params.delete(:repository_storage)
        )
        storage_move.schedule
      end

      yield if block_given?

      validate_classification_label(project, :external_authorization_classification_label)

      # If the block added errors, don't try to save the project
      return update_failed! if project.errors.any?

      if project.update(params.except(:default_branch))
        after_update

        success
      else
        update_failed!
      end
    rescue ValidationError => e
      error(e.message)
    end

    def run_auto_devops_pipeline?
      return false if project.repository.gitlab_ci_yml || !project.auto_devops&.previous_changes&.include?('enabled')

      project.auto_devops_enabled?
    end

    private

    def add_pages_unique_domain
      if Feature.disabled?(:pages_unique_domain, project)
        params[:project_setting_attributes]&.delete(:pages_unique_domain_enabled)

        return
      end

      return unless params.dig(:project_setting_attributes, :pages_unique_domain_enabled)

      # If the project used a unique domain once, it'll always use the same
      return if project.project_setting.pages_unique_domain_in_database.present?

      params[:project_setting_attributes][:pages_unique_domain] = Gitlab::Pages::RandomDomain.generate(
        project_path: project.path,
        namespace_path: project.parent.full_path
      )
    end

    def validate!
      unless valid_visibility_level_change?(project, project.visibility_attribute_value(params))
        raise ValidationError, s_('UpdateProject|New visibility level not allowed!')
      end

      if renaming_project_with_container_registry_tags?
        raise ValidationError, s_('UpdateProject|Cannot rename project because it contains container registry tags!')
      end

      validate_default_branch_change
    end

    def validate_default_branch_change
      return unless changing_default_branch?

      previous_default_branch = project.default_branch
      new_default_branch = params[:default_branch]

      if project.change_head(new_default_branch)
        params[:previous_default_branch] = previous_default_branch

        if !project.root_ref?(new_default_branch) && has_custom_head_branch?
          raise ValidationError,
            format(
              s_("UpdateProject|Could not set the default branch. Do you have a branch named 'HEAD' in your repository? (%{linkStart}How do I fix this?%{linkEnd})"),
              linkStart: ambiguous_head_documentation_link, linkEnd: '</a>'
            ).html_safe
        end

        after_default_branch_change(previous_default_branch)
      else
        raise ValidationError, s_("UpdateProject|Could not set the default branch")
      end
    end

    def ambiguous_head_documentation_link
      url = Rails.application.routes.url_helpers.help_page_path('user/project/repository/branches/index.md', anchor: 'error-ambiguous-head-branch-exists')

      format('<a href="%{url}" target="_blank" rel="noopener noreferrer">', url: url)
    end

    # See issue: https://gitlab.com/gitlab-org/gitlab/-/issues/381731
    def has_custom_head_branch?
      project.repository.branch_names.any? { |name| name.casecmp('head') == 0 }
    end

    def after_default_branch_change(previous_default_branch)
      # overridden by EE module
    end

    def remove_unallowed_params
      params.delete(:emails_enabled) unless can?(current_user, :set_emails_disabled, project)

      params.delete(:runner_registration_enabled) if Gitlab::CurrentSettings.valid_runner_registrars.exclude?('project')
    end

    def after_update
      todos_features_changes = %w(
        issues_access_level
        merge_requests_access_level
        repository_access_level
      )
      project_changed_feature_keys = project.project_feature.previous_changes.keys

      if project.visibility_level_previous_changes && project.private?
        # don't enqueue immediately to prevent todos removal in case of a mistake
        TodosDestroyer::ConfidentialIssueWorker.perform_in(Todo::WAIT_FOR_DELETE, nil, project.id)
        TodosDestroyer::ProjectPrivateWorker.perform_in(Todo::WAIT_FOR_DELETE, project.id)
      elsif (project_changed_feature_keys & todos_features_changes).present?
        TodosDestroyer::PrivateFeaturesWorker.perform_in(Todo::WAIT_FOR_DELETE, project.id)
      end

      if project.previous_changes.include?('path')
        after_rename_service(project).execute
      else
        system_hook_service.execute_hooks_for(project, :update)
      end

      update_pending_builds if runners_settings_toggled?

      publish_events
    end

    def after_rename_service(project)
      AfterRenameService.new(project, path_before: project.path_before_last_save, full_path_before: project.full_path_before_last_save)
    end

    def update_failed!
      model_errors = project.errors.full_messages.to_sentence
      error_message = model_errors.presence || s_('UpdateProject|Project could not be updated!')

      error(error_message)
    end

    def renaming_project_with_container_registry_tags?
      new_path = params[:path]

      new_path && new_path != project.path &&
        project.has_container_registry_tags?
    end

    def changing_default_branch?
      new_branch = params[:default_branch]

      new_branch && project.repository.exists? &&
        new_branch != project.default_branch
    end

    def enabling_wiki?
      return false if project.wiki_enabled?

      params.dig(:project_feature_attributes, :wiki_access_level).to_i > ProjectFeature::DISABLED
    end

    def ensure_wiki_exists
      return if project.create_wiki

      log_error("Could not create wiki for #{project.full_name}")
      Gitlab::Metrics.counter(:wiki_can_not_be_created_total, 'Counts the times we failed to create a wiki').increment
    end

    def changing_repository_storage?
      new_repository_storage = params[:repository_storage]

      new_repository_storage && project.repository.exists? &&
        project.repository_storage != new_repository_storage &&
        can?(current_user, :change_repository_storage, project)
    end

    def build_topics
      topics = params.delete(:topics)
      tag_list = params.delete(:tag_list)
      topic_list = topics || tag_list

      params[:topic_list] ||= topic_list if topic_list
    end

    def update_pending_builds
      update_params = {
        instance_runners_enabled: project.shared_runners_enabled?,
        namespace_traversal_ids: group_runner_traversal_ids
      }

      ::Ci::UpdatePendingBuildService
        .new(project, update_params)
        .execute
    end

    def shared_runners_settings_toggled?
      project.previous_changes.include?(:shared_runners_enabled)
    end

    def group_runners_settings_toggled?
      return false unless project.ci_cd_settings.present?

      project.ci_cd_settings.previous_changes.include?(:group_runners_enabled)
    end

    def runners_settings_toggled?
      shared_runners_settings_toggled? || group_runners_settings_toggled?
    end

    def group_runner_traversal_ids
      if project.group_runners_enabled?
        project.namespace.traversal_ids
      else
        []
      end
    end

    def publish_events
      publish_project_archived_event
      publish_project_attributed_changed_event
      publish_project_features_changed_event
    end

    def publish_project_archived_event
      return unless project.archived_previously_changed?

      event = Projects::ProjectArchivedEvent.new(data: {
        project_id: @project.id,
        namespace_id: @project.namespace_id,
        root_namespace_id: @project.root_namespace.id
      })

      Gitlab::EventStore.publish(event)
    end

    def publish_project_attributed_changed_event
      changes = @project.previous_changes

      return if changes.blank?

      event = Projects::ProjectAttributesChangedEvent.new(data: {
        project_id: @project.id,
        namespace_id: @project.namespace_id,
        root_namespace_id: @project.root_namespace.id,
        attributes: changes.keys
      })

      Gitlab::EventStore.publish(event)
    end

    def publish_project_features_changed_event
      changes = @project.project_feature.previous_changes

      return if changes.blank?

      event = Projects::ProjectFeaturesChangedEvent.new(data: {
        project_id: @project.id,
        namespace_id: @project.namespace_id,
        root_namespace_id: @project.root_namespace.id,
        features: changes.keys
      })

      Gitlab::EventStore.publish(event)
    end
  end
end

Projects::UpdateService.prepend_mod_with('Projects::UpdateService')

# frozen_string_literal: true

require 'uri'

module ApplicationHelper
  # See https://docs.gitlab.com/ee/development/ee_features.html#code-in-appviews
  # rubocop: disable CodeReuse/ActiveRecord
  # We allow partial to be nil so that collection views can be passed in
  # `render partial: 'some/view', collection: @some_collection`
  def render_if_exists(partial = nil, **options)
    return unless partial_exists?(partial || options[:partial])

    if partial.nil?
      render(**options)
    else
      render(partial, options)
    end
  end

  def dispensable_render(...)
    render(...)
  rescue StandardError => e
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
    nil
  end

  def dispensable_render_if_exists(...)
    render_if_exists(...)
  rescue StandardError => e
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)
    nil
  end

  def partial_exists?(partial)
    lookup_context.exists?(partial, [], true)
  end

  def template_exists?(template)
    lookup_context.exists?(template, [], false)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # Check if a particular controller is the current one
  #
  # args - One or more controller names to check (using path notation when inside namespaces)
  #
  # Examples
  #
  #   # On TreeController
  #   current_controller?(:tree)           # => true
  #   current_controller?(:commits)        # => false
  #   current_controller?(:commits, :tree) # => true
  #
  #   # On Admin::ApplicationController
  #   current_controller?(:application)         # => true
  #   current_controller?('admin/application')  # => true
  #   current_controller?('gitlab/application') # => false
  def current_controller?(*args)
    args.any? do |v|
      Gitlab::Utils.safe_downcase!(v.to_s) == controller.controller_name || Gitlab::Utils.safe_downcase!(v.to_s) == controller.controller_path
    end
  end

  # Check if a particular action is the current one
  #
  # args - One or more action names to check
  #
  # Examples
  #
  #   # On Projects#new
  #   current_action?(:new)           # => true
  #   current_action?(:create)        # => false
  #   current_action?(:new, :create)  # => true
  def current_action?(*args)
    args.any? { |v| Gitlab::Utils.safe_downcase!(v.to_s) == action_name }
  end

  def admin_section?
    controller.class.ancestors.include?(Admin::ApplicationController)
  end

  def last_commit(project)
    if project.repo_exists?
      time_ago_with_tooltip(project.repository.commit.committed_date)
    else
      'Never'
    end
  rescue StandardError
    'Never'
  end

  # Define whenever show last push event
  # with suggestion to create MR
  # rubocop: disable CodeReuse/ActiveRecord
  def show_last_push_widget?(event)
    # Skip if event is not about added or modified non-master branch
    return false unless event && event.last_push_to_non_root? && !event.rm_ref?

    project = event.project

    # Skip if project repo is empty or MR disabled
    return false unless project && !project.empty_repo? && project.feature_available?(:merge_requests, current_user)

    # Skip if user already created appropriate MR
    return false if project.merge_requests.where(source_branch: event.branch_name).opened.any?

    # Skip if user removed branch right after that
    return false unless project.repository.branch_exists?(event.branch_name)

    true
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def hexdigest(string)
    Digest::SHA1.hexdigest string
  end

  def simple_sanitize(str)
    sanitize(str, tags: %w[a span])
  end

  def body_data
    {
      page: body_data_page,
      page_type_id: controller.params[:id],
      find_file: find_file_path,
      group: @group&.path,
      group_full_path: @group&.full_path
    }.merge(project_data)
  end

  def project_data
    return {} unless @project

    {
      project_id: @project.id,
      project: @project.path,
      group: @project.group&.path,
      group_full_path: @project.group&.full_path,
      namespace_id: @project.namespace&.id
    }
  end

  def body_data_page
    [*controller.controller_path.split('/'), controller.action_name].compact.join(':')
  end

  # shortcut for gitlab config
  def gitlab_config
    Gitlab.config.gitlab
  end

  # shortcut for gitlab extra config
  def extra_config
    Gitlab.config.extra
  end

  # shortcut for gitlab registry config
  def registry_config
    Gitlab.config.registry
  end

  # Render a `time` element with Javascript-based relative date and tooltip
  #
  # time       - Time object
  # placement  - Tooltip placement String (default: "top")
  # html_class - Custom class for `time` element (default: "time_ago")
  #
  # By default also includes a `script` element with Javascript necessary to
  # initialize the `timeago` jQuery extension. If this method is called many
  # times, for example rendering hundreds of commits, it's advisable to disable
  # this behavior using the `skip_js` argument and re-initializing `timeago`
  # manually once all of the elements have been rendered.
  #
  # A `js-timeago` class is always added to the element, even when a custom
  # `html_class` argument is provided.
  #
  # Returns an HTML-safe String
  def time_ago_with_tooltip(time, placement: 'top', html_class: '', short_format: false)
    return "" if time.nil?

    css_classes = [short_format ? 'js-short-timeago' : 'js-timeago']
    css_classes << html_class unless html_class.blank?

    content_tag :time, l(time, format: "%b %d, %Y"),
      class: css_classes.join(' '),
      title: l(time.to_time.in_time_zone, format: :timeago_tooltip),
      datetime: time.to_time.getutc.iso8601,
      data: {
        toggle: 'tooltip',
        placement: placement,
        container: 'body'
      }
  end

  def edited_time_ago_with_tooltip(editable_object, placement: 'top', html_class: 'time_ago', exclude_author: false)
    return unless editable_object.edited?

    content_tag :small, class: 'edited-text' do
      timeago = time_ago_with_tooltip(editable_object.last_edited_at, placement: placement, html_class: html_class)

      if !exclude_author && editable_object.last_edited_by
        author_link = link_to_member(editable_object.project, editable_object.last_edited_by, avatar: false, extra_class: 'gl-hover-text-decoration-underline', author_class: nil)
        output = safe_format(_("Edited %{timeago} by %{author}"), timeago: timeago, author: author_link)
      else
        output = safe_format(_("Edited %{timeago}"), timeago: timeago)
      end

      output
    end
  end

  # This needs to be used outside of Rails
  def self.promo_host
    'about.gitlab.com'
  end

  # Convenient method for Rails helper
  def promo_host
    ApplicationHelper.promo_host
  end

  # This needs to be used outside of Rails
  def self.community_forum
    'https://forum.gitlab.com'
  end

  # Convenient method for Rails helper
  def community_forum
    ApplicationHelper.community_forum
  end

  def promo_url
    "https://#{promo_host}"
  end

  def support_url
    Gitlab::CurrentSettings.current_application_settings.help_page_support_url.presence || "#{promo_url}/get-help/"
  end

  def instance_review_permitted?
    ::Gitlab::CurrentSettings.instance_review_permitted? && current_user&.can_read_all_resources?
  end

  def static_objects_external_storage_enabled?
    Gitlab::CurrentSettings.static_objects_external_storage_enabled?
  end

  def external_storage_url_or_path(path, project = @project)
    return path if @snippet || !static_objects_external_storage_enabled?

    uri = URI(Gitlab::CurrentSettings.static_objects_external_storage_url)
    path = URI(path) # `path` could have query parameters, so we need to split query and path apart

    query = Rack::Utils.parse_nested_query(path.query)
    query['token'] = current_user.static_object_token unless project.public?

    uri.path = path.path
    uri.query = query.to_query unless query.empty?

    uri.to_s
  end

  def page_filter_path(options = {})
    without = options.delete(:without)

    options = request.query_parameters.merge(options)

    if without.present?
      without.each do |key|
        options.delete(key)
      end
    end

    "#{request.path}?#{options.compact.to_param}"
  end

  def stylesheet_link_tag_defer(path)
    stylesheet_link_tag(path, media: "all", crossorigin: ActionController::Base.asset_host ? 'anonymous' : nil)
  end

  def sign_in_with_redirect?
    current_page?(new_user_session_path) && session[:user_return_to].present?
  end

  def outdated_browser?
    browser.ie?
  end

  def path_to_key(key, admin = false)
    if admin
      admin_user_key_path(@user, key)
    else
      profile_key_path(key)
    end
  end

  def truncate_first_line(message, length = 50)
    truncate(message.each_line.first.chomp, length: length) if message
  end

  # While similarly named to Rails's `link_to_if`, this method behaves quite differently.
  # If `condition` is truthy, a link will be returned with the result of the block
  # as its body. If `condition` is falsy, only the result of the block will be returned.
  def conditional_link_to(condition, options, html_options = {}, &block)
    if condition
      link_to options, html_options, &block
    else
      capture(&block)
    end
  end

  def page_class
    class_names = []
    class_names << 'issue-boards-page gl-overflow-auto' if current_controller?(:boards)
    class_names << 'epic-boards-page gl-overflow-auto' if current_controller?(:epic_boards)
    class_names << 'with-performance-bar' if performance_bar_enabled?
    class_names << 'with-top-bar' if show_super_sidebar? && !@hide_top_bar
    class_names << system_message_class
    class_names << 'logged-out-marketing-header' if !current_user && ::Gitlab.com?

    class_names
  end

  def system_message_class
    class_names = []

    return class_names unless appearance

    class_names << 'with-system-header' if appearance.show_header?
    class_names << 'with-system-footer' if appearance.show_footer?

    class_names.join(' ')
  end

  # Returns active css class when condition returns true
  # otherwise returns nil.
  #
  # Example:
  #   %li{ class: active_when(params[:filter] == '1') }
  def active_when(condition)
    'active' if condition
  end

  def show_callout?(name)
    cookies[name] != 'true'
  end

  def linkedin_url(user)
    name = user.linkedin
    if %r{\Ahttps?://(www\.)?linkedin\.com/in/}.match?(name)
      name
    else
      "https://www.linkedin.com/in/#{name}"
    end
  end

  def twitter_url(user)
    name = user.twitter
    if %r{\Ahttps?://(www\.)?twitter\.com/}.match?(name)
      name
    else
      "https://twitter.com/#{name}"
    end
  end

  def discord_url(user)
    return '' if user.discord.blank?

    "https://discord.com/users/#{user.discord}"
  end

  def collapsed_sidebar?
    cookies["sidebar_collapsed"] == "true"
  end

  def collapsed_super_sidebar?
    return false if @force_desktop_expanded_sidebar

    cookies["super_sidebar_collapsed"] == "true"
  end

  def locale_path
    asset_path("locale/#{Gitlab::I18n.locale}/app.js")
  end

  # Overridden in EE
  def read_only_message
    return unless Gitlab::Database.read_only?

    _('You are on a read-only GitLab instance.')
  end

  def client_class_list
    "gl-browser-#{browser_id} gl-platform-#{platform_id}"
  end

  def client_js_flags
    {
      "is#{browser_id.titlecase}": true,
      "is#{platform_id.titlecase}": true
    }
  end

  def add_page_specific_style(path, defer: true)
    content_for :page_specific_styles do
      if defer
        stylesheet_link_tag_defer path
      else
        stylesheet_link_tag path
      end
    end
  end

  def page_startup_api_calls
    @api_startup_calls
  end

  def add_page_startup_api_call(api_path, options: {})
    @api_startup_calls ||= {}
    @api_startup_calls[api_path] = options
  end

  def autocomplete_data_sources(object, noteable_type)
    return {} unless object && noteable_type

    if object.is_a?(Group)
      {
        members: members_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
        issues: issues_group_autocomplete_sources_path(object),
        mergeRequests: merge_requests_group_autocomplete_sources_path(object),
        labels: labels_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
        milestones: milestones_group_autocomplete_sources_path(object),
        commands: commands_group_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id])
      }
    else
      {
        members: members_project_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
        issues: issues_project_autocomplete_sources_path(object),
        mergeRequests: merge_requests_project_autocomplete_sources_path(object),
        labels: labels_project_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
        milestones: milestones_project_autocomplete_sources_path(object),
        commands: commands_project_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id]),
        snippets: snippets_project_autocomplete_sources_path(object),
        contacts: contacts_project_autocomplete_sources_path(object, type: noteable_type, type_id: params[:id])
      }
    end
  end

  def asset_to_string(name)
    app = Rails.application
    if Rails.configuration.assets.compile
      app.assets.find_asset(name).to_s
    else
      controller.view_context.render(file: Rails.root.join('public/assets', app.assets_manifest.assets[name]).to_s)
    end
  end

  def gitlab_ui_form_for(record, *args, &block)
    options = args.extract_options!

    form_for(record, *(args << options.merge({ builder: ::Gitlab::FormBuilders::GitlabUiFormBuilder })), &block)
  end

  def gitlab_ui_form_with(**args, &block)
    form_with(**args.merge({ builder: ::Gitlab::FormBuilders::GitlabUiFormBuilder }), &block)
  end

  def hidden_resource_icon(resource, css_class: nil)
    issuable_title = _('This %{issuable} is hidden because its author has been banned')

    case resource
    when Issue
      title = format(issuable_title, issuable: _('issue'))
    when MergeRequest
      title = format(issuable_title, issuable: _('merge request'))
    when Project
      title = _('This project is hidden because its creator has been banned')
    end

    return unless title

    content_tag(:span, class: 'has-tooltip', title: title) do
      sprite_icon('spam', css_class: ['gl-vertical-align-text-bottom', css_class].compact_blank.join(' '))
    end
  end

  private

  def browser_id
    browser.unknown? ? 'generic' : browser.id.to_s
  end

  def platform_id
    browser.platform.unknown? ? 'other' : browser.platform.id.to_s
  end

  def appearance
    ::Appearance.current
  end
end

ApplicationHelper.prepend_mod

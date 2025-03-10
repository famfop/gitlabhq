---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index
---

# Admin Area settings **(FREE SELF)**

As an administrator of a GitLab self-managed instance, you can manage the behavior of your
deployment.

The **Admin Area** is not accessible on GitLab.com, and settings can only be changed by the
GitLab.com administrators. For the settings and limits on the GitLab.com instance,
read [GitLab.com settings](../../user/gitlab_com/index.md).

## Access the Admin Area

To access the **Admin Area**:

1. Sign in to your GitLab instance as an administrator.
1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings**, and the group of settings to view:
   - [General](#general)
   - [Geo](#geo)
   - [CI/CD](#cicd)
   - [Integrations](#integrations)
   - [Metrics and profiling](#metrics-and-profiling)
   - [Network](#network)
   - [Preferences](#preferences)
   - [Reporting](#reporting)
   - [Repository](#repository)
   - [Templates](#templates)

### General

The **General** settings contain:

- [Visibility and access controls](../settings/visibility_and_access_controls.md) - Set default and
 restrict visibility levels. Configure import sources and Git access protocol.
- [Account and limit](../settings/account_and_limit_settings.md) - Set projects and maximum size limits,
 session duration, user options, and check feature availability for namespace plan.
- [Diff limits](../diff_limits.md) - Diff content limits.
- [Sign-up restrictions](../settings/sign_up_restrictions.md) - Configure the way a user creates a new account.
- [Sign in restrictions](../settings/sign_in_restrictions.md) - Set requirements for a user to sign in.
 Enable mandatory two-factor authentication.
- [Terms of Service and Privacy Policy](../settings/terms.md) - Include a Terms of Service agreement
 and Privacy Policy that all users must accept.
- [External Authentication](../../administration/settings/external_authorization.md#configuration) - External Classification Policy Authorization.
- [Web terminal](../integration/terminal.md#limiting-websocket-connection-time) -
 Set max session time for web terminal.
- [FLoC](floc.md) - Enable or disable
 [Federated Learning of Cohorts (FLoC)](https://en.wikipedia.org/wiki/Federated_Learning_of_Cohorts) tracking.
- [GitLab for Slack app](slack_app.md) - Enable and configure the GitLab for Slack app.

### CI/CD

The **CI/CD** settings contain:

- [Continuous Integration and Deployment](../../administration/settings/continuous_integration.md) -
  Auto DevOps, runners and job artifacts.
- [Required pipeline configuration](../../administration/settings/continuous_integration.md#required-pipeline-configuration) -
  Set an instance-wide auto included [pipeline configuration](../../ci/yaml/index.md).
  This pipeline configuration is run after the project's own configuration.
- [Package Registry](../../administration/settings/continuous_integration.md#package-registry-configuration) -
  Settings related to the use and experience of using the GitLab Package Registry. Some
  [risks are involved](../../user/packages/container_registry/reduce_container_registry_storage.md#use-with-external-container-registries)
  in enabling some of these settings.

## Security and Compliance settings

- [License compliance settings](security_and_compliance.md#choose-package-registry-metadata-to-sync): Enable or disable synchronization of package metadata by a registry type.

### Geo **(PREMIUM SELF)**

The **Geo** setting contains:

- [Geo](../geo/index.md) - Replicate your GitLab instance to other
  geographical locations. Redirects to **Admin Area > Geo > Settings** are no
  longer available at **Admin Area > Settings > Geo** in [GitLab 13.0](https://gitlab.com/gitlab-org/gitlab/-/issues/36896).

### Integrations

The **Integrations** settings contain:

- [Elasticsearch](../../integration/advanced_search/elasticsearch.md#enable-advanced-search) -
  Elasticsearch integration. Elasticsearch AWS IAM.
- [Kroki](../integration/kroki.md#enable-kroki-in-gitlab) -
  Allow rendering of diagrams in AsciiDoc and Markdown documents using [kroki.io](https://kroki.io).
- [Mailgun](../integration/mailgun.md) - Enable your GitLab instance
  to receive invite email bounce events from Mailgun, if it is your email provider.
- [PlantUML](../integration/plantuml.md) - Allow rendering of PlantUML
  diagrams in documents.
- [Customer experience improvement and third-party offers](../settings/third_party_offers.md) -
  Control the display of customer experience improvement content and third-party offers.
- [Snowplow](../../development/internal_analytics/snowplow/index.md) - Configure the Snowplow integration.
- [Google GKE](../../user/project/clusters/add_gke_clusters.md) - Google GKE integration enables
  you to provision GKE clusters from GitLab.
- [Amazon EKS](../../user/project/clusters/add_eks_clusters.md) - Amazon EKS integration enables
  you to provision EKS clusters from GitLab.

### Metrics and profiling

The **Metrics and profiling** settings contain:

- [Metrics - Prometheus](../monitoring/prometheus/gitlab_metrics.md) -
  Enable and configure Prometheus metrics.
- [Metrics - Grafana](../monitoring/performance/grafana_configuration.md#integrate-with-gitlab-ui) -
  Enable and configure Grafana.
- [Profiling - Performance bar](../monitoring/performance/performance_bar.md#enable-the-performance-bar-for-non-administrators) -
  Enable access to the Performance Bar for non-administrator users in a given group.
- [Usage statistics](../settings/usage_statistics.md) - Enable or disable version check and Service Ping.

### Network

The **Network** settings contain:

- Performance optimization - Various settings that affect GitLab performance, including:
  - [Write to `authorized_keys` file](../operations/fast_ssh_key_lookup.md#set-up-fast-lookup).
  - [Push event activities limit and bulk push events](../settings/push_event_activities_limit.md).
- [User and IP rate limits](../settings/user_and_ip_rate_limits.md) - Configure limits for web and API requests.
  These rate limits can be overridden:
  - [Package Registry Rate Limits](../settings/package_registry_rate_limits.md) - Configure specific
    limits for Packages API requests that supersede the user and IP rate limits.
  - [Git LFS Rate Limits](../settings/git_lfs_rate_limits.md) - Configure specific limits for
    Git LFS requests that supersede the user and IP rate limits.
  - [Files API Rate Limits](../settings/files_api_rate_limits.md) - Configure specific limits for
    Files API requests that supersede the user and IP rate limits.
  - [Search rate limits](../instance_limits.md#search-rate-limit) - Configure global search request rate limits for authenticated and unauthenticated users.
  - [Deprecated API Rate Limits](../settings/deprecated_api_rate_limits.md) - Configure specific limits
    for deprecated API requests that supersede the user and IP rate limits.
- [Outbound requests](../../security/webhooks.md) - Allow requests to the local network from webhooks and integrations, or deny all outbound requests.
- [Protected Paths](../settings/protected_paths.md) - Configure paths to be protected by Rack Attack.
- [Incident Management Limits](../../operations/incident_management/index.md) - Limit the
  number of inbound alerts that can be sent to a project.
- [Notes creation limit](../settings/rate_limit_on_notes_creation.md) - Set a rate limit on the note creation requests.
- [Get single user limit](../settings/rate_limit_on_users_api.md) - Set a rate limit on users API endpoint to get a user by ID.
- [Projects API rate limits for unauthenticated requests](../settings/rate_limit_on_projects_api.md) - Set a rate limit on Projects list API endpoint for unauthenticated requests.

### Preferences

The **Preferences** settings contain:

- [Email](../settings/email.md) - Various email settings.
- [What's new](../whats-new.md) - Configure **What's new** drawer and content.
- [Help page](help_page.md) - Help page text and support page URL.
- [Pages](../pages/index.md#custom-domain-verification) -
  Size and domain settings for static websites.
- [Polling interval multiplier](../polling.md) -
  Configure how frequently the GitLab UI polls for updates.
- [Gitaly timeouts](gitaly_timeouts.md) - Configure Gitaly timeouts.
- Localization:
  - [Default first day of the week](../../user/profile/preferences.md).
  - [Time tracking](../../user/project/time_tracking.md#limit-displayed-units-to-hours).
- [Sidekiq Job Limits](../settings/sidekiq_job_limits.md) - Limit the size of Sidekiq jobs stored in Redis.

### Reporting

The **Reporting** settings contain:

- Spam and Anti-bot protection:
  - Anti-spam services, such as [reCAPTCHA](../../integration/recaptcha.md),
    [Akismet](../../integration/akismet.md), or [Spamcheck](../reporting/spamcheck.md).
  - [IP address restrictions](../reporting/ip_addr_restrictions.md).
- [Abuse reports](../review_abuse_reports.md) - Set notification email for abuse reports.
- [Git abuse rate limit](../reporting/git_abuse_rate_limit.md) - Configure Git abuse rate limit settings. **(ULTIMATE SELF)**

### Repository

The **Repository** settings contain:

- [Repository's custom initial branch name](../../user/project/repository/branches/default.md#instance-level-custom-initial-branch-name) -
  Set a custom branch name for new repositories created in your instance.
- [Repository's initial default branch protection](../../user/project/repository/branches/default.md#instance-level-default-branch-protection) -
  Configure the branch protections to apply to every repository's default branch.
- [Repository mirror](visibility_and_access_controls.md#enable-project-mirroring) -
  Configure repository mirroring.
- [Repository storage](../repository_storage_types.md) - Configure storage path settings.
- Repository maintenance:
  - [Repository checks](../repository_checks.md) - Configure
    automatic Git checks on repositories.
  - [Housekeeping](../housekeeping.md). Configure automatic
    Git housekeeping on repositories.
  - [Inactive project deletion](../inactive_project_deletion.md). Configure inactive
    project deletion.
- [Repository static objects](../static_objects_external_storage.md) -
  Serve repository static objects (for example, archives and blobs) from an external storage (for example, a CDN).

### Templates **(PREMIUM SELF)**

The **Templates** settings contain:

- [Templates](instance_template_repository.md#configuration) - Set instance-wide template repository.
- [Custom project templates](../custom_project_templates.md) - Select the custom project template source group.

## Default first day of the week

You can change the [Default first day of the week](../../user/profile/preferences.md)
for the entire GitLab instance:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings > Preferences**.
1. Scroll to the **Localization** section, and select your desired first day of the week.

## Default language

You can change the [Default language](../../user/profile/preferences.md)
for the entire GitLab instance:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings > Preferences**.
1. Scroll to the **Localization** section, and select your desired default language.

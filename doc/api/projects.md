---
stage: Data Stores
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Projects API **(FREE)**

Interact with [projects](../user/project/index.md) by using the REST API.

## Project visibility level

A project in GitLab can be private, internal, or public.
The visibility level is determined by the `visibility` field in the project.

For details, see [Project visibility](../user/public_access.md).

The fields returned in responses vary based on the [permissions](../user/permissions.md) of the authenticated user.

## Removals in API v5

These attributes are deprecated, and are scheduled to be removed in v5 of the API:

- `tag_list`: Use the `topics` attribute instead.
- `marked_for_deletion_at`: Use the `marked_for_deletion_on` attribute instead.
  Available only to [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/).
- `approvals_before_merge`: Use the [Merge request approvals API](merge_request_approvals.md) instead.
  Available only to [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/).

## Project merge method

The `merge_method` can use these options:

- `merge`: a merge commit is created for every merge, and merging is allowed if
 no conflicts are present.
- `rebase_merge`: a merge commit is created for every merge, but merging is only
  allowed if fast-forward merge is possible. You can make sure that the target
  branch would build after this merge request builds and merges.
- `ff`: no merge commits are created and all merges are fast-forwarded. Merging
  is only allowed if the branch could be fast-forwarded.

## List all projects

> The `_links.cluster_agents` attribute in the response was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 15.0.

Get a list of all visible projects across GitLab for the authenticated user.
When accessed without authentication, only public projects with _simple_ fields
are returned.

```plaintext
GET /projects
```

| Attribute                                  | Type     | Required               | Description |
|--------------------------------------------|----------|------------------------|-------------|
| `archived`                                 | boolean  | **{dotted-circle}** No | Limit by archived status. |
| `id_after`                                 | integer  | **{dotted-circle}** No | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                                | integer  | **{dotted-circle}** No | Limit results to projects with IDs less than the specified ID. |
| `imported`                                 | boolean  | **{dotted-circle}** No | Limit results to projects which were imported from external systems by current user. |
| `last_activity_after`                      | datetime | **{dotted-circle}** No | Limit results to projects with last activity after specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `last_activity_before`                     | datetime | **{dotted-circle}** No | Limit results to projects with last activity before specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) |
| `membership`                               | boolean  | **{dotted-circle}** No | Limit by projects that the current user is a member of. |
| `min_access_level`                         | integer  | **{dotted-circle}** No | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                                 | string   | **{dotted-circle}** No | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, `last_activity_at`, or `similarity` fields. `repository_size`, `storage_size`, `packages_size` or `wiki_size` fields are only allowed for administrators. `similarity` ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332890) in GitLab 14.1) is only available when searching and is limited to projects that the current user is a member of. Default is `created_at`. |
| `owned`                                    | boolean  | **{dotted-circle}** No | Limit by projects explicitly owned by the current user. |
| `repository_checksum_failed` **(PREMIUM)** | boolean  | **{dotted-circle}** No | Limit projects where the repository checksum calculation has failed. |
| `repository_storage`                       | string   | **{dotted-circle}** No | Limit results to projects stored on `repository_storage`. _(administrators only)_ |
| `search_namespaces`                        | boolean  | **{dotted-circle}** No | Include ancestor namespaces when matching search criteria. Default is `false`. |
| `search`                                   | string   | **{dotted-circle}** No | Return list of projects matching the search criteria. |
| `simple`                                   | boolean  | **{dotted-circle}** No | Return only limited fields for each project. This operation is a no-op without authentication where only simple fields are returned. |
| `sort`                                     | string   | **{dotted-circle}** No | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                                  | boolean  | **{dotted-circle}** No | Limit by projects starred by the current user. |
| `statistics`                               | boolean  | **{dotted-circle}** No | Include project statistics. Available only to users with at least the Reporter role. |
| `topic`                                    | string   | **{dotted-circle}** No | Comma-separated topic names. Limit results to projects that match all of given topics. See `topics` attribute. |
| `topic_id`                                 | integer  | **{dotted-circle}** No | Limit results to projects with the assigned topic given by the topic ID. |
| `visibility`                               | string   | **{dotted-circle}** No | Limit by visibility `public`, `internal`, or `private`. |
| `wiki_checksum_failed` **(PREMIUM)**       | boolean  | **{dotted-circle}** No | Limit projects where the wiki checksum calculation has failed. |
| `with_custom_attributes`                   | boolean  | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(administrator only)_ |
| `with_issues_enabled`                      | boolean  | **{dotted-circle}** No | Limit by enabled issues feature. |
| `with_merge_requests_enabled`              | boolean  | **{dotted-circle}** No | Limit by enabled merge requests feature. |
| `with_programming_language`                | string   | **{dotted-circle}** No | Limit by projects which use the given programming language. |
| `updated_before`                           | datetime | **{dotted-circle}** No | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. For this filter to work, you must also provide `updated_at` as the `order_by` attribute. |
| `updated_after`                           | datetime | **{dotted-circle}** No | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. For this filter to work, you must also provide `updated_at` as the `order_by` attribute. |

This endpoint supports [keyset pagination](rest/index.md#keyset-based-pagination)
for selected `order_by` options.

When `simple=true` or the user is unauthenticated this returns something like:

Example request:

```shell
curl --request GET "https://gitlab.example.com/api/v4/projects"
```

Example response:

```json
[
  {
    "id": 4,
    "description": null,
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "star_count": 0,
    "last_activity_at": "2013-09-30T13:46:02Z",
    "namespace": {
      "id": 2,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": null,
      "web_url": "https://gitlab.example.com/diaspora"
    }
  },
  {
    ...
  }
```

When the user is authenticated and `simple` is not set this returns something like:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "default_branch": "main",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "ssh_url_to_repo": "git@gitlab.example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "https://gitlab.example.com/diaspora/diaspora-client.git",
    "web_url": "https://gitlab.example.com/diaspora/diaspora-client",
    "readme_url": "https://gitlab.example.com/diaspora/diaspora-client/blob/master/README.md",
    "avatar_url": "https://gitlab.example.com/uploads/project/avatar/4/uploads/avatar.png",
    "forks_count": 0,
    "star_count": 0,
    "last_activity_at": "2022-06-24T17:11:26.841Z",
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora",
      "parent_id": null,
      "avatar_url": "https://gitlab.example.com/uploads/project/avatar/6/uploads/avatar.png",
      "web_url": "https://gitlab.example.com/diaspora"
    },
    "container_registry_image_prefix": "registry.gitlab.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "https://gitlab.example.com/api/v4/projects/4",
      "issues": "https://gitlab.example.com/api/v4/projects/4/issues",
      "merge_requests": "https://gitlab.example.com/api/v4/projects/4/merge_requests",
      "repo_branches": "https://gitlab.example.com/api/v4/projects/4/repository/branches",
      "labels": "https://gitlab.example.com/api/v4/projects/4/labels",
      "events": "https://gitlab.example.com/api/v4/projects/4/events",
      "members": "https://gitlab.example.com/api/v4/projects/4/members",
      "cluster_agents": "https://gitlab.example.com/api/v4/projects/4/cluster_agents"
    },
    "packages_enabled": true,
    "empty_repo": false,
    "archived": false,
    "visibility": "public",
    "resolve_outdated_diff_discussions": false,
    "container_expiration_policy": {
      "cadence": "1month",
      "enabled": true,
      "keep_n": 1,
      "older_than": "14d",
      "name_regex": "",
      "name_regex_keep": ".*-main",
      "next_run_at": "2022-06-25T17:11:26.865Z"
    },
    "issues_enabled": true,
    "merge_requests_enabled": true,
    "wiki_enabled": true,
    "jobs_enabled": true,
    "snippets_enabled": true,
    "container_registry_enabled": true,
    "service_desk_enabled": true,
    "can_create_merge_request_in": true,
    "issues_access_level": "enabled",
    "repository_access_level": "enabled",
    "merge_requests_access_level": "enabled",
    "forking_access_level": "enabled",
    "wiki_access_level": "enabled",
    "builds_access_level": "enabled",
    "snippets_access_level": "enabled",
    "pages_access_level": "enabled",
    "analytics_access_level": "enabled",
    "container_registry_access_level": "enabled",
    "security_and_compliance_access_level": "private",
    "emails_disabled": null,
    "emails_enabled": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "lfs_enabled": true,
    "creator_id": 1,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "open_issues_count": 0,
    "ci_default_git_depth": 20,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_job_token_scope_enabled": false,
    "ci_separated_caches": true,
    "public_jobs": true,
    "build_timeout": 3600,
    "auto_cancel_pending_pipelines": "enabled",
    "ci_config_path": "",
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": null,
    "restrict_user_defined_variables": false,
    "request_access_enabled": true,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": true,
    "printing_merge_request_link_enabled": true,
    "merge_method": "merge",
    "squash_option": "default_off",
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "auto_devops_enabled": false,
    "auto_devops_deploy_strategy": "continuous",
    "autoclose_referenced_issues": true,
    "keep_latest_artifact": true,
    "runner_token_expiration_interval": null,
    "external_authorization_classification_label": "",
    "requirements_enabled": false,
    "requirements_access_level": "enabled",
    "security_and_compliance_enabled": false,
    "compliance_frameworks": [],
    "permissions": {
      "project_access": null,
      "group_access": null
    }
  },
  {
    ...
  }
]
```

You can filter by [custom attributes](custom_attributes.md) with:

```plaintext
GET /projects?custom_attributes[key]=value&custom_attributes[other_key]=other_value
```

Example request:

```shell
curl --globoff --request GET "https://gitlab.example.com/api/v4/projects?custom_attributes[location]=Antarctica&custom_attributes[role]=Developer"
```

### Pagination limits

In GitLab 13.0 and later, [offset-based pagination](rest/index.md#offset-based-pagination)
is [limited to 50,000 records](https://gitlab.com/gitlab-org/gitlab/-/issues/34565).
[Keyset pagination](rest/index.md#keyset-based-pagination) is required to retrieve
projects beyond this limit.

Keyset pagination supports only `order_by=id`. Other sorting options aren't available.

## List user projects

> The `_links.cluster_agents` attribute in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 14.10.

Get a list of visible projects owned by the given user. When accessed without
authentication, only public projects are returned.

Prerequisite:

- To view [certain attributes](https://gitlab.com/gitlab-org/gitlab/-/blob/520776fa8e5a11b8275b7c597d75246fcfc74c89/lib/api/entities/project.rb#L109-130), you must be an administrator or have the Owner role for the project.

NOTE:
Only the projects in the user's (specified in `user_id`) namespace are returned. Projects owned by the user in any group or subgroups are not returned. An empty list is returned if a profile is set to private.

This endpoint supports [keyset pagination](rest/index.md#keyset-based-pagination)
for selected `order_by` options.

```plaintext
GET /users/:user_id/projects
```

| Attribute                     | Type    | Required               | Description |
|-------------------------------|---------|------------------------|-------------|
| `user_id`                     | string  | **{check-circle}** Yes | The ID or username of the user. |
| `archived`                    | boolean | **{dotted-circle}** No | Limit by archived status. |
| `id_after`                    | integer | **{dotted-circle}** No | Limit results to projects with IDs greater than the specified ID. |
| `id_before`                   | integer | **{dotted-circle}** No | Limit results to projects with IDs less than the specified ID. |
| `membership`                  | boolean | **{dotted-circle}** No | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer | **{dotted-circle}** No | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                    | string  | **{dotted-circle}** No | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean | **{dotted-circle}** No | Limit by projects explicitly owned by the current user. |
| `search`                      | string  | **{dotted-circle}** No | Return list of projects matching the search criteria. |
| `simple`                      | boolean | **{dotted-circle}** No | Return only limited fields for each project. Without authentication, this operation is a no-op; only simple fields are returned. |
| `sort`                        | string  | **{dotted-circle}** No | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean | **{dotted-circle}** No | Limit by projects starred by the current user. |
| `statistics`                  | boolean | **{dotted-circle}** No | Include project statistics. Available only to users with at least the Reporter role. |
| `visibility`                  | string  | **{dotted-circle}** No | Limit by visibility `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(administrator only)_ |
| `with_issues_enabled`         | boolean | **{dotted-circle}** No | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean | **{dotted-circle}** No | Limit by enabled merge requests feature. |
| `with_programming_language`   | string  | **{dotted-circle}** No | Limit by projects which use the given programming language. |
| `updated_before`              | datetime | **{dotted-circle}** No | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |
| `updated_after`               | datetime | **{dotted-circle}** No | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/master/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 50,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_separated_caches": true,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "marked_for_deletion_at": "2020-04-03", // Deprecated and will be removed in API v5 in favor of marked_for_deletion_on
    "marked_for_deletion_on": "2020-04-03",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/master/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "import_url": null,
    "import_type": null,
    "import_status": "none",
    "import_error": null,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "ci_default_git_depth": 0,
    "ci_forward_deployment_enabled": true,
    "ci_forward_deployment_rollback_allowed": true,
    "ci_allow_fork_pipelines_to_run_in_parent_project": true,
    "ci_separated_caches": true,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true,
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "wiki_size" : 0,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## List projects a user has contributed to

Get a list of visible projects a given user has contributed to.

```plaintext
GET /users/:user_id/contributed_projects
```

| Attribute                     | Type    | Required               | Description |
|-------------------------------|---------|------------------------|-------------|
| `user_id`                     | string  | **{check-circle}** Yes | The ID or username of the user. |
| `order_by`                    | string  | **{dotted-circle}** No | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `simple`                      | boolean | **{dotted-circle}** No | Return only limited fields for each project. Without authentication, this operation is a no-op; only simple fields are returned. |
| `sort`                        | string  | **{dotted-circle}** No | Return projects sorted in `asc` or `desc` order. Default is `desc`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/5/contributed_projects"
```

Example response:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/master/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/master/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true,
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## List projects starred by a user

> The `_links.cluster_agents` attribute in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 14.10.

Get a list of visible projects starred by the given user. When accessed without
authentication, only public projects are returned.

```plaintext
GET /users/:user_id/starred_projects
```

| Attribute                     | Type    | Required               | Description |
|-------------------------------|---------|------------------------|-------------|
| `user_id`                     | string  | **{check-circle}** Yes | The ID or username of the user. |
| `archived`                    | boolean | **{dotted-circle}** No | Limit by archived status. |
| `membership`                  | boolean | **{dotted-circle}** No | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer | **{dotted-circle}** No | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                    | string  | **{dotted-circle}** No | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean | **{dotted-circle}** No | Limit by projects explicitly owned by the current user. |
| `search`                      | string  | **{dotted-circle}** No | Return list of projects matching the search criteria. |
| `simple`                      | boolean | **{dotted-circle}** No | Return only limited fields for each project. Without authentication, this operation is a no-op; only simple fields are returned. |
| `sort`                        | string  | **{dotted-circle}** No | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean | **{dotted-circle}** No | Limit by projects starred by the current user. |
| `statistics`                  | boolean | **{dotted-circle}** No | Include project statistics. Available only to users with at least the Reporter role. |
| `visibility`                  | string  | **{dotted-circle}** No | Limit by visibility `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(administrator only)_ |
| `with_issues_enabled`         | boolean | **{dotted-circle}** No | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean | **{dotted-circle}** No | Limit by enabled merge requests feature. |
| `updated_before`              | datetime | **{dotted-circle}** No | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |
| `updated_after`               | datetime | **{dotted-circle}** No | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/5/starred_projects"
```

Example response:

```json
[
  {
    "id": 4,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-client.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-client.git",
    "web_url": "http://example.com/diaspora/diaspora-client",
    "readme_url": "http://example.com/diaspora/diaspora-client/blob/master/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora client"
    ],
    "topics": [
      "example",
      "disapora client"
    ],
    "owner": {
      "id": 3,
      "name": "Diaspora",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Diaspora Client",
    "name_with_namespace": "Diaspora / Diaspora Client",
    "path": "diaspora-client",
    "path_with_namespace": "diaspora/diaspora-client",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": false,
    "avatar_url": "http://example.com/uploads/project/avatar/4/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 37,
      "storage_size": 1038090,
      "repository_size": 1038090,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  },
  {
    "id": 6,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "master",
    "visibility": "private",
    "ssh_url_to_repo": "git@example.com:brightbox/puppet.git",
    "http_url_to_repo": "http://example.com/brightbox/puppet.git",
    "web_url": "http://example.com/brightbox/puppet",
    "readme_url": "http://example.com/brightbox/puppet/blob/master/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "puppet"
    ],
    "topics": [
      "example",
      "puppet"
    ],
    "owner": {
      "id": 4,
      "name": "Brightbox",
      "created_at": "2013-09-30T13:46:02Z"
    },
    "name": "Puppet",
    "name_with_namespace": "Brightbox / Puppet",
    "path": "puppet",
    "path_with_namespace": "brightbox/puppet",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 4,
      "name": "Brightbox",
      "path": "brightbox",
      "kind": "group",
      "full_path": "brightbox"
    },
    "import_status": "none",
    "import_error": null,
    "permissions": {
      "project_access": {
        "access_level": 10,
        "notification_level": 3
      },
      "group_access": {
        "access_level": 50,
        "notification_level": 3
      }
    },
    "archived": false,
    "avatar_url": null,
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 0,
    "runners_token": "b8547b1dc37721d05889db52fa2f02",
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "auto_devops_enabled": true,
    "auto_devops_deploy_strategy": "continuous",
    "repository_storage": "default",
    "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
    "mirror": false,
    "mirror_user_id": 45,
    "mirror_trigger_builds": false,
    "only_mirror_protected_branches": false,
    "mirror_overwrites_diverged_branches": false,
    "external_authorization_classification_label": null,
    "packages_enabled": true,
    "service_desk_enabled": false,
    "service_desk_address": null,
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "squash_commit_template": null,
    "issue_branch_template": "gitlab/%{id}-%{title}",
    "statistics": {
      "commit_count": 12,
      "storage_size": 2066080,
      "repository_size": 2066080,
      "lfs_objects_size": 0,
      "job_artifacts_size": 0,
      "pipeline_artifacts_size": 0,
      "packages_size": 0,
      "snippets_size": 0,
      "uploads_size": 0
    },
    "container_registry_image_prefix": "registry.example.com/brightbox/puppet",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## Get single project

> The `_links.cluster_agents` attribute in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 14.10.

Get a specific project. This endpoint can be accessed without authentication if
the project is publicly accessible.

```plaintext
GET /projects/:id
```

| Attribute                | Type           | Required               | Description |
|--------------------------|----------------|------------------------|-------------|
| `id`                     | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `license`                | boolean        | **{dotted-circle}** No | Include project license data. |
| `statistics`             | boolean        | **{dotted-circle}** No | Include project statistics. Available only to users with at least the Reporter role. |
| `with_custom_attributes` | boolean        | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(administrators only)_ |

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "master",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null, // to be deprecated in GitLab 13.0 in favor of `name_regex_delete`
    "name_regex_delete": null,
    "name_regex_keep": null,
    "next_run_at": "2020-01-07T21:42:58.658Z"
  },
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/3/foo.jpg",
    "web_url": "http://localhost:3000/groups/diaspora"
  },
  "import_url": null,
  "import_type": null,
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_separated_caches": true,
  "public_jobs": true,
  "shared_with_groups": [
    {
      "group_id": 4,
      "group_name": "Twitter",
      "group_full_path": "twitter",
      "group_access_level": 30
    },
    {
      "group_id": 3,
      "group_name": "Gitlab Org",
      "group_full_path": "gitlab-org",
      "group_access_level": 10
    }
  ],
  "repository_storage": "default",
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "printing_merge_requests_link_enabled": true,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "mirror_user_id": 45,
  "mirror_trigger_builds": false,
  "only_mirror_protected_branches": false,
  "mirror_overwrites_diverged_branches": false,
  "external_authorization_classification_label": null,
  "packages_enabled": true,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "autoclose_referenced_issues": true,
  "suggestion_commit_message": null,
  "enforce_auth_checks_on_uploads": true,
  "merge_commit_template": null,
  "squash_commit_template": null,
  "issue_branch_template": "gitlab/%{id}-%{title}",
  "marked_for_deletion_at": "2020-04-03", // Deprecated and will be removed in API v5 in favor of marked_for_deletion_on
  "marked_for_deletion_on": "2020-04-03",
  "compliance_frameworks": [ "sox" ],
  "statistics": {
    "commit_count": 37,
    "storage_size": 1038090,
    "repository_size": 1038090,
    "wiki_size" : 0,
    "lfs_objects_size": 0,
    "job_artifacts_size": 0,
    "pipeline_artifacts_size": 0,
    "packages_size": 0,
    "snippets_size": 0,
    "uploads_size": 0
  },
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-client",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

Users of [GitLab Ultimate](https://about.gitlab.com/pricing/)
can also see the `only_allow_merge_if_all_status_checks_passed`
parameters using GitLab 15.5 and later:

```json
{
  "id": 1,
  "project_id": 3,
  "only_allow_merge_if_all_status_checks_passed": false,
  ...
}
```

If the project is a fork, the `forked_from_project` field appears in the response.
For this field, if the upstream project is private, a valid token for authentication must be provided.
The field `mr_default_target_self` appears as well. If this value is `false`, then all merge requests
target the upstream project by default.

```json
{
   "id":3,

   ...

   "mr_default_target_self": false,
   "forked_from_project":{
      "id":13083,
      "description":"GitLab Community Edition",
      "name":"GitLab Community Edition",
      "name_with_namespace":"GitLab.org / GitLab Community Edition",
      "path":"gitlab-foss",
      "path_with_namespace":"gitlab-org/gitlab-foss",
      "created_at":"2013-09-26T06:02:36.000Z",
      "default_branch":"master",
      "tag_list":[], //deprecated, use `topics` instead
      "topics":[],
      "ssh_url_to_repo":"git@gitlab.com:gitlab-org/gitlab-foss.git",
      "http_url_to_repo":"https://gitlab.com/gitlab-org/gitlab-foss.git",
      "web_url":"https://gitlab.com/gitlab-org/gitlab-foss",
      "avatar_url":"https://gitlab.com/uploads/-/system/project/avatar/13083/logo-extra-whitespace.png",
      "license_url": "https://gitlab.com/gitlab-org/gitlab/-/blob/master/LICENSE",
      "license": {
        "key": "mit",
        "name": "MIT License",
        "nickname": null,
        "html_url": "http://choosealicense.com/licenses/mit/",
        "source_url": "https://opensource.org/licenses/MIT"
      },
      "star_count":3812,
      "forks_count":3561,
      "last_activity_at":"2018-01-02T11:40:26.570Z",
      "namespace": {
            "id": 72,
            "name": "GitLab.org",
            "path": "gitlab-org",
            "kind": "group",
            "full_path": "gitlab-org",
            "parent_id": null
      }
   }

   ...

}
```

### Templates for issues and merge requests **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55718) in GitLab 13.10.

Users of [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/)
can also see the `issues_template` and `merge_requests_template` parameters for managing
[issue and merge request description templates](../user/project/description_templates.md).

```json
{
  "id": 3,
  "issues_template": null,
  "merge_requests_template": null,
  ...
}
```

## Get project users

Get the users list of a project.

```plaintext
GET /projects/:id/users
```

| Attribute    | Type           | Required               | Description |
|--------------|----------------|------------------------|-------------|
| `id`         | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search`     | string         | **{dotted-circle}** No | Search for specific users. |
| `skip_users` | integer array  | **{dotted-circle}** No | Filter out users with the specified IDs. |

```json
[
  {
    "id": 1,
    "username": "john_smith",
    "name": "John Smith",
    "state": "active",
    "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
    "web_url": "http://localhost:3000/john_smith"
  },
  {
    "id": 2,
    "username": "jack_smith",
    "name": "Jack Smith",
    "state": "blocked",
    "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
    "web_url": "http://localhost:3000/jack_smith"
  }
]
```

## List a project's groups

Get a list of ancestor groups for this project.

```plaintext
GET /projects/:id/groups
```

| Attribute                   | Type              | Required               | Description |
|-----------------------------|-------------------|------------------------|-------------|
| `id`                        | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search`                    | string            | **{dotted-circle}** No | Search for specific groups. |
| `shared_min_access_level`   | integer           | **{dotted-circle}** No | Limit to shared groups with at least this [role (`access_level`)](members.md#roles). |
| `shared_visible_only`       | boolean           | **{dotted-circle}** No | Limit to shared groups user has access to. |
| `skip_groups`               | array of integers | **{dotted-circle}** No | Skip the group IDs passed. |
| `with_shared`               | boolean           | **{dotted-circle}** No | Include projects shared with this group. Default is `false`. |

```json
[
  {
    "id": 1,
    "name": "Foobar Group",
    "avatar_url": "http://localhost:3000/uploads/group/avatar/1/foo.jpg",
    "web_url": "http://localhost:3000/groups/foo-bar",
    "full_name": "Foobar Group",
    "full_path": "foo-bar"
  },
  {
    "id": 2,
    "name": "Shared Group",
    "avatar_url": "http://gitlab.example.com/uploads/group/avatar/1/bar.jpg",
    "web_url": "http://gitlab.example.com/groups/foo/bar",
    "full_name": "Shared Group",
    "full_path": "foo/shared"
  }
]
```

## List a project's shareable groups

Get a list of groups that can be shared with a project

```plaintext
GET /projects/:id/share_locations
```

| Attribute                   | Type              | Required               | Description |
|-----------------------------|-------------------|------------------------|-------------|
| `id`                        | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search`                    | string            | **{dotted-circle}** No | Search for specific groups. |

```json
[
  {
    "id": 22,
    "web_url": "http://127.0.0.1:3000/groups/gitlab-org",
    "name": "Gitlab Org",
    "avatar_url": null,
    "full_name": "Gitlab Org",
    "full_path": "gitlab-org"
  },
  {
    "id": 25,
    "web_url": "http://127.0.0.1:3000/groups/gnuwget",
    "name": "Gnuwget",
    "avatar_url": null,
    "full_name": "Gnuwget",
    "full_path": "gnuwget"
  }
]
```

## Get project events

Refer to the [Events API documentation](events.md#list-a-projects-visible-events).

## Create project

> `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.

Creates a new project owned by the authenticated user.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
POST /projects
```

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your-token>" \
     --header "Content-Type: application/json" --data '{
        "name": "new_project", "description": "New Project", "path": "new_project",
        "namespace_id": "42", "initialize_with_readme": "true"}' \
     --url "https://gitlab.example.com/api/v4/projects/"
```

| Attribute                                                   | Type    | Required               | Description |
|-------------------------------------------------------------|---------|------------------------|-------------|
| `name`                                                      | string  | **{check-circle}** Yes (if `path` isn't provided) | The name of the new project. Equals path if not provided. |
| `path`                                                      | string  | **{check-circle}** Yes (if `name` isn't provided) | Repository name for new project. Generated based on name if not provided (generated as lowercase with dashes). Starting with GitLab 14.9, path must not start or end with a special character and must not contain consecutive special characters. |
| `allow_merge_on_skipped_pipeline`                           | boolean | **{dotted-circle}** No | Set whether or not merge requests can be merged with skipped jobs. |
| `only_allow_merge_if_all_status_checks_passed` **(ULTIMATE)** | boolean | **{dotted-circle}** No | Indicates that merges of merge requests should be blocked unless all status checks have passed. Defaults to false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 with feature flag `only_allow_merge_if_all_status_checks_passed` disabled by default. |
| `analytics_access_level`                                    | string  | **{dotted-circle}** No | One of `disabled`, `private` or `enabled` |
| `approvals_before_merge` **(PREMIUM)**                      | integer | **{dotted-circle}** No | How many approvers should approve merge requests by default. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. |
| `auto_cancel_pending_pipelines`                             | string  | **{dotted-circle}** No | Auto-cancel pending pipelines. This action toggles between an enabled state and a disabled state; it is not a boolean. |
| `auto_devops_deploy_strategy`                               | string  | **{dotted-circle}** No | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`). |
| `auto_devops_enabled`                                       | boolean | **{dotted-circle}** No | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                               | boolean | **{dotted-circle}** No | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                                    | mixed   | **{dotted-circle}** No | Image file for avatar of the project.                |
| `build_git_strategy`                                        | string  | **{dotted-circle}** No | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                             | integer | **{dotted-circle}** No | The maximum amount of time, in seconds, that a job can run. |
| `builds_access_level`                                       | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `ci_config_path`                                            | string  | **{dotted-circle}** No | The path to CI configuration file. |
| `container_expiration_policy_attributes`                    | hash    | **{dotted-circle}** No | Update the image cleanup policy for this project. Accepts: `cadence` (string), `keep_n` (integer), `older_than` (string), `name_regex` (string), `name_regex_delete` (string), `name_regex_keep` (string), `enabled` (boolean). See the [Container Registry](../user/packages/container_registry/reduce_container_registry_storage.md#use-the-cleanup-policy-api) documentation for more information on `cadence`, `keep_n` and `older_than` values. |
| `container_registry_access_level`                           | string  | **{dotted-circle}** No | Set visibility of container registry, for this project, to one of `disabled`, `private` or `enabled`. |
| `container_registry_enabled`                                | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable container registry for this project. Use `container_registry_access_level` instead. |
| `default_branch`                                            | string  | **{dotted-circle}** No | The [default branch](../user/project/repository/branches/default.md) name. Requires `initialize_with_readme` to be `true`. |
| `description`                                               | string  | **{dotted-circle}** No | Short project description. |
| `emails_disabled`                                           | boolean | **{dotted-circle}** No | _(Deprecated)_ Disable email notifications. Use `emails_enabled` instead|
| `emails_enabled`                                            | boolean | **{dotted-circle}** No | Enable email notifications. |
| `external_authorization_classification_label` **(PREMIUM)** | string  | **{dotted-circle}** No | The classification label for the project. |
| `forking_access_level`                                      | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `group_with_project_templates_id` **(PREMIUM)**             | integer | **{dotted-circle}** No | For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true. |
| `import_url`                                                | string  | **{dotted-circle}** No | URL to import repository from. When the URL value isn't empty, you must not set `initialize_with_readme` to `true`. Doing so might result in the [following error](https://gitlab.com/gitlab-org/gitlab/-/issues/360266): `not a git repository`. |
| `initialize_with_readme`                                    | boolean | **{dotted-circle}** No | Whether to create a Git repository with just a `README.md` file. Default is `false`. When this boolean is true, you must not pass `import_url` or other attributes of this endpoint which specify alternative contents for the repository. Doing so might result in the [following error](https://gitlab.com/gitlab-org/gitlab/-/issues/360266): `not a git repository`. |
| `issues_access_level`                                       | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `issues_enabled`                                            | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `jobs_enabled`                                              | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `lfs_enabled`                                               | boolean | **{dotted-circle}** No | Enable LFS. |
| `merge_method`                                              | string  | **{dotted-circle}** No | Set the [merge method](#project-merge-method) used. |
| `merge_pipelines_enabled`                                   | boolean | **{dotted-circle}** No | Enable or disable merge pipelines. |
| `merge_requests_access_level`                               | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `merge_requests_enabled`                                    | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `merge_trains_enabled`                                      | boolean | **{dotted-circle}** No | Enable or disable merge trains. |
| `mirror_trigger_builds` **(PREMIUM)**                       | boolean | **{dotted-circle}** No | Pull mirroring triggers builds. |
| `mirror` **(PREMIUM)**                                      | boolean | **{dotted-circle}** No | Enables pull mirroring in a project. |
| `namespace_id`                                              | integer | **{dotted-circle}** No | Namespace for the new project (defaults to the current user's namespace). |
| `only_allow_merge_if_all_discussions_are_resolved`          | boolean | **{dotted-circle}** No | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_pipeline_succeeds`                     | boolean | **{dotted-circle}** No | Set whether merge requests can only be merged with successful pipelines. This setting is named [**Pipelines must succeed**](../user/project/merge_requests/merge_when_pipeline_succeeds.md#require-a-successful-pipeline-for-merge) in the project settings. |
| `packages_enabled`                                          | boolean | **{dotted-circle}** No | Enable or disable packages repository feature. |
| `pages_access_level`                                        | string  | **{dotted-circle}** No | One of `disabled`, `private`, `enabled`, or `public`. |
| `printing_merge_request_link_enabled`                       | boolean | **{dotted-circle}** No | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                             | boolean | **{dotted-circle}** No | If `true`, jobs can be viewed by non-project members. |
| `releases_access_level`                                     | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `environments_access_level`                                 | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `feature_flags_access_level`                                | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `infrastructure_access_level`                               | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `monitor_access_level`                                      | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `remove_source_branch_after_merge`                          | boolean | **{dotted-circle}** No | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_access_level`                                   | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `repository_storage`                                        | string  | **{dotted-circle}** No | Which storage shard the repository is on. _(administrator only)_ |
| `request_access_enabled`                                    | boolean | **{dotted-circle}** No | Allow users to request member access. |
| `requirements_access_level`                                 | string  | **{dotted-circle}** No | One of `disabled`, `private` or `enabled` |
| `resolve_outdated_diff_discussions`                         | boolean | **{dotted-circle}** No | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `security_and_compliance_access_level`                      | string  | **{dotted-circle}** No | (GitLab 14.9 and later) Security and compliance access level. One of `disabled`, `private`, or `enabled`. |
| `shared_runners_enabled`                                    | boolean | **{dotted-circle}** No | Enable shared runners for this project. |
| `group_runners_enabled`                                     | boolean | **{dotted-circle}** No | Enable group runners for this project. |
| `snippets_access_level`                                     | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `snippets_enabled`                                          | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `squash_option`                                             | string  | **{dotted-circle}** No | One of `never`, `always`, `default_on`, or `default_off`. |
| `tag_list`                                                  | array   | **{dotted-circle}** No | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `template_name`                                             | string  | **{dotted-circle}** No | When used without `use_custom_template`, name of a [built-in project template](../user/project/index.md#create-a-project-from-a-built-in-template). When used with `use_custom_template`, name of a custom project template. |
| `template_project_id` **(PREMIUM)**                         | integer | **{dotted-circle}** No | When used with `use_custom_template`, project ID of a custom project template. Using a project ID is preferable to using `template_name` since `template_name` may be ambiguous. |
| `topics`                                                    | array   | **{dotted-circle}** No | The list of topics for a project; put array of topics, that should be finally assigned to a project. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0.)_ |
| `use_custom_template` **(PREMIUM)**                         | boolean | **{dotted-circle}** No | Use either custom [instance](../administration/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template. |
| `visibility`                                                | string  | **{dotted-circle}** No | See [project visibility level](#project-visibility-level). |
| `wiki_access_level`                                         | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `wiki_enabled`                                              | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

## Create project for user

> `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.

Creates a new project owned by the specified user. Available only for administrators.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
POST /projects/user/:user_id
```

| Attribute                                                   | Type    | Required               | Description |
|-------------------------------------------------------------|---------|------------------------|-------------|
| `user_id`                                                   | integer | **{check-circle}** Yes | The user ID of the project owner. |
| `name`                                                      | string  | **{check-circle}** Yes | The name of the new project. |
| `allow_merge_on_skipped_pipeline`                           | boolean | **{dotted-circle}** No | Set whether or not merge requests can be merged with skipped jobs. |
| `only_allow_merge_if_all_status_checks_passed` **(ULTIMATE)** | boolean | **{dotted-circle}** No | Indicates that merges of merge requests should be blocked unless all status checks have passed. Defaults to false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 with feature flag `only_allow_merge_if_all_status_checks_passed` disabled by default. |
| `analytics_access_level`                                    | string  | **{dotted-circle}** No | One of `disabled`, `private` or `enabled` |
| `approvals_before_merge` **(PREMIUM)**                      | integer | **{dotted-circle}** No | How many approvers should approve merge requests by default. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). |
| `auto_cancel_pending_pipelines`                             | string  | **{dotted-circle}** No | Auto-cancel pending pipelines. This action toggles between an enabled state and a disabled state; it is not a boolean. |
| `auto_devops_deploy_strategy`                               | string  | **{dotted-circle}** No | Auto Deploy strategy (`continuous`, `manual` or `timed_incremental`). |
| `auto_devops_enabled`                                       | boolean | **{dotted-circle}** No | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                               | boolean | **{dotted-circle}** No | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                                    | mixed   | **{dotted-circle}** No | Image file for avatar of the project. |
| `build_git_strategy`                                        | string  | **{dotted-circle}** No | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                             | integer | **{dotted-circle}** No | The maximum amount of time, in seconds, that a job can run. |
| `builds_access_level`                                       | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `ci_config_path`                                            | string  | **{dotted-circle}** No | The path to CI configuration file. |
| `container_registry_access_level`                           | string  | **{dotted-circle}** No | Set visibility of container registry, for this project, to one of `disabled`, `private` or `enabled`. |
| `container_registry_enabled`                                | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable container registry for this project. Use `container_registry_access_level` instead. |
| `default_branch`                                            | string  | **{dotted-circle}** No | The [default branch](../user/project/repository/branches/default.md) name. Requires `initialize_with_readme` to be `true`. |
| `description`                                               | string  | **{dotted-circle}** No | Short project description. |
| `emails_disabled`                                           | boolean | **{dotted-circle}** No | _(Deprecated)_ Disable email notifications. Use `emails_enabled` instead|
| `emails_enabled`                                            | boolean | **{dotted-circle}** No | Enable email notifications. |
| `enforce_auth_checks_on_uploads`                            | boolean | **{dotted-circle}** No | Enforce [auth checks](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files) on uploads. |
| `external_authorization_classification_label` **(PREMIUM)** | string  | **{dotted-circle}** No | The classification label for the project. |
| `forking_access_level`                                      | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `group_with_project_templates_id` **(PREMIUM)**             | integer | **{dotted-circle}** No | For group-level custom templates, specifies ID of group from which all the custom project templates are sourced. Leave empty for instance-level templates. Requires `use_custom_template` to be true. |
| `import_url`                                                | string  | **{dotted-circle}** No | URL to import repository from. |
| `initialize_with_readme`                                    | boolean | **{dotted-circle}** No | `false` by default. |
| `issues_access_level`                                       | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `issues_enabled`                                            | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `jobs_enabled`                                              | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `lfs_enabled`                                               | boolean | **{dotted-circle}** No | Enable LFS. |
| `merge_commit_template`                                     | string  | **{dotted-circle}** No | [Template](../user/project/merge_requests/commit_templates.md) used to create merge commit message in merge requests. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20263) in GitLab 14.5.)_ |
| `merge_method`                                              | string  | **{dotted-circle}** No | Set the [merge method](#project-merge-method) used. |
| `merge_requests_access_level`                               | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `merge_requests_enabled`                                    | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `mirror_trigger_builds` **(PREMIUM)**                       | boolean | **{dotted-circle}** No | Pull mirroring triggers builds. |
| `mirror` **(PREMIUM)**                                      | boolean | **{dotted-circle}** No | Enables pull mirroring in a project. |
| `namespace_id`                                              | integer | **{dotted-circle}** No | Namespace for the new project (defaults to the current user's namespace). |
| `only_allow_merge_if_all_discussions_are_resolved`          | boolean | **{dotted-circle}** No | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_pipeline_succeeds`                     | boolean | **{dotted-circle}** No | Set whether merge requests can only be merged with successful jobs. |
| `packages_enabled`                                          | boolean | **{dotted-circle}** No | Enable or disable packages repository feature. |
| `pages_access_level`                                        | string  | **{dotted-circle}** No | One of `disabled`, `private`, `enabled`, or `public`. |
| `path`                                                      | string  | **{dotted-circle}** No | Custom repository name for new project. By default generated based on name. |
| `printing_merge_request_link_enabled`                       | boolean | **{dotted-circle}** No | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                             | boolean | **{dotted-circle}** No | If `true`, jobs can be viewed by non-project-members. |
| `releases_access_level`                                     | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `environments_access_level`                                 | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `feature_flags_access_level`                                | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `infrastructure_access_level`                               | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `monitor_access_level`                                      | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `remove_source_branch_after_merge`                          | boolean | **{dotted-circle}** No | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_access_level`                                   | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `repository_storage`                                        | string  | **{dotted-circle}** No | Which storage shard the repository is on. _(administrators only)_ |
| `request_access_enabled`                                    | boolean | **{dotted-circle}** No | Allow users to request member access. |
| `requirements_access_level`                                 | string  | **{dotted-circle}** No | One of `disabled`, `private`, `enabled` or `public` |
| `resolve_outdated_diff_discussions`                         | boolean | **{dotted-circle}** No | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `security_and_compliance_access_level`                      | string  | **{dotted-circle}** No | (GitLab 14.9 and later) Security and compliance access level. One of `disabled`, `private`, or `enabled`. |
| `shared_runners_enabled`                                    | boolean | **{dotted-circle}** No | Enable shared runners for this project. |
| `group_runners_enabled`                                     | boolean | **{dotted-circle}** No | Enable group runners for this project. |
| `snippets_access_level`                                     | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `snippets_enabled`                                          | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `issue_branch_template`                                     | string  | **{dotted-circle}** No | Template used to suggest names for [branches created from issues](../user/project/merge_requests/creating_merge_requests.md#from-an-issue). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21243) in GitLab 15.6.)_ |
| `squash_commit_template`                                    | string  | **{dotted-circle}** No | [Template](../user/project/merge_requests/commit_templates.md) used to create squash commit message in merge requests. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345275) in GitLab 14.6.)_ |
| `squash_option`                                             | string  | **{dotted-circle}** No | One of `never`, `always`, `default_on`, or `default_off`. |
| `suggestion_commit_message`                                 | string  | **{dotted-circle}** No | The commit message used to apply merge request [suggestions](../user/project/merge_requests/reviews/suggestions.md). |
| `tag_list`                                                  | array   | **{dotted-circle}** No | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `template_name`                                             | string  | **{dotted-circle}** No | When used without `use_custom_template`, name of a [built-in project template](../user/project/index.md#create-a-project-from-a-built-in-template). When used with `use_custom_template`, name of a custom project template. |
| `topics`                                                    | array   | **{dotted-circle}** No | The list of topics for the project. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0.)_ |
| `use_custom_template` **(PREMIUM)**                         | boolean | **{dotted-circle}** No | Use either custom [instance](../administration/custom_project_templates.md) or [group](../user/group/custom_project_templates.md) (with `group_with_project_templates_id`) project template. |
| `visibility`                                                | string  | **{dotted-circle}** No | See [project visibility level](#project-visibility-level). |
| `wiki_access_level`                                         | string  | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `wiki_enabled`                                              | boolean | **{dotted-circle}** No | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

## Edit project

> `operations_access_level` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/385798) in GitLab 16.0.

Updates an existing project.

If your HTTP repository isn't publicly accessible, add authentication information
to the URL `https://username:password@gitlab.company.com/group/project.git`,
where `password` is a public access key with the `api` scope enabled.

```plaintext
PUT /projects/:id
```

For example, to toggle the setting for
[shared runners on a GitLab.com project](../ci/runners/index.md):

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your-token>" \
     --url "https://gitlab.com/api/v4/projects/<your-project-ID>" \
     --data "shared_runners_enabled=true" # to turn off: "shared_runners_enabled=false"
```

Supported attributes:

| Attribute                                                   | Type           | Required               | Description |
|-------------------------------------------------------------|----------------|------------------------|-------------|
| `id`                                                        | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `allow_merge_on_skipped_pipeline`                           | boolean        | **{dotted-circle}** No | Set whether or not merge requests can be merged with skipped jobs. |
| `allow_pipeline_trigger_approve_deployment` **(PREMIUM)**   | boolean        | **{dotted-circle}** No | Set whether or not a pipeline triggerer is allowed to approve deployments. |
| `only_allow_merge_if_all_status_checks_passed` **(ULTIMATE)** | boolean | **{dotted-circle}** No | Indicates that merges of merge requests should be blocked unless all status checks have passed. Defaults to false.<br/><br/>[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369859) in GitLab 15.5 with feature flag `only_allow_merge_if_all_status_checks_passed` disabled by default. The feature flag was enabled by default in GitLab 15.9. |
| `analytics_access_level`                                    | string         | **{dotted-circle}** No | One of `disabled`, `private` or `enabled` |
| `approvals_before_merge` **(PREMIUM)**                      | integer        | **{dotted-circle}** No | How many approvers should approve merge requests by default. [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/353097) in GitLab 16.0. To configure approval rules, see [Merge request approvals API](merge_request_approvals.md). |
| `auto_cancel_pending_pipelines`                             | string         | **{dotted-circle}** No | Auto-cancel pending pipelines. This action toggles between an enabled state and a disabled state; it is not a boolean. |
| `auto_devops_deploy_strategy`                               | string         | **{dotted-circle}** No | Auto Deploy strategy (`continuous`, `manual`, or `timed_incremental`). |
| `auto_devops_enabled`                                       | boolean        | **{dotted-circle}** No | Enable Auto DevOps for this project. |
| `autoclose_referenced_issues`                               | boolean        | **{dotted-circle}** No | Set whether auto-closing referenced issues on default branch. |
| `avatar`                                                    | mixed          | **{dotted-circle}** No | Image file for avatar of the project.                |
| `build_git_strategy`                                        | string         | **{dotted-circle}** No | The Git strategy. Defaults to `fetch`. |
| `build_timeout`                                             | integer        | **{dotted-circle}** No | The maximum amount of time, in seconds, that a job can run. |
| `builds_access_level`                                       | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `ci_config_path`                                            | string         | **{dotted-circle}** No | The path to CI configuration file. |
| `ci_default_git_depth`                                      | integer        | **{dotted-circle}** No | Default number of revisions for [shallow cloning](../ci/pipelines/settings.md#limit-the-number-of-changes-fetched-during-clone). |
| `ci_forward_deployment_enabled`                             | boolean        | **{dotted-circle}** No | Enable or disable [prevent outdated deployment jobs](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_forward_deployment_rollback_allowed`                    | boolean        | **{dotted-circle}** No | Enable or disable [allow job retries for rollback deployments](../ci/pipelines/settings.md#prevent-outdated-deployment-jobs). |
| `ci_allow_fork_pipelines_to_run_in_parent_project`          | boolean        | **{dotted-circle}** No | Enable or disable [running pipelines in the parent project for merge requests from forks](../ci/pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/325189) in GitLab 15.3.)_ |
| `ci_separated_caches`                                       | boolean        | **{dotted-circle}** No | Set whether or not caches should be [separated](../ci/caching/index.md#cache-key-names) by branch protection status. |
| `container_expiration_policy_attributes`                    | hash           | **{dotted-circle}** No | Update the image cleanup policy for this project. Accepts: `cadence` (string), `keep_n` (integer), `older_than` (string), `name_regex` (string), `name_regex_delete` (string), `name_regex_keep` (string), `enabled` (boolean). |
| `container_registry_access_level`                           | string         | **{dotted-circle}** No | Set visibility of container registry, for this project, to one of `disabled`, `private` or `enabled`. |
| `container_registry_enabled`                                | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable container registry for this project. Use `container_registry_access_level` instead. |
| `default_branch`                                            | string         | **{dotted-circle}** No | The [default branch](../user/project/repository/branches/default.md) name. |
| `description`                                               | string         | **{dotted-circle}** No | Short project description. |
| `emails_disabled`                                           | boolean        | **{dotted-circle}** No | _(Deprecated)_ Disable email notifications. Use `emails_enabled` instead|
| `emails_enabled`                                            | boolean        | **{dotted-circle}** No | Enable email notifications. |
| `enforce_auth_checks_on_uploads`                            | boolean | **{dotted-circle}** No | Enforce [auth checks](../security/user_file_uploads.md#enable-authorization-checks-for-all-media-files) on uploads. |
| `external_authorization_classification_label` **(PREMIUM)** | string         | **{dotted-circle}** No | The classification label for the project. |
| `forking_access_level`                                      | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `import_url`                                                | string         | **{dotted-circle}** No | URL the repository was imported from. |
| `issues_access_level`                                       | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `issues_enabled`                                            | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable issues for this project. Use `issues_access_level` instead. |
| `issues_template` **(PREMIUM)**                             | string         | **{dotted-circle}** No | Default description for Issues. Description is parsed with GitLab Flavored Markdown. See [Templates for issues and merge requests](#templates-for-issues-and-merge-requests). |
| `jobs_enabled`                                              | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable jobs for this project. Use `builds_access_level` instead. |
| `keep_latest_artifact`                                      | boolean        | **{dotted-circle}** No | Disable or enable the ability to keep the latest artifact for this project. |
| `lfs_enabled`                                               | boolean        | **{dotted-circle}** No | Enable LFS. |
| `merge_commit_template`                                     | string         | **{dotted-circle}** No | [Template](../user/project/merge_requests/commit_templates.md) used to create merge commit message in merge requests. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20263) in GitLab 14.5.)_ |
| `merge_method`                                              | string         | **{dotted-circle}** No | Set the [merge method](#project-merge-method) used. |
| `merge_pipelines_enabled`                                   | boolean        | **{dotted-circle}** No | Enable or disable merge pipelines. |
| `merge_requests_access_level`                               | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `merge_requests_enabled`                                    | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable merge requests for this project. Use `merge_requests_access_level` instead. |
| `merge_requests_template` **(PREMIUM)**                     | string         | **{dotted-circle}** No | Default description for merge requests. Description is parsed with GitLab Flavored Markdown. See [Templates for issues and merge requests](#templates-for-issues-and-merge-requests). |
| `merge_trains_enabled`                                      | boolean        | **{dotted-circle}** No | Enable or disable merge trains. |
| `mirror_overwrites_diverged_branches` **(PREMIUM)**         | boolean        | **{dotted-circle}** No | Pull mirror overwrites diverged branches. |
| `mirror_trigger_builds` **(PREMIUM)**                       | boolean        | **{dotted-circle}** No | Pull mirroring triggers builds. |
| `mirror_user_id` **(PREMIUM)**                              | integer        | **{dotted-circle}** No | User responsible for all the activity surrounding a pull mirror event. _(administrators only)_ |
| `mirror` **(PREMIUM)**                                      | boolean        | **{dotted-circle}** No | Enables pull mirroring in a project. |
| `mr_default_target_self`                                    | boolean        | **{dotted-circle}** No | For forked projects, target merge requests to this project. If `false`, the target is the upstream project. |
| `name`                                                      | string         | **{dotted-circle}** No | The name of the project. |
| `only_allow_merge_if_all_discussions_are_resolved`          | boolean        | **{dotted-circle}** No | Set whether merge requests can only be merged when all the discussions are resolved. |
| `only_allow_merge_if_pipeline_succeeds`                     | boolean        | **{dotted-circle}** No | Set whether merge requests can only be merged with successful jobs. |
| `only_mirror_protected_branches` **(PREMIUM)**              | boolean        | **{dotted-circle}** No | Only mirror protected branches. |
| `packages_enabled`                                          | boolean        | **{dotted-circle}** No | Enable or disable packages repository feature. |
| `pages_access_level`                                        | string         | **{dotted-circle}** No | One of `disabled`, `private`, `enabled`, or `public`. |
| `path`                                                      | string         | **{dotted-circle}** No | Custom repository name for the project. By default generated based on name. |
| `printing_merge_request_link_enabled`                       | boolean        | **{dotted-circle}** No | Show link to create/view merge request when pushing from the command line. |
| `public_builds`                                             | boolean        | **{dotted-circle}** No | If `true`, jobs can be viewed by non-project members. |
| `releases_access_level`                                     | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `environments_access_level`                                 | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `feature_flags_access_level`                                | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `infrastructure_access_level`                               | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `monitor_access_level`                                      | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `remove_source_branch_after_merge`                          | boolean        | **{dotted-circle}** No | Enable `Delete source branch` option by default for all new merge requests. |
| `repository_access_level`                                   | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `repository_storage`                                        | string         | **{dotted-circle}** No | Which storage shard the repository is on. _(administrators only)_ |
| `request_access_enabled`                                    | boolean        | **{dotted-circle}** No | Allow users to request member access. |
| `requirements_access_level`                                 | string         | **{dotted-circle}** No | One of `disabled`, `private`, `enabled` or `public` |
| `resolve_outdated_diff_discussions`                         | boolean        | **{dotted-circle}** No | Automatically resolve merge request diffs discussions on lines changed with a push. |
| `restrict_user_defined_variables`                           | boolean        | **{dotted-circle}** No | Allow only users with the Maintainer role to pass user-defined variables when triggering a pipeline. For example when the pipeline is triggered in the UI, with the API, or by a trigger token. |
| `security_and_compliance_access_level`                      | string         | **{dotted-circle}** No | (GitLab 14.9 and later) Security and compliance access level. One of `disabled`, `private`, or `enabled`. |
| `service_desk_enabled`                                      | boolean        | **{dotted-circle}** No | Enable or disable Service Desk feature. |
| `shared_runners_enabled`                                    | boolean        | **{dotted-circle}** No | Enable shared runners for this project. |
| `group_runners_enabled`                                     | boolean        | **{dotted-circle}** No | Enable group runners for this project. |
| `snippets_access_level`                                     | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `snippets_enabled`                                          | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable snippets for this project. Use `snippets_access_level` instead. |
| `issue_branch_template`                                     | string         | **{dotted-circle}** No | Template used to suggest names for [branches created from issues](../user/project/merge_requests/creating_merge_requests.md#from-an-issue). _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21243) in GitLab 15.6.)_ |
| `squash_commit_template`                                    | string         | **{dotted-circle}** No | [Template](../user/project/merge_requests/commit_templates.md) used to create squash commit message in merge requests. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/345275) in GitLab 14.6.)_ |
| `squash_option`                                             | string         | **{dotted-circle}** No | One of `never`, `always`, `default_on`, or `default_off`. |
| `suggestion_commit_message`                                 | string         | **{dotted-circle}** No | The commit message used to apply merge request suggestions. |
| `tag_list`                                                  | array          | **{dotted-circle}** No | _([Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0)_ The list of tags for a project; put array of tags, that should be finally assigned to a project. Use `topics` instead. |
| `topics`                                                    | array          | **{dotted-circle}** No | The list of topics for the project. This replaces any existing topics that are already added to the project. _([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/328226) in GitLab 14.0.)_ |
| `visibility`                                                | string         | **{dotted-circle}** No | See [project visibility level](#project-visibility-level). |
| `wiki_access_level`                                         | string         | **{dotted-circle}** No | One of `disabled`, `private`, or `enabled`. |
| `wiki_enabled`                                              | boolean        | **{dotted-circle}** No | _(Deprecated)_ Enable wiki for this project. Use `wiki_access_level` instead. |

## Fork project

Forks a project into the user namespace of the authenticated user or the one provided.

The forking operation for a project is asynchronous and is completed in a
background job. The request returns immediately. To determine whether the
fork of the project has completed, query the `import_status` for the new project.

```plaintext
POST /projects/:id/fork
```

| Attribute        | Type           | Required               | Description |
|------------------|----------------|------------------------|-------------|
| `id`             | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `description`    | string         | **{dotted-circle}** No | The description assigned to the resultant project after forking.                 |
| `mr_default_target_self` | boolean | **{dotted-circle}** No | For forked projects, target merge requests to this project. If `false`, the target is the upstream project. |
| `name`           | string         | **{dotted-circle}** No | The name assigned to the resultant project after forking.                        |
| `namespace_id`   | integer        | **{dotted-circle}** No | The ID of the namespace that the project is forked to.                           |
| `namespace_path` | string         | **{dotted-circle}** No | The path of the namespace that the project is forked to.                         |
| `namespace`      | integer or string | **{dotted-circle}** No | _(Deprecated)_ The ID or path of the namespace that the project is forked to.    |
| `path`           | string         | **{dotted-circle}** No | The path assigned to the resultant project after forking.                        |
| `visibility`     | string         | **{dotted-circle}** No | The [visibility level](#project-visibility-level) assigned to the resultant project after forking. |

## List forks of a project

> The `_links.cluster_agents` attribute in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 14.10.

List the projects accessible to the calling user that have an established,
forked relationship with the specified project

```plaintext
GET /projects/:id/forks
```

| Attribute                     | Type           | Required               | Description |
|-------------------------------|----------------|------------------------|-------------|
| `id`                          | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `archived`                    | boolean        | **{dotted-circle}** No | Limit by archived status. |
| `membership`                  | boolean        | **{dotted-circle}** No | Limit by projects that the current user is a member of. |
| `min_access_level`            | integer        | **{dotted-circle}** No | Limit by current user minimal [role (`access_level`)](members.md#roles). |
| `order_by`                    | string         | **{dotted-circle}** No | Return projects ordered by `id`, `name`, `path`, `created_at`, `updated_at`, or `last_activity_at` fields. Default is `created_at`. |
| `owned`                       | boolean        | **{dotted-circle}** No | Limit by projects explicitly owned by the current user. |
| `search`                      | string         | **{dotted-circle}** No | Return list of projects matching the search criteria. |
| `simple`                      | boolean        | **{dotted-circle}** No | Return only limited fields for each project. Without authentication, this operation is a no-op; only simple fields are returned. |
| `sort`                        | string         | **{dotted-circle}** No | Return projects sorted in `asc` or `desc` order. Default is `desc`. |
| `starred`                     | boolean        | **{dotted-circle}** No | Limit by projects starred by the current user. |
| `statistics`                  | boolean        | **{dotted-circle}** No | Include project statistics. Available only to users with at least the Reporter role. |
| `visibility`                  | string         | **{dotted-circle}** No | Limit by visibility `public`, `internal`, or `private`. |
| `with_custom_attributes`      | boolean        | **{dotted-circle}** No | Include [custom attributes](custom_attributes.md) in response. _(administrators only)_ |
| `with_issues_enabled`         | boolean        | **{dotted-circle}** No | Limit by enabled issues feature. |
| `with_merge_requests_enabled` | boolean        | **{dotted-circle}** No | Limit by enabled merge requests feature. |
| `updated_before`              | datetime       | **{dotted-circle}** No | Limit results to projects last updated before the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |
| `updated_after`               | datetime       | **{dotted-circle}** No | Limit results to projects last updated after the specified time. Format: ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/393979) in GitLab 15.10. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/forks"
```

Example responses:

```json
[
  {
    "id": 3,
    "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
    "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
    "default_branch": "master",
    "visibility": "internal",
    "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
    "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
    "web_url": "http://example.com/diaspora/diaspora-project-site",
    "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
    "tag_list": [ //deprecated, use `topics` instead
      "example",
      "disapora project"
    ],
    "topics": [
      "example",
      "disapora project"
    ],
    "name": "Diaspora Project Site",
    "name_with_namespace": "Diaspora / Diaspora Project Site",
    "path": "diaspora-project-site",
    "path_with_namespace": "diaspora/diaspora-project-site",
    "issues_enabled": true,
    "open_issues_count": 1,
    "merge_requests_enabled": true,
    "jobs_enabled": true,
    "wiki_enabled": true,
    "snippets_enabled": false,
    "can_create_merge_request_in": true,
    "resolve_outdated_diff_discussions": false,
    "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
    "container_registry_access_level": "disabled",
    "security_and_compliance_access_level": "disabled",
    "created_at": "2013-09-30T13:46:02Z",
    "updated_at": "2013-09-30T13:46:02Z",
    "last_activity_at": "2013-09-30T13:46:02Z",
    "creator_id": 3,
    "namespace": {
      "id": 3,
      "name": "Diaspora",
      "path": "diaspora",
      "kind": "group",
      "full_path": "diaspora"
    },
    "import_status": "none",
    "archived": true,
    "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
    "shared_runners_enabled": true,
    "group_runners_enabled": true,
    "forks_count": 0,
    "star_count": 1,
    "public_jobs": true,
    "shared_with_groups": [],
    "only_allow_merge_if_pipeline_succeeds": false,
    "allow_merge_on_skipped_pipeline": false,
    "restrict_user_defined_variables": false,
    "only_allow_merge_if_all_discussions_are_resolved": false,
    "remove_source_branch_after_merge": false,
    "request_access_enabled": false,
    "merge_method": "merge",
    "squash_option": "default_on",
    "autoclose_referenced_issues": true,
    "enforce_auth_checks_on_uploads": true,
    "suggestion_commit_message": null,
    "merge_commit_template": null,
    "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
    "_links": {
      "self": "http://example.com/api/v4/projects",
      "issues": "http://example.com/api/v4/projects/1/issues",
      "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
      "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
      "labels": "http://example.com/api/v4/projects/1/labels",
      "events": "http://example.com/api/v4/projects/1/events",
      "members": "http://example.com/api/v4/projects/1/members",
      "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
    }
  }
]
```

## Star a project

> The `_links.cluster_agents` attribute in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 14.10.

Stars a given project. Returns status code `304` if the project is already
starred.

```plaintext
POST /projects/:id/star
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/star"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "master",
  "visibility": "internal",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 1,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

## Unstar a project

> The `_links.cluster_agents` attribute in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 14.10.

Unstars a given project. Returns status code `304` if the project is not starred.

```plaintext
POST /projects/:id/unstar
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/unstar"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "master",
  "visibility": "internal",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

## List starrers of a project

List the users who starred the specified project.

```plaintext
GET /projects/:id/starrers
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search`  | string         | **{dotted-circle}** No | Search for specific users. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/starrers"
```

Example responses:

```json
[
  {
    "starred_since": "2019-01-28T14:47:30.642Z",
    "user": {
        "id": 1,
        "username": "jane_smith",
        "name": "Jane Smith",
        "state": "active",
        "avatar_url": "http://localhost:3000/uploads/user/avatar/1/cd8.jpeg",
        "web_url": "http://localhost:3000/jane_smith"
    }
  },
  {
    "starred_since": "2018-01-02T11:40:26.570Z",
    "user": {
      "id": 2,
      "username": "janine_smith",
      "name": "Janine Smith",
      "state": "blocked",
      "avatar_url": "http://gravatar.com/../e32131cd8.jpeg",
      "web_url": "http://localhost:3000/janine_smith"
    }
  }
]
```

## Languages

Get languages used in a project with percentage value.

```plaintext
GET /projects/:id/languages
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/languages"
```

Example response:

```json
{
  "Ruby": 66.69,
  "JavaScript": 22.98,
  "HTML": 7.91,
  "CoffeeScript": 2.42
}
```

## Archive a project

> The `_links.cluster_agents` attribute in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 14.10.

Archives the project if the user is either an administrator or the owner of this
project. This action is idempotent, thus archiving an already archived project
does not change the project.

```plaintext
POST /projects/:id/archive
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/archive"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "master",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": true,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_separated_caches": true,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

## Unarchive a project

> The `_links.cluster_agents` attribute in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 14.10.

Unarchives the project if the user is either an administrator or the owner of
this project. This action is idempotent, thus unarchiving a non-archived project
doesn't change the project.

```plaintext
POST /projects/:id/unarchive
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/unarchive"
```

Example response:

```json
{
  "id": 3,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "default_branch": "master",
  "visibility": "private",
  "ssh_url_to_repo": "git@example.com:diaspora/diaspora-project-site.git",
  "http_url_to_repo": "http://example.com/diaspora/diaspora-project-site.git",
  "web_url": "http://example.com/diaspora/diaspora-project-site",
  "readme_url": "http://example.com/diaspora/diaspora-project-site/blob/master/README.md",
  "tag_list": [ //deprecated, use `topics` instead
    "example",
    "disapora project"
  ],
  "topics": [
    "example",
    "disapora project"
  ],
  "owner": {
    "id": 3,
    "name": "Diaspora",
    "created_at": "2013-09-30T13:46:02Z"
  },
  "name": "Diaspora Project Site",
  "name_with_namespace": "Diaspora / Diaspora Project Site",
  "path": "diaspora-project-site",
  "path_with_namespace": "diaspora/diaspora-project-site",
  "issues_enabled": true,
  "open_issues_count": 1,
  "merge_requests_enabled": true,
  "jobs_enabled": true,
  "wiki_enabled": true,
  "snippets_enabled": false,
  "can_create_merge_request_in": true,
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": false, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "disabled",
  "security_and_compliance_access_level": "disabled",
  "created_at": "2013-09-30T13:46:02Z",
  "updated_at": "2013-09-30T13:46:02Z",
  "last_activity_at": "2013-09-30T13:46:02Z",
  "creator_id": 3,
  "namespace": {
    "id": 3,
    "name": "Diaspora",
    "path": "diaspora",
    "kind": "group",
    "full_path": "diaspora"
  },
  "import_status": "none",
  "import_error": null,
  "permissions": {
    "project_access": {
      "access_level": 10,
      "notification_level": 3
    },
    "group_access": {
      "access_level": 50,
      "notification_level": 3
    }
  },
  "archived": false,
  "avatar_url": "http://example.com/uploads/project/avatar/3/uploads/avatar.png",
  "license_url": "http://example.com/diaspora/diaspora-client/blob/master/LICENSE",
  "license": {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0",
    "nickname": "GNU LGPLv3",
    "html_url": "http://choosealicense.com/licenses/lgpl-3.0/",
    "source_url": "http://www.gnu.org/licenses/lgpl-3.0.txt"
  },
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "forks_count": 0,
  "star_count": 0,
  "runners_token": "b8bc4a7a29eb76ea83cf79e4908c2b",
  "ci_default_git_depth": 50,
  "ci_forward_deployment_enabled": true,
  "ci_forward_deployment_rollback_allowed": true,
  "ci_allow_fork_pipelines_to_run_in_parent_project": true,
  "ci_separated_caches": true,
  "public_jobs": true,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": false,
  "restrict_user_defined_variables": false,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": false,
  "request_access_enabled": false,
  "merge_method": "merge",
  "squash_option": "default_on",
  "autoclose_referenced_issues": true,
  "enforce_auth_checks_on_uploads": true,
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "container_registry_image_prefix": "registry.example.com/diaspora/diaspora-project-site",
  "_links": {
    "self": "http://example.com/api/v4/projects",
    "issues": "http://example.com/api/v4/projects/1/issues",
    "merge_requests": "http://example.com/api/v4/projects/1/merge_requests",
    "repo_branches": "http://example.com/api/v4/projects/1/repository_branches",
    "labels": "http://example.com/api/v4/projects/1/labels",
    "events": "http://example.com/api/v4/projects/1/events",
    "members": "http://example.com/api/v4/projects/1/members",
    "cluster_agents": "http://example.com/api/v4/projects/1/cluster_agents"
  }
}
```

## Delete project

> The default behavior of [Delayed project deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/32935) in GitLab 12.6 was changed to [Immediate deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) in GitLab 13.2.

This endpoint:

- Deletes a project including all associated resources (including issues and
  merge requests).
- In [GitLab 12.6](https://gitlab.com/gitlab-org/gitlab/-/issues/32935) and later, on
  [Premium or Ultimate](https://about.gitlab.com/pricing/) tiers,
  [delayed project deletion](../user/project/settings/index.md#delayed-project-deletion)
  is applied if enabled.
- From [GitLab 15.11](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) on
  [Premium or Ultimate](https://about.gitlab.com/pricing/) tiers, deletes a project immediately if the project is already
  marked for deletion, and the `permanently_remove` and `full_path` parameters are passed.
- From [GitLab 16.0](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) on
  [Premium or Ultimate](https://about.gitlab.com/pricing/) tiers, delayed project deletion is enabled by default.
  The deletion happens after the number of days specified in the
  [default deletion delay](../administration/settings/visibility_and_access_controls.md#deletion-protection).

WARNING:
The option to delete projects immediately from deletion protection settings in the Admin Area was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) in GitLab 15.9 and removed in GitLab 16.0.

```plaintext
DELETE /projects/:id
```

| Attribute                          | Type              | Required               | Description                                                                                                                                                                                                                                              |
|------------------------------------|-------------------|------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                               | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding).                                                                                                                                                                     |
| `permanently_remove` **(PREMIUM)** | boolean/string    | no                     | Immediately deletes a project if it is marked for deletion. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) in GitLab 15.11                                                                                                           |
| `full_path` **(PREMIUM)**          | string            | no                     | Full path of project to use with `permanently_remove`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/396500) in GitLab 15.11. To find the project path, use `path_with_namespace` from [get single project](projects.md#get-single-project) |

## Restore project marked for deletion **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32935) in GitLab 12.6.

Restores project marked for deletion.

```plaintext
POST /projects/:id/restore
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

## Upload a file

> - Maximum attachment size enforcement [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57250) in GitLab 13.11 [with a flag](../administration/feature_flags.md) named `enforce_max_attachment_size_upload_api`. Disabled by default.
> - Maximum attachment size [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62542) in GitLab 13.11.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112450) in GitLab 15.10. Feature flag `enforce_max_attachment_size_upload_api` removed.

Uploads a file to the specified project to be used in an issue or merge request
description, or a comment.

```plaintext
POST /projects/:id/uploads
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `file`    | string         | **{check-circle}** Yes | The file to be uploaded. |
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

To upload a file from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to a file on your file system and be preceded by
`@`. For example:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "file=@dk.png" "https://gitlab.example.com/api/v4/projects/5/uploads"
```

Returned object:

```json
{
  "alt": "dk",
  "url": "/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "full_path": "/namespace1/project1/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png",
  "markdown": "![dk](/uploads/66dbcd21ec5d24ed6ea225176098d52b/dk.png)"
}
```

The returned `url` is relative to the project path. The returned `full_path` is
the absolute path to the file. In Markdown contexts, the link is expanded when
the format in `markdown` is used.

## Upload a project avatar

Uploads an avatar to the specified project.

```plaintext
PUT /projects/:id
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `avatar`  | string         | **{check-circle}** Yes | The file to be uploaded. |
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

To upload an avatar from your file system, use the `--form` argument. This causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to an image file on your file system and be
preceded by `@`. For example:

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form "avatar=@dk.png" "https://gitlab.example.com/api/v4/projects/5"
```

Returned object:

```json
{
  "avatar_url": "https://gitlab.example.com/uploads/-/system/project/avatar/2/dk.png"
}
```

## Remove a project avatar

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/92604) in GitLab 15.4.

To remove a project avatar, use a blank value for the `avatar` attribute.

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --data "avatar=" "https://gitlab.example.com/api/v4/projects/5"
```

## Share project with group

Allow to share project with group.

```plaintext
POST /projects/:id/share
```

| Attribute      | Type           | Required               | Description |
|----------------|----------------|------------------------|-------------|
| `group_access` | integer        | **{check-circle}** Yes | The [role (`access_level`)](members.md#roles) to grant the group. |
| `group_id`     | integer        | **{check-circle}** Yes | The ID of the group to share with. |
| `id`           | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `expires_at`   | string         | **{dotted-circle}** No | Share expiration date in ISO 8601 format: 2016-09-26 |

## Delete a shared project link within a group

Unshare the project from the group. Returns `204` and no content on success.

```plaintext
DELETE /projects/:id/share/:group_id
```

| Attribute  | Type           | Required               | Description |
|------------|----------------|------------------------|-------------|
| `group_id` | integer        | **{check-circle}** Yes | The ID of the group. |
| `id`       | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/share/17"
```

## Import project members

Import members from another project.

If the importing member's role in the target project is:

- Maintainer, then members with the Owner role in the source project are imported with the Maintainer role.
- Owner, then members with the Owner role in the source project are imported with the Owner role.

```plaintext
POST /projects/:id/import_project_members/:project_id
```

| Attribute    | Type              | Required               | Description |
|--------------|-------------------|------------------------|-------------|
| `id`         | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path](rest/index.md#namespaced-path-encoding) of the target project to receive the members. |
| `project_id` | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path](rest/index.md#namespaced-path-encoding) of the source project to import the members from. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/import_project_members/32"
```

Returns:

- `200 OK` on success.
- `404 Project Not Found` if the target or source project does not exist or cannot be accessed by the requester.
- `422 Unprocessable Entity` if the import of project members does not complete successfully.

Example responses:

When all emails were successfully sent (`200` HTTP status code):

```json
{  "status":  "success"  }
```

When there was any error importing 1 or more members (`200` HTTP status code):

```json
{
  "status": "error",
  "message": {
               "john_smith": "Some individual error message",
               "jane_smith": "Some individual error message"
             },
  "total_members_count": 3
}
```

When there is a system error (`404` and `422` HTTP status codes):

```json
{  "message":  "Import failed"  }
```

## Hooks

Also called Project Hooks and Webhooks. These are different for [System Hooks](system_hooks.md)
that are system-wide.

### List project hooks

Get a list of project hooks.

```plaintext
GET /projects/:id/hooks
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

### Get project hook

Get a specific hook for a project.

```plaintext
GET /projects/:id/hooks/:hook_id
```

| Attribute | Type           | Required               | Description               |
|-----------|----------------|------------------------|---------------------------|
| `hook_id` | integer        | **{check-circle}** Yes | The ID of a project hook. |
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```json
{
  "id": 1,
  "url": "http://example.com/hook",
  "project_id": 3,
  "push_events": true,
  "push_events_branch_filter": "",
  "issues_events": true,
  "confidential_issues_events": true,
  "merge_requests_events": true,
  "tag_push_events": true,
  "note_events": true,
  "confidential_note_events": true,
  "job_events": true,
  "pipeline_events": true,
  "wiki_page_events": true,
  "deployment_events": true,
  "releases_events": true,
  "enable_ssl_verification": true,
  "repository_update_events": false,
  "alert_status": "executable",
  "disabled_until": null,
  "url_variables": [ ],
  "created_at": "2012-10-12T17:04:47Z"
}
```

### Add project hook

Adds a hook to a specified project.

```plaintext
POST /projects/:id/hooks
```

| Attribute                    | Type           | Required               | Description |
|------------------------------|----------------|------------------------|-------------|
| `id`                         | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `url`                        | string         | **{check-circle}** Yes | The hook URL. |
| `confidential_issues_events` | boolean        | **{dotted-circle}** No | Trigger hook on confidential issues events. |
| `confidential_note_events`   | boolean        | **{dotted-circle}** No | Trigger hook on confidential note events. |
| `deployment_events`          | boolean        | **{dotted-circle}** No | Trigger hook on deployment events. |
| `enable_ssl_verification`    | boolean        | **{dotted-circle}** No | Do SSL verification when triggering the hook. |
| `issues_events`              | boolean        | **{dotted-circle}** No | Trigger hook on issues events. |
| `job_events`                 | boolean        | **{dotted-circle}** No | Trigger hook on job events. |
| `merge_requests_events`      | boolean        | **{dotted-circle}** No | Trigger hook on merge requests events. |
| `note_events`                | boolean        | **{dotted-circle}** No | Trigger hook on note events. |
| `pipeline_events`            | boolean        | **{dotted-circle}** No | Trigger hook on pipeline events. |
| `push_events_branch_filter`  | string         | **{dotted-circle}** No | Trigger hook on push events for matching branches only. |
| `push_events`                | boolean        | **{dotted-circle}** No | Trigger hook on push events. |
| `releases_events`            | boolean        | **{dotted-circle}** No | Trigger hook on release events. |
| `tag_push_events`            | boolean        | **{dotted-circle}** No | Trigger hook on tag push events. |
| `token`                      | string         | **{dotted-circle}** No | Secret token to validate received payloads; the token isn't returned in the response. |
| `wiki_page_events`           | boolean        | **{dotted-circle}** No | Trigger hook on wiki events. |

### Edit project hook

Edits a hook for a specified project.

```plaintext
PUT /projects/:id/hooks/:hook_id
```

| Attribute                    | Type           | Required               | Description |
|------------------------------|----------------|------------------------|-------------|
| `hook_id`                    | integer        | **{check-circle}** Yes | The ID of the project hook. |
| `id`                         | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `url`                        | string         | **{check-circle}** Yes | The hook URL. |
| `confidential_issues_events` | boolean        | **{dotted-circle}** No | Trigger hook on confidential issues events. |
| `confidential_note_events`   | boolean        | **{dotted-circle}** No | Trigger hook on confidential note events. |
| `deployment_events`          | boolean        | **{dotted-circle}** No | Trigger hook on deployment events. |
| `enable_ssl_verification`    | boolean        | **{dotted-circle}** No | Do SSL verification when triggering the hook. |
| `issues_events`              | boolean        | **{dotted-circle}** No | Trigger hook on issues events. |
| `job_events`                 | boolean        | **{dotted-circle}** No | Trigger hook on job events. |
| `merge_requests_events`      | boolean        | **{dotted-circle}** No | Trigger hook on merge requests events. |
| `note_events`                | boolean        | **{dotted-circle}** No | Trigger hook on note events. |
| `pipeline_events`            | boolean        | **{dotted-circle}** No | Trigger hook on pipeline events. |
| `push_events_branch_filter`  | string         | **{dotted-circle}** No | Trigger hook on push events for matching branches only. |
| `push_events`                | boolean        | **{dotted-circle}** No | Trigger hook on push events. |
| `releases_events`            | boolean        | **{dotted-circle}** No | Trigger hook on release events. |
| `tag_push_events`            | boolean        | **{dotted-circle}** No | Trigger hook on tag push events. |
| `token`                      | string         | **{dotted-circle}** No | Secret token to validate received payloads. Not returned in the response. When you change the webhook URL, the secret token is reset and not retained. |
| `wiki_page_events`           | boolean        | **{dotted-circle}** No | Trigger hook on wiki page events. |

### Delete project hook

Removes a hook from a project. This method is idempotent, and can be called
multiple times. Either the hook is available or not.

```plaintext
DELETE /projects/:id/hooks/:hook_id
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `hook_id` | integer        | **{check-circle}** Yes | The ID of the project hook. |
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

Note the JSON response differs if the hook is available or not. If the project
hook is available before it's returned in the JSON response or an empty response
is returned.

## Fork relationship

Allows modification of the forked relationship between existing projects.
Available only for project owners and administrators.

### Create a forked from/to relation between existing projects

```plaintext
POST /projects/:id/fork/:forked_from_id
```

| Attribute        | Type           | Required               | Description |
|------------------|----------------|------------------------|-------------|
| `forked_from_id` | ID             | **{check-circle}** Yes | The ID of the project that was forked from. |
| `id`             | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

### Delete an existing forked from relationship

```plaintext
DELETE /projects/:id/fork
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

## Search for projects by name

Search for projects by name which are accessible to the authenticated user. This
endpoint can be accessed without authentication if the project is publicly
accessible.

```plaintext
GET /projects
```

| Attribute  | Type   | Required               | Description |
|------------|--------|------------------------|-------------|
| `search`   | string | **{check-circle}** Yes | A string contained in the project name. |
| `order_by` | string | **{dotted-circle}** No | Return requests ordered by `id`, `name`, `created_at` or `last_activity_at` fields. |
| `sort`     | string | **{dotted-circle}** No | Return requests sorted in `asc` or `desc` order. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects?search=test"
```

## Start the Housekeeping task for a project

```plaintext
POST /projects/:id/housekeeping
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `task`   | string           | **{dotted-circle}** No | `prune` to trigger manual prune of unreachable objects or `eager` to trigger eager housekeeping. |

## Push rules **(PREMIUM)**

### Get project push rules

Get the [push rules](../user/project/repository/push_rules.md) of a
project.

```plaintext
GET /projects/:id/push_rule
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) |

```json
{
  "id": 1,
  "project_id": 3,
  "commit_message_regex": "Fixes \\d+\\..*",
  "commit_message_negative_regex": "ssh\\:\\/\\/",
  "branch_name_regex": "",
  "deny_delete_tag": false,
  "created_at": "2012-10-12T17:04:47Z",
  "member_check": false,
  "prevent_secrets": false,
  "author_email_regex": "",
  "file_name_regex": "",
  "max_file_size": 5,
  "commit_committer_check": false,
  "reject_unsigned_commits": false
}
```

### Add project push rule

Adds a push rule to a specified project.

```plaintext
POST /projects/:id/push_rule
```

| Attribute                               | Type           | Required               | Description |
|-----------------------------------------|----------------|------------------------|-------------|
| `id`                                    | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `author_email_regex`                    | string         | **{dotted-circle}** No | All commit author emails must match this, for example `@my-company.com$`. |
| `branch_name_regex`                     | string         | **{dotted-circle}** No | All branch names must match this, for example `(feature|hotfix)\/*`. |
| `commit_committer_check`                | boolean        | **{dotted-circle}** No | Users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_message_negative_regex`         | string         | **{dotted-circle}** No | No commit message is allowed to match this, for example `ssh\:\/\/`. |
| `commit_message_regex`                  | string         | **{dotted-circle}** No | All commit messages must match this, for example `Fixed \d+\..*`. |
| `deny_delete_tag`                       | boolean        | **{dotted-circle}** No | Deny deleting a tag. |
| `file_name_regex`                       | string         | **{dotted-circle}** No | All committed filenames must **not** match this, for example `(jar|exe)$`. |
| `max_file_size`                         | integer        | **{dotted-circle}** No | Maximum file size (MB). |
| `member_check`                          | boolean        | **{dotted-circle}** No | Restrict commits by author (email) to existing GitLab users. |
| `prevent_secrets`                       | boolean        | **{dotted-circle}** No | GitLab rejects any files that are likely to contain secrets. |
| `reject_unsigned_commits`               | boolean        | **{dotted-circle}** No | Reject commit when it's not signed through GPG. |

### Edit project push rule

Edits a push rule for a specified project.

```plaintext
PUT /projects/:id/push_rule
```

| Attribute                               | Type           | Required               | Description |
|-----------------------------------------|----------------|------------------------|-------------|
| `id`                                    | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `author_email_regex`                    | string         | **{dotted-circle}** No | All commit author emails must match this, for example `@my-company.com$`. |
| `branch_name_regex`                     | string         | **{dotted-circle}** No | All branch names must match this, for example `(feature|hotfix)\/*`. |
| `commit_committer_check`                | boolean        | **{dotted-circle}** No | Users can only push commits to this repository if the committer email is one of their own verified emails. |
| `commit_message_negative_regex`         | string         | **{dotted-circle}** No | No commit message is allowed to match this, for example `ssh\:\/\/`. |
| `commit_message_regex`                  | string         | **{dotted-circle}** No | All commit messages must match this, for example `Fixed \d+\..*`. |
| `deny_delete_tag`                       | boolean        | **{dotted-circle}** No | Deny deleting a tag. |
| `file_name_regex`                       | string         | **{dotted-circle}** No | All committed filenames must **not** match this, for example `(jar|exe)$`. |
| `max_file_size`                         | integer        | **{dotted-circle}** No | Maximum file size (MB). |
| `member_check`                          | boolean        | **{dotted-circle}** No | Restrict commits by author (email) to existing GitLab users. |
| `prevent_secrets`                       | boolean        | **{dotted-circle}** No | GitLab rejects any files that are likely to contain secrets. |
| `reject_unsigned_commits`               | boolean        | **{dotted-circle}** No | Reject commits when they are not GPG signed. |

### Delete project push rule

> Moved to GitLab Premium in 13.9.

Removes a push rule from a project. This method is idempotent and can be
called multiple times. Either the push rule is available or not.

```plaintext
DELETE /projects/:id/push_rule
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

## Get groups to which a user can transfer a project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/371006) in GitLab 15.4

Retrieve a list of groups to which the user can transfer a project.

```plaintext
GET /projects/:id/transfer_locations
```

| Attribute   | Type           | Required               | Description |
|-------------|----------------|------------------------|-------------|
| `id`        | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `search` | string | **{dotted-circle}** No  | The group names to search for. |

Example request:

```shell
curl --request GET "https://gitlab.example.com/api/v4/projects/1/transfer_locations"
```

Example response:

```json
[
  {
    "id": 27,
    "web_url": "https://gitlab.example.com/groups/gitlab",
    "name": "GitLab",
    "avatar_url": null,
    "full_name": "GitLab",
    "full_path": "GitLab"
  },
  {
    "id": 31,
    "web_url": "https://gitlab.example.com/groups/foobar",
    "name": "FooBar",
    "avatar_url": null,
    "full_name": "FooBar",
    "full_path": "FooBar"
  }
]
```

## Transfer a project to a new namespace

> The `_links.cluster_agents` attribute in the response [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347047) in GitLab 14.10.

See the [Project documentation](../user/project/settings/index.md#transfer-a-project-to-another-namespace)
for prerequisites to transfer a project.

```plaintext
PUT /projects/:id/transfer
```

| Attribute   | Type           | Required               | Description |
|-------------|----------------|------------------------|-------------|
| `id`        | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `namespace` | integer or string | **{check-circle}** Yes | The ID or path of the namespace to transfer to project to. |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/transfer?namespace=14"
```

Example response:

```json
  {
  "id": 7,
  "description": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
  "description_html": "<p data-sourcepos=\"1:1-1:56\" dir=\"auto\">Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>",
  "name": "hello-world",
  "name_with_namespace": "cute-cats / hello-world",
  "path": "hello-world",
  "path_with_namespace": "cute-cats/hello-world",
  "created_at": "2020-10-15T16:25:22.415Z",
  "updated_at": "2020-10-15T16:25:22.415Z",
  "default_branch": "master",
  "tag_list": [], //deprecated, use `topics` instead
  "topics": [],
  "ssh_url_to_repo": "git@gitlab.example.com:cute-cats/hello-world.git",
  "http_url_to_repo": "https://gitlab.example.com/cute-cats/hello-world.git",
  "web_url": "https://gitlab.example.com/cute-cats/hello-world",
  "readme_url": "https://gitlab.example.com/cute-cats/hello-world/-/blob/master/README.md",
  "avatar_url": null,
  "forks_count": 0,
  "star_count": 0,
  "last_activity_at": "2020-10-15T16:25:22.415Z",
  "namespace": {
    "id": 18,
    "name": "cute-cats",
    "path": "cute-cats",
    "kind": "group",
    "full_path": "cute-cats",
    "parent_id": null,
    "avatar_url": null,
    "web_url": "https://gitlab.example.com/groups/cute-cats"
  },
  "container_registry_image_prefix": "registry.example.com/cute-cats/hello-world",
  "_links": {
    "self": "https://gitlab.example.com/api/v4/projects/7",
    "issues": "https://gitlab.example.com/api/v4/projects/7/issues",
    "merge_requests": "https://gitlab.example.com/api/v4/projects/7/merge_requests",
    "repo_branches": "https://gitlab.example.com/api/v4/projects/7/repository/branches",
    "labels": "https://gitlab.example.com/api/v4/projects/7/labels",
    "events": "https://gitlab.example.com/api/v4/projects/7/events",
    "members": "https://gitlab.example.com/api/v4/projects/7/members"
  },
  "packages_enabled": true,
  "empty_repo": false,
  "archived": false,
  "visibility": "private",
  "resolve_outdated_diff_discussions": false,
  "container_registry_enabled": true, // deprecated, use container_registry_access_level instead
  "container_registry_access_level": "enabled",
  "container_expiration_policy": {
    "cadence": "7d",
    "enabled": false,
    "keep_n": null,
    "older_than": null,
    "name_regex": null,
    "name_regex_keep": null,
    "next_run_at": "2020-10-22T16:25:22.746Z"
  },
  "issues_enabled": true,
  "merge_requests_enabled": true,
  "wiki_enabled": true,
  "jobs_enabled": true,
  "snippets_enabled": true,
  "service_desk_enabled": false,
  "service_desk_address": null,
  "can_create_merge_request_in": true,
  "issues_access_level": "enabled",
  "repository_access_level": "enabled",
  "merge_requests_access_level": "enabled",
  "forking_access_level": "enabled",
  "analytics_access_level": "enabled",
  "wiki_access_level": "enabled",
  "builds_access_level": "enabled",
  "snippets_access_level": "enabled",
  "pages_access_level": "enabled",
  "security_and_compliance_access_level": "enabled",
  "emails_disabled": null,
  "emails_enabled": null,
  "shared_runners_enabled": true,
  "group_runners_enabled": true,
  "lfs_enabled": true,
  "creator_id": 2,
  "import_status": "none",
  "open_issues_count": 0,
  "ci_default_git_depth": 50,
  "public_jobs": true,
  "build_timeout": 3600,
  "auto_cancel_pending_pipelines": "enabled",
  "ci_config_path": null,
  "shared_with_groups": [],
  "only_allow_merge_if_pipeline_succeeds": false,
  "allow_merge_on_skipped_pipeline": null,
  "restrict_user_defined_variables": false,
  "request_access_enabled": true,
  "only_allow_merge_if_all_discussions_are_resolved": false,
  "remove_source_branch_after_merge": true,
  "printing_merge_request_link_enabled": true,
  "merge_method": "merge",
  "squash_option": "default_on",
  "suggestion_commit_message": null,
  "merge_commit_template": null,
  "auto_devops_enabled": true,
  "auto_devops_deploy_strategy": "continuous",
  "autoclose_referenced_issues": true,
  "approvals_before_merge": 0, // Deprecated. Use merge request approvals API instead.
  "mirror": false,
  "compliance_frameworks": []
}
```

## Branches

Read more in the [Branches](branches.md) documentation.

## Project import/export

Read more in the [Project import/export](project_import_export.md) documentation.

## Project members

Read more in the [Project members](members.md) documentation.

## Project vulnerabilities

Read more in the [Project vulnerabilities](project_vulnerabilities.md) documentation.

## Get a project's pull mirror details **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354506) in GitLab 15.6.

Returns the details of the project's pull mirror.

```plaintext
GET /projects/:id/mirror/pull
```

Supported attributes:

| Attribute | Type  | Required    | Description |
|:----------|:------|:------------|:------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

Example response:

```json
{
  "id": 101486,
  "last_error": null,
  "last_successful_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_at": "2020-01-06T17:32:02.823Z",
  "last_update_started_at": "2020-01-06T17:31:55.864Z",
  "update_status": "finished",
  "url": "https://*****:*****@gitlab.com/gitlab-org/security/gitlab.git"
}
```

## Configure pull mirroring for a project **(PREMIUM)**

> - Field `mirror_branch_regex` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 15.8 [with a flag](../administration/feature_flags.md) named `mirror_only_branches_match_regex`. Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/410354) in GitLab 16.2. Feature flag `mirror_only_branches_match_regex` removed.

Configure pull mirroring while [creating a new project](#create-project)
or [updating an existing project](#edit-project) using the API
if the remote repository is publicly accessible
or via `username:token` authentication.
In case your HTTP repository is not publicly accessible,
you can add the authentication information to the URL:
`https://username:token@gitlab.company.com/group/project.git`,
where `token` is a [personal access token](../user/profile/personal_access_tokens.md)
with the API scope enabled.

| Attribute    | Type    | Required               | Description |
|--------------|---------|------------------------|-------------|
| `import_url` | string  | **{check-circle}** Yes | URL of remote repository being mirrored (with `user:token` if needed). |
| `mirror`     | boolean | **{check-circle}** Yes | Enables pull mirroring on project when set to `true`. |
| `mirror_trigger_builds`| boolean | **{dotted-circle}** No | Trigger pipelines for mirror updates when set to `true`. |
| `only_mirror_protected_branches`| boolean | **{dotted-circle}** No | Limits mirroring to only protected branches when set to `true`. |
| `mirror_branch_regex`            | String  | **{dotted-circle}** No | Contains a regular expression. Only branches with names matching the regex are mirrored. Requires `only_mirror_protected_branches` to be disabled. |

## Start the pull mirroring process for a Project **(PREMIUM)**

> Moved to GitLab Premium in 13.9.

```plaintext
POST /projects/:id/mirror/pull
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/:id/mirror/pull"
```

## Project badges

Read more in the [Project Badges](project_badges.md) documentation.

## Download snapshot of a Git repository

This endpoint may only be accessed by an administrative user.

Download a snapshot of the project (or wiki, if requested) Git repository. This
snapshot is always in uncompressed [tar](https://en.wikipedia.org/wiki/Tar_(computing))
format.

If a repository is corrupted to the point where `git clone` doesn't work, the
snapshot may allow some of the data to be retrieved.

```plaintext
GET /projects/:id/snapshot
```

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer or string | **{check-circle}** Yes | The ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |
| `wiki`    | boolean        | **{dotted-circle}** No | Whether to download the wiki, rather than project, repository. |

## Get the path to repository storage

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29861) in GitLab 14.0.

Get the path to repository storage for specified project if Gitaly Cluster is not being used. If Gitaly Cluster is being used, see
[Praefect-generated replica paths (GitLab 15.0 and later)](../administration/gitaly/index.md#praefect-generated-replica-paths-gitlab-150-and-later).

Available for administrators only.

```plaintext
GET /projects/:id/storage
```

| Attribute    | Type           | Required               | Description |
|--------------|----------------|------------------------|-------------|
| `id`         | integer or string | **{check-circle}** Yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding). |

```json
[
  {
    "project_id": 1,
    "disk_path": "@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b",
    "created_at": "2012-10-12T17:04:47Z",
    "repository_storage": "default"
  }
]
```

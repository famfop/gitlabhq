---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Group and project migration by direct transfer API **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/64335) in GitLab 14.1.
> - Project migration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390515) in GitLab 15.11.

With the group migration by direct transfer API, you can start and view the progress of migrations initiated with
[group migration by direct transfer](../user/group/import/index.md#migrate-groups-by-direct-transfer-recommended).

WARNING:
Migrating projects with this API is in [Beta](../policy/experiment-beta-support.md#beta). This feature is not
ready for production use.

## Prerequisites

For information on prerequisites for group migration by direct transfer API, see
prerequisites for [migrating groups by direct transfer](../user/group/import/index.md#prerequisites).

## Start a new group or project migration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66353) in GitLab 14.2.
> - `project_entity` source type [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390515) in GitLab 15.11.

Use this endpoint to start a new group or project migration. Specify:

- `entities[group_entity]` to migrate a group.
- `entities[project_entity]` to migrate a project (Beta).

```plaintext
POST /bulk_imports
```

| Attribute                         | Type   | Required | Description |
| --------------------------------- | ------ | -------- | ----------- |
| `configuration`                   | Hash   | yes      | The source GitLab instance configuration. |
| `configuration[url]`              | String | yes      | Source GitLab instance URL. |
| `configuration[access_token]`     | String | yes      | Access token to the source GitLab instance. |
| `entities`                        | Array  | yes      | List of entities to import. |
| `entities[source_type]`           | String | yes      | Source entity type. Valid values are `group_entity` (GitLab 14.2 and later) and `project_entity` (GitLab 15.11 and later). |
| `entities[source_full_path]`      | String | yes      | Source full path of the entity to import. |
| `entities[destination_slug]`      | String | yes      | Destination slug for the entity. |
| `entities[destination_name]`      | String | no       | Deprecated: Use `destination_slug` instead. Destination slug for the entity. |
| `entities[destination_namespace]` | String | yes      | Destination namespace for the entity. |
| `entities[migrate_projects]`      | Boolean | no      | Also import all nested projects of the group (if `source_type` is `group_entity`). Defaults to `true`. |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports" \
  --header "Content-Type: application/json" \
  --data '{
    "configuration": {
      "url": "http://gitlab.example/",
      "access_token": "access_token"
    },
    "entities": [
      {
        "source_full_path": "source/full/path",
        "source_type": "group_entity",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination/namespace/path"
      }
    ]
  }'
```

```json
{ "id": 1, "status": "created", "source_type": "gitlab", "created_at": "2021-06-18T09:45:55.358Z", "updated_at": "2021-06-18T09:46:27.003Z" }
```

## List all group or project migrations

```plaintext
GET /bulk_imports
```

| Attribute  | Type    | Required | Description                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | integer | no       | Number of records to return per page.                                              |
| `page`     | integer | no       | Page to retrieve.                                                                  |
| `sort`     | string  | no       | Return records sorted in `asc` or `desc` order by creation date. Default is `desc` |
| `status`   | string  | no       | Import status.                                                                     |

The status can be one of the following:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports?per_page=2&page=1"
```

```json
[
    {
        "id": 1,
        "status": "finished",
        "source_type": "gitlab",
        "created_at": "2021-06-18T09:45:55.358Z",
        "updated_at": "2021-06-18T09:46:27.003Z"
    },
    {
        "id": 2,
        "status": "started",
        "source_type": "gitlab",
        "created_at": "2021-06-18T09:47:36.581Z",
        "updated_at": "2021-06-18T09:47:58.286Z"
    }
]
```

## List all group or project migrations' entities

```plaintext
GET /bulk_imports/entities
```

| Attribute  | Type    | Required | Description                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | integer | no       | Number of records to return per page.                                              |
| `page`     | integer | no       | Page to retrieve.                                                                  |
| `sort`     | string  | no       | Return records sorted in `asc` or `desc` order by creation date. Default is `desc` |
| `status`   | string  | no       | Import status.                                                                     |

The status can be one of the following:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports/entities?per_page=2&page=1&status=started"
```

```json
[
    {
        "id": 1,
        "bulk_import_id": 1,
        "status": "finished",
        "source_full_path": "source_group",
        "destination_slug": "destination_slug",
        "destination_namespace": "destination_path",
        "parent_id": null,
        "namespace_id": 1,
        "project_id": null,
        "created_at": "2021-06-18T09:47:37.390Z",
        "updated_at": "2021-06-18T09:47:51.867Z",
        "failures": []
    },
    {
        "id": 2,
        "bulk_import_id": 2,
        "status": "failed",
        "source_full_path": "another_group",
        "destination_slug": "another_slug",
        "destination_namespace": "another_namespace",
        "parent_id": null,
        "namespace_id": null,
        "project_id": null,
        "created_at": "2021-06-24T10:40:20.110Z",
        "updated_at": "2021-06-24T10:40:46.590Z",
        "failures": [
            {
                "relation": "group",
                "step": "extractor",
                "exception_message": "Error!",
                "exception_class": "Exception",
                "correlation_id_value": "dfcf583058ed4508e4c7c617bd7f0edd",
                "created_at": "2021-06-24T10:40:46.495Z",
                "pipeline_class": "BulkImports::Groups::Pipelines::GroupPipeline",
                "pipeline_step": "extractor"
            }
        ]
    }
]
```

## Get group or project migration details

```plaintext
GET /bulk_imports/:id
```

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports/1"
```

```json
{
  "id": 1,
  "status": "finished",
  "source_type": "gitlab",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z"
}
```

## List group or project migration entities

```plaintext
GET /bulk_imports/:id/entities
```

| Attribute  | Type    | Required | Description                                                                        |
|:-----------|:--------|:---------|:-----------------------------------------------------------------------------------|
| `per_page` | integer | no       | Number of records to return per page.                                              |
| `page`     | integer | no       | Page to retrieve.                                                                  |
| `sort`     | string  | no       | Return records sorted in `asc` or `desc` order by creation date. Default is `desc` |
| `status`   | string  | no       | Import status.                                                                     |

The status can be one of the following:

- `created`
- `started`
- `finished`
- `failed`

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports/1/entities?per_page=2&page=1&status=finished"
```

```json
[
    {
        "id": 1,
        "status": "finished",
        "source_type": "gitlab",
        "created_at": "2021-06-18T09:45:55.358Z",
        "updated_at": "2021-06-18T09:46:27.003Z"
    }
]
```

## Get group or project migration entity details

```plaintext
GET /bulk_imports/:id/entities/:entity_id
```

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/bulk_imports/1/entities/2"
```

```json
{
  "id": 1,
  "status": "finished",
  "source_type": "gitlab",
  "created_at": "2021-06-18T09:45:55.358Z",
  "updated_at": "2021-06-18T09:46:27.003Z"
}
```

---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Project iterations API **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.5.
> - Moved to GitLab Premium in 13.9.

This page describes the project iterations API.
There's a separate [group iterations API](group_iterations.md) page.

As of GitLab 13.5, we don't have project-level iterations, but you can use this endpoint to fetch the iterations of the project's ancestor groups.

## List project iterations

Returns a list of project iterations.

```plaintext
GET /projects/:id/iterations
GET /projects/:id/iterations?state=opened
GET /projects/:id/iterations?state=closed
GET /projects/:id/iterations?search=version
GET /projects/:id/iterations?include_ancestors=false
GET /projects/:id/iterations?updated_before=2013-10-02T09%3A24%3A18Z
GET /projects/:id/iterations?updated_after=2013-10-02T09%3A24%3A18Z
```

| Attribute           | Type    | Required | Description |
| ------------------- | ------- | -------- | ----------- |
| `state`             | string  | no       | 'Return `opened`, `upcoming`, `current`, `closed`, or `all` iterations.'                       |
| `search`            | string  | no       | Return only iterations with a title matching the provided string.                              |
| `in`                | array of strings | no | Fields in which fuzzy search should be performed with the query given in the argument `search`. The available options are `title` and `cadence_title`. Default is `[title]`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/350991) in GitLab 16.2. |
| `include_ancestors` | boolean | no       | Include iterations from parent group and its ancestors. Defaults to `true`.                    |
| `updated_before`    | datetime | no      | Return only iterations updated before the given datetime. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378662) in GitLab 15.10. |
| `updated_after`     | datetime | no      | Return only iterations updated after the given datetime. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378662) in GitLab 15.10. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/iterations"
```

Example response:

```json
[
  {
    "id": 53,
    "iid": 13,
    "group_id": 5,
    "title": "Iteration II",
    "description": "Ipsum Lorem ipsum",
    "state": 2,
    "created_at": "2020-01-27T05:07:12.573Z",
    "updated_at": "2020-01-27T05:07:12.573Z",
    "due_date": "2020-02-01",
    "start_date": "2020-02-14",
    "web_url": "http://gitlab.example.com/groups/my-group/-/iterations/13"
  }
]
```

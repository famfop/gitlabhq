---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# SAML API **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227841) in GitLab 15.5.

API for accessing SAML features.

## Get SAML identities for a group

```plaintext
GET /groups/:id/saml/identities
```

Fetch SAML identities for a group.

Supported attributes:

| Attribute         | Type    | Required | Description           |
|:------------------|:--------|:---------|:----------------------|
| `id`              | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |

If successful, returns [`200`](rest/index.md#status-codes) and the following
response attributes:

| Attribute    | Type   | Description               |
| ------------ | ------ | ------------------------- |
| `extern_uid` | string | External UID for the user |
| `user_id`    | string | ID for the user           |

Example request:

```shell
curl --location --request GET "https://gitlab.example.com/api/v4/groups/33/saml/identities" --header "PRIVATE-TOKEN: <PRIVATE-TOKEN>"
```

Example response:

```json
[
    {
        "extern_uid": "4",
        "user_id": 48
    }
]
```

## Get a single SAML identity

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123591) in GitLab 16.1.

```plaintext
GET /groups/:id/saml/:uid
```

Supported attributes:

| Attribute | Type           | Required | Description               |
| --------- | -------------- | -------- | ------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `uid`     | string         | yes      | External UID of the user. |

Example request:

```shell
curl --location --request GET "https://gitlab.example.com/api/v4/groups/33/saml/sydney_jones" --header "PRIVATE-TOKEN: <PRIVATE TOKEN>"
```

Example response:

```json
{
    "extern_uid": "4",
    "user_id": 48
}
```

## Update `extern_uid` field for a SAML identity

Update `extern_uid` field for a SAML identity:

| SAML IdP attribute | GitLab field |
| ------------------ | ------------ |
| `id/externalId`    | `extern_uid` |

```plaintext
PATCH /groups/:id/saml/:uid
```

Supported attributes:

| Attribute | Type   | Required | Description               |
| --------- | ------ | -------- | ------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the group](rest/index.md#namespaced-path-encoding) |
| `uid`     | string | yes      | External UID of the user. |

Example request:

```shell
curl --location --request PATCH "https://gitlab.example.com/api/v4/groups/33/saml/sydney_jones" \
--header "PRIVATE-TOKEN: <PRIVATE TOKEN>" \
--form "extern_uid=sydney_jones_new"
```

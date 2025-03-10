---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure GitLab as an OAuth 2.0 authentication identity provider

[OAuth 2.0](https://oauth.net/2/) provides secure delegated server resource
access to client applications on behalf of a resource owner. OAuth 2 allows
authorization servers to issue access tokens to third-party clients with the approval
of the resource owner or the end-user.

You can use GitLab as an OAuth 2 authentication identity provider by adding the
following types of OAuth 2 application to an instance:

- [User owned applications](#create-a-user-owned-application).
- [Group owned applications](#create-a-group-owned-application).
- [Instance-wide applications](#create-an-instance-wide-application).

These methods only differ by [permission level](../user/permissions.md). The
default callback URL is the SSL URL `https://your-gitlab.example.com/users/auth/gitlab/callback`.
You can use a non-SSL URL instead, but you should use an SSL URL.

After adding an OAuth 2 application to an instance, you can use OAuth 2 to:

- Enable users to sign in to your application with their GitLab.com account.
- Set up GitLab.com for authentication to your GitLab instance. For more information,
  see [integrating your server with GitLab.com](gitlab.md).

- After an application is created, external services can manage access tokens using the
  [OAuth 2 API](../api/oauth2.md).

## Create a user-owned application

To create a new application for your user:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Applications**.
1. Enter a **Name** and **Redirect URI**.
1. Select OAuth 2 **Scopes** as defined in [Authorized Applications](#view-all-authorized-applications).
1. In the **Redirect URI**, enter the URL where users are sent after they authorize with GitLab.
1. Select **Save application**. GitLab provides:

   - The OAuth 2 Client ID in the **Application ID** field.
   - The OAuth 2 Client Secret, accessible:
     - In the **Secret** field in GitLab 14.1 and earlier.
     - By selecting **Copy** in the **Secret** field
       [in GitLab 14.2 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/332844).
   - The **Renew secret** function in [GitLab 15.9 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/338243). Use this function to generate and copy a new secret for this application. Renewing a secret prevents the existing application from functioning until the credentials are updated.

## Create a group-owned application

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16227) in GitLab 13.11.

To create a new application for a group:

1. Go to the desired group.
1. On the left sidebar, select **Settings > Applications**.
1. Enter a **Name** and **Redirect URI**.
1. Select OAuth 2 scopes as defined in [Authorized Applications](#view-all-authorized-applications).
1. In the **Redirect URI**, enter the URL where users are sent after they authorize with GitLab.
1. Select **Save application**. GitLab provides:

   - The OAuth 2 Client ID in the **Application ID** field.
   - The OAuth 2 Client Secret, accessible:
     - In the **Secret** field in GitLab 14.1 and earlier.
     - By selecting **Copy** in the **Secret** field
       [in GitLab 14.2 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/332844).
   - The **Renew secret** function in [GitLab 15.9 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/338243). Use this function to generate and copy a new secret for this application. Renewing a secret prevents the existing application from functioning until the credentials are updated.

## Create an instance-wide application

To create an application for your GitLab instance:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. On the left sidebar, select **Applications**.
1. Select **New application**.

When creating application in the **Admin Area** , mark it as **trusted**.
The user authorization step is automatically skipped for this application.

## View all authorized applications

To see all the application you've authorized with your GitLab credentials:

1. On the left sidebar, select your avatar.
1. Select **Edit profile** and then select **Applications**.
1. See the **Authorized applications** section.

The GitLab OAuth 2 applications support scopes, which allow application to perform
different actions. See the following table for all available scopes.

| Scope              | Description |
| ------------------ | ----------- |
| `api`              | Grants complete read/write access to the API, including all groups and projects, the container registry, and the package registry. |
| `read_user`        | Grants read-only access to the authenticated user's profile through the /user API endpoint, which includes username, public email, and full name. Also grants access to read-only API endpoints under /users. |
| `read_api`         | Grants read access to the API, including all groups and projects, the container registry, and the package registry. |
| `read_repository`  | Grants read-only access to repositories on private projects using Git-over-HTTP or the Repository Files API. |
| `write_repository` | Grants read-write access to repositories on private projects using Git-over-HTTP (not using the API). |
| `read_registry`    | Grants read-only access to container registry images on private projects. |
| `write_registry`   | Grants read-only access to container registry images on private projects. |
| `sudo`             | Grants permission to perform API actions as any user in the system, when authenticated as an administrator user. |
| `openid`           | Grants permission to authenticate with GitLab using [OpenID Connect](openid_connect_provider.md). Also gives read-only access to the user's profile and group memberships. |
| `profile`          | Grants read-only access to the user's profile data using [OpenID Connect](openid_connect_provider.md). |
| `email`            | Grants read-only access to the user's primary email address using [OpenID Connect](openid_connect_provider.md). |
| `create_runner`    | Grants permission to create runners. |

At any time you can revoke any access by selecting **Revoke**.

## Access token expiration

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21745) in GitLab 14.3, with the ability to opt out.
> - Ability to opt-out of expiring access token [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/340848) in GitLab 15.0.

WARNING:
The ability to opt out of expiring access tokens was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/340848)
in GitLab 14.3 and [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/340848) in 15.0. All
existing integrations must be updated to support access token refresh.

Access tokens expire after two hours. Integrations that use access tokens must generate new ones at least every
two hours.

When applications are deleted, all grants and tokens associated with the application are also deleted.

## Hashed OAuth application secrets

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/374588) in GitLab 15.4 [with a flag](../administration/feature_flags.md) named `hash_oauth_secrets`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/374588) in GitLab 15.8.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/374588) in GitLab 15.9.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](../administration/feature_flags.md) named `hash_oauth_secrets`.
On GitLab.com, this feature is available.

By default, GitLab stores OAuth application secrets in the database in hashed format. These secrets are only available to users immediately after creating OAuth applications. In
earlier versions of GitLab, application secrets are stored as plain text in the database.

## Other ways to use OAuth 2 in GitLab

You can:

- Create and manage OAuth 2 applications using the [Applications API](../api/applications.md).
- Enable users to sign in to GitLab using third-party OAuth 2 providers. For more
  information, see the [OmniAuth documentation](omniauth.md).
- Use the GitLab Importer with OAuth 2 to give access to repositories without
  sharing user credentials to your GitLab.com account.

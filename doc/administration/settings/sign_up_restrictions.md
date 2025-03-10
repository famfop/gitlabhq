---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Sign-up restrictions **(FREE SELF)**

You can enforce the following restrictions on sign ups:

- Disable new sign ups.
- Require administrator approval for new sign ups.
- Require user email confirmation.
- Allow or deny sign ups using specific email domains.

## Disable new sign ups

By default, any user visiting your GitLab domain can sign up for an account. For customers running
public-facing GitLab instances, we **highly** recommend that you consider disabling new sign ups if
you do not expect public users to sign up for an account.

To disable sign ups:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Clear the **Sign-up enabled** checkbox, then select **Save changes**.

## Require administrator approval for new sign ups

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4491) in GitLab 13.5.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/267568) in GitLab 13.6.

When this setting is enabled, any user visiting your GitLab domain and signing up for a new account using the registration form
must be explicitly [approved](../../administration/moderate_users.md#approve-or-reject-a-user-sign-up) by an
administrator before they can start using their account. In GitLab 13.6 and later, this setting is
enabled by default for new GitLab instances. It is only applicable if sign ups are enabled.

To require administrator approval for new sign ups:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Select the **Require admin approval for new sign-ups** checkbox, then select **Save changes**.

In [GitLab 13.7 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/273258), if an administrator disables this setting, the users in pending approval state are
automatically approved in a background job.

NOTE:
This setting doesn't apply to LDAP or OmniAuth users. To enforce approvals for new users
signing up using OmniAuth or LDAP, set `block_auto_created_users` to `true` in the
[OmniAuth configuration](../../integration/omniauth.md#configure-common-settings) or
[LDAP configuration](../auth/ldap/index.md#basic-configuration-settings).
A [user cap](#user-cap) can also be used to enforce approvals for new users.

## Confirm user email

> - Soft email confirmation [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/47003) in GitLab 12.2 [with a flag](../../operations/feature_flags.md) named `soft_email_confirmation`.
> - Soft email confirmation [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107302/diffs) from a feature flag to an application setting in GitLab 15.9.

You can send confirmation emails during sign up and require that users confirm
their email address before they are allowed to sign in.

For example, to enforce confirmation of the email address used for new sign ups:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Under **Email confirmation settings**, select **Hard**.

The following settings are available:

- **Hard** - Send a confirmation email during sign up. New users must confirm their email address before they can log in.
- **Soft** - Send a confirmation email during sign up. New users can log in immediately, but must confirm their email in three days. Unconfirmed accounts are deleted.
- **Off** - New users can sign up without confirming their email address.

## User cap

The user cap is the maximum number of billable users who can sign up or be added to a subscription
without administrator approval. After the user cap is reached, users who sign up or are
added must be [approved](../../administration/moderate_users.md#approve-or-reject-a-user-sign-up)
by an administrator. Users can use their account only after they have been approved by an administrator.

If an administrator increases or removes the user cap, users pending approval are automatically approved.

NOTE:
For instances that use LDAP or OmniAuth, when [administrator approval for new sign-ups](#require-administrator-approval-for-new-sign-ups)
is enabled or disabled, downtime might occur due to changes in the Rails configuration.
You can set a user cap to enforce approvals for new users. To ensure the user cap applies immediately, set the cap to a value below the current number of billable users (for example, `1`).

### Set a user cap

Set a user cap to restrict the number of users who can sign up without administrator approval.

The number of [billable users](../../subscriptions/self_managed/index.md#billable-users) is updated once a day.
The user cap might apply only retrospectively after the cap has already been exceeded.
To ensure the cap is enabled immediately, set the cap to a value below the current number of
billable users (for example, `1`).

Prerequisite:

- You must be an administrator.

To set a user cap:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Enter a number in **User cap**.
1. Select **Save changes**.

### Remove the user cap

Remove the user cap so that the number of new users who can sign up without
administrator approval is not restricted.

After you remove the user cap, users pending approval are automatically approved.

Prerequisite:

- You must be an administrator.

To remove the user cap:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Remove the number from **User cap**.
1. Select **Save changes**.

## Minimum password length limit

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/20661) in GitLab 12.6

You can [change](../../security/password_length_limits.md#modify-minimum-password-length)
the minimum number of characters a user must have in their password using the GitLab UI.

### Password complexity requirements **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354965) in GitLab 15.2.

By default, the only requirement for user passwords is [minimum password length](#minimum-password-length-limit).
You can add additional complexity requirements. Changes to password complexity requirements apply to new passwords:

- For new users that sign up.
- For existing users that reset their password.

Existing passwords are unaffected. To change password complexity requirements:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. Under **Minimum password length (number of characters)**, select additional password complexity requirements. You can require numbers, uppercase letters, lowercase letters,
   and symbols.
1. Select **Save changes**.

## Allow or deny sign ups using specific email domains

You can specify an inclusive or exclusive list of email domains which can be used for user sign up.

These restrictions are only applied during sign up from an external user. An administrator can add a
user through the administrator panel with a disallowed domain. The users can also change their
email addresses to disallowed domains after sign up.

### Allowlist email domains

You can restrict users only to sign up using email addresses matching the given
domains list.

### Denylist email domains

You can block users from signing up when using an email addresses of specific domains. This can
reduce the risk of malicious users creating spam accounts with disposable email addresses.

### Create email domain allowlist or denylist

To create an email domain allowlist or denylist:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Sign-up restrictions**.
1. For the allowlist, you must enter the list manually. For the denylist, you can enter the list
   manually or upload a `.txt` file that contains list entries.

   Both the allowlist and denylist accept wildcards. For example, you can use
`*.company.com` to accept every `company.com` subdomain, or `*.io` to block all
domains ending in `.io`. Domains must be separated by a whitespace,
semicolon, comma, or a new line.

   ![Domain Denylist](img/domain_denylist_v14_1.png)

## Set up LDAP user filter

You can limit GitLab access to a subset of the LDAP users on your LDAP server.

See the [documentation on setting up an LDAP user filter](../auth/ldap/index.md#set-up-ldap-user-filter) for more information.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

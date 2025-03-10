---
stage: Analytics
group: Observability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Error Tracking **(FREE)**

Error Tracking allows developers to discover and view errors generated by their application. Because error information is surfaced where the code is developed, this increases efficiency and awareness. Users can choose between [GitLab Integrated error tracking](#integrated-error-tracking) and [Sentry based](#sentry-error-tracking) backends.

## How error tracking works

For error tracking to work, you need:

- **Your application configured with the Sentry SDK:** when the error happens, Sentry SDK captures information
  about it and sends it over the network to the backend. The backend stores information about all
  errors.

- **Error tracking backend:** the backend can be either GitLab itself or Sentry. When it's GitLab,
  you name it _integrated error tracking_ because you don't need to set up a separate backend. It's
  already part of the product.

  - To use the GitLab backend, see [integrated error tracking](#integrated-error-tracking).
  - To use Sentry as the backend, see [Sentry error tracking](#sentry-error-tracking).

  Whatever backend you choose, the [error tracking UI](#error-tracking-list)
  is the same.

## Integrated error tracking **(FREE SAAS)**

This guide provides you with basics of setting up error tracking for your project, using examples from different languages.

Error tracking provided by GitLab Observability is based on [Sentry SDK](https://docs.sentry.io/). Check the [Sentry SDK documentation](https://docs.sentry.io/platforms/) for more thorough examples of how you can use Sentry SDK in your application.

According to the Sentry [data model](https://develop.sentry.dev/sdk/envelopes/#data-model), the item types are:

- [Event](https://develop.sentry.dev/sdk/event-payloads/)
- [Transactions](https://develop.sentry.dev/sdk/event-payloads/transaction/)
- [Attachments](https://develop.sentry.dev/sdk/envelopes/#attachment)
- [Session](https://develop.sentry.dev/sdk/envelopes/#session)
- [Sessions](https://develop.sentry.dev/sdk/envelopes/#sessions)
- [User feedback](https://develop.sentry.dev/sdk/envelopes/#user-feedback) (also known as user report)
- [Client report](https://develop.sentry.dev/sdk/client-reports/)

### Enable error tracking for a project

Regardless of the programming language you use, you first need to enable error tracking for your GitLab project.

The `GitLab.com` instance is used in this guide.

Prerequisites:

- You have a project for which you want to enable error tracking. To learn how to create a new one, see [Create a project](../user/project/index.md).

To enable error tracking with GitLab as the backend:

1. In your project, go to **Settings > Monitor**.
1. Expand **Error Tracking**.
1. Under **Enable error tracking**, select the **Active** checkbox.
1. Under **Error tracking backend**, select **GitLab**.
1. Select **Save changes**.

1. Copy the Data Source Name (DSN) string. You need it for configuring your SDK implementation.

## Error tracking list

After your application has emitted errors to the Error Tracking API through the Sentry SDK,
they should be available under the **Monitor > Error Tracking** tab/section.

![MonitorListErrors](img/list_errors_v16_0.png)

## Error tracking details

In the Error Details view you can see more details of the exception, including number of occurrences,
users affected, first seen, and last seen dates.

You can also review the stack trace.

![MonitorDetailErrors](img/detail_errors_v16_0.png)

## Emit errors

### Supported language SDKs & Sentry types

In the following table, you can see a list of all event types available through Sentry SDK, and whether they are supported by GitLab Error Tracking.

| Language | Tested SDK client and version   | Endpoint   | Supported item types              |
| -------- | ------------------------------- | ---------- | --------------------------------- |
| Go       | `sentry-go/0.20.0`              | `store`    | `exception`, `message`            |
| Java     | `sentry.java:6.18.1`            | `envelope` | `exception`, `message`            |
| NodeJS   | `sentry.javascript.node:7.38.0` | `envelope` | `exception`, `message`            |
| PHP      | `sentry.php/3.18.0`             | `store`    | `exception`, `message`            |
| Python   | `sentry.python/1.21.0`          | `envelope` | `exception`, `message`, `session` |
| Ruby     | `sentry.ruby:5.9.0`             | `envelope` | `exception`, `message`            |
| Rust     | `sentry.rust/0.31.0`            | `envelope` | `exception`, `message`, `session` |

For a detailed version of this table, see [this issue](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/1737).

## Usage examples

You can also find working samples for all [supported language SDKs](https://gitlab.com/gitlab-org/opstrace/opstrace/-/tree/main/test/sentry-sdk/testdata/supported-sdk-clients).
Each listed program shows a basic example of how to capture exceptions, events,
or messages with the respective SDK.

For more in-depth documentation,
see [Sentry SDK's documentation](https://docs.sentry.io/) specific to the used language.

## Rotate generated DSN

The Sentry Data Source Name, or DSN, (client key) is a secret and it should not be exposed to the public.
In case of a leak, rotate the Sentry DSN by following these steps:

1. [Create an access token](../user/profile/personal_access_tokens.md#create-a-personal-access-token)
   by selecting your profile picture in GitLab.com.
   Then select Preferences, and then Access Token. Make sure you add API scope.
1. Using the [error tracking API](../api/error_tracking.md),
   create a new Sentry DSN:

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>"
   --header "Content-Type: application/json" \
      "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys"
   ```

1. Get the available client keys (Sentry DSNs).
   Ensure that the newly created Sentry DSN is in place.
   Then note down the key ID of the old client key:

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys"
   ```

1. Delete the old client key.

   ```shell
   curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/<your_project_number>/error_tracking/client_keys/<key_id>"
   ```

## Debug SDK issues

The majority of languages supported by Sentry expose `debug` option as part of initialization.
This can be helpful when debugging issues with sending errors. Otherwise,
there are options that could allow outputting JSON before it is sent to the API.

## Sentry error tracking

[Sentry](https://sentry.io/) is an open source error tracking system. GitLab allows
administrators to connect Sentry to GitLab
so users can view a list of Sentry errors in GitLab.

### Deploying Sentry

You can sign up to the cloud-hosted [Sentry](https://sentry.io) or deploy your own
[on-premise instance](https://github.com/getsentry/onpremise/).

### Enable Sentry integration for a project

GitLab provides a way to connect Sentry to your project.

Prerequisites:

- You must have at least the Developer role for the project.

To enable the Sentry integration:

1. Sign up to Sentry.io or [deploy your own](#deploying-sentry) Sentry instance.
1. [Create a new Sentry project](https://docs.sentry.io/product/sentry-basics/guides/integrate-frontend/create-new-project/).
   For each GitLab project that you want to integrate, you should create a new Sentry project.
1. Find or generate a [Sentry auth token](https://docs.sentry.io/api/auth/#auth-tokens).
   For the SaaS version of Sentry, you can find or generate the auth token at [https://sentry.io/api/](https://sentry.io/api/).
   You should give the token at least the following scopes: `project:read`,
   `event:read`, and
   `event:write` (for resolving events).
1. In GitLab, enable and configure Error Tracking:
   1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
   1. Select **Monitor > Error Tracking**.
   1. Under **Enable error tracking**, select the **Active** checkbox.
   1. Under **Error tracking backend**, select **Sentry**.
   1. Under **Sentry API URL**, enter your Sentry hostname. For example,
      enter `https://sentry.example.com`.
      For the SaaS version of Sentry, the hostname is `https://sentry.io`.
   1. Under **Auth Token**, enter the token you previously generated.
   1. To test the connection to Sentry and populate the **Project** dropdown list,
   select **Connect**.
   1. From the **Project** list, choose a Sentry project to link to your GitLab project.
   1. Select **Save changes**.

You can now visit **Monitor > Error Tracking** in your project's sidebar to
[view a list](#error-tracking-list) of Sentry errors.

### Sentry's GitLab integration

You might also want to enable Sentry's GitLab integration by following the steps
in the [Sentry documentation](https://docs.sentry.io/product/integrations/gitlab/).

### Enable GitLab Runner

To configure GitLab Runner with Sentry, you must add the value for `sentry_dsn`
to your runner's `config.toml` configuration file, as referenced in
[Advanced configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html).

If you're asked for the project type while setting up Sentry, select **Go**.

If you see the following error in your GitLab Runner logs, then you should
specify the deprecated
DSN in **Sentry.io > Project Settings > Client Keys (DSN) > Show deprecated DSN**.

```plaintext
ERROR: Sentry failure builds=0 error=raven: dsn missing private key
```

---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Audit event streaming GraphQL API **(ULTIMATE)**

> - API [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/332747) in GitLab 14.5 [with a flag](../feature_flags.md) named `ff_external_audit_events_namespace`. Disabled by default.
> - API [Enabled on GitLab.com and by default on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338939) in GitLab 14.7.
> - API [Feature flag `ff_external_audit_events_namespace`](https://gitlab.com/gitlab-org/gitlab/-/issues/349588) removed in GitLab 14.8.
> - Custom HTTP headers API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361216) in GitLab 15.1 [with a flag](../feature_flags.md) named `streaming_audit_event_headers`. Disabled by default.
> - Custom HTTP headers API [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/362941) in GitLab 15.2.
> - Custom HTTP headers API [made generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/366524) in GitLab 15.3. [Feature flag `streaming_audit_event_headers`](https://gitlab.com/gitlab-org/gitlab/-/issues/362941) removed.
> - User-specified verification token API support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/360813) in GitLab 15.4.
> - APIs for custom HTTP headers for instance level streaming destinations [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404560) in GitLab 16.1 [with a flag](../feature_flags.md) named `ff_external_audit_events`. Disabled by default.
> - [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) enabled by default in GitLab 16.2.
> - User-specified destination name API support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/413894) in GitLab 16.2.

Audit event streaming destinations can be maintained using a GraphQL API.

## Top-level group streaming destinations

Manage streaming destinations for top-level groups.

### HTTP destinations

Manage HTTP streaming destinations for top-level groups.

#### Add a new streaming destination

Add a new streaming destination to top-level groups.

WARNING:
Streaming destinations receive **all** audit event data, which could include sensitive information. Make sure you trust the streaming destination.

Prerequisites:

- Owner role for a top-level group.

To enable streaming and add a destination to a top-level group, use the `externalAuditEventDestinationCreate` mutation.

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group" } ) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

You can optionally specify your own verification token (instead of the default GitLab-generated one) using the GraphQL
`externalAuditEventDestinationCreate`
mutation. Verification token length must be within 16 to 24 characters and trailing whitespace are not trimmed. You
should set a cryptographically random and unique value. For example:

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group", verificationToken: "unique-random-verification-token-here" } ) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

You can optionally specify your own destination name (instead of the default GitLab-generated one) using the GraphQL
`externalAuditEventDestinationCreate`
mutation. Name length must not exceed 72 characters and trailing whitespace are not trimmed. This value should be unique scoped to a group. For example:

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", name: "destination-name-here", groupPath: "my-group" }) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

Event streaming is enabled if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

You can add an HTTP header using the GraphQL `auditEventsStreamingHeadersCreate` mutation. You can retrieve the
destination ID by [listing all the streaming destinations](#list-streaming-destinations) for the group or from the
mutation above.

```graphql
mutation {
  auditEventsStreamingHeadersCreate(input: { destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/24601", key: "foo", value: "bar" }) {
    errors
  }
}
```

The header is created if the returned `errors` object is empty.

#### List streaming destinations

List streaming destinations for a top-level groups.

Prerequisites:

- Owner role for a top-level group.

You can view a list of streaming destinations for a top-level group using the `externalAuditEventDestinations` query
type.

```graphql
query {
  group(fullPath: "my-group") {
    id
    externalAuditEventDestinations {
      nodes {
        destinationUrl
        verificationToken
        id
        name
        headers {
          nodes {
            key
            value
            id
          }
        }
        eventTypeFilters
      }
    }
  }
}
```

If the resulting list is empty, then audit streaming is not enabled for that group.

#### Update streaming destinations

Update streaming destinations for a top-level group.

Prerequisites:

- Owner role for a top-level group.

Users with the Owner role for a group can update streaming destinations' custom HTTP headers using the
`auditEventsStreamingHeadersUpdate` mutation type. You can retrieve the custom HTTP headers ID
by [listing all the custom HTTP headers](#list-streaming-destinations) for the group.

```graphql
mutation {
  externalAuditEventDestinationUpdate(input: { 
    id:"gid://gitlab/AuditEvents::ExternalAuditEventDestination/1", 
    destinationUrl: "https://www.new-domain.com/webhook",
    name: "destination-name"} ) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

Streaming destination is updated if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

Group owners can remove an HTTP header using the GraphQL `auditEventsStreamingHeadersDestroy` mutation. You can retrieve the header ID
by [listing all the custom HTTP headers](#list-streaming-destinations) for the group.

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

The header is deleted if the returned `errors` object is empty.

#### Delete streaming destinations

Delete streaming destinations for a top-level group.

When the last destination is successfully deleted, streaming is disabled for the group.

Prerequisites:

- Owner role for a top-level group.

Users with the Owner role for a group can delete streaming destinations using the
`externalAuditEventDestinationDestroy` mutation type. You can retrieve the destinations ID
by [listing all the streaming destinations](#list-streaming-destinations) for the group.

```graphql
mutation {
  externalAuditEventDestinationDestroy(input: { id: destination }) {
    errors
  }
}
```

Streaming destination is deleted if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

Group owners can remove an HTTP header using the GraphQL `auditEventsStreamingHeadersDestroy` mutation. You can retrieve the header ID
by [listing all the custom HTTP headers](#list-streaming-destinations) for the group.

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

The header is deleted if the returned `errors` object is empty.

#### Event type filters

> Event type filters API [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/344845) in GitLab 15.7.

When this feature is enabled for a group, you can use an API to permit users to filter streamed audit events per destination.
If the feature is enabled with no filters, the destination receives all audit events.

A streaming destination that has an event type filter set has a **filtered** (**{filter}**) label.

##### Use the API to add an event type filter

Prerequisites:

- You must have the Owner role for the group.

You can add a list of event type filters using the `auditEventsStreamingDestinationEventsAdd` query type:

```graphql
mutation {
    auditEventsStreamingDestinationEventsAdd(input: {
        destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
        eventTypeFilters: ["list of event type filters"]}){
        errors
        eventTypeFilters
    }
}
```

Event type filters are added if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

##### Use the API to remove an event type filter

Prerequisites:

- You must have the Owner role for the group.

You can remove a list of event type filters using the `auditEventsStreamingDestinationEventsRemove` query type:

```graphql
mutation {
    auditEventsStreamingDestinationEventsRemove(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    eventTypeFilters: ["list of event type filters"]
  }){
    errors
  }
}
```

Event type filters are removed if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

### Google Cloud Logging destinations

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/409422) in GitLab 16.1.

Manage Google Cloud Logging destinations for top-level groups.

Before setting up Google Cloud Logging streaming audit events, you must satisfy [the prerequisites](index.md#prerequisites).

#### Add a new Google Cloud Logging destination

Add a new Google Cloud Logging configuration destination to a top-level group.

Prerequisites:

- Owner role for a top-level group.
- A Google Cloud project with the necessary permissions to create service accounts and enable Google Cloud Logging.

To enable streaming and add a configuration, use the
`googleCloudLoggingConfigurationCreate` mutation in the GraphQL API.

```graphql
mutation {
  googleCloudLoggingConfigurationCreate(input: { groupPath: "my-group", googleProjectIdName: "my-google-project", clientEmail: "my-email@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events" } ) {
    errors
    googleCloudLoggingConfiguration {
      id
      googleProjectIdName
      logIdName
      privateKey
      clientEmail
    }
    errors
  }
}
```

Event streaming is enabled if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

#### List Google Cloud Logging configurations

List all Google Cloud Logging configuration destinations for a top-level group.

Prerequisite:

- Owner role for a top-level group.

You can view a list of streaming configurations for a top-level group using the `googleCloudLoggingConfigurations` query
type.

```graphql
query {
  group(fullPath: "my-group") {
    id
    googleCloudLoggingConfigurations {
      nodes {
        id
        logIdName
        googleProjectIdName
        privateKey
        clientEmail
      }
    }
  }
}
```

If the resulting list is empty, then audit streaming is not enabled for the group.

You need the ID values returned by this query for the update and delete mutations.

#### Update Google Cloud Logging configurations

Update a Google Cloud Logging configuration destinations for a top-level group.

Prerequisite:

- Owner role for a top-level group.

To update streaming configuration for a top-level group, use the
`googleCloudLoggingConfigurationUpdate` mutation type. You can retrieve the configuration ID
by [listing all the external destinations](#list-streaming-destinations).

```graphql
mutation {
  googleCloudLoggingConfigurationUpdate(
    input: {id: "gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1", googleProjectIdName: "my-google-project", clientEmail: "my-email@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events"}
  ) {
    errors
    googleCloudLoggingConfiguration {
      id
      logIdName
      privateKey
      googleProjectIdName
      clientEmail
    }
  }
}
```

Streaming configuration is updated if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

#### Delete Google Cloud Logging configurations

Delete streaming destinations for a top-level group.

When the last destination is successfully deleted, streaming is disabled for the group.

Prerequisite:

- Owner role for a top-level group.

Users with the Owner role for a group can delete streaming configurations using the
`googleCloudLoggingConfigurationDestroy` mutation type. You can retrieve the configurations ID
by [listing all the streaming destinations](#list-streaming-destinations) for the group.

```graphql
mutation {
  googleCloudLoggingConfigurationDestroy(input: { id: "gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1" }) {
    errors
  }
}
```

Streaming configuration is deleted if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

## Instance streaming destinations **(ULTIMATE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/335175) in GitLab 16.0 [with a flag](../feature_flags.md) named `ff_external_audit_events`. Disabled by default.
> - [Feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) enabled by default in GitLab 16.2.

FLAG:
On self-managed GitLab, by default this feature is enabled. To disable it, an administrator can [disable the feature flag](../feature_flags.md) named
`ff_external_audit_events`. On GitLab.com, this feature is available but can be configured by GitLab.com administrators only. The feature is ready for production use.

Manage HTTP streaming destinations for an entire instance.

### Add a new HTTP destination

Add a new HTTP streaming destination to an instance.

Prerequisites:

- Administrator access on the instance.

To enable streaming and add a destination, use the
`instanceExternalAuditEventDestinationCreate` mutation in the GraphQL API.

```graphql
mutation {
  instanceExternalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

Event streaming is enabled if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

You can optionally specify your own destination name (instead of the default GitLab-generated one) using the GraphQL
`instanceExternalAuditEventDestinationCreate`
mutation. Name length must not exceed 72 characters and trailing whitespace are not trimmed. This value should be unique. For example:

```graphql
mutation {
  instanceExternalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", name: "destination-name-here"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

Instance administrators can add an HTTP header using the GraphQL `auditEventsStreamingInstanceHeadersCreate` mutation. You can retrieve the destination ID
by [listing all the streaming destinations](#list-streaming-destinations) for the instance or from the mutation above.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersCreate(input:
    {
      destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/42",
      key: "foo",
      value: "bar"
    }) {
    errors
    header {
      id
      key
      value
    }
  }
}
```

The header is created if the returned `errors` object is empty.

### List streaming destinations

List all HTTP streaming destinations for an instance.

Prerequisites:

- Administrator access on the instance.

To view a list of streaming destinations for an instance, use the
`instanceExternalAuditEventDestinations` query type.

```graphql
query {
  instanceExternalAuditEventDestinations {
    nodes {
      id
      name
      destinationUrl
      verificationToken
      headers {
        nodes {
          id
          key
          value
        }
      }
    }
  }
}
```

If the resulting list is empty, then audit streaming is not enabled for the instance.

You need the ID values returned by this query for the update and delete mutations.

### Update streaming destinations

Update a HTTP streaming destination for an instance.

Prerequisites:

- Administrator access on the instance.

To update streaming destinations for an instance, use the
`instanceExternalAuditEventDestinationUpdate` mutation type. You can retrieve the destination ID
by [listing all the external destinations](#list-streaming-destinations-1) for the instance.

```graphql
mutation {
  instanceExternalAuditEventDestinationUpdate(input: { 
    id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
    destinationUrl: "https://www.new-domain.com/webhook",
    name: "destination-name"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

Streaming destination is updated if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

Instance administrators can update streaming destinations custom HTTP headers using the
`auditEventsStreamingInstanceHeadersUpdate` mutation type. You can retrieve the custom HTTP headers ID
by [listing all the custom HTTP headers](#list-streaming-destinations-1) for the instance.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersUpdate(input: { headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/2", key: "new-key", value: "new-value" }) {
    errors
    header {
      id
      key
      value
    }
  }
}
```

The header is updated if the returned `errors` object is empty.

### Delete streaming destinations

Delete streaming destinations for an entire instance.

When the last destination is successfully deleted, streaming is disabled for the instance.

Prerequisites:

- Administrator access on the instance.

To delete streaming destinations, use the
`instanceExternalAuditEventDestinationDestroy` mutation type. You can retrieve the destinations ID
by [listing all the streaming destinations](#list-streaming-destinations-1) for the instance.

```graphql
mutation {
  instanceExternalAuditEventDestinationDestroy(input: { id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1" }) {
    errors
  }
}
```

Streaming destination is deleted if:

- The returned `errors` object is empty.
- The API responds with `200 OK`.

To remove an HTTP header, use the GraphQL `auditEventsStreamingInstanceHeadersDestroy` mutation.
To retrieve the header ID,
[list all the custom HTTP headers](#list-streaming-destinations) for the instance.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/<id>" }) {
    errors
  }
}
```

The header is deleted if the returned `errors` object is empty.

---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Manage runners

GitLab Runner has the following types of runners, which are available based on who you want to have access:

- [Shared runners](#shared-runners) are available to all groups and projects in a GitLab instance.
- [Group runners](#group-runners) are available to all projects and subgroups in a group.
- [Project runners](#project-runners) are associated with specific projects.
  Typically, project runners are used by one project at a time.

## Shared runners

*Shared runners* are available to every project in a GitLab instance.

Use shared runners when you have multiple jobs with similar requirements. Rather than
having multiple runners idling for many projects, you can have a few runners that handle
multiple projects.

If you are using a self-managed instance of GitLab:

- Your administrator can [install GitLab Runner](https://docs.gitlab.com/runner/install/index.html) and register a shared runner.
- The administrator can also configure a maximum number of shared runner
  [compute minutes for each group](../pipelines/cicd_minutes.md#set-the-compute-quota-for-a-specific-namespace).

If you are using GitLab.com:

- You can select from a list of [shared runners that GitLab maintains](index.md).
- The shared runners consume the [compute minutes](../pipelines/cicd_minutes.md)
  included with your account.

### Create a shared runner with an authentication token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383139) in GitLab 15.10. Deployed behind the `create_runner_workflow_for_admin` [flag](../../administration/feature_flags.md)
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/389269) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/415447) in GitLab 16.2. Feature flag `create_runner_workflow_for_admin` removed.

Prerequisites:

- You must be an administrator.

When you create a runner, it is assigned an authentication token that you use to register it. The runner uses the token to authenticate with GitLab when picking up jobs from the job queue.

To create a shared runner:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. On the left sidebar, select **CI/CD > Runners**.
1. Select **New instance runner**.
1. Select a platform.
1. Optional. Enter configurations for the runner.
1. Select **Submit**.
1. Follow the on-screen instructions to register the runner from the command line.

You can also [create a runner](../../api/users.md#create-a-runner) with the API to generate an authentication token.

NOTE:
The authentication token displays in the UI for only a short period of time during registration.

### Create a shared runner with a registration token (deprecated)

WARNING:
The ability to pass a runner registration token, and support for certain configuration arguments was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6 and will be removed in GitLab 17.0. Authentication tokens
should be used instead. For more information, see [Migrating to the new runner registration workflow](new_creation_workflow.md).

Prerequisites:

- You must be an administrator.

To create a shared runner:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. Select **CI/CD > Runners**.
1. Select **Register an instance runner**.
1. Copy the registration token.
1. [Register the runner](https://docs.gitlab.com/runner/register/).

### Enable shared runners for a project

On GitLab.com, [shared runners](index.md) are enabled in all projects by
default.

On self-managed instances of GitLab, an administrator can
[enable them for all new projects](../../administration/settings/continuous_integration.md#enable-shared-runners-for-new-projects).

For existing projects, an administrator must
[install](https://docs.gitlab.com/runner/install/index.html) and
[register](https://docs.gitlab.com/runner/register/index.html) them.

To enable shared runners for a project:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. Turn on the **Enable shared runners for this project** toggle.

### Enable shared runners for a group

To enable shared runners for a group:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. Turn on the **Enable shared runners for this group** toggle.

### Disable shared runners for a project

You can disable shared runners for individual projects or for groups.
You must have the Owner role for the project
or group.

To disable shared runners for a project:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. In the **Shared runners** area, turn off the **Enable shared runners for this project** toggle.

Shared runners are automatically disabled for a project:

- If the shared runners setting for the parent group is disabled, and
- If overriding this setting is not permitted at the project level.

### Disable shared runners for a group

To disable shared runners for a group:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. Turn off the **Enable shared runners for this group** toggle.
1. Optional. To allow shared runners to be enabled for individual projects or subgroups,
   select **Allow projects and subgroups to override the group setting**.

### How shared runners pick jobs

Shared runners process jobs by using a fair usage queue. This queue prevents
projects from creating hundreds of jobs and using all available
shared runner resources.

The fair usage queue algorithm assigns jobs based on the projects that have the
fewest number of jobs already running on shared runners.

For example, if these jobs are in the queue:

- Job 1 for Project 1
- Job 2 for Project 1
- Job 3 for Project 1
- Job 4 for Project 2
- Job 5 for Project 2
- Job 6 for Project 3

When several CI/CD jobs run concurrently, the fair usage algorithm assigns jobs in this order:

1. Job 1 is first, because it has the lowest job number from projects with no running jobs (that is, all projects).
1. Job 4 is next, because 4 is now the lowest job number from projects with no running jobs (Project 1 has a job running).
1. Job 6 is next, because 6 is now the lowest job number from projects with no running jobs (Projects 1 and 2 have jobs running).
1. Job 2 is next, because, of projects with the lowest number of jobs running (each has 1), it is the lowest job number.
1. Job 5 is next, because Project 1 now has 2 jobs running and Job 5 is the lowest remaining job number between Projects 2 and 3.
1. Finally is Job 3... because it's the only job left.

When only one job runs at a time, the fair usage algorithm assigns jobs in this order:

1. Job 1 is chosen first, because it has the lowest job number from projects with no running jobs (that is, all projects).
1. We finish Job 1.
1. Job 2 is next, because, having finished Job 1, all projects have 0 jobs running again, and 2 is the lowest available job number.
1. Job 4 is next, because with Project 1 running a Job, 4 is the lowest number from projects running no jobs (Projects 2 and 3).
1. We finish Job 4.
1. Job 5 is next, because having finished Job 4, Project 2 has no jobs running again.
1. Job 6 is next, because Project 3 is the only project left with no running jobs.
1. Lastly we choose Job 3... because, again, it's the only job left.

## Group runners

Use _group runners_ when you want all projects in a group
to have access to a set of runners.

Group runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

### Create a group runner with an authentication token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383143) in GitLab 15.10. Deployed behind the `create_runner_workflow_for_namespace` [flag](../../administration/feature_flags.md). Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/393919) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/415447) in GitLab 16.2. Feature flag `create_runner_workflow_for_admin` removed.

Prerequisites:

- You must have the Owner role for the group.

You can create a group runner for your self-managed GitLab instance or for GitLab.com.
When you create a runner, it is assigned an authentication token that you use to register it. The runner uses the token to authenticate with GitLab when picking up jobs from the job queue.

To create a group runner:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Build > Runners**.
1. Select **New group runner**.
1. Select a platform.
1. Optional. Enter configurations for the runner.
1. Select **Submit**.
1. Follow the on-screen instructions to register the runner from the command line.

You can also [create a runner](../../api/users.md#create-a-runner) with the API to generate an authentication token.

NOTE:
The authentication token displays in the UI for only a short period of time during registration.

### Create a group runner with a registration token (deprecated)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/19819) in GitLab 14.10, path changed from **Settings > CI/CD > Runners**.

WARNING:
The ability to pass a runner registration token, and support for certain configuration arguments was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6 and will be removed in GitLab 17.0. Authentication tokens
should be used instead. For more information, see [Migrating to the new runner registration workflow](new_creation_workflow.md).

You must have the Owner role for the group.

To create a group runner:

1. [Install GitLab Runner](https://docs.gitlab.com/runner/install/).
1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Build > Runners**.
1. In the upper-right corner, select **Register a group runner**.
1. Select **Show runner installation and registration instructions**.
   These instructions include the token, URL, and a command to register a runner.

Alternately, you can copy the registration token and follow the documentation for
how to [register a runner](https://docs.gitlab.com/runner/register/).

### View and manage group runners

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/37366/) in GitLab 13.2.

You can view and manage all runners for a group, its subgroups, and projects.
You can do this for your self-managed GitLab instance or for GitLab.com.
You must have the Owner role for the group.

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Build > Runners**.

From this page, you can edit, pause, and remove runners from the group, its subgroups, and projects.

#### Delete multiple group runners

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/361721/) in GitLab 15.6

Prerequisites:

- You must have either:
  - Owner role for the group.
  - Access to delete any runners in the group.

To delete multiple runners in a single action in the group list:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Build > Runners**.
1. To delete multiple runners, you can either:
   - Select the checkbox next to the runner.
   - Select the checkbox at the top of the runner list to select all runners in the list.
1. To delete the runners, select **Delete selected**.

#### Filter group runners to show only inherited

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/337838/) in GitLab 15.5.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101099) in GitLab 15.5. Feature flag `runners_finder_all_available` removed.

You can choose to show all runners in the list, or show only
those that are inherited from the instance or other groups.

By default, only those that are inherited are shown.

To show all runners available in the instance, including shared runners and
those in other groups:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Build > Runners**.
1. Above the list, turn off the **Show only inherited** toggle.

### Pause or remove a group runner

You can pause or remove a group runner for your self-managed GitLab instance or for GitLab.com.
You must have the Owner role for the group.

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Build > Runners**.
1. Select **Pause** or **Remove runner**.
   - If you pause a group runner that is used by multiple projects, the runner pauses for all projects.
   - From the group view, you cannot remove a runner that is assigned to more than one project.
     You must remove it from each project first.
1. On the confirmation dialog, select **OK**.

### Clean up stale group runners **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363012) in GitLab 15.1.

You can clean up group runners that have been inactive for more than three months.

Group runners are those that were created at the group level.

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. Turn on the **Enable stale runner cleanup** toggle.

#### View stale runner cleanup logs

You can check the [Sidekiq logs](../../administration/logs/index.md#sidekiq-logs) to see the cleanup result. In Kibana you can use the following query:

```json
{
  "query": {
    "match_phrase": {
      "json.class.keyword": "Ci::Runners::StaleGroupRunnersPruneCronWorker"
    }
  }
}
```

Filter entries where stale runners were removed:

```json
{
  "query": {
    "range": {
      "json.extra.ci_runners_stale_group_runners_prune_cron_worker.total_pruned": {
        "gte": 1,
        "lt": null
      }
    }
  }
}
```

## Project runners

Use _project runners_ when you want to use runners for specific projects. For example,
when you have:

- Jobs with specific requirements, like a deploy job that requires credentials.
- Projects with a lot of CI activity that can benefit from being separate from other runners.

You can set up a project runner to be used by multiple projects. Project runners
must be enabled for each project explicitly.

Project runners process jobs by using a first in, first out ([FIFO](https://en.wikipedia.org/wiki/FIFO_(computing_and_electronics))) queue.

NOTE:
Project runners do not get shared with forked projects automatically.
A fork *does* copy the CI/CD settings of the cloned repository.

### Create a project runner with an authentication token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383143) in GitLab 15.10. Deployed behind the `create_runner_workflow_for_namespace` [flag](../../administration/feature_flags.md). Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/393919) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/415447) in GitLab 16.2. Feature flag `create_runner_workflow_for_admin` removed.

Prerequisites:

- You must have the Maintainer role for the project.

You can create a project runner for your self-managed GitLab instance or for GitLab.com. When you create a runner, it is assigned an authentication token that you use to register to the runner. The runner uses the token to authenticate with GitLab when picking up jobs from the job queue.

To create a project runner:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > CI/CD**.
1. Expand the **Runners** section.
1. Select **New project runner**.
1. Select a platform.
1. Optional. Enter configurations for the runner.
1. Select **Submit**.
1. Follow the on-screen instructions to register the runner from the command line.

You can also [create a runner](../../api/users.md#create-a-runner) with the API to generate an authentication token.

NOTE:
The authentication token displays in the UI for only a short period of time during registration.

### Create a project runner with a registration token (deprecated)

WARNING:
The ability to pass a runner registration token, and support for certain configuration arguments was
[deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/380872) in GitLab 15.6 and will be removed in GitLab 17.0. Authentication tokens
should be used instead. For more information, see [Migrating to the new runner registration workflow](new_creation_workflow.md).

Prerequisite:

- You must have at least the Maintainer role for the project.

To create a project runner:

1. [Install GitLab Runner](https://docs.gitlab.com/runner/install/).
1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to
   find the project where you want to use the runner.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. In the **Project runners** section, note the URL and token.
1. [Register the runner](https://docs.gitlab.com/runner/register/).

The runner is now enabled for the project.

### Enable a project runner for a different project

After a project runner is created, you can enable it for other projects.

Prerequisites:
You must have at least the Maintainer role for:

- The project where the runner is already enabled.
- The project where you want to enable the runner.
- The project runner must not be [locked](#prevent-a-project-runner-from-being-enabled-for-other-projects).

To enable a project runner for a project:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to
   find the project where you want to enable the runner.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. In the **Project runners** area, by the runner you want, select **Enable for this project**.

You can edit a project runner from any of the projects it's enabled for.
The modifications, which include unlocking and editing tags and the description,
affect all projects that use the runner.

An administrator can [enable the runner for multiple projects](../../administration/settings/continuous_integration.md#enable-a-project-runner-for-multiple-projects).

### Prevent a project runner from being enabled for other projects

You can configure a project runner so it is "locked" and cannot be enabled for other projects.
This setting can be enabled when you first [register a runner](https://docs.gitlab.com/runner/register/),
but can also be changed later.

To lock or unlock a project runner:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to
   find the project where you want to enable the runner.
1. Select **Settings > CI/CD**.
1. Expand **Runners**.
1. Find the project runner you want to lock or unlock. Make sure it's enabled. You cannot lock shared or group runners.
1. Select **Edit** (**{pencil}**).
1. Select the **Lock to current projects** checkbox.
1. Select **Save changes**.

## Runner statuses

A runner can have one of the following statuses.

| Status  | Description |
|---------|-------------|
| `online`  | The runner has contacted GitLab within the last 2 hours and is available to run jobs. |
| `offline` | The runner has not contacted GitLab in more than 2 hours and is not available to run jobs. Check the runner to see if you can bring it online. |
| `stale`   | The runner has not contacted GitLab in more than 3 months. If the runner was created more than 3 months ago, but it never contacted the instance, it is also considered **stale**. |
| `never_contacted` | The runner has never contacted GitLab. To make the runner contact GitLab, run `gitlab-runner run`. |

## View statistics for runner performance **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/377963) in GitLab 15.8.

As an administrator, you can view runner statistics to learn about the performance of your runner fleet.

- The **Median job queued time** value is calculated by sampling the queue duration of the
most recent 100 jobs that were run by Instance runners. Jobs from only the latest 5000
runners are considered.
- The median is a value that falls into the 50th percentile: half of the jobs
queued for longer than the median value, and half of the jobs queued for less than the
median value.

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. On the left sidebar, select **CI/CD > Runners**.
1. Select **View metrics**.

## Determine which runners need to be upgraded **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/365078) in GitLab 15.3.

The version of GitLab Runner used by your runners should be
[kept up-to-date](https://docs.gitlab.com/runner/index.html#gitlab-runner-versions).

To determine which runners need to be upgraded:

1. View the list of runners:
   - For a group:
     1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your group.
     1. Select **Build > Runners**.
   - For the instance:
     1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
     1. Select **Admin Area**.
     1. Select **CI/CD > Runners**.

1. Above the list of runners, view the status:
   - **Outdated - recommended**: The runner does not have the latest `PATCH` version, which may make it vulnerable
     to security or high severity bugs. Or, the runner is one or more `MAJOR` versions behind your GitLab instance, so some features may not be available or work properly.
   - **Outdated - available**: Newer versions are available but upgrading is not critical.

1. Filter the list by status to view which individual runners need to be upgraded.

## Determine the IP address of a runner

It may be useful to know the IP address of a runner so you can troubleshoot
issues with that runner. GitLab stores and displays the IP address by viewing
the source of the HTTP requests it makes to GitLab when polling for jobs. The
IP address is always kept up to date so if the runner IP changes it
automatically updates in GitLab.

The IP address for shared runners and project runners can be found in
different places.

### Determine the IP address of a shared runner

Prerequisite:

- You must have administrator access to the instance.

To determine the IP address of a shared runner:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. On the left sidebar, select **CI/CD > Runners**.
1. Find the runner in the table and view the **IP Address** column.

![shared runner IP address](img/shared_runner_ip_address_14_5.png)

### Determine the IP address of a project runner

To can find the IP address of a runner for a project project,
you must have the Owner role for the
project.

1. Go to the project's **Settings > CI/CD** and expand the **Runners** section.
1. On the details page you should see a row for **IP Address**.

![Project runner IP address](img/project_runner_ip_address.png)

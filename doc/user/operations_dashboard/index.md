---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Operations Dashboard **(PREMIUM)**

The Operations Dashboard provides a summary of each project's operational health,
including pipeline and alert status.

To access the dashboard:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Your work**.
1. Select **Operations**.

## Adding a project to the dashboard

To add a project to the dashboard:

1. Ensure your alerts populate the `gitlab_environment_name` label on the alerts you set up in Prometheus.
   The value of this should match the name of your environment in GitLab.
   In GitLab 13.9, you can display alerts for the `production` environment only.
1. Select **Add projects** in the home screen of the dashboard.
1. Search and add one or more projects using the **Search your projects** field.
1. Select **Add projects**.

Once added, the dashboard displays the project's number of active alerts,
last commit, pipeline status, and when it was last deployed.

The Operations and [Environments](../../ci/environments/environments_dashboard.md) dashboards share the same list of projects. Adding or removing a project from one adds or removes the project from the other.

![Operations Dashboard with projects](img/index_operations_dashboard_with_projects.png)

## Arranging projects on a dashboard

You can drag project cards to change their order. The card order is currently only saved to your browser, so it doesn't change the dashboard for other people.

## Making it the default dashboard when you sign in

The Operations Dashboard can also be made the default GitLab dashboard shown when
you sign in. To make it the default, see [Profile preferences](../profile/preferences.md).

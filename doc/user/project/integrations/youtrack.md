---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# YouTrack **(FREE)**

JetBrains [YouTrack](https://www.jetbrains.com/youtrack/) is a web-based issue tracking and project
management platform.

You can configure YouTrack as an
[external issue tracker](../../../integration/external-issue-tracker.md) in GitLab.

To enable the YouTrack integration in a project:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > Integrations**.
1. Select **YouTrack**.
1. Under **Enable integration**, select the **Active** checkbox.
1. Fill in the required fields:
   - **Project URL**: The URL to the project in YouTrack.
   - **Issue URL**: The URL to view an issue in the YouTrack project.
     The URL must contain `:id`. GitLab replaces `:id` with the issue number.
1. Optional. Select **Test settings**.
1. Select **Save changes**.

After you configure and enable YouTrack, a link appears on the GitLab
project pages. This link takes you to the appropriate YouTrack project.

You can also disable [GitLab internal issue tracking](../issues/index.md) in this project.
For more information about the steps and consequences of disabling GitLab issues, see
[Configure project visibility, features, and permissions](../settings/index.md#configure-project-visibility-features-and-permissions).

## Reference YouTrack issues in GitLab

You can reference issues in YouTrack using `<PROJECT>-<ID>` (for example `YT-101`, `Api_32-143` or `gl-030`) where:

- `<PROJECT>` starts with a letter and is followed by letters, numbers, or underscores.
- `<ID>` is a number.

References to `<PROJECT>-<ID>` in merge requests, commits, or comments are automatically linked
to the YouTrack issue URL.

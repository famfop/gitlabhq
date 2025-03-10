---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Harbor Registry **(FREE)**

You can integrate the [Harbor container registry](../../../user/project/integrations/harbor.md) into GitLab and use Harbor as the container registry for your GitLab project to store images.

## View the Harbor Registry

You can view the Harbor Registry for a project or group.

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project or group.
1. Select **Operate > Harbor Registry**.

You can search, sort, and filter images on this page. You can share a filtered view by copying the URL from your browser.

At the project level, in the upper-right corner, you can see **CLI Commands** where you can copy
corresponding commands to sign in, build images, and push images. **CLI Commands** is not shown at
the group level.

NOTE:
Default settings for the Harbor integration at the project level are inherited from the group level.

## Use images from the Harbor Registry

To download and run a Harbor image hosted in the GitLab Harbor Registry:

1. Copy the link to your container image:
    1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project or group.
    1. Select **Operate > Harbor Registry** and find the image you want.
    1. Select the **Copy** icon next to the image name.

1. Use the command to run the container image you want.

## View the tags of a specific artifact

To view the list of tags associated with a specific artifact:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project or group.
1. Go to **Operate > Harbor Registry**.
1. Select the image name to view its artifacts.
1. Select the artifact you want.

This brings up the list of tags. You can view the tag count and the time published.

You can also copy the tag URL and use it to pull the corresponding artifact.

## Build and push images by using commands

To build and push to the Harbor Registry:

1. Authenticate with the Harbor Registry.
1. Run the command to build or push.

To view these commands:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project or group.
1. Select **Operate > Harbor Registry**.
1. Select **CLI Commands**.

## Disable the Harbor Registry for a project

To remove the Harbor Registry for a project:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project or group.
1. Select **Settings > Integrations**.
1. Select **Harbor** under **Active integrations**.
1. Under **Enable integration**, clear the **Active** checkbox.
1. Select **Save changes**.

The **Operate > Harbor Registry** entry is removed from the sidebar.

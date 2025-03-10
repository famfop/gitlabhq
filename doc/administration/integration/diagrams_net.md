---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference, howto
---

# Diagrams.net **(FREE)**

With the [diagrams.net](https://www.diagrams.net/) integration, you can create and embed SVG diagrams in wikis.
The diagram editor is available in both the plain text editor and the rich text editor.

On GitLab.com, this integration is enabled for all SaaS users and does not require any additional configuration.

On self-managed GitLab, you can choose to integrate with the free [diagrams.net](https://www.diagrams.net/)
website, or use a self-managed diagrams.net site in offline environments.

To set up the integration on a self-managed instance, you must:

1. Choose to integrate with the free diagrams.net website or
   [configure your diagrams.net server](#configure-your-diagramsnet-server).
1. [Enable the integration](#enable-diagramsnet-integration).

After completing the integration, the diagrams.net editor opens with the URL you provided.

## Configure your diagrams.net server

You can set up your own diagrams.net server to generate the diagrams.

This is a required step for users on offline (or "air-gapped") self-managed GitLab installations.

For example, to run a diagrams.net container in Docker, run the following command:

```shell
docker run -it --rm --name="draw" -p 8080:8080 -p 8443:8443 jgraph/drawio
```

Make note of the hostname of the server running the container, to be used as the diagrams.net URL
when you enable the integration.

For more information, see [Run your own diagrams.net server with Docker](https://www.diagrams.net/blog/diagrams-docker-app).

## Enable Diagrams.net integration

1. Sign in to GitLab as an [Administrator](../../user/permissions.md) user.
1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Diagrams.net**.
1. Select the **Enable Diagrams.net** checkbox.
1. Enter the Diagrams.net URL. To connect to:
   - The free public instance: enter `https://embed.diagrams.net`.
   - A self-managed diagrams.net instance: enter the URL you [configured earlier](#configure-your-diagramsnet-server).
1. Select **Save changes**.

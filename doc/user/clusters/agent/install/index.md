---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Installing the agent for Kubernetes **(FREE)**

> - [Moved](https://gitlab.com/groups/gitlab-org/-/epics/6290) from GitLab Premium to GitLab Free in 14.5.
> - [Introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/594) multi-arch images in GitLab 14.8. The first multi-arch release is `v14.8.1`. It supports AMD64 and ARM64 architectures.
> - [Introduced](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/603) ARM architecture support in GitLab 14.9.

To connect a Kubernetes cluster to GitLab, you must install an agent in your cluster.

## Prerequisites

Before you can install the agent in your cluster, you need:

- An existing Kubernetes cluster. If you don't have a cluster, you can create one on a cloud provider, like:
  - [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs/deploy-app-cluster)
  - [Amazon Elastic Kubernetes Service (EKS)](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)
  - [Digital Ocean](https://docs.digitalocean.com/products/kubernetes/quickstart/)
- On self-managed GitLab instances, a GitLab administrator must set up the
  [agent server](../../../../administration/clusters/kas.md).
  Then it is available by default at `wss://gitlab.example.com/-/kubernetes-agent/`.
  On GitLab.com, the agent server is available at `wss://kas.gitlab.com`.

## Installation steps

To install the agent in your cluster:

1. [Create an agent configuration file](#create-an-agent-configuration-file).
1. [Register the agent with GitLab](#register-the-agent-with-gitlab).
1. [Install the agent in your cluster](#install-the-agent-in-the-cluster).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> Watch a GitLab 14.2 [walk-through of this process](https://www.youtube.com/watch?v=XuBpKtsgGkE).

### Create an agent configuration file

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/259669) in GitLab 13.7, the agent configuration file can be added to multiple directories (or subdirectories) of the repository.
> - Group authorization was [introduced](https://gitlab.com/groups/gitlab-org/-/epics/5784) in GitLab 14.3.

For configuration settings, the agent uses a YAML file in the GitLab project. You must create this file if:

- You use [a GitOps workflow](../gitops/agent.md#gitops-workflow-steps).
- You use [a GitLab CI/CD workflow](../ci_cd_workflow.md#gitlab-cicd-workflow-steps) and want to authorize a different project to use the agent.
- You [allow specific project or group members to access Kubernetes](../user_access.md).

To create an agent configuration file:

1. Choose a name for your agent. The agent name follows the
   [DNS label standard from RFC 1123](https://www.rfc-editor.org/rfc/rfc1123). The name must:

   - Be unique in the project.
   - Contain at most 63 characters.
   - Contain only lowercase alphanumeric characters or `-`.
   - Start with an alphanumeric character.
   - End with an alphanumeric character.

1. In the repository, in the default branch, create an agent configuration file at the root:

   ```plaintext
   .gitlab/agents/<agent-name>/config.yaml
   ```

You can leave the file blank for now, and [configure it](#configure-your-agent) later.

### Register the agent with GitLab

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5786) in GitLab 14.1, you can create a new agent record directly from the GitLab UI.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/347240) in GitLab 14.9, the agent can be registered without creating an agent configuration file.

FLAG:
In GitLab 14.10, a [flag](../../../../administration/feature_flags.md) named `certificate_based_clusters` changed the **Actions** menu to focus on the agent rather than certificates. The flag is [enabled on GitLab.com and self-managed](https://gitlab.com/groups/gitlab-org/configure/-/epics/8).

Prerequisites:

- For a [GitLab CI/CD workflow](../ci_cd_workflow.md), ensure that
  [GitLab CI/CD is enabled](../../../../ci/enable_or_disable_ci.md#enable-cicd-in-a-project).

You must register an agent before you can install the agent in your cluster. To register an agent:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
   If you have an [agent configuration file](#create-an-agent-configuration-file),
   it must be in this project. Your cluster manifest files should also be in this project.
1. Select **Operate > Kubernetes clusters**.
1. Select **Connect a cluster (agent)**.
   - If you want to create a configuration with CI/CD defaults, type a name.
   - If you already have an [agent configuration file](#create-an-agent-configuration-file), select it from the list.
1. Select **Register an agent**.
1. GitLab generates an access token for the agent. You need this token to install the agent
   in your cluster.

   WARNING:
   Securely store the agent access token. A bad actor can use this token to access source code in the agent's configuration project, access source code in any public project on the GitLab instance, or even, under very specific conditions, obtain a Kubernetes manifest.

1. Copy the command under **Recommended installation method**. You need it when you use
   the one-liner installation method to install the agent in your cluster.

### Install the agent in the cluster

> Introduced in GitLab 14.10, GitLab recommends using Helm to install the agent.

To connect your cluster to GitLab, install the registered agent
in your cluster. You can either:

- [Install the agent with Helm](#install-the-agent-with-helm).
- Or, follow the [advanced installation method](#advanced-installation-method).

If you do not know which one to choose, we recommend starting with Helm.

NOTE:
To connect to multiple clusters, you must configure, register, and install an agent in each cluster. Make sure to give each agent a unique name.

#### Install the agent with Helm

To install the agent on your cluster using Helm:

1. [Install Helm](https://helm.sh/docs/intro/install/).
1. In your computer, open a terminal and [connect to your cluster](https://kubernetes.io/docs/tasks/access-application-cluster/access-cluster/).
1. Run the command you copied when you [registered your agent with GitLab](#register-the-agent-with-gitlab).

Optionally, you can [customize the Helm installation](#customize-the-helm-installation). If you install the agent on a production system, you should customize the Helm installation to skip creating the service account.

##### Customize the Helm installation

By default, the Helm installation command generated by GitLab:

- Creates a namespace `gitlab-agent` for the deployment (`--namespace gitlab-agent`). You can skip creating the namespace by omitting the `--create-namespace` flag.
- Sets up a service account for the agent with `cluster-admin` rights. You can:
  - Skip creating the service account by adding `--set serviceAccount.create=false` to the `helm install` command. In this case, you must set `serviceAccount.name` to a pre-existing service account.
  - Skip creating the RBAC permissions by adding `--set rbac.create=false` to the `helm install` command. In this case, you must bring your own RBAC permissions for the agent. Otherwise, it has no permissions at all.
- Creates a `Secret` resource for the agent's access token. To instead bring your own secret with a token, omit the token (`--set token=...`) and instead use `--set config.secretName=<your secret name>`.
- Creates a `Deployment` resource for the `agentk` pod.

To see the full list of customizations available, see the Helm chart's [default values file](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/blob/main/values.yaml).

##### Use the agent when KAS is behind a self-signed certificate

When [KAS](../../../../administration/clusters/kas.md) is behind a self-signed certificate,
you can set the value of `config.caCert` to the certificate. For example:

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set-file config.caCert=my-custom-ca.pem
```

In this example, `my-custom-ca.pem` is the path to a local file that contains
the CA certificate used by KAS. The certificate is automatically stored in a
config map and mounted in the `agentk` pod.

If KAS is installed with the GitLab chart, and the chart is configured to provide
an [auto-generated self-signed wildcard certificate](https://docs.gitlab.com/charts/installation/tls.html#option-4-use-auto-generated-self-signed-wildcard-certificate), you can extract the CA certificate from the `RELEASE-wildcard-tls-ca` secret.

##### Use the agent behind an HTTP proxy

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/351867) in GitLab 15.0, the GitLab agent Helm chart supports setting environment variables.

To configure an HTTP proxy when using the Helm chart, you can use the environment variables `HTTP_PROXY`, `HTTPS_PROXY`,
and `NO_PROXY`. Upper and lowercase are both acceptable.

You can set these variables by using the `extraEnv` value, as a list of objects with keys `name` and `value`.
For example, to set only the environment variable `HTTPS_PROXY` to the value `https://example.com/proxy`, you can run:

```shell
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --set extraEnv[0].name=HTTPS_PROXY \
  --set extraEnv[0].value=https://example.com/proxy \
  ...
```

NOTE:
DNS rebind protection is disabled when either the `HTTP_PROXY` or the `HTTPS_PROXY` environment variable is set,
and the domain DNS can't be resolved.

#### Advanced installation method

GitLab also provides a [KPT package for the agent](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/tree/master/build/deployment/gitlab-agent). This method provides greater flexibility, but is only recommended for advanced users.

### Configure your agent

To configure your agent, add content to the `config.yaml` file:

- For a GitOps workflow, [view the configuration reference](../gitops/agent.md#gitops-configuration-reference).
- For a GitLab CI/CD workflow, [authorize the agent to access your projects](../ci_cd_workflow.md#authorize-the-agent). Then
  [add `kubectl` commands to your `.gitlab-ci.yml` file](../ci_cd_workflow.md#update-your-gitlab-ciyml-file-to-run-kubectl-commands).

## Install multiple agents in your cluster

To install a second agent in your cluster, you can follow the [previous steps](#register-the-agent-with-gitlab) a second time. To avoid resource name collisions within the cluster, you must either:

- Use a different release name for the agent, for example, `second-gitlab-agent`:

  ```shell
  helm upgrade --install second-gitlab-agent gitlab/gitlab-agent ...
  ```

- Or, install the agent in a different namespace, for example, `different-namespace`:

  ```shell
  helm upgrade --install gitlab-agent gitlab/gitlab-agent \
    --namespace different-namespace \
    ...
  ```

## Example projects

The following example projects can help you get started with the agent.

- [Configuration repository with minimal manifests](https://gitlab.com/gitlab-examples/ops/gitops-demo/k8s-agents)
- [Distinct application and manifest repository example](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service-gitops)
- [Auto DevOps setup that uses the CI/CD workflow](https://gitlab.com/gitlab-examples/ops/gitops-demo/hello-world-service)
- [Cluster management project template example that uses the CI/CD workflow](https://gitlab.com/gitlab-examples/ops/gitops-demo/cluster-management)

## Updates and version compatibility

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/340882) in GitLab 14.8, GitLab warns you on the agent's list page to update the agent version installed on your cluster.

For the best experience, the version of the agent installed in your cluster should match the GitLab major and minor version. The previous minor version is also supported. For example, if your GitLab version is v14.9.4 (major version 14, minor version 9), then versions v14.9.0 and v14.9.1 of the agent are ideal, but any v14.8.x version of the agent is also supported. See [the release page](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/releases) of the GitLab agent.

### Update the agent version

To update the agent to the latest version, you can run:

```shell
helm repo update
helm upgrade --install gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent \
  --reuse-values
```

To set a specific version, you can override the `image.tag` value. For example, to install version `v14.9.1`, run:

```shell
helm upgrade gitlab-agent gitlab/gitlab-agent \
  --namespace gitlab-agent \
  --reuse-values \
  --set image.tag=v14.9.1
```

The Helm chart is updated separately from the agent for Kubernetes, and might occasionally lag behind the latest version of the agent. If you run `helm repo update` and don't specify an image tag, your agent runs the version specified in the chart.

To use the latest release of the agent for Kubernetes, set the image tag to match the most recent agent image.

## Uninstall the agent

If you [installed the agent with Helm](#install-the-agent-with-helm), then you can also uninstall with Helm. For example, if the release and namespace are both called `gitlab-agent`, then you can uninstall the agent using the following command:

```shell
helm uninstall gitlab-agent \
    --namespace gitlab-agent
```

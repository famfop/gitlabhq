---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Repository mirroring **(FREE)**

You can _mirror_ a repository to and from external sources. You can select which repository
serves as the source. Branches, tags, and commits are synced automatically.

NOTE:
SCP-style URLs are **not** supported. However, the work for implementing SCP-style URLs is tracked
in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/18993).
Subscribe to the issue to follow its progress.

Several mirroring methods exist:

- [Push](push.md): Mirror a repository from GitLab to another location.
- [Pull](pull.md): Mirror a repository from another location to a GitLab Premium instance.
- [Bidirectional](bidirectional.md) mirroring is also available, but can cause conflicts.

Mirror a repository when:

- The canonical version of your project has migrated to GitLab. To keep providing a
  copy of your project at its previous home, configure your GitLab repository as a
  [push mirror](push.md). Changes you make to your GitLab repository are copied to
  the old location.
- Your GitLab instance is private, but you want to open-source some projects.
- You migrated to GitLab, but the canonical version of your project is somewhere else.
  Configure your GitLab repository as a [pull mirror](pull.md) of the other project.
  Your GitLab repository pulls copies of the commits, tags, and branches of project.
  They become available to use on GitLab.

## Create a repository mirror

Prerequisites:

- You must have at least the Maintainer role for the project.
- If your mirror connects with `ssh://`, the host key must be detectable on the server,
  or you must have a local copy of the key.

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > Repository**.
1. Expand **Mirroring repositories**.
1. Enter a **Git repository URL**. For security reasons, the URL to the original
   repository is only displayed to users with the Maintainer role
   or the Owner role for the mirrored project.
1. Select a **Mirror direction**.
1. If you entered a `ssh://` URL, select either:
   - **Detect host keys**: GitLab fetches the host keys from the server and displays the fingerprints.
   - **Input host keys manually**, and enter the host key into **SSH host key**.

   When mirroring the repository, GitLab confirms at least one of the stored host keys
   matches before connecting. This check can protect your mirror from malicious code injections,
   or your password from being stolen.
1. Select an **Authentication method**. For more information, see
   [Authentication methods for mirrors](#authentication-methods-for-mirrors).
1. If you authenticate with SSH host keys, [verify the host key](#verify-a-host-key)
   to ensure it is correct.
1. To prevent force-pushing over diverged refs, select [**Keep divergent refs**](push.md#keep-divergent-refs).
1. Optional. To limit the number of branches mirrored, select
   **Mirror only protected branches** or enter a regex in **Mirror specific branches**.
1. Select **Mirror repository**.

If you select `SSH public key` as your authentication method, GitLab generates a
public key for your GitLab repository. You must provide this key to the non-GitLab server.
For more information, see [Get your SSH public key](#get-your-ssh-public-key).

### Mirror only protected branches

You can choose to mirror only the
[protected branches](../../protected_branches.md) in the mirroring project,
either from or to your remote repository. For [pull mirroring](pull.md),
non-protected branches in the mirroring project are not mirrored and can diverge.

To use this option, select **Only mirror protected branches** when you create a repository mirror.

### Mirror specific branches **(PREMIUM)**

> - Mirroring branches matching a regex [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102608) in GitLab 15.8 [with a flag](../../../../administration/feature_flags.md) named `mirror_only_branches_match_regex`. Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/381667) in GitLab 16.0.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/410354) in GitLab 16.2. Feature flag `mirror_only_branches_match_regex` removed.
To mirror only branches with names matching an [re2 regular expression](https://github.com/google/re2/wiki/Syntax),
enter a regular expression into the **Mirror specific branches** field. Branches with names that
do not match the regular expression are not mirrored.

## Update a mirror

When the mirror repository is updated, all new branches, tags, and commits are visible in the
project's activity feed. A repository mirror at GitLab updates automatically.
You can also manually trigger an update:

- At most once every five minutes on GitLab.com.
- According to [the pull mirroring interval limit](../../../../administration/instance_limits.md#pull-mirroring-interval)
  set by the administrator on self-managed instances.

NOTE:
[GitLab Silent Mode](../../../../administration/silent_mode/index.md) disables both push and pull updates.

### Force an update

While mirrors are scheduled to update automatically, you can force an immediate update unless:

- The mirror is already being updated.
- The [interval, in seconds](../../../../administration/instance_limits.md#pull-mirroring-interval)
  for pull mirroring limits has not elapsed after its last update.

Prerequisite:

- You must have at least the Maintainer role for the project.

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > Repository**.
1. Expand **Mirroring repositories**.
1. Scroll to **Mirrored repositories** and identify the mirror to update.
1. Select **Update now** (**{retry}**):
   ![Repository mirroring force update user interface](img/repository_mirroring_force_update.png)

## Authentication methods for mirrors

When you create a mirror, you must configure the authentication method for it.
GitLab supports these authentication methods:

- [SSH authentication](#ssh-authentication).
- Password.

When using password authentication, ensure you specify the username.
For a [project access token](../../settings/project_access_tokens.md) or
[group access token](../../../group/settings/group_access_tokens.md),
use the username (not token name) and the token as the password.

### SSH authentication

SSH authentication is mutual:

- You must prove to the server that you're allowed to access the repository.
- The server must also *prove to you* that it's who it claims to be.

For SSH authentication, you provide your credentials as a password or _public key_.
The server that the other repository resides on provides its credentials as a _host key_.
You must [verify the fingerprint](#verify-a-host-key) of this host key manually.

If you're mirroring over SSH (using an `ssh://` URL), you can authenticate using:

- Password-based authentication, just as over HTTPS.
- Public key authentication. This method is often more secure than password authentication,
  especially when the other repository supports [deploy keys](../../deploy_keys/index.md).

### Get your SSH public key

When you mirror a repository and select the **SSH public key** as your
authentication method, GitLab generates a public key for you. The non-GitLab server
needs this key to establish trust with your GitLab repository. To copy your SSH public key:

1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
1. Select **Settings > Repository**.
1. Expand **Mirroring repositories**.
1. Scroll to **Mirrored repositories**.
1. Identify the correct repository, and select **Copy SSH public key** (**{copy-to-clipboard}**).
1. Add the public SSH key to the other repository's configuration:
   - If the other repository is hosted on GitLab, add the public SSH key
     as a [deploy key](../../../project/deploy_keys/index.md).
   - If the other repository is hosted elsewhere, add the key to
     your user's `authorized_keys` file. Paste the entire public SSH key into the
     file on its own line and save it.

If you must change the key at any time, you can remove and re-add the mirror
to generate a new key. Update the other repository with the new
key to keep the mirror running.

NOTE:
The generated keys are stored in the GitLab database, not in the file system. Therefore,
SSH public key authentication for mirrors cannot be used in a pre-receive hook.

### Verify a host key

When using a host key, always verify the fingerprints match what you expect.
GitLab.com and other code hosting sites publish their fingerprints
for you to check:

- [AWS CodeCommit](https://docs.aws.amazon.com/codecommit/latest/userguide/regions.html#regions-fingerprints)
- [Bitbucket](https://support.atlassian.com/bitbucket-cloud/docs/configure-ssh-and-two-step-verification/)
- [Codeberg](https://docs.codeberg.org/security/ssh-fingerprint/)
- [GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)
- [GitLab.com](../../../gitlab_com/index.md#ssh-host-keys-fingerprints)
- [Launchpad](https://help.launchpad.net/SSHFingerprints)
- [Savannah](https://savannah.gnu.org/maintenance/SshAccess/)
- [SourceForge](https://sourceforge.net/p/forge/documentation/SSH%20Key%20Fingerprints/)

Other providers vary. You can securely gather key fingerprints with the following
command if you:

- Run self-managed GitLab.
- Have access to the server for the other repository.

```shell
$ cat /etc/ssh/ssh_host*pub | ssh-keygen -E md5 -l -f -
256 MD5:f4:28:9f:23:99:15:21:1b:bf:ed:1f:8e:a0:76:b2:9d root@example.com (ECDSA)
256 MD5:e6:eb:45:8a:3c:59:35:5f:e9:5b:80:12:be:7e:22:73 root@example.com (ED25519)
2048 MD5:3f:72:be:3d:62:03:5c:62:83:e8:6e:14:34:3a:85:1d root@example.com (RSA)
```

Older versions of SSH may require you to remove `-E md5` from the command.

## Related topics

- [Troubleshooting](troubleshooting.md) for repository mirroring.
- Configure a [Pull Mirroring Interval](../../../../administration/instance_limits.md#pull-mirroring-interval)
- [Disable mirrors for a project](../../../../administration/settings/visibility_and_access_controls.md#enable-project-mirroring)
- [Secrets file and mirroring](../../../../administration/backup_restore/backup_gitlab.md#when-the-secrets-file-is-lost)

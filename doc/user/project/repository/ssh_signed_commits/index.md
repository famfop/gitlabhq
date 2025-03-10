---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sign commits with SSH keys **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/343879) in GitLab 15.7 [with a flag](../../../../administration/feature_flags.md) named `ssh_commit_signatures`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/384202) in GitLab 15.8. Feature flag `ssh_commit_signatures` removed.

Use SSH keys to sign Git commits in the same manner as
[GPG signed commits](../gpg_signed_commits/index.md). When you sign commits
with SSH keys, GitLab uses the SSH public keys associated with your
GitLab account to cryptographically verify the commit signature.
If successful, GitLab displays a **Verified** label on the commit.

You may use the same SSH keys for `git+ssh` authentication to GitLab
and signing commit signatures as long as their usage type is **Authentication & Signing**.
It can be verified on the page for [adding an SSH key to your GitLab account](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account).

For more information about managing the SSH keys associated with your GitLab account, see
[Use SSH keys to communicate with GitLab](../../../ssh.md).

## Configure Git to sign commits with your SSH key

After you [create an SSH key](../../../ssh.md#generate-an-ssh-key-pair) and
[add it to your GitLab account](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account)
or [generate it using a password manager](../../../ssh.md#generate-an-ssh-key-pair-with-a-password-manager),
configure Git to begin using the key.

Prerequisites:

- Git 2.34.0 or newer.
- OpenSSH 8.0 or newer.

  NOTE:
  OpenSSH 8.7 has broken signing functionality. If you are on OpenSSH 8.7, upgrade to OpenSSH 8.8.

- A SSH key with the usage type of either **Authentication & Signing** or **Signing**.
  The SSH key must be one of these types:
  - [ED25519](../../../ssh.md#ed25519-ssh-keys) (recommended)
  - [RSA](../../../ssh.md#rsa-ssh-keys)

To configure Git to use your key:

1. Configure Git to use SSH for commit signing:

   ```shell
   git config --global gpg.format ssh
   ```

1. Specify which SSH key should be used as the signing key, changing the filename
   (here, `~/.ssh/examplekey`) to the location of your key. The filename may
   differ, depending on how you generated your key:

   ```shell
   git config --global user.signingkey ~/.ssh/examplekey
   ```

## Sign commits with your SSH key

Prerequisites:

- You've [created an SSH key](../../../ssh.md#generate-an-ssh-key-pair).
- You've [added the key](../../../ssh.md#add-an-ssh-key-to-your-gitlab-account) to your GitLab account.
- You've [configured Git to sign commits](#configure-git-to-sign-commits-with-your-ssh-key) with your SSH key.

To sign a commit:

1. Use the `-S` flag when signing your commits:

   ```shell
   git commit -S -m "My commit msg"
   ```

1. Optional. If you don't want to type the `-S` flag every time you commit, tell
   Git to sign your commits automatically:

   ```shell
   git config --global commit.gpgsign true
   ```

1. If your SSH key is protected, Git prompts you to enter your passphrase.
1. Push to GitLab.
1. Check that your commits [are verified](#verify-commits).
   Signature verification uses the `allowed_signers` file to associate emails and SSH keys.
   For help configuring this file, read [Verify commits locally](#verify-commits-locally).

## Verify commits

You can review commits for a merge request, or for an entire project, to confirm
they are signed:

1. To review commits for a project:
   1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
   1. Select **Code > Commits**.
1. To review commits for a merge request:
   1. On the left sidebar, at the top, select **Search GitLab** (**{search}**) to find your project.
   1. On the left sidebar, select **Merge requests**, then select your merge request.
   1. Select **Commits**.
1. Identify the commit you want to review. Signed commits show either a **Verified**
   or **Unverified** badge, depending on the verification status of the signature.
   Unsigned commits do not display a badge.
1. To display the signature details for a commit, select **Verified**. GitLab shows
   the SSH key's fingerprint.

## Verify commits locally

To verify commits locally, create an
[allowed signers file](https://man7.org/linux/man-pages/man1/ssh-keygen.1.html#ALLOWED_SIGNERS)
for Git to associate SSH public keys with users:

1. Create an allowed signers file:

   ```shell
   touch allowed_signers
   ```

1. Configure the `allowed_signers` file in Git:

   ```shell
   git config gpg.ssh.allowedSignersFile "$(pwd)/allowed_signers"
   ```

1. Add your entry to the allowed signers file. Use this command to add your
   email address and public SSH key to the `allowed_signers` file. Replace `<MY_KEY>`
   with the name of your key, and `~/.ssh/allowed_signers`
   with the location of your project's `allowed_signers` file:

   ```shell
   # Modify this line to meet your needs.
   # Declaring the `git` namespace helps prevent cross-protocol attacks.
   echo "$(git config --get user.email) namespaces=\"git\" $(cat ~/.ssh/<MY_KEY>.pub)" >> ~/.ssh/allowed_signers
   ```

   The resulting entry in the `allowed_signers` file contains your email address, key type,
   and key contents, like this:

   ```plaintext
   example@gitlab.com namespaces="git" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAmaTS47vRmsKyLyK1jlIFJn/i8wdGQ3J49LYyIYJ2hv
   ```

1. Repeat the previous step for each user who you want to verify signatures for.
   Consider checking this file in to your Git repository if you want to locally
   verify signatures for many different contributors.

1. Use `git log --show-signature` to view the signature status for the commits:

   ```shell
   $ git log --show-signature

   commit e2406b6cd8ebe146835ceab67ff4a5a116e09154 (HEAD -> main, origin/main, origin/HEAD)
   Good "git" signature for johndoe@example.com with ED25519 key SHA256:Ar44iySGgxic+U6Dph4Z9Rp+KDaix5SFGFawovZLAcc
   Author: John Doe <johndoe@example.com>
   Date:   Tue Nov 29 06:54:15 2022 -0600

       SSH signed commit
   ```

## Revoke an SSH key for signing commits

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108344) in GitLab 15.9.

If an SSH key becomes compromised, revoke it. Revoking a key changes both future and past commits:

- Past commits signed by this key are marked as unverified.
- Future commits signed by this key are marked as unverified.

To revoke an SSH key:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select (**{key}**) **SSH Keys**.
1. Select **Revoke** next to the SSH key you want to delete.

## Related topics

- [Sign commits and tags with X.509 certificates](../x509_signed_commits/index.md)
- [Sign commits with GPG](../gpg_signed_commits/index.md)
- [Commits API](../../../../api/commits.md)

---
stage: Govern
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Scan execution policies **(ULTIMATE)**

> - Group-level security policies [introduced](https://gitlab.com/groups/gitlab-org/-/epics/4425) in GitLab 15.2.
> - Group-level security policies [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/356258) in GitLab 15.4.
> - Operational container scanning [introduced](https://gitlab.com/groups/gitlab-org/-/epics/3410) in GitLab 15.5
> - Support for custom CI variables in the Scan Execution Policies editor [introduced](https://gitlab.com/groups/gitlab-org/-/epics/9566) in GitLab 16.2.
> - Enforcement of scan execution policies on projects with an existing GitLab CI/CD configuration [introduced](https://gitlab.com/groups/gitlab-org/-/epics/6880) in GitLab 16.2 [with a flag](../../../administration/feature_flags.md) named `scan_execution_policy_pipelines`. Enabled by default.

FLAG:
On self-managed GitLab, this feature is enabled by default. To disable it, ask an
administrator to [disable the feature flag](../../../administration/feature_flags.md) named
`scan_execution_policy_pipelines`. On GitLab.com, this feature is enabled.

Group, subgroup, or project owners can use scan execution policies to require that security scans
run on a specified schedule or with the project pipeline. The security scan runs with multiple
project pipelines if you define the policy at a group or subgroup level. GitLab injects the required
scans into the CI/CD pipeline as new jobs.

Scan execution policies are enforced for all applicable projects, even those without a GitLab
CI/CD configuration file or where AutoDevOps is disabled. Security policies create the file
implicitly so that the policies can be enforced. This ensures policies enabling execution of
secret detection, static analysis, or other scanners that do not require a build in the
project, are still able to execute and be enforced.

In the event of a job name collision, GitLab appends a hyphen and a number to the job name. GitLab
increments the number until the name no longer conflicts with existing job names. If you create a
policy at the group level, it applies to every child project or subgroup. You cannot edit a
group-level policy from a child project or subgroup.

This feature has some overlap with [compliance framework pipelines](../../group/compliance_frameworks.md#compliance-pipelines),
as we have not [unified the user experience for these two features](https://gitlab.com/groups/gitlab-org/-/epics/7312).
For details on the similarities and differences between these features, see
[Enforce scan execution](../index.md#enforce-scan-execution).

NOTE:
Policy jobs for scans other than DAST scans are created in the `test` stage of the pipeline. If you modify the default pipeline
[`stages`](../../../ci/yaml/index.md#stages),
to remove the `test` stage, jobs will run in the `scan-policies` stage instead. This stage is injected into the CI pipeline at evaluation time if it doesn't exist. If the `build` stage exists, it is injected just after the `build` stage. If the `build` stage does not exist, it is injected at the beginning of the pipeline. DAST scans always run in the `dast` stage. If this stage does not exist, then a `dast` stage is injected at the end of the pipeline.

## Scan execution policy editor

NOTE:
Only group, subgroup, or project Owners have the [permissions](../../permissions.md#project-members-permissions)
to select Security Policy Project.

Once your policy is complete, save it by selecting **Configure with a merge request**
at the bottom of the editor. You are redirected to the merge request on the project's
configured security policy project. If one does not link to your project, a security
policy project is automatically created. Existing policies can also be
removed from the editor interface by selecting **Delete policy**
at the bottom of the editor.

Most policy changes take effect as soon as the merge request is merged. Any changes that
do not go through a merge request and are committed directly to the default branch may require up to 10 minutes
before the policy changes take effect.

![Scan Execution Policy Editor Rule Mode](img/scan_execution_policy_rule_mode_v15_11.png)

NOTE:
Selection of site and scanner profiles using the rule mode editor for DAST execution policies differs based on
whether the policy is being created at the project or group level. For project-level policies the rule mode editor
presents a list of profiles to choose from that are already defined in the project. For group-level policies
you are required to type in the names of the profiles to use, and to prevent pipeline errors, profiles with
matching names must exist in all of the group's projects.

## Scan execution policies schema

The YAML file with scan execution policies consists of an array of objects matching scan execution
policy schema nested under the `scan_execution_policy` key. You can configure a maximum of 5
policies under the `scan_execution_policy` key. Any other policies configured after
the first 5 are not applied.

When you save a new policy, GitLab validates its contents against [this JSON schema](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/validators/json_schemas/security_orchestration_policy.json).
If you're not familiar with how to read [JSON schemas](https://json-schema.org/),
the following sections and tables provide an alternative.

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `scan_execution_policy` | `array` of scan execution policy | true |  | List of scan execution policies (maximum 5) |

## Scan execution policy schema

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `name` | `string` | true |  | Name of the policy. Maximum of 255 characters.|
| `description` (optional) | `string` | true |  | Description of the policy. |
| `enabled` | `boolean` | true | `true`, `false` | Flag to enable (`true`) or disable (`false`) the policy. |
| `rules` | `array` of rules | true |  | List of rules that the policy applies. |
| `actions` | `array` of actions | true |  | List of actions that the policy enforces. |

## `pipeline` rule type

> - The `branch_type` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404774) in GitLab 16.1 [with a flag](../../../administration/feature_flags.md) named `security_policies_branch_type`. Disabled by default.
> - The `branch_type` field was [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/413062) in GitLab 16.2.

This rule enforces the defined actions whenever the pipeline runs for a selected branch.

| Field | Type | Required | Possible values | Description |
|-------|------|----------|-----------------|-------------|
| `type` | `string` | true | `pipeline` | The rule's type. |
| `branches` <sup>1</sup> | `array` of `string` | true if `branch_type` field does not exist | `*` or the branch's name | The branch the given policy applies to (supports wildcard). |
| `branch_type` <sup>1</sup> | `string` | true if `branches` field does not exist |  `default`, `protected` or `all` | The types of branches the given policy applies to. |

1. You must specify only one of `branches` or `branch_type`.

## `schedule` rule type

> - The `branch_type` field was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/404774) in GitLab 16.1 [with a flag](../../../administration/feature_flags.md) named `security_policies_branch_type`. Disabled by default.
> - The `branch_type` field was [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/413062) in GitLab 16.2.

This rule enforces the defined actions and schedules a scan on the provided date/time.

| Field      | Type | Required | Possible values | Description |
|------------|------|----------|-----------------|-------------|
| `type`     | `string` | true | `schedule` | The rule's type. |
| `branches` <sup>1</sup> | `array` of `string` | true if either `branch_type` or `agents` fields does not exist | `*` or the branch's name | The branch the given policy applies to (supports wildcard). |
| `branch_type` <sup>1</sup> | `string` | true if either `branches` or `agents` fields does not exist | `default`, `protected` or `all` | The types of branches the given policy applies to. |
| `cadence`  | `string` | true | CRON expression (for example, `0 0 * * *`) | A whitespace-separated string containing five fields that represents the scheduled time. Minimum of 15 minute intervals when used together with the `branches` field. |
| `timezone` | `string` | false | Time zone identifier (for example, `America/New_York`) | Time zone to apply to the cadence. Value must be an IANA Time Zone Database identifier. |
| `agents` <sup>1</sup>   | `object` | true if either `branch_type` or `branches` fields do not exists  |  | The name of the [GitLab agents](../../clusters/agent/index.md) where [Operational Container Scanning](../../clusters/agent/vulnerabilities.md) runs. The object key is the name of the Kubernetes agent configured for your project in GitLab. |

1. You must specify only one of `branches`, `branch_type`, or `agents`.

GitLab supports the following types of CRON syntax for the `cadence` field:

- A daily cadence of once per hour at a specified hour, for example: `0 18 * * *`
- A weekly cadence of once per week on a specified day and at a specified hour, for example: `0 13 * * 0`

NOTE:
Other elements of the [CRON syntax](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm) may work in the cadence field if supported by the [cron](https://github.com/robfig/cron) we are using in our implementation, however, GitLab does not officially test or support them.

When using the `schedule` rule type in conjunction with the `agents` field, note the following:

- The GitLab Agent for Kubernetes checks every 30 seconds to see if there is an applicable policy. When a policy is found, the scans are executed according to the `cadence` defined.
- The CRON expression is evaluated using the system-time of the Kubernetes-agent pod.

When using the `schedule` rule type in conjunction with the `branches` field, note the following:

- The cron worker runs on 15 minute intervals and starts any pipelines that were scheduled to run during the previous 15 minutes.
- Based on your rule, you might expect scheduled pipelines to run with an offset of up to 15 minutes.
- The CRON expression is evaluated in standard [UTC](https://www.timeanddate.com/worldclock/timezone/utc) time from GitLab.com. If you have a self-managed GitLab instance and have [changed the server time zone](../../../administration/timezone.md), the CRON expression is evaluated with the new time zone.

![CRON worker diagram](img/scheduled_scan_execution_policies_diagram.png)

### `agent` schema

Use this schema to define `agents` objects in the [`schedule` rule type](#schedule-rule-type).

| Field        | Type                | Required | Possible values          | Description |
|--------------|---------------------|----------|--------------------------|-------------|
| `namespaces` | `array` of `string` | true | The namespace that is scanned. If empty, all namespaces are scanned. |

#### Policy example

```yaml
- name: Enforce Container Scanning in cluster connected through my-gitlab-agent for default and kube-system namespaces
  enabled: true
  rules:
  - type: schedule
    cadence: '0 10 * * *'
    agents:
      <agent-name>:
        namespaces:
        - 'default'
        - 'kube-system'
  actions:
  - scan: container_scanning
```

The keys for a schedule rule are:

- `cadence` (required): a [CRON expression](https://docs.oracle.com/cd/E12058_01/doc/doc.1014/e12030/cron_expressions.htm) for when the scans are run
- `agents:<agent-name>` (required): The name of the agent to use for scanning
- `agents:<agent-name>:namespaces` (optional): The Kubernetes namespaces to scan. If omitted, all namespaces are scanned.

## `scan` action type

This action executes the selected `scan` with additional parameters when conditions for at least one
rule in the defined policy are met.

| Field | Type | Possible values | Description |
|-------|------|-----------------|-------------|
| `scan` | `string` | `sast`, `sast_iac`, `dast`, `secret_detection`, `container_scanning`, `dependency_scanning` | The action's type. |
| `site_profile` | `string` | Name of the selected [DAST site profile](../dast/proxy-based.md#site-profile). | The DAST site profile to execute the DAST scan. This field should only be set if `scan` type is `dast`. |
| `scanner_profile` | `string` or `null` | Name of the selected [DAST scanner profile](../dast/proxy-based.md#scanner-profile). | The DAST scanner profile to execute the DAST scan. This field should only be set if `scan` type is `dast`.|
| `variables` | `object` | | A set of CI variables, supplied as an array of `key: value` pairs, to apply and enforce for the selected scan. The `key` is the variable name, with its `value` provided as a string. This parameter supports any variable that the GitLab CI job supports for the specified scan. |
| `tags` | `array` of `string` | | A list of runner tags for the policy. The policy jobs are run by runner with the specified tags. |

Note the following:

- You must create the [site profile](../dast/proxy-based.md#site-profile) and [scanner profile](../dast/proxy-based.md#scanner-profile)
  with selected names for each project that is assigned to the selected Security Policy Project.
  Otherwise, the policy is not applied and a job with an error message is created instead.
- Once you associate the site profile and scanner profile by name in the policy, it is not possible
  to modify or delete them. If you want to modify them, you must first disable the policy by setting
  the `active` flag to `false`.
- When configuring policies with a scheduled DAST scan, the author of the commit in the security
  policy project's repository must have access to the scanner and site profiles. Otherwise, the scan
  is not scheduled successfully.
- For a secret detection scan, only rules with the default ruleset are supported. [Custom rulesets](../secret_detection/index.md#custom-rulesets)
  are not supported.
- A secret detection scan runs in `normal` mode when executed as part of a pipeline, and in
  [`historic`](../secret_detection/index.md#full-history-secret-detection)
  mode when executed as part of a scheduled scan.
- A container scanning scan that is configured for the `pipeline` rule type ignores the agent defined in the `agents` object. The `agents` object is only considered for `schedule` rule types.
  An agent with a name provided in the `agents` object must be created and configured for the project.

## Example security policies project

You can use this example in a `.gitlab/security-policies/policy.yml` file stored in a
[security policy project](index.md#security-policy-project):

```yaml
---
scan_execution_policy:
- name: Enforce DAST in every release pipeline
  description: This policy enforces pipeline configuration to have a job with DAST scan for release branches
  enabled: true
  rules:
  - type: pipeline
    branches:
    - release/*
  actions:
  - scan: dast
    scanner_profile: Scanner Profile A
    site_profile: Site Profile B
- name: Enforce DAST and secret detection scans every 10 minutes
  description: This policy enforces DAST and secret detection scans to run every 10 minutes
  enabled: true
  rules:
  - type: schedule
    branches:
    - main
    cadence: "*/10 * * * *"
  actions:
  - scan: dast
    scanner_profile: Scanner Profile C
    site_profile: Site Profile D
  - scan: secret_detection
- name: Enforce Secret Detection and Container Scanning in every default branch pipeline
  description: This policy enforces pipeline configuration to have a job with Secret Detection and Container Scanning scans for the default branch
  enabled: true
  rules:
  - type: pipeline
    branches:
    - main
  actions:
  - scan: secret_detection
  - scan: sast
    variables:
      SAST_EXCLUDED_ANALYZERS: brakeman
  - scan: container_scanning
```

In this example:

- For every pipeline executed on branches that match the `release/*` wildcard (for example, branch
  `release/v1.2.1`), DAST scans run with `Scanner Profile A` and `Site Profile B`.
- DAST and secret detection scans run every 10 minutes. The DAST scan runs with `Scanner Profile C`
  and `Site Profile D`.
- Secret detection, container scanning, and SAST scans run for every pipeline executed on the `main`
  branch. The SAST scan runs with the `SAST_EXCLUDED_ANALYZER` variable set to `"brakeman"`.

## Example for scan execution policy editor

You can use this example in the YAML mode of the [scan execution policy editor](#scan-execution-policy-editor).
It corresponds to a single object from the previous example.

```yaml
name: Enforce Secret Detection and Container Scanning in every default branch pipeline
description: This policy enforces pipeline configuration to have a job with Secret Detection and Container Scanning scans for the default branch
enabled: true
rules:
  - type: pipeline
    branches:
      - main
actions:
  - scan: secret_detection
  - scan: container_scanning
```

## Avoiding duplicate scans

Scan execution policies can cause the same type of scanner to run more than once if developers include scan jobs in the project's
`.gitlab-ci.yml` file. This behavior is intentional as scanners can run more than once with different variables and settings. For example, a
developer may want to try running a SAST scan with different variables than the one enforced by the security and compliance team. In
this case, two SAST jobs run in the pipeline, one with the developer's variables and one with the security and compliance team's variables.

If you want to avoid running duplicate scans, you can either remove the scans from the project's `.gitlab-ci.yml` file or disable your
local jobs by setting `SAST_DISABLED: "true"`. Disabling jobs this way does not prevent the security jobs defined by scan execution
policies from running.

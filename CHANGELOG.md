# changelog

[![Keep a Changelog](https://img.shields.io/badge/Keep%20a%20Changelog-1.0.0-informational)](https://keepachangelog.com/en/1.0.0/)
[![Semantic Versioning](https://img.shields.io/badge/Semantic%20Versioning-2.0.0-informational)](https://semver.org/spec/v2.0.0.html)
![clq validated](https://img.shields.io/badge/clq-validated-success)

Keep the newest entry at top, format date according to ISO 8601: `YYYY-MM-DD`.

Categories, defined in [changemap.json](.github/clq/changemap.json):

- *major* release trigger:
  - `Changed` for changes in existing functionality.
  - `Removed` for now removed features.
- *minor* release trigger:
  - `Added` for new features.
  - `Deprecated` for soon-to-be removed features.
- *bugfix* release trigger:
  - `Fixed` for any bugfixes.
  - `Security` in case of vulnerabilities.

## [4.0.0] - 2026-03-09

### Removed

- Home-grown gating mechanism removed, use the GitHub Enterprise model instead [Deployments and environments](https://docs.github.com/en/enterprise-cloud@latest/actions/reference/workflows-and-actions/deployments-and-environments)
- Inline the `Arda-cards/helm-deploy-action@v5` to reduce the maintenance burden.
- Support for override of the `aws_role`, `aws_region` and `cluster_name` parameters. This action relies entirely
  on the configuration provided by the `locator_url`.
- The action no longer supports optional `namespace`. The parameter must be provided.

### Added

- When executing a dry_run, the action creates the cloudFormation templates but does not execute them.

### Fixed

- Bump `aws-actions/configure-aws-credentials` from 5 to 6
- Bump `aws-actions/aws-cloudformation-github-deploy` from 1 to 2
- Always provides the infrastructure name as a helm value.
- Remove reference to old `no-fail-on-empty-changeset` from the CloudFormation deployment template. It has been
  replaced by a new parameter `fail-on-empty-changeset` which defaults to `false`.
- `pull_request_upkeep.yml` uses GitHub variable to identify the project.
- Configure `super-linter` with the list of languages to be linted.

## [3.1.2] - 2025-11-25

### Fixed

- Deployment must apply all cloudformation templates before reading cloudformation exports for use by helm.
- `make lint` calls `clq` and `super-linter` to get better error reporting.
- Bump `actions/checkout` from 5 to 6

## [3.1.1] - 2025-10-08

### Fixed

- `dry_run` and `timeout` are now passed to `helm-deploy-action`.
- Do not install the CloudFormation pre- and post- deployment when `dry_run` is set.
- Bump `aws-actions/configure-aws-credentials` from 4 to 5
- Automatically annotate new pull-requests with the *assignee*, the *project*, the *iteration* and the *status*.
  It is an asynchronous event-based process that might take a minute or two to complete.
- Makefile provides for local execution of super-linter.
- Super-linter configured to skip biome.

## [3.1.0] - 2025-08-25

### Added

- Support for parametrized `read-cloudFormation-values.cmd`

### Fixed

- `global.clusterIam` has been removed in 3.0.0

## [3.0.0] - 2025-08-20

### Removed

- CloudFormation parameter `Environment`.

### Added

- Include `Arda-cards/deployment-gate-action` if the purpose defines `deployment_gate` with a value other than `none`
- CloudFormation parameter `Infrastructure`.
- Helm value `global.infrastructure`

### Fixed

- Bump `actions/checkout` from 4 to 5.
- Bump `Arda-cards/helm-deploy-action` from 4 to 5

## [2.0.0] - 2025-07-23

### Changed

- Renamed *phase* to *purpose*.
- Renamed *module* to *component*. This change also applies to the pre and post CloudFormation file.
- Bump `helm-deploy-action` from v3 to v4

### Removed

- Removed deprecated parameter `image_pull_secret`.
- Removed parameter `helm_value`.

### Added

- Pass the aws account name as the `environment` parameter to the Helm Deploy action
- New parameter `locator_url` to identify a locator file with the optional authentication parameters `locator_url_bearer`, `locator_url_token`.
- New parameter `helm_value_command`, a list of `action`, `key`, `value` that writes a file that set the Helm `key` to `action` for `value`.
- `Purpose` added to the standard CloudFormation parameters.

### Fixed

- Rely on branch protection rule, not branch name.
- Skip all work on draft pull requests.
- Bump `super-linter` from 7 to 8

## [1.1.0] - 2025-05-15

### Added

- `cloudformation_parameter` and `helm_value` to provide deployment time values to helm/CloudFormation.

### Deprecated

- `image_pull_secret` should be passed through the `cloudformation_parameter`.

## [1.0.0] - 2025-05-14

### Added

- Extracted

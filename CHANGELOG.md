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

## [2.0.0] - 2025-07-10

### Changed

- Renamed *phase* to *purpose*.
- Renamed *module* to *component*. This change also applies to the pre and post CloudFormation file.

### Removed

- Removed deprecated parameter `image_pull_secret`.
- Removed parameter `helm_value`.

### Added

- Pass the aws account name as the `environment` parameter to the Helm Deploy action
- New parameter `locator_url` to identify a locator file with the optional authentication parameters `locator_url_bearer`, `locator_url_token`.
- New parameter `helm_value_command`, a list of `action`, `key`, `value` that writes a file that set the Helm `key` to `action` for `value`.

### Fixed

- Rely on branch protection rule, not branch name.
- Skip all work on draft pull requests.

## [1.1.0] - 2025-05-15

### Added

- `cloudformation_parameter` and `helm_value` to provide deployment time values to helm/CloudFormation.

### Deprecated

- `image_pull_secret` should be passed through the `cloudformation_parameter`.

## [1.0.0] - 2025-05-14

### Added

- Extracted

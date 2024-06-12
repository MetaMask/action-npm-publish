# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [5.2.0]
### Uncategorized
- Handle publishing of packages using Yarn Classic / NPM  ([#87](https://github.com/MetaMask/action-npm-publish/pull/87))
- Update CODEOWNERS ([#89](https://github.com/MetaMask/action-npm-publish/pull/89))
- 5.1.2 ([#86](https://github.com/MetaMask/action-npm-publish/pull/86))
- Fix changelog following backport ([#84](https://github.com/MetaMask/action-npm-publish/pull/84))
- 5.1.1 ([#82](https://github.com/MetaMask/action-npm-publish/pull/82))
- 5.1.0 ([#80](https://github.com/MetaMask/action-npm-publish/pull/80))
- Update version and changelog with v5.0.1 release ([#79](https://github.com/MetaMask/action-npm-publish/pull/79))
- Update changelog with v4.0.x releases ([#76](https://github.com/MetaMask/action-npm-publish/pull/76))
- 5.0.0 ([#67](https://github.com/MetaMask/action-npm-publish/pull/67))
- Run linting and testing GitHub workflows on PRs ([#62](https://github.com/MetaMask/action-npm-publish/pull/62))
- Enabling MetaMask security code scanner ([#60](https://github.com/MetaMask/action-npm-publish/pull/60))
- Add Shared Libraries team in codeowners file ([#59](https://github.com/MetaMask/action-npm-publish/pull/59))
- Update README.md ([#56](https://github.com/MetaMask/action-npm-publish/pull/56))
- Update README.md ([#55](https://github.com/MetaMask/action-npm-publish/pull/55))
- Update README.md ([#54](https://github.com/MetaMask/action-npm-publish/pull/54))
- Bump word-wrap from 1.2.3 to 1.2.4 ([#53](https://github.com/MetaMask/action-npm-publish/pull/53))
- 4.0.1 ([#52](https://github.com/MetaMask/action-npm-publish/pull/52))
- Bump semver from 6.3.0 to 6.3.1 ([#50](https://github.com/MetaMask/action-npm-publish/pull/50))
- Update README.md ([#48](https://github.com/MetaMask/action-npm-publish/pull/48))
- 4.0.0 ([#47](https://github.com/MetaMask/action-npm-publish/pull/47))
- 3.2.0 ([#38](https://github.com/MetaMask/action-npm-publish/pull/38))
- Remove `target-name-text` step ([#39](https://github.com/MetaMask/action-npm-publish/pull/39))

## [5.1.2]
### Fixed
- Fix report script when publishing package with dash in organisation name ([#85](https://github.com/MetaMask/action-npm-publish/pull/85))

## [5.1.1]
### Fixed
- Add missing configuration for non-default Slack channel messages ([#81](https://github.com/MetaMask/action-npm-publish/pull/81))

## [5.1.0]
### Added
- Improve Dry Run Output ([#64](https://github.com/MetaMask/action-npm-publish/pull/64))
  - The dry run step now includes a detailed report about the changes in each published package. It is stored as an artifact, and a link is shared in the logs of the "Dry Run Publish" step.

### Fixed
- Fix Slack announcement for public default channel ([#73](https://github.com/MetaMask/action-npm-publish/pull/73), [#77](https://github.com/MetaMask/action-npm-publish/pull/77))
  - We have found that the Slack announcement does not work correctly for public channels when the `channel` parameter is given. The action has been updated to omit the default if no channel is specified, so that announcements to the default channel work correctly even if it is public.
  - This was originally published in v4.0.4, but this is the first v5.x release that includes this change.

## [5.0.1]
### Fixed
- Prevent workflow from failing if Slack announcement step fails ([#69](https://github.com/MetaMask/action-npm-publish/pull/69))
  - Within the context of a project, the Slack announcement message that is posted after running this workflow in dry-run mode is not crucial, and thus this change ensures that the package will still be published for real if this step fails.

## [5.0.0]
### Changed
- **BREAKING:** Disallow publishing packages with version 0.0.0 ([#63](https://github.com/MetaMask/action-npm-publish/pull/63))

### Fixed
- Fix Yarn 4 compatibility ([#65](https://github.com/MetaMask/action-npm-publish/pull/65))

## [4.0.5]
### Fixed
- Add missing configuration for non-default Slack channel messages ([#81](https://github.com/MetaMask/action-npm-publish/pull/81))

## [4.0.4]
### Fixed
- Fix action validation error ([#77](https://github.com/MetaMask/action-npm-publish/pull/77))

## [4.0.3]
### Fixed
- Fix Slack announcement for public default channel ([#73](https://github.com/MetaMask/action-npm-publish/pull/73))
  - We have found that the Slack announcement does not work correctly for public channels when the `channel` parameter is given. The action has been updated to omit the default if no channel is specified, so that announcements to the default channel work correctly even if it is public.

## [4.0.2]
### Fixed
- Prevent workflow from failing if Slack announcement step fails ([#69](https://github.com/MetaMask/action-npm-publish/pull/69))
  - Within the context of a project, the Slack announcement message that is posted after running this workflow in dry-run mode is not crucial, and thus this change ensures that the package will still be published for real if this step fails.

## [4.0.1]
### Changed
- Use tag to check latest package version ([#51](https://github.com/MetaMask/action-npm-publish/pull/51))

## [4.0.0]
### Added
- Add new input to support customising the Slack channel ([#40](https://github.com/MetaMask/action-npm-publish/pull/40))

### Removed
- **BREAKING:** Remove `target-name` option ([#44](https://github.com/MetaMask/action-npm-publish/pull/44))
  - `target-name` used to support tagging individuals in Slack announcements. This option has been replaced by a `subteam` option just for teams; tagging individuals is no longer supported

### Fixed
- Fix functionality for subteams ([#44](https://github.com/MetaMask/action-npm-publish/pull/44))
  - The `target-name` option was supposed to work for teams and individuals, but it didn't work for teams. It has been replaced by a `subteam` option which only works for teams.
- Only run final-text if slack-webhook-url is defined ([#41](https://github.com/MetaMask/action-npm-publish/pull/41))

## [3.2.0]
### Added
- Add options for customising Slack announce message ([#37](https://github.com/MetaMask/action-npm-publish/pull/37))
- Use MetaMaskBot avatar for `icon_url` in Slack message ([#36](https://github.com/MetaMask/action-npm-publish/pull/36))

### Changed
- Use Yarn rather than npm for package version comparison ([#34](https://github.com/MetaMask/action-npm-publish/pull/34))
  - This improves compatibility for projects using custom registries

## [3.1.1]
### Fixed
- Rename `YARN_NPM_TAG` to `PUBLISH_NPM_TAG` ([#32](https://github.com/MetaMask/action-npm-publish/pull/32))
  - This fixes a bug in the previous release, due to environment variables starting with `YARN_` being reserved for Yarn settings.

## [3.1.0]
### Added
- Add optional npm-tag parameter to action ([#30](https://github.com/MetaMask/action-npm-publish/pull/30))

## [3.0.0]
### Changed
- **BREAKING:** Restore Slack notification feature ([#9](https://github.com/MetaMask/action-npm-publish/pull/9), [#22](https://github.com/MetaMask/action-npm-publish/pull/22), [#23](https://github.com/MetaMask/action-npm-publish/pull/23), [#24](https://github.com/MetaMask/action-npm-publish/pull/24))
  - The action depends upon `slackapi/slack-github-action@007b2c3c751a190b6f0f040e47ed024deaa72844`. You may need to update repository or organization settings to allow this action to run.

## [2.1.1]
### Fixed
- Revert Slack announce feature ([#22](https://github.com/MetaMask/action-npm-publish/pull/22))
  - The Slack announce feature used the action `slackapi/slack-github-action`. This caused failures in repositories/organizations that use an Action allowlist, unless that action was explicitly allowed. This has been temporarily reverted so that we can properly document this requirement, and make it a breaking change.

## [2.1.0]
### Added
- Add support for Slack notification when release is pending approval ([#9](https://github.com/MetaMask/action-npm-publish/pull/9))

## [2.0.0]
### Changed
- **BREAKING:** Require Yarn v3 ([#10](https://github.com/MetaMask/action-npm-publish/pull/10))
  - If your project is using NPM or Yarn v1, you will need to upgrade it to Yarn v3.
  - If your package has a `prepack` script and is using the `node-modules` linker, you will need to ensure that the file `node_modules/.yarn-state.yml` is present before this action is invoked.
- Use Yarn for publishing rather than npm ([#10](https://github.com/MetaMask/action-npm-publish/pull/10))

## [1.2.0]
### Added
- Add support for monorepos ([#5](https://github.com/MetaMask/action-npm-publish/pull/5))

## [1.1.0]
### Added
- Add ability to execute in dry-run mode by omitting `npm-token` ([#4](https://github.com/MetaMask/action-publish-release/pull/4))

## [1.0.0]
### Changed
- Initial release ([#1](https://github.com/MetaMask/action-npm-publish/pull/1))

[Unreleased]: https://github.com/MetaMask/action-npm-publish/compare/v5.2.0...HEAD
[5.2.0]: https://github.com/MetaMask/action-npm-publish/compare/v5.1.2...v5.2.0
[5.1.2]: https://github.com/MetaMask/action-npm-publish/compare/v5.1.1...v5.1.2
[5.1.1]: https://github.com/MetaMask/action-npm-publish/compare/v5.1.0...v5.1.1
[5.1.0]: https://github.com/MetaMask/action-npm-publish/compare/v5.0.1...v5.1.0
[5.0.1]: https://github.com/MetaMask/action-npm-publish/compare/v5.0.0...v5.0.1
[5.0.0]: https://github.com/MetaMask/action-npm-publish/compare/v4.0.5...v5.0.0
[4.0.5]: https://github.com/MetaMask/action-npm-publish/compare/v4.0.4...v4.0.5
[4.0.4]: https://github.com/MetaMask/action-npm-publish/compare/v4.0.3...v4.0.4
[4.0.3]: https://github.com/MetaMask/action-npm-publish/compare/v4.0.2...v4.0.3
[4.0.2]: https://github.com/MetaMask/action-npm-publish/compare/v4.0.1...v4.0.2
[4.0.1]: https://github.com/MetaMask/action-npm-publish/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/MetaMask/action-npm-publish/compare/v3.2.0...v4.0.0
[3.2.0]: https://github.com/MetaMask/action-npm-publish/compare/v3.1.1...v3.2.0
[3.1.1]: https://github.com/MetaMask/action-npm-publish/compare/v3.1.0...v3.1.1
[3.1.0]: https://github.com/MetaMask/action-npm-publish/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/MetaMask/action-npm-publish/compare/v2.1.1...v3.0.0
[2.1.1]: https://github.com/MetaMask/action-npm-publish/compare/v2.1.0...v2.1.1
[2.1.0]: https://github.com/MetaMask/action-npm-publish/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/MetaMask/action-npm-publish/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/MetaMask/action-npm-publish/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/MetaMask/action-npm-publish/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/MetaMask/action-npm-publish/releases/tag/v1.0.0

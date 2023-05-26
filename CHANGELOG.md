# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.2.1]
### Uncategorized
- add functionality for subteams ([#44](https://github.com/MetaMask/action-npm-publish/pull/44))
- only run final-text if slack-webhook-url is defined ([#41](https://github.com/MetaMask/action-npm-publish/pull/41))
- Add new input to support customising the Slack channel ([#40](https://github.com/MetaMask/action-npm-publish/pull/40))

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

[Unreleased]: https://github.com/MetaMask/action-npm-publish/compare/v3.2.1...HEAD
[3.2.1]: https://github.com/MetaMask/action-npm-publish/compare/v3.2.0...v3.2.1
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

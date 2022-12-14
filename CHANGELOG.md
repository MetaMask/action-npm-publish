# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0]
### Uncategorized
- Add release workflows ([#15](https://github.com/MetaMask/action-npm-publish/pull/15))
- Feature/slack announce ([#9](https://github.com/MetaMask/action-npm-publish/pull/9))
- Bring README up to date ([#12](https://github.com/MetaMask/action-npm-publish/pull/12))

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

[Unreleased]: https://github.com/MetaMask/action-npm-publish/compare/v2.1.0...HEAD
[2.1.0]: https://github.com/MetaMask/action-npm-publish/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/MetaMask/action-npm-publish/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/MetaMask/action-npm-publish/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/MetaMask/action-npm-publish/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/MetaMask/action-npm-publish/releases/tag/v1.0.0

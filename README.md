# MetaMask/action-npm-publish

## Description

This Action publishes and npm module when a release PR is merged.
A "release PR" is a PR whose branch is named with a particular prefix, followed by a SemVer version.
The release title will simply be the SemVer version of the release, and the release body will be the change entries of the release from the repository's [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)-compatible changelog.

Designed for use with [MetaMask/action-publish-release](https://github.com/MetaMask/action-publish-release).

## Usage

To create a GitHub release whenever a PR created by `MetaMask/action-create-release-pr` is merged, add the following workflow to your repository at `.github/workflows/publish-release.yml`:

```yaml
name: Publish Release

on:
  pull_request:
    types: [closed]

jobs:
  publish-release:
    permissions:
      contents: write
    # The second argument to startsWith() must match the release-branch-prefix
    # input to this Action. Here, we use the default, "release/".
    if: |
      github.event.pull_request.merged == true &&
      startsWith(github.event.pull_request.head.ref, 'release/')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          # We check out the release pull request's base branch, which will be
          # used as the base branch for all git operations.
          ref: ${{ github.event.pull_request.base.ref }}
      - name: Get Node.js version
        id: nvm
        run: echo ::set-output name=NODE_VERSION::$(cat .nvmrc)
      - uses: actions/setup-node@v2
        with:
          node-version: ${{ steps.nvm.outputs.NODE_VERSION }}
      - uses: MetaMask/action-npm-publish@v1
        with:
          npm-token: ${{ secrets.NPM_TOKEN }}
```

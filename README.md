# MetaMask/action-npm-publish

## Description

This Action publishes an npm module with a given `npm-token`.

## Usage

To publish an npm module whenever a PR created by `MetaMask/action-create-release-pr` is merged, add the following workflow to your repository at `.github/workflows/publish-npm.yml`:

```yaml
name: Publish to npm

on:
  pull_request:
    types: [closed]

jobs:
  cache-build:
    permissions:
      contents: write
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
      - run: |
          yarn setup
          yarn build
      - uses: actions/cache@v2
        id: restore-build
        with:
          path: ./*
          key: ${{ github.sha }}

  publish-npm:
    name: Publish to npm
    runs-on: ubuntu-latest
    needs: cache-build
    steps:
      - uses: actions/cache@v2
        id: restore-build
        with:
          path: ./*
          key: ${{ github.sha }}
      - name: Publish
        uses: rickycodes/action-npm-publish@c561c6562c3f8c24cd6372b526a5feb138506332
        with:
          npm-token: ${{ secrets.NPM_TOKEN }}
```

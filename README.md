# action-npm-publish

## Description

GitHub action to publish an npm module with a provided `npm-token`. If the `npm-token` is omitted the action will perform a dry run npm publish by default.

## Usage

Pass your token to the action:

```yaml
- name: Publish
  uses: MetaMask/action-npm-publish@v1
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
```

To publish an npm module whenever a release PR is merged, you could do something like this:

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
  publish-npm-dry-run:
    runs-on: ubuntu-latest
    needs: cache-build
    steps:
      - uses: actions/cache@v2
        id: restore-build
        with:
          path: ./*
          key: ${{ github.sha }}
      - name: Publish
        # omitting npm-token will perform a dry run publish
        uses: MetaMask/action-npm-publish@v1
  publish-npm:
    # use a github actions environment
    environment: publish
    runs-on: ubuntu-latest
    needs: publish-npm-dry-run
    steps:
      - uses: actions/cache@v2
        id: restore-build
        with:
          path: ./*
          key: ${{ github.sha }}
      - name: Publish
        uses: MetaMask/action-npm-publish@v1
        with:
          npm-token: ${{ secrets.NPM_TOKEN }}
```

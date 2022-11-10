# action-npm-publish

## Description

GitHub action to publish an npm module with a provided `npm-token`. If the `npm-token` is omitted the action will perform a dry run npm publish by default.

This action assumes that Yarn is installed and that the package is using Yarn v3. It may fail for other Yarn versions or other package managers.

If your package has a `prepack` script and is using the `node-modules` linker, you will need to ensures that the file `node_modules/.yarn-state.yml` is present before this action is invoked. This file is generated automatically when installing dependencies. If you want to publish without dependencies present, you can instantiate an empty state file or restore one from a cache.

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
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version-file: '.nvmrc'
      - run: |
          yarn install
          yarn build
      - uses: actions/cache@v2
        id: restore-build
        with:
          path: |
            ./dist
            ./node_modules/.yarn-state.yml
          key: ${{ github.sha }}
  publish-npm-dry-run:
    runs-on: ubuntu-latest
    needs: cache-build
    steps:
      - uses: actions/cache@v2
        id: restore-build
        with:
          path: |
            ./dist
            ./node_modules/.yarn-state.yml
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
          path: |
            ./dist
            ./node_modules/.yarn-state.yml
          key: ${{ github.sha }}
      - name: Publish
        uses: MetaMask/action-npm-publish@v1
        with:
          npm-token: ${{ secrets.NPM_TOKEN }}
```

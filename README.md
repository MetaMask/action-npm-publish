# action-npm-publish

## Description

GitHub action to publish an npm module with a provided `npm-token`. If the `npm-token` is omitted the action will perform a dry run npm publish by default.

This action assumes that Yarn is installed and that the package is using Yarn v3. It may fail for other Yarn versions or other package managers.

If your package has a `prepack` script and is using the `node-modules` linker, you will need to ensures that the file `node_modules/.yarn-state.yml` is present before this action is invoked. This file is generated automatically when installing dependencies. If you want to publish without dependencies present, you can instantiate an empty state file or restore one from a cache.

## Usage

Pass your token to the action:

```yaml
- name: Publish
  uses: MetaMask/action-npm-publish@v2
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
```

To publish an NPM module whenever a release PR is merged, you could add a workflow file like the following to your project. Note that this requires you add a `publish` environment to your repository and set the `NPM_TOKEN` environment variable within that environment to your NPM token:

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
        uses: MetaMask/action-npm-publish@v2
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
        uses: MetaMask/action-npm-publish@v2
        with:
          npm-token: ${{ secrets.NPM_TOKEN }}
```

If you are making changes to the workflow(s) in your repository and need to test that your package still gets published correctly, you can configure the action to use your own NPM registry instead of the official one. For instance, here is a workflow file that uses [Gemfury](https://gemfury.com/help/npm-registry/):

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
        uses: MetaMask/action-npm-publish@v2
        with:
          # omitting npm-token will perform a dry run publish
          npm-registry: https://npm.fury.io/YOUR-USERNAME-GOES-HERE/
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
        uses: MetaMask/action-npm-publish@v2
        with:
          npm-registry: https://npm.fury.io/YOUR-USERNAME-GOES-HERE/
          npm-token: ${{ secrets.NPM_TOKEN }}
```

## API

### Inputs

- **`npm-registry`** _(optional; defaults to whatever Yarn's `npmPublishRegistry` option defaults to)_. The URL of the NPM registry that Yarn commands will use to access and publish packages.
- **`npm-token`** _(optional)_. The auth token associated with the registry that Yarn commands will use to access and publish packages. If omitted, the action will perform a dry-run publish.

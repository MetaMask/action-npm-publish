# action-npm-publish

This is a GitHub action that handles publishing to NPM for a project that represents a single package (in the case of a polyrepo) or a collection of packages (in the case of a monorepo).

- For a polyrepo project, the action will publish the package using its current version as per `package.json`.

- For a monorepo, the action will publish each workspace package (the set of packages matched via the `workspaces` field in `package.json`, recursively) using its current version as per `package.json`. (Any package which has already been published at its current version will be skipped.)


## Requirements

**This action assumes that Yarn is installed and that the package is using Yarn v3.** It may fail for other Yarn versions or other package managers.

If your project is configured to use the `node-modules` linker and defines a `prepack` script for any releasable packages, you will need to ensure that the file `node_modules/.yarn-state.yml` is present before this action is invoked. This file is generated automatically when installing dependencies. If you want to publish without dependencies present, you can instantiate an empty state file or restore one from a cache.

This action depends upon the action `slackapi/slack-github-action@007b2c3c751a190b6f0f040e47ed024deaa72844`. This action is authored by a Marketplace "verified creator". If your repository or organization restricts which actions can be used and does not allow Marketplace verified creators by default, ensure that this action is listed as an allowed action.

## Usage

### Quick start

If you're in a hurry, take a look at the [`publish-release` workflow](https://github.com/MetaMask/metamask-module-template/blob/main/.github/workflows/publish-release.yml) from the [module template](https://github.com/MetaMask/metamask-module-template), which uses this action to publish appropriate packages whenever a release commit is merged, once in dry-run mode and once in "real" mode. (A release commit is a commit that changes the version of the primary package within the project, whether that is the sole package in the case of a polyrepo package, or the root package in the case of a monorepo.) Note that in order to use this workflow file in your project, you will need to create an `npm-publish` environment via your repository's settings and set the `NPM_TOKEN` secret within this environment to the authentication token for the MetaMask organization on `npmjs.com`.

### Publish mode

Add the following to a job's list of steps. This requires that you set the `NPM_TOKEN` secret in your repository's settings to an appropriate NPM authentication token:

```yaml
- uses: MetaMask/action-npm-publish@v2
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
```

### Dry run mode

If you omit `npm-token`, then packages will be prepared for publishing, but no publishing will actually occur:

```yaml
- uses: MetaMask/action-npm-publish@v2
```

### Slack announce

You can optionally send deployment announcements to Slack by providing a `slack-webhook-url` input:

The absolute minimum configuration for this is:

```yaml
- uses: MetaMask/action-npm-publish@v2
  with:
    slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

We've added the ability to customize the message posted in Slack and those optional inputs are as follows:

- `icon-url`
- `username`
- `target-name`

example:

```yaml
- uses: MetaMask/action-npm-publish@v2
  with:
    slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    icon-url: 'https://ricky.codes/me.jpg'
    username: 'rickybot'
    target-name: 'ricky'
```

You can read more about these option in the [API](#API) section below

![image](https://user-images.githubusercontent.com/675259/203841602-124d537d-7476-4263-a17c-6d05b68c37d0.png)

## API

### Inputs

- **`npm-token`** _(optional)_. The auth token associated with the registry that Yarn commands will use to access and publish packages. If omitted, the action will perform a dry-run publish.

- **`slack-webhook-url`** _(optional)_. The incoming webhook URL associated with your Slack application for announcing releases to a Slack channel. This can be added under the "Incoming Webhooks" section of your Slack app configuration.

#### The following inputs only apply if `slack-webhook-url` is set...

- **`icon-url`** _(optional)_. Url to the avatar used for the bot in Slack. If not set this defaults to the avatar in this repository.
- **`username`** _(optional)_. The name of the bot as it appears on Slack. If not set this defaults to `MetaMask bot`.
- **`target-name`** _(optional)_. Use this if you want to ping an individual or subset of individuals on Slack using `@`.

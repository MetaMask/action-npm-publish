# action-npm-publish

This is a GitHub action that publishes one or more packages in a repo to NPM.

- For a single-package project, the action will publish the package at the version listed in `package.json`.
- For a multi-package package (monorepo), the action will publish each workspace package (the set of packages matched via the `workspaces` field in `package.json`, recursively) at the version listed in its `package.json`. (Any package which has already been published at its current version will be skipped.)

## Usage

### Prequisites

- Ensure your project is using Yarn.
- Create an NPM token for your repo and assign it as a secret. Place this secret under an `npm-publish` environment so that releases can go through an approval step. Reach out to the `@metamask/npm-publishers` group for help on creating the NPM token and setting up this environment.
- If your project is using Yarn Modern, is configured to use the `node-modules` linker, and defines a `prepack` script for any releasable packages, ensure that the file `node_modules/.yarn-state.yml` is present before this action is invoked. This file is generated automatically when installing dependencies. If you want to publish without dependencies present, you can instantiate an empty state file or restore one from a cache.
- The `slack-webhook-url` option for this action makes use of another action, `slackapi/slack-github-action@007b2c3c751a190b6f0f040e47ed024deaa72844`. This action is authored by a Marketplace "verified creator". If your repository or organization restricts which actions can be used and does not allow Marketplace verified creators by default, ensure that this is listed as an allowed action.

### Quick start

If you're in a hurry, take a look at the [`publish-release` workflow](https://github.com/MetaMask/metamask-module-template/blob/main/.github/workflows/publish-release.yml) from the [module template](https://github.com/MetaMask/metamask-module-template). This workflow defines two jobs relevant to NPM publishing:

- `publish-npm`: Runs `npm publish` under the `npm-publish` environment. This environment is set up in the module template (and other repos) so that the workflow will pause and allow a member of `@MetaMask/npm-publishers` to inspect and approve the release.
- `publish-npm-dry-run`: Runs `npm publish` in dry-run mode. This runs before the previous step and prints out a list of the package contents so approvers can inspect the package before it is published.

### Publishing to NPM

Add the following to a job's list of steps:

```yaml
- uses: MetaMask/action-npm-publish@v5
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
```

### Running dry-run mode

If you omit the `npm-token` input, then packages will be prepared for publishing, but no publishing will actually occur:

```yaml
- uses: MetaMask/action-npm-publish@v5
```

### Automatically requesting approvals in Slack

This step assumes that you've created an `npm-publish` environment and placed it behind an approval step.

You can notify `@MetaMask/npm-publishers` that a release is ready to be approved by providing a `slack-webhook-url` input:

```yaml
- uses: MetaMask/action-npm-publish@v5
  with:
    slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

If you want to customize the Slack message, you can use these inputs to do so:

- `icon-url`
- `username`
- `subteam`
- `channel`

For example:

```yaml
- uses: MetaMask/action-npm-publish@v5
  with:
    slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    icon-url: https://ricky.codes/me.jpg
    username: rickybot
    # re subteam, see: https://api.slack.com/reference/surfaces/formatting#mentioning-groups
    subteam: S042S7RE4AE  # @metamask-npm-publishers
    channel: dev-channel
```

This creates a message such as:

![image](https://user-images.githubusercontent.com/675259/203841602-124d537d-7476-4263-a17c-6d05b68c37d0.png)

You can read more about these options in the [API](#api) section below.

## API

### Inputs

- **`npm-token`** _(optional)_. The auth token associated with the registry that Yarn commands will use to access and publish packages. If omitted, the action will perform a dry-run publish.
- **`slack-webhook-url`** _(optional)_. The incoming webhook URL associated with your Slack application for announcing releases to a Slack channel. This can be added under the "Incoming Webhooks" section of your Slack app configuration.
- **`icon-url`** _(optional)_. Only applicable if `slack-webhook-url` is set. URL to the avatar used for the bot in Slack. Defaults to the avatar in this repository.
- **`username`** _(optional)_. Only applicable if `slack-webhook-url` is set. The name of the bot as it appears on Slack. Defaults to `MetaMask bot`.
- **`subteam`** _(optional)_. Only applicable if `slack-webhook-url` is set. Use this if you want to ping a subteam of individuals on Slack using `@`.
- **`channel`** _(optional)_. Only applicable if `slack-webhook-url` is set. Use this if you want to post to a channel other than the default: `metamask-dev`. (Do not include the leading `#`.)

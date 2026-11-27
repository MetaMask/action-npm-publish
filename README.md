# action-npm-publish

This is a GitHub action that handles publishing to NPM for a project that represents a single package (in the case of a polyrepo) or a collection of packages (in the case of a monorepo).

- For a polyrepo project, the action will publish the package using its current version as per `package.json`.

- For a monorepo, the action will publish each workspace package (the set of packages matched via the `workspaces` field in `package.json`, recursively) using its current version as per `package.json`. (Any package which has already been published at its current version will be skipped.)


## Requirements

**This action requires Yarn 4.16.0 or higher.**

This action assumes that your project uses the `node-modules` linker (`nodeLinker: node-modules`). For monorepos, you will need to ensure that the file `node_modules/.yarn-state.yml` is present before this action is invoked. This file is generated automatically when installing dependencies. If you want to publish without dependencies present, you can instantiate an empty state file or restore one from a cache.

This action depends upon the action `slackapi/slack-github-action@007b2c3c751a190b6f0f040e47ed024deaa72844`. This action is authored by a Marketplace "verified creator". If your repository or organization restricts which actions can be used and does not allow Marketplace verified creators by default, ensure that this action is listed as an allowed action.

## Security

Yarn runs code from the repository being published: plugins, `yarnPath` releases, and lifecycle scripts. To prevent that code from reading publishing credentials, the action first sanitises the checkout:

- Yarn is pointed to a minimal configuration file stored outside of the checkout, so `.yarnrc.yml` in the repository (including its plugins) is not loaded. The configuration sets `nodeLinker: node-modules` and disables scripts (`enableScripts: false`), telemetry, and environment file injection. Packages are always published to `https://registry.npmjs.org`, and custom registries are not supported.
- `~/.yarnrc.yml` is removed.
- `YARN_*` environment variables override the configuration file, so they are unset before Yarn runs. If you set a Yarn setting through an environment variable (e.g., `YARN_NPM_PUBLISH_REGISTRY`) in the job that runs this action, it has no effect on the publish.
- The `prepublish`, `prepublishOnly`, `prepack`, and `postpack` scripts are removed from the `package.json` of every package that may be published. These scripts do not run, so any build step must happen before this action is invoked.
- Publishing fails if a package sets `publishConfig.registry` to anything other than `https://registry.npmjs.org`.

## Usage

### Quick start

If you're in a hurry, take a look at the [`publish-release` workflow](https://github.com/MetaMask/metamask-module-template/blob/main/.github/workflows/publish-release.yml) from the [module template](https://github.com/MetaMask/metamask-module-template), which uses this action to publish appropriate packages whenever a release commit is merged, once in dry-run mode and once in "real" mode. (A release commit is a commit that changes the version of the primary package within the project, whether that is the sole package in the case of a polyrepo package, or the root package in the case of a monorepo.)

### Publish with OIDC

OIDC is the only supported authentication method. Grant the job `id-token: write` permission, and configure each package on npm to trust the workflow:

```yaml
jobs:
  publish:
    permissions:
      id-token: write
    steps:
      - uses: MetaMask/action-npm-publish@v6
        with:
          dry-run: false
```

This uses `--provenance` and `--staged` for publishing.

### Initial publish

NPM requires a package to exist on the registry before OIDC can be configured for it. The action doesn't support tokens, so it can't do the very first publish: it fails if a package hasn't been published before and `dry-run` is `false`. Publish the package once yourself, configure OIDC for it, and use the action from then on.

### Dry run mode

The `dry-run` input is required, and must be `true` or `false`. The action doesn't decide it for you, so a missing OIDC permission fails the publish instead of silently turning it into a dry run.

In dry run mode, packages will be prepared for publishing but no publishing will actually occur. OIDC is not necessary, and packages that haven't been published before are allowed.

```yaml
- uses: MetaMask/action-npm-publish@v6
  with:
    dry-run: true
```

### Slack announce

You can optionally send deployment announcements to Slack by providing a `slack-webhook-url` input:

The absolute minimum configuration for this is:

```yaml
- uses: MetaMask/action-npm-publish@v6
  with:
    dry-run: false
    slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

We've added the ability to customize the message posted in Slack and those optional inputs are as follows:

- `icon-url`
- `username`
- `subteam`
- `channel`

example:

```yaml
- uses: MetaMask/action-npm-publish@v6
  with:
    slack-webhook-url: ${{ secrets.SLACK_WEBHOOK_URL }}
    icon-url: https://ricky.codes/me.jpg
    username: rickybot
    # re subteam, see: https://api.slack.com/reference/surfaces/formatting#mentioning-groups
    subteam: S042S7RE4AE # @metamask-npm-publishers
    channel: dev-channel
```

You can read more about these option in the [API](#API) section below

![image](https://user-images.githubusercontent.com/675259/203841602-124d537d-7476-4263-a17c-6d05b68c37d0.png)

## API

### Inputs

- **`dry-run`** _(required)_. Whether to do a dry run, which prepares the packages for publishing but does not publish them. Must be `true` or `false`.

- **`npm-tag`** _(optional)_. The npm tag to publish to. Defaults to `latest`.

- **`slack-webhook-url`** _(optional)_. The incoming webhook URL associated with your Slack application for announcing releases to a Slack channel. This can be added under the "Incoming Webhooks" section of your Slack app configuration.

#### The following inputs only apply if `slack-webhook-url` is set...

- **`icon-url`** _(optional)_. Url to the avatar used for the bot in Slack. If not set this defaults to the avatar in this repository.
- **`username`** _(optional)_. The name of the bot as it appears on Slack. If not set this defaults to `MetaMask bot`.
- **`subteam`** _(optional)_. Use this if you want to ping a subteam of individuals on Slack using `@`.
- **`channel`** _(optional)_. Use this if you want to post to a channel other than the default: `metamask-dev`.

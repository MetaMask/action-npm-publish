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

After the initial publish, OIDC is the only supported authentication method. Grant the job `id-token: write` permission and no `npm-token` is needed:

```yaml
jobs:
  publish:
    permissions:
      id-token: write
    steps:
      - uses: MetaMask/action-npm-publish@v6
```

This uses `--provenance` and (by default) `--staged` for publishing.

### Initial publish with token

NPM requires a package to exist on the registry before OIDC can be configured for it, so the very first publish must use a token:

```yaml
- uses: MetaMask/action-npm-publish@v6
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
```

Once the package has been published at least once, the token is ignored and OIDC is used exclusively for all subsequent publishes.

### Dry run mode

In dry run mode, packages will be prepared for publishing but no publishing will actually occur. No token or OIDC is necessary.

```yaml
- uses: MetaMask/action-npm-publish@v6
  with:
    dry-run: true
```

If neither a token nor OIDC is available, `dry-run` will default to `true`, otherwise it defaults to `false`.

### Pack packages

The `pack` action packs packages into tarballs with `yarn pack`, without running code from the repository. It sanitises the Yarn configuration (see [Security](#security)), removes lifecycle scripts, and packs the packages to release. It's meant for workflows that build packages in one job and publish the tarballs in another, so it also uploads the tarballs as an artifact.

By default, the packages to release are the ones whose `version` in the current commit differs from the version in a base commit, including new packages. Private packages and packages with version `0.0.0` are skipped. This selects from the Git history instead of from what is published on npm, so a release doesn't include packages that an earlier release commit already released.

The base commit is the commit before the push (`github.event.before`), so a push of several commits selects every package that was bumped in any of them. If that isn't available, which is the case for the first push of a branch and for events other than a push, the parent of the current commit is used instead. Set `base` to use another commit. The action fetches the base commit if needed, authenticating with the `token` input (the token of the workflow by default, which needs the `contents: read` permission), and fails if it can't. The token is only used for that fetch, and not when packing. It never falls back to packing all packages.

Because the selection only looks at the commits in the push, packages from a release that failed to publish aren't included in the next release. Re-run the failed workflow instead, which publishes the same tarballs.

```yaml
- uses: MetaMask/action-npm-publish/pack@v7
  id: pack
```

To pack specific packages instead, set `locations`:

```yaml
- uses: MetaMask/action-npm-publish/pack@v7
  id: pack
  with:
    artifact-name: my-tarballs
    locations: |
      packages/foo
      packages/bar
```

If no packages are selected, the action succeeds without packing or uploading anything, and `has-packages` is `false`. Use it to skip later steps and jobs. The tarballs are named `<name>-<version>.tgz`. Set `artifact-name` to an empty string to skip uploading.

### Slack announce

You can optionally send deployment announcements to Slack by providing a `slack-webhook-url` input:

The absolute minimum configuration for this is:

```yaml
- uses: MetaMask/action-npm-publish@v6
  with:
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

### Main action

#### Inputs

- **`npm-token`** _(optional)_. The auth token for the NPM registry. Only used for the initial publish of a package that has not been published before, to allow OIDC to be set up for all subsequent publishes. If omitted, the action will attempt to use OIDC. If neither a token nor OIDC is available, the action will perform a dry run.

- **`npm-tag`** _(optional)_. The npm tag to publish to. Defaults to `latest`.

- **`staged-publish`** _(optional)_. Whether to use staged publishing when publishing via OIDC. Defaults to `true`. If set to `false`, the action will publish directly to NPM without a staging step.

- **`slack-webhook-url`** _(optional)_. The incoming webhook URL associated with your Slack application for announcing releases to a Slack channel. This can be added under the "Incoming Webhooks" section of your Slack app configuration.

##### The following inputs only apply if `slack-webhook-url` is set...

- **`icon-url`** _(optional)_. Url to the avatar used for the bot in Slack. If not set this defaults to the avatar in this repository.
- **`username`** _(optional)_. The name of the bot as it appears on Slack. If not set this defaults to `MetaMask bot`.
- **`subteam`** _(optional)_. Use this if you want to ping a subteam of individuals on Slack using `@`.
- **`channel`** _(optional)_. Use this if you want to post to a channel other than the default: `metamask-dev`.

### Pack sub-action

The `MetaMask/action-npm-publish/pack` action. See [Pack packages](#pack-packages) for how it works.

#### Inputs

- **`locations`** _(optional)_. The locations of the packages to pack, one per line. Use `.` for a polyrepo. Defaults to the packages whose version changed compared to the base commit.

- **`base`** _(optional)_. The commit to compare the current commit to, to select the packages to pack. Only used if `locations` is not set. Defaults to `github.event.before`, or the parent of the current commit if that isn't available. The commit is fetched if needed.

- **`token`** _(optional)_. The token used to fetch the base commit if it isn't available, which is needed for private repositories. Only used to select packages. Requires the `contents: read` permission. Defaults to the token of the workflow.

- **`output-directory`** _(optional)_. The directory to write the tarballs to. It must be empty or not exist, so that tarballs from an earlier step can't end up in the output. Defaults to a `tarballs` directory in the runner temporary directory.

- **`artifact-name`** _(optional)_. The name of the artifact to upload the tarballs to. Defaults to `npm-tarballs`. Set to an empty string to skip uploading.

- **`retention-days`** _(optional)_. The number of days to retain the artifact. Defaults to `4`.

#### Outputs

- **`has-packages`**. Whether there were any packages to pack (`true` or `false`).

- **`locations`**. The locations of the packed packages, one per line.

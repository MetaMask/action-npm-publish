# action-npm-publish

This repository has two GitHub actions that handle publishing to NPM for a project that represents a single package (in the case of a polyrepo) or a collection of packages (in the case of a monorepo):

- The [`pack` action](#pack-packages) packs the packages to release into tarballs, in a job that has no publishing credentials.
- The [main action](#publish-packed-tarballs) publishes those exact tarballs in another job, which needs no checkout and no Yarn.

Any package that has already been published at its current version is skipped.

## Requirements

The `pack` action requires Yarn 4.16.0 or higher in the project. It assumes that the project uses the `node-modules` linker (`nodeLinker: node-modules`). The main action doesn't need Yarn or a checkout.

The main action depends upon the action `slackapi/slack-github-action@007b2c3c751a190b6f0f040e47ed024deaa72844`. This action is authored by a Marketplace "verified creator". If your repository or organization restricts which actions can be used and does not allow Marketplace verified creators by default, ensure that this action is listed as an allowed action.

## Security

Yarn runs code from the repository being published: plugins, `yarnPath` releases, and lifecycle scripts. The `pack` action runs without publishing credentials, and it first sanitises the checkout, so that code from the repository can't change what is packed:

- Yarn is pointed to a minimal configuration file stored outside of the checkout, so `.yarnrc.yml` in the repository (including its plugins) is not loaded. The configuration sets `nodeLinker: node-modules` and disables scripts (`enableScripts: false`), telemetry, and environment file injection. Packages are always published to `https://registry.npmjs.org`, and custom registries are not supported.
- `~/.yarnrc.yml` is removed.
- `YARN_*` environment variables override the configuration file, so they are unset before Yarn runs. If you set a Yarn setting through an environment variable (e.g., `YARN_NPM_PUBLISH_REGISTRY`) in the job that runs the `pack` action, it has no effect.
- The `prepublish`, `prepublishOnly`, `prepack`, and `postpack` scripts are removed from the `package.json` of every package that may be packed. These scripts do not run, so any build step must happen before the `pack` action is invoked.

The main action doesn't run code from the repository at all: it validates each tarball (see [Publish packed tarballs](#publish-packed-tarballs)) and publishes it with `npm publish --ignore-scripts`.

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
      - uses: MetaMask/action-npm-publish@v8
        with:
          dry-run: false
```

This uses `--provenance` and (by default) staged publishing. See [Publish packed tarballs](#publish-packed-tarballs) for the complete workflow, with the job that packs the packages.

### Initial publish

NPM requires a package to exist on the registry before OIDC can be configured for it. The action doesn't support tokens, so it can't do the very first publish: it fails if a package hasn't been published before and `dry-run` is `false`. Publish the package once yourself, configure OIDC for it, and use the action from then on.

### Dry run mode

The `dry-run` input is required, and must be `true` or `false`. The action doesn't decide it for you, so a missing OIDC permission fails the publish instead of silently turning it into a dry run.

In dry run mode, packages will be prepared for publishing but no publishing will actually occur. OIDC is not necessary, and packages that haven't been published before are allowed.

```yaml
- uses: MetaMask/action-npm-publish@v8
  with:
    dry-run: true
```

### Pack packages

The `pack` action packs packages into tarballs with `yarn pack`, without running code from the repository. It sanitises the Yarn configuration (see [Security](#security)), removes lifecycle scripts, and packs the packages to release. It's meant for workflows that build packages in one job and publish the tarballs in another, so it also uploads the tarballs as an artifact.

By default, the packages to release are the ones whose `version` in the current commit differs from the version in a base commit, including new packages. Private packages and packages with version `0.0.0` are skipped. This selects from the Git history instead of from what is published on npm, so a release doesn't include packages that an earlier release commit already released.

The base commit is the commit before the push (`github.event.before`), so a push of several commits selects every package that was bumped in any of them. If that isn't available, which is the case for the first push of a branch and for events other than a push, the parent of the current commit is used instead. Set `base` to use another commit. The action fetches the base commit if needed, authenticating with the `token` input (the token of the workflow by default, which needs the `contents: read` permission), and fails if it can't. The token is only used for that fetch, and not when packing. It never falls back to packing all packages.

Because the selection only looks at the commits in the push, packages from a release that failed to publish aren't included in the next release. Re-run the failed workflow instead, which publishes the same tarballs.

```yaml
- uses: MetaMask/action-npm-publish/pack@v8
  id: pack
```

To pack specific packages instead, set `locations`:

```yaml
- uses: MetaMask/action-npm-publish/pack@v8
  id: pack
  with:
    artifact-name: my-tarballs
    locations: |
      packages/foo
      packages/bar
```

If no packages are selected, the action succeeds without packing or uploading anything, and `has-packages` is `false`. Use it to skip later steps and jobs. The tarballs are named `<name>-<version>.tgz`. Set `artifact-name` to an empty string to skip uploading.

### Publish packed tarballs

To keep credentials away from the build, pack the packages in one job, and publish the tarballs in another. The publish job needs no checkout and no Yarn:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      has-packages: ${{ steps.pack.outputs.has-packages }}
    steps:
      - uses: actions/checkout@v6
      - run: yarn install --immutable && yarn build
      - uses: MetaMask/action-npm-publish/pack@v8
        id: pack

  publish:
    needs: build
    if: needs.build.outputs.has-packages == 'true'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: MetaMask/action-npm-publish@v8
        with:
          dry-run: false
```

The action downloads the artifact (named by `artifact-name`, `npm-tarballs` by default, as in the pack action) and publishes the tarballs in it, as they are, with `npm publish --ignore-scripts`. It fails if the artifact doesn't exist.

Because the tarballs come from another job, the action only publishes a tarball that:

- Is a valid tarball, which only contains files in a `package/` directory.
- Contains exactly one `package/package.json`, with a name and a version, which isn't private.
- Only sets `access` and `registry` in `publishConfig`, and `registry` is `https://registry.npmjs.org`.

The job summary starts with the release details: a link to the pull request, if there is one, and the packages that are released. In a dry run, nothing is published. Instead, the log and the job summary show the checksum and the list of files in each tarball, and the summary links to the report with the diffs against the latest published versions, so you can look for files that shouldn't be published before approving the release.

A package whose version is already published, for example because a failed job is re-run, is skipped. The Slack message reads the name and version from the `package.json` in the root of the repository, at the commit being released, using the GitHub API, and its "review deployment" link goes to the job summary with the packages and their files.

### Slack announce

You can optionally send deployment announcements to Slack by providing a `slack-webhook-url` input:

The absolute minimum configuration for this is:

```yaml
- uses: MetaMask/action-npm-publish@v8
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
- uses: MetaMask/action-npm-publish@v8
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

- **`dry-run`** _(required)_. Whether to do a dry run, which prepares the packages for publishing but does not publish them. Must be `true` or `false`.

- **`npm-tag`** _(optional)_. The npm tag to publish to. Defaults to `latest`.

- **`staged-publish`** _(optional)_. Whether to use staged publishing when publishing via OIDC. Defaults to `true`. If set to `false`, the action will publish directly to NPM without a staging step.

- **`artifact-name`** _(optional)_. The name of the artifact that contains the tarballs packed by the [`pack` action](#pack-packages). Defaults to `npm-tarballs`.

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

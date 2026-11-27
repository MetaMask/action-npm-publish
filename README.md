# action-npm-publish

This is a GitHub action that handles publishing to NPM for a project that represents a single package (in the case of a polyrepo) or a collection of packages (in the case of a monorepo). It runs in two jobs:

- With `dry-run: true`, the action packs the packages that were released in the commit into tarballs with `yarn pack`, uploads the tarballs as an artifact, and reports what would be published.
- With `dry-run: false`, the action downloads those tarballs and publishes them as they are, in a job that needs no checkout and no Yarn.

A package whose version is already published is skipped.

## Requirements

The job with the dry run needs the project checked out and built, **Yarn 4.16.0 or higher**, and the `node-modules` linker (`nodeLinker: node-modules`). The file `node_modules/.yarn-state.yml` must be present, which is generated when installing dependencies. The job that publishes needs neither a checkout nor Yarn.

This action depends upon the action `slackapi/slack-github-action@007b2c3c751a190b6f0f040e47ed024deaa72844`. This action is authored by a Marketplace "verified creator". If your repository or organization restricts which actions can be used and does not allow Marketplace verified creators by default, ensure that this action is listed as an allowed action.

## Which packages are released

A package is released when its `version` in the commit differs from its version in the commit before the push (`github.event.before`), which includes new packages. Private packages and packages with version `0.0.0` are skipped. This uses the Git history instead of what is published on npm, so a release doesn't include packages that an earlier release commit already released.

A push of several commits releases every package that was bumped in any of them. For the first push of a branch and for events other than a push, the parent of the commit is used. The action fetches the commit if it isn't available, using the token of the workflow (which needs the `contents: read` permission). The dry run fails if no package is released, or if the commit can't be fetched. It never packs all packages as a fallback.

Because the selection only looks at the commits in the push, packages from a release that failed to publish aren't included in the next release. Re-run the failed workflow instead, which publishes the same tarballs. A force push makes `github.event.before` the old tip of the branch, which defeats the selection.

## Security

Yarn runs code from the repository: plugins, `yarnPath` releases, and lifecycle scripts. The dry run has no publishing credentials, and it first sanitises the checkout:

- Yarn is pointed to a minimal configuration file stored outside of the checkout, so `.yarnrc.yml` in the repository (including its plugins) is not loaded. The configuration sets `nodeLinker: node-modules` and disables scripts (`enableScripts: false`), telemetry, and environment file injection. Packages are always published to `https://registry.npmjs.org`, and custom registries are not supported.
- `~/.yarnrc.yml` is removed.
- `YARN_*` environment variables override the configuration file, so they are unset before Yarn runs. If you set a Yarn setting through an environment variable (e.g., `YARN_NPM_PUBLISH_REGISTRY`) in the job with the dry run, it has no effect.
- The lifecycle scripts that Yarn or npm may run when packing or publishing (e.g., `prepublish`, `prepack`, and `postpack`) are removed from the `package.json` of every package that may be released. These scripts do not run, so any build step must happen before the dry run.

Sanitising is not a boundary against code that already ran in the same job: a build step can change environment variables, `PATH`, and the files of this action. Run the dry run in a job that did not run the build, and only restore the build output that the packages need, as in the [example](#publish-with-oidc) below.

The job that publishes runs no code from the repository. It only publishes tarballs that:

- Are exactly the tarballs that the dry run packed. The `checksums` output of the dry run lists the name, version, and SHA-512 of each tarball, and the action fails if a tarball was added, removed, or replaced since.
- Are valid tarballs, which only contain files in a `package/` directory, and exactly one `package/package.json`, with a name and a version, which isn't private.
- Only set `access` and `registry` in `publishConfig`, and `registry` is `https://registry.npmjs.org`.

## Usage

### Quick start

If you're in a hurry, take a look at the [`publish-release` workflow](https://github.com/MetaMask/metamask-module-template/blob/main/.github/workflows/publish-release.yml) from the [module template](https://github.com/MetaMask/metamask-module-template), which uses this action to publish appropriate packages whenever a release commit is merged, once in dry-run mode and once in "real" mode. (A release commit is a commit that changes the version of the primary package within the project, whether that is the sole package in the case of a polyrepo package, or the root package in the case of a monorepo.)

### Publish with OIDC

OIDC is the only supported authentication method. Grant the job that publishes the `id-token: write` permission, and configure each package on npm to trust the workflow. The packages are published with `--provenance` (for public repositories) and `--staged`, so they must be approved on npm before they are published.

The dry run and the publish are separate jobs. Pass the `checksums` output of the dry run to the job that publishes:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v6
      - run: yarn install --immutable
      - run: yarn build
      - uses: actions/upload-artifact@v7
        with:
          name: build-output
          include-hidden-files: true
          path: |
            node_modules/.yarn-state.yml
            packages/*/dist

  dry-run:
    needs: build
    runs-on: ubuntu-latest
    permissions:
      contents: read
    outputs:
      checksums: ${{ steps.dry-run.outputs.checksums }}
    steps:
      - uses: actions/checkout@v6
      - uses: actions/download-artifact@v8
        with:
          name: build-output
          path: ${{ runner.temp }}/build-output
      - name: Restore the build output
        run: |
          mkdir -p node_modules
          cp "$RUNNER_TEMP/build-output/node_modules/.yarn-state.yml" node_modules/.yarn-state.yml
          for dist in "$RUNNER_TEMP"/build-output/packages/*/dist; do
            cp -R "$dist" "packages/$(basename "$(dirname "$dist")")/"
          done
      - id: dry-run
        uses: MetaMask/action-npm-publish@v8
        with:
          dry-run: true

  publish:
    needs: dry-run
    runs-on: ubuntu-latest
    environment: npm-publish
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: MetaMask/action-npm-publish@v8
        with:
          dry-run: false
          checksums: ${{ needs.dry-run.outputs.checksums }}
```

### Initial publish

NPM requires a package to exist on the registry before OIDC can be configured for it. The action doesn't support tokens, so it can't do the very first publish: it fails if a package hasn't been published before and `dry-run` is `false`. Publish the package once yourself, configure OIDC for it, and use the action from then on.

### Dry run mode

The `dry-run` input is required, and must be `true` or `false`. The action doesn't decide it for you, so a missing OIDC permission fails the publish instead of silently turning it into a dry run.

In dry run mode, nothing is published. The action packs the packages, uploads the tarballs as an artifact (named by `artifact-name`, `npm-tarballs` by default), and reports what would be published, so you can look for files that shouldn't be published before approving the release:

- The job summary starts with a warning if a package has never been published, because the action can't publish it (see [Initial publish](#initial-publish)). It then has the release details: a link to the pull request, if there is one, and the packages that are released.
- The log and the job summary show the checksum, the integrity, and the list of files in each tarball.
- A report with the diffs between each package and its latest published version is uploaded as an artifact.

OIDC is not necessary, and packages that haven't been published before are allowed. Without a dry run, the action downloads the artifact with the same `artifact-name`, and fails if it doesn't exist.

### Slack announce

You can optionally send deployment announcements to Slack by providing a `slack-webhook-url` input:

The absolute minimum configuration for this is:

```yaml
- uses: MetaMask/action-npm-publish@v8
  with:
    dry-run: false
    checksums: ${{ needs.dry-run.outputs.checksums }}
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
    dry-run: false
    checksums: ${{ needs.dry-run.outputs.checksums }}
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

- **`dry-run`** _(required)_. Whether to do a dry run, which packs the packages that were released in the commit, uploads the tarballs as an artifact, and reports what would be published, without publishing. Without a dry run, the action publishes the tarballs from that artifact. Must be `true` or `false`.

- **`checksums`** _(required if `dry-run` is `false`)_. The `checksums` output of the dry run. The action only publishes the tarballs that the dry run packed.

- **`artifact-name`** _(optional)_. The name of the artifact that the dry run uploads the tarballs to, and that is published without a dry run. Defaults to `npm-tarballs`.

- **`npm-tag`** _(optional)_. The npm tag to publish to. Defaults to `latest`.

- **`slack-webhook-url`** _(optional)_. The incoming webhook URL associated with your Slack application for announcing releases to a Slack channel. This can be added under the "Incoming Webhooks" section of your Slack app configuration.

#### The following inputs only apply if `slack-webhook-url` is set...

- **`icon-url`** _(optional)_. Url to the avatar used for the bot in Slack. If not set this defaults to the avatar in this repository.
- **`username`** _(optional)_. The name of the bot as it appears on Slack. If not set this defaults to `MetaMask bot`.
- **`subteam`** _(optional)_. Use this if you want to ping a subteam of individuals on Slack using `@`.
- **`channel`** _(optional)_. Use this if you want to post to a channel other than the default: `metamask-dev`.

### Outputs

- **`checksums`**. The tarballs that the dry run packed, one per line, as `<name>@<version> <integrity>`. Pass it to the action that publishes, as the `checksums` input. Only set with `dry-run: true`.

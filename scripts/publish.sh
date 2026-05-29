#!/usr/bin/env bash

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

IFS='.' read -r YARN_MAJOR YARN_MINOR _ <<< "$(yarn --version)"

# TODO: Set this to the right version when Yarn releases a new version with the
# `--staged` flag for `yarn npm publish`.
if [[ "$YARN_MAJOR" -lt 4 || ( "$YARN_MAJOR" -eq 4 && "$YARN_MINOR" -lt 15 ) ]]; then
  echo "::error::Yarn version 4.15.0 or higher is required. Detected version: $(yarn --version)."
  exit 1
fi

if [[ -z "$PUBLISH_NPM_TAG" ]]; then
  echo "::error::'npm-tag' not set."
  exit 1
fi

PACK_CMD="yarn pack --out /tmp/%s-%v.tgz"

# Get the package name and the latest published version for the specified tag,
# if it exists. Note that we're `cd`ing into /tmp before running `npm view` to
# avoid any issues with Corepack detecting Yarn.
PACKAGE_NAME=$(jq --raw-output .name package.json)
LATEST_PACKAGE_VERSION=$(cd /tmp && npm view "$PACKAGE_NAME" dist-tags --workspaces false --json 2>/dev/null | jq --raw-output --arg tag "$PUBLISH_NPM_TAG" '.[$tag] // empty' || echo "")

# Determine the publish command and whether to perform a dry run. It works as
# follows:
# 1. If a token is provided, and the package has not been published before, use
# the token for the initial publish.
# 2. If a token is provided, but the package has already been published, ignore
# the token and fall back to OIDC (if available) for subsequent publish.
# 3. If no token is provided, use OIDC if available.
# 4. If neither a token nor OIDC is available, perform a dry run.
if [[ -n "$YARN_NPM_AUTH_TOKEN" && -z "$LATEST_PACKAGE_VERSION" ]]; then
  echo "Notice: Package not yet published. Using token for initial publish."
  PUBLISH_CMD="yarn npm publish --tag $PUBLISH_NPM_TAG"
  DRY_RUN="false"
elif [[ -n "$YARN_NPM_AUTH_TOKEN" ]]; then
  echo "Notice: Package already published. Ignoring token and falling back to OIDC."
fi

# Dry run will be set to false if a token is provided and the package has not
# been published before. Otherwise, we check for OIDC availability and set the
# publish command accordingly.
if [[ -z "$DRY_RUN" ]]; then
  # No token used - use OIDC if available.
  if [[ -n "$ACTIONS_ID_TOKEN_REQUEST_URL" ]]; then
    if [[ "$STAGED_PUBLISH" = "true" ]]; then
      PUBLISH_CMD="yarn npm publish --tag $PUBLISH_NPM_TAG --staged --provenance"
    else
      PUBLISH_CMD="yarn npm publish --tag $PUBLISH_NPM_TAG --provenance"
    fi
    DRY_RUN="false"
  else
    echo "Notice: OIDC is not available. Performing a dry run."
    DRY_RUN="true"
  fi
fi

# Export the "dry-run" status for use in subsequent steps, if GITHUB_OUTPUT is
# available.
[[ -n "$GITHUB_OUTPUT" ]] && echo "dry-run=$DRY_RUN" >> "$GITHUB_OUTPUT"

# "dry-run" for polyrepo
if [[ "$DRY_RUN" = "true" && -z "$IS_MONOREPO" ]]; then
  $PACK_CMD
  exit 0
fi

CURRENT_PACKAGE_VERSION=$(jq --raw-output .version package.json)

if [[ "$CURRENT_PACKAGE_VERSION" = "0.0.0" ]]; then
  echo "Notice: Invalid version: $CURRENT_PACKAGE_VERSION. Aborting publish."
  exit 0
fi

IS_MONOREPO="$1"

# check param, if it's set (monorepo) we check if it's published before proceeding
if [[ -n "$IS_MONOREPO" ]]; then
  # "dry-run" for monorepo.
  if [[ "$DRY_RUN" = "true" && ! "$LATEST_PACKAGE_VERSION" = "$CURRENT_PACKAGE_VERSION" ]]; then
    echo "Notice: OIDC is not available. Running '$PACK_CMD'."
    $PACK_CMD
    exit 0
  fi

  if [ "$LATEST_PACKAGE_VERSION" = "$CURRENT_PACKAGE_VERSION" ]; then
    echo "Notice: This module is already published at $CURRENT_PACKAGE_VERSION. Aborting publish."
    exit 0
  fi
fi

$PUBLISH_CMD

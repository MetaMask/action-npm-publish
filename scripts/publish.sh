#!/usr/bin/env bash

set -e
set -o pipefail

YARN_MAJOR="$(yarn --version | sed 's/\..*//' || true)"
if [[ "$YARN_MAJOR" -ge "3" ]]; then
  PUBLISH_CMD="yarn npm publish --tag $PUBLISH_NPM_TAG"
  PACK_CMD="yarn pack --out /tmp/%s-%v.tgz"
  # install is handled by yarn berry pack/publish
  INSTALL_CMD=""
else
  echo "Warning: Did not detect compatible yarn version. This action officially supports Yarn v3 and newer. Falling back to using npm." >&2
  PUBLISH_CMD="npm publish --tag $PUBLISH_NPM_TAG"
  PACK_CMD="npm pack --pack-destination=/tmp/"
  if [[ -f 'yarn.lock' ]]; then
    INSTALL_CMD="yarn install --frozen-lockfile"
  else
    INSTALL_CMD="npm ci"
  fi
fi

# https://docs.npmjs.com/staged-publishing
if [[ "$STAGED_PUBLISH" = "true" ]]; then
  # Yarn does not support staged publishing (yet), so we use NPM for that even
  # if Yarn is the default package manager.
  PUBLISH_CMD="npm stage publish --tag $PUBLISH_NPM_TAG --provenance"
fi

# Perform a dry run if OIDC is not available.
if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_URL" ]]; then
  echo "Notice: OIDC is not available. Performing a dry run."
  DRY_RUN="true"
else
  DRY_RUN="false"
fi

[[ -n "$GITHUB_OUTPUT" ]] && echo "dry-run=$DRY_RUN" >> "$GITHUB_OUTPUT"

IS_MONOREPO="$1"

# "dry-run" for polyrepo
if [[ "$DRY_RUN" = "true" && -z "$IS_MONOREPO" ]]; then
  $INSTALL_CMD
  $PACK_CMD
  exit 0
fi

if [ "${RUNNER_DEBUG}" = "1" ]; then
  set -x
fi

if [[ -z "$PUBLISH_NPM_TAG" ]]; then
  echo "Notice: 'npm-tag' not set."
  exit 1
fi

CURRENT_PACKAGE_VERSION=$(jq --raw-output .version package.json)

if [[ "$CURRENT_PACKAGE_VERSION" = "0.0.0" ]]; then
  echo "Notice: Invalid version: $CURRENT_PACKAGE_VERSION. aborting publish."
  exit 0
fi

# check param, if it's set (monorepo) we check if it's published before proceeding
if [[ -n "$IS_MONOREPO" ]]; then
  # check if module is published
  PACKAGE_NAME=$(jq --raw-output .name package.json)
  LATEST_PACKAGE_VERSION=$(npm view "$PACKAGE_NAME" dist-tags --workspaces false --json | jq --raw-output --arg tag "$PUBLISH_NPM_TAG" '.[$tag]' || echo "")

  # "dry-run" for monorepo
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

$INSTALL_CMD
$PUBLISH_CMD

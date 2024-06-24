#!/usr/bin/env bash

set -e
set -o pipefail

export YARN_NPM_AUTH_TOKEN="${YARN_NPM_AUTH_TOKEN:-$NPM_TOKEN}"

YARN_MAJOR="$(yarn --version | sed 's/\..*//' || true)"
if [[ "$YARN_MAJOR" -ge "3" ]]; then
  PUBLISH_CMD="yarn npm publish --tag $PUBLISH_NPM_TAG"
  PACK_CMD="yarn pack --out /tmp/%s-%v.tgz"
  # install is handled by yarn berry pack/publish
  INSTALL_CMD=""
else
  echo "Warning: Did not detect compatible yarn version. This action officially supports Yarn v3 and newer. Falling back to using npm." >&2
  echo "//registry.npmjs.org/:_authToken=${YARN_NPM_AUTH_TOKEN}" >> "$HOME/.npmrc"
  PUBLISH_CMD="npm publish --tag $PUBLISH_NPM_TAG"
  PACK_CMD="npm pack --pack-destination=/tmp/"
  if [[ -f 'yarn.lock' ]]; then
    INSTALL_CMD="yarn install --frozen-lockfile"
  else
    INSTALL_CMD="npm ci"
  fi
fi

# "dry-run" for polyrepo
if [[ -z "$YARN_NPM_AUTH_TOKEN" && -z "$1" ]]; then
  echo "Notice: 'npm-token' not set. Running '$PACK_CMD'."
  $INSTALL_CMD
  $PACK_CMD
  exit 0
fi

set -x

if [[ -z $PUBLISH_NPM_TAG ]]; then
  echo "Notice: 'npm-tag' not set."
  exit 1
fi

CURRENT_PACKAGE_VERSION=$(jq --raw-output .version package.json)

if [[ "$CURRENT_PACKAGE_VERSION" = "0.0.0" ]]; then
  echo "Notice: Invalid version: $CURRENT_PACKAGE_VERSION. aborting publish."
  exit 0
fi

# check param, if it's set (monorepo) we check if it's published before proceeding
if [[ -n "$1" ]]; then
  # check if module is published
  PACKAGE_NAME=$(jq --raw-output .name package.json)
  LATEST_PACKAGE_VERSION=$(npm view "$PACKAGE_NAME" dist-tags --workspaces false --json | jq --raw-output --arg tag "$PUBLISH_NPM_TAG" '.[$tag]' || echo "")

  # "dry-run" for monorepo
  if [[ -z "$YARN_NPM_AUTH_TOKEN" && ! "$LATEST_PACKAGE_VERSION" = "$CURRENT_PACKAGE_VERSION" ]]; then
    echo "Notice: 'npm-token' not set. Running '$PACK_CMD'."
    $PACK_CMD
    exit 0
  fi

  if [ "$LATEST_PACKAGE_VERSION" = "$CURRENT_PACKAGE_VERSION" ]; then
    echo "Notice: This module is already published at $CURRENT_PACKAGE_VERSION. aborting publish."
    exit 0
  fi
fi

$INSTALL_CMD
$PUBLISH_CMD
rm -f "$HOME/.npmrc"

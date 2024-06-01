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
  LOGIN_CMD=""
else
  echo "Warning: Did not detect compatible yarn version. This action officially supports Yarn v3 and newer. Falling back to using npm." >&2
  export npm_config__auth="$YARN_NPM_AUTH_TOKEN"
  PUBLISH_CMD="npm publish --tag $PUBLISH_NPM_TAG"
  LOGIN_CMD="npm adduser"
  PACK_CMD="npm pack --pack-destination=/tmp/"
  if [[ -f 'yarn.lock' ]]; then
    INSTALL_CMD="yarn install --frozen-lockfile"
  else
    INSTALL_CMD="npm ci"
  fi
fi

if [[ -z $YARN_NPM_AUTH_TOKEN ]]; then
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

# check param, if it's set (monorepo) we check if it's published before proceeding
if [[ -n "$1" ]]; then
  # check if module is published
  LATEST_PACKAGE_VERSION=$(npm view . version --workspaces=false || echo "")
  CURRENT_PACKAGE_VERSION=$(jq --raw-output .version package.json)

  if [ "$LATEST_PACKAGE_VERSION" = "$CURRENT_PACKAGE_VERSION" ]; then
    echo "Notice: This module is already published at $CURRENT_PACKAGE_VERSION. aborting publish."
    exit 0
  fi
fi

$INSTALL_CMD
$LOGIN_CMD
$PUBLISH_CMD

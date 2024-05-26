#!/usr/bin/env bash

set -x
set -e
set -o pipefail

YARN_NPM_AUTH_TOKEN="${YARN_NPM_AUTH_TOKEN:-$NPM_TOKEN}"

if [[ -z $YARN_NPM_AUTH_TOKEN ]]; then
  echo "Notice: 'npm-token' not set. Running 'yarn pack --dry-run'."
  yarn pack --dry-run
  exit 0
fi

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

YARN_VERSION="$(yarn --version)"
if [[ "$YARN_VERSION" =~ ^1 ]]; then
  echo "Warning: Detected Yarn Classic. This action officially supports Yarn v3 and newer. Older versions may break in future versions." >&2
  npm_config__auth="$YARN_NPM_AUTH_TOKEN" yarn publish --tag "$PUBLISH_NPM_TAG"
else
  yarn npm publish --tag "$PUBLISH_NPM_TAG"
fi

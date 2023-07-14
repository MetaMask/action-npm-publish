#!/usr/bin/env bash

set -x
set -e
set -o pipefail

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
  PACKAGE_NAME=$(jq --raw-output .name package.json)
  LATEST_PACKAGE_VERSION=$(npm view "$PACKAGE_NAME" dist-tags --workspaces false --json | jq --raw-output --arg tag "$PUBLISH_NPM_TAG" '.[$tag]' || echo "")
  CURRENT_PACKAGE_VERSION=$(jq --raw-output .version package.json)

  if [ "$LATEST_PACKAGE_VERSION" = "$CURRENT_PACKAGE_VERSION" ]; then
    echo "Notice: This module is already published at $CURRENT_PACKAGE_VERSION. aborting publish."
    exit 0
  fi
fi

yarn npm publish --tag "$PUBLISH_NPM_TAG"

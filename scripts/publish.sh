#!/usr/bin/env bash

set -x
set -e
set -o pipefail

if [[ -z $NPM_TOKEN ]]; then
  echo "Notice: NPM_TOKEN environment variable not set. Running 'npm publish --dry-run'."
  npm publish --dry-run
  exit 0
fi

# check param, if it's set (monorepo) we check if it's published before proceeding
if [[ -n "$1" ]]; then
  # check if module is published
  LATEST_PACKAGE_VERSION=$(npm view . version --workspaces=false || echo "")
  CURRENT_PACKAGE_VERSION=$(jq --raw-output .version package.json)

  if [ "$LATEST_PACKAGE_VERSION" = "$CURRENT_PACKAGE_VERSION" ]; then
    echo "Notice: This module is already published at this version. aborting publish."
    exit 0
  fi
fi

npm publish

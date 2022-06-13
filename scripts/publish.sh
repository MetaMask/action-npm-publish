#!/usr/bin/env bash

set -x
set -e
set -o pipefail

if [[ -z $NPM_TOKEN ]]; then
  echo "Notice: NPM_TOKEN environment variable not set. Running 'npm publish --dry-run'."
  npm publish --dry-run
  exit 0
fi

# Get the published version
# If the package is not published, set the published version to "NULL"
NPM_VERSION=$(npm show . version || echo "NULL")

# Get the local version of the package, from package.json
# The jq "r" flag gives us the raw, unquoted output
LOCAL_VERSION=$(jq -r .version < package.json)

# Skip Publish if this version is already published
if [[ $NPM_VERSION != "NULL" || $LOCAL_VERSION == "$NPM_VERSION" ]]; then
  echo "Notice: This module has already been published at this verion. Aborting publish."
  echo 0
fi

npm publish

#!/usr/bin/env bash

set -x
set -e
set -o pipefail

semver_to_nat () {
  echo "${1//./}"
}

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
  # convert to natural numbers for below comparison
  LATEST_PACKAGE_VERSION_NAT=$(semver_to_nat "$LATEST_PACKAGE_VERSION")
  CURRENT_PACKAGE_VERSION_NAT=$(semver_to_nat "$CURRENT_PACKAGE_VERSION")

  if [ "$LATEST_PACKAGE_VERSION_NAT" -ge "$CURRENT_PACKAGE_VERSION_NAT" ]; then
    echo -e \
      "Notice: This module cannot be published at v$CURRENT_PACKAGE_VERSION." \
      "This module has been already published at v$LATEST_PACKAGE_VERSION." \
      "aborting publish."
    exit 0
  fi
fi

npm publish

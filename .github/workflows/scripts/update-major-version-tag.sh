#!/usr/bin/env bash

set -x
set -e
set -o pipefail

RELEASE_VERSION="${1}"

if [[ -z $RELEASE_VERSION ]]; then
  echo "Error: No release version specified."
  exit 1
fi

MAJOR_VERSION_TAG="v${RELEASE_VERSION/\.*/}"

git config user.name github-actions
git config user.email github-actions@github.com

git tag -f "$MAJOR_VERSION_TAG" HEAD
git push -f origin "$MAJOR_VERSION_TAG"
echo "Updated shorthand major version tag."

echo "MAJOR_VERSION_TAG=$MAJOR_VERSION_TAG" >> "$GITHUB_OUTPUT"

#!/usr/bin/env bash

set -x
set -e
set -o pipefail

if [[ -z $NPM_TOKEN ]]; then
  echo "Notice: NPM_TOKEN environment variable not set. Running 'npm publish --dry-run'."
  npm publish --dry-run
  exit 0
fi

#TODO: detect if module has been published
npm publish

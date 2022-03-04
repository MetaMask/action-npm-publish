#!/usr/bin/env bash

set -x
set -e
set -o pipefail

if [[ -z $NPM_TOKEN ]]; then
  echo "Notice: NPM_TOKEN environment variable not set. Skipping npm publishing."
  exit 1
fi

npm config set //registry.npmjs.org/:_authToken ${NPM_TOKEN}
npm publish

#!/usr/bin/env bash

set -x
set -e
set -o pipefail

if ! [[ -z $NPM_TOKEN ]]; then
  npm config set //registry.npmjs.org/:_authToken "${NPM_TOKEN}"
fi

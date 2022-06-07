#!/usr/bin/env bash

set -x
set -e
set -o pipefail

if [[ "$(jq 'has("workspaces")' package.json)" == "true" ]]; then
  echo "Notice: workspaces detected. Treating as monorepo."
  yarn workspaces foreach --no-private --verbose ./publish.sh
  exit 0
fi

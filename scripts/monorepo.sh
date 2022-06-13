#!/usr/bin/env bash

set -x
set -e
set -o pipefail

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

if [[ "$(jq 'has("workspaces")' package.json)" == "true" ]]; then
  echo "Notice: workspaces detected. Treating as monorepo."
  yarn workspaces foreach --no-private --verbose "${script_path}"/publish.sh
  exit 0
fi

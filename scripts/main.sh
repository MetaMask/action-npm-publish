#!/usr/bin/env bash

if [ "${RUNNER_DEBUG}" = "1" ]; then
  set -x
fi
set -e
set -o pipefail

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

if [[ "$(jq 'has("workspaces")' package.json)" = "true" ]]; then
  echo "Notice: workspaces detected. Treating as monorepo."
  yarn workspaces foreach --all --no-private --verbose exec "$script_path/publish.sh true"
  exit 0
fi

echo "Notice: no workspaces detected. Treating as polyrepo."
"${script_path}"/publish.sh

#!/usr/bin/env bash

set -x
set -e
set -o pipefail

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

if [[ -n $NPM_TOKEN ]]; then
  npm config set //registry.npmjs.org/:_authToken "${NPM_TOKEN}"
fi

if [[ "$(jq 'has("workspaces")' package.json)" == "true" ]]; then
  echo "Notice: workspaces detected. Treating as monorepo."
  # yarn workspaces foreach --no-private --verbose exec "${script_path}"/publish.sh
  # try npm instead
  npm exec -wc "${script_path}"/publish.sh
  exit 0
fi

echo "Notice: no workspaces detected. Treating as polyrepo."
"${script_path}"/publish.sh

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
  # npm exec -c "$script_path/publish.sh" --workspaces
  npm exec -c "npm publish --dry-run" --workspaces
  exit 0
fi

echo "Notice: no workspaces detected. Treating as polyrepo."
"${script_path}"/publish.sh

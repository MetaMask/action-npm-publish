#!/usr/bin/env bash

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

publish_monorepo() {
  echo "Notice: Workspaces detected. Treating as monorepo."

  if [[ -z "$PUBLISH_NPM_TAG" ]]; then
    echo "::error::'npm-tag' not set."
    exit 1
  fi

  # Determine upfront which workspaces actually need publishing, so that
  # `yarn workspaces foreach` only runs for those. Each workspace is checked
  # in parallel via `xargs -P`.
  pending=$(
    yarn workspaces list --json --no-private \
      | jq --raw-output '.location' \
      | while read -r location; do
          jq --raw-output '[.name, .version] | @tsv' "$location/package.json"
        done \
      | xargs -P 10 -n 2 "$script_path/needs-publish.sh"
  )

  if [[ -z "$pending" ]]; then
    echo "Notice: No packages need publishing."
    exit 0
  fi

  mapfile -t names <<< "$pending"
  include_args=()
  for name in "${names[@]}"; do
    include_args+=(--include "$name")
  done

  echo "Notice: Publishing ${#names[@]} package(s): ${pending//$'\n'/, }."

  yarn workspaces foreach "${include_args[@]}" --no-private --verbose \
    exec "$script_path/publish.sh" true
}

if [[ "$(jq 'has("workspaces")' package.json)" = "true" ]]; then
  publish_monorepo
  exit 0
fi

echo "Notice: No workspaces detected. Treating as polyrepo."
"${script_path}"/publish.sh

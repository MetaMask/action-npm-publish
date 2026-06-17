#!/usr/bin/env bash

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

IFS='.' read -r YARN_MAJOR YARN_MINOR _ <<< "$(yarn --version)"
if [[ "$YARN_MAJOR" -lt 4 || ( "$YARN_MAJOR" -eq 4 && "$YARN_MINOR" -lt 16 ) ]]; then
  echo "::error::Yarn version 4.16.0 or higher is required. Detected version: $(yarn --version)."
  exit 1
fi

if [[ -z "$PUBLISH_NPM_TAG" ]]; then
  echo "::error::'npm-tag' not set."
  exit 1
fi

publish_monorepo() {
  echo "Notice: Workspaces detected. Treating as monorepo."

  # Determine upfront which workspaces actually need publishing, so that
  # `yarn workspaces foreach` only runs for those. Each workspace is checked
  # in parallel via `xargs -P`.
  pending=$(
    yarn workspaces list --json --no-private \
      | jq --raw-output '.location' \
      | while read -r location; do
          jq --raw-output --arg location "$location" '
            [
              (.name // error("Missing .name in " + $location + "/package.json")),
              (.version // error("Missing .version in " + $location + "/package.json"))
            ] | @tsv
          ' "$location/package.json"
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

  yarn workspaces foreach --all "${include_args[@]}" --no-private --verbose \
    exec "$script_path/publish.sh"
}

if [[ "$(jq 'has("workspaces")' package.json)" = "true" ]]; then
  publish_monorepo
  exit 0
fi

echo "Notice: No workspaces detected. Treating as polyrepo."
"${script_path}"/publish.sh

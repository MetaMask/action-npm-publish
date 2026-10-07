#!/usr/bin/env bash

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

if [[ -n "$GITHUB_SHA" && -n "$GITHUB_REPOSITORY" ]]; then
  pr_url=$(gh api "/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA/pulls" \
    --jq '.[0].html_url // empty' 2>/dev/null || true)
  if [[ -n "$pr_url" ]]; then
    echo "Notice: Releasing via pull request: $pr_url"
  fi
fi

# The GitHub token is only needed for the `gh` call above. Unset it before any
# `yarn` invocation, so that it isn't inherited by repository-loaded Yarn
# configuration, plugins, or lifecycle scripts.
unset GITHUB_TOKEN

# Yarn loads repository-controlled configuration and plugins, so run Yarn
# commands that don't publish without any npm or OIDC credentials. The variables
# are set to empty values rather than unset, because Yarn aborts when its
# configuration interpolates a missing variable (e.g.,
# `npmAuthToken: "${YARN_NPM_AUTH_TOKEN}"`). The real values are retained in this
# shell for `publish.sh`.
run_yarn() {
  env YARN_NPM_AUTH_TOKEN= \
      ACTIONS_ID_TOKEN_REQUEST_URL= \
      ACTIONS_ID_TOKEN_REQUEST_TOKEN= \
      yarn "$@"
}

YARN_VERSION=$(run_yarn --version)
IFS='.' read -r YARN_MAJOR YARN_MINOR _ <<< "$YARN_VERSION"
if [[ "$YARN_MAJOR" -lt 4 || ( "$YARN_MAJOR" -eq 4 && "$YARN_MINOR" -lt 16 ) ]]; then
  echo "::error::Yarn version 4.16.0 or higher is required. Detected version: $YARN_VERSION."
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
    run_yarn workspaces list --json --no-private \
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

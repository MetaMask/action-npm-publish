#!/usr/bin/env bash

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

if [[ "$DRY_RUN" != "true" && "$DRY_RUN" != "false" ]]; then
  echo "::error::'dry-run' must be set to \"true\" or \"false\"."
  exit 1
fi

if [[ -z "$PUBLISH_NPM_TAG" ]]; then
  echo "::error::'npm-tag' not set."
  exit 1
fi

if [[ -n "$GITHUB_SHA" && -n "$GITHUB_REPOSITORY" ]]; then
  pr_url=$(gh api "/repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA/pulls" \
    --jq '.[0].html_url // empty' 2>/dev/null || true)

  if [[ -n "$pr_url" ]]; then
    echo "Notice: Releasing via pull request: $pr_url"
  fi

  # Used by the script that publishes tarballs, for its release details.
  export PULL_REQUEST_URL="$pr_url"
fi

echo "Notice: Publishing the tarballs packed by the pack action."
"$script_path/publish-tarballs.sh"

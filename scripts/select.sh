#!/usr/bin/env bash

# Prints the locations of the packages to release, one per line.
#
# A package is selected when its `version` in `HEAD` differs from its version
# in the base commit, which includes new packages. Private packages and
# packages with version `0.0.0` are never selected. Selecting from the Git
# history, instead of from what is published on npm, keeps a release from
# including packages that were released by an earlier commit.
#
# The base commit is `$SELECT_BASE`, which is expected to be
# `github.event.before` for a push. If it's empty or all zeros (e.g., for the
# first push of a branch, or for events other than a push), the parent of
# `HEAD` (`HEAD^`) is used. The script fetches the base commit if it isn't
# available, and fails if it can't, rather than selecting everything.
#
# Run `sanitize.sh` before this script, so that Yarn doesn't load any
# configuration from the repository.

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# shellcheck source=scripts/environment.sh
source "$script_path/environment.sh"

base="${SELECT_BASE:-}"

# `github.event.before` is all zeros for the first push of a branch, and empty
# for events that aren't a push.
if [[ -z "$base" || "$base" =~ ^0+$ ]]; then
  base="HEAD^"
fi

if ! base_commit="$(git rev-parse --verify --quiet "${base}^{commit}")"; then
  # Only the manifests at the base commit are needed, not its history, so a
  # shallow fetch is enough. Fetching `HEAD` with a depth of 2 includes its
  # parent.
  if [[ "$base" = "HEAD^" ]]; then
    fetch_depth=2
    fetch_ref="$(git rev-parse HEAD)"
    resolved="HEAD^"
  else
    fetch_depth=1
    fetch_ref="$base"
    resolved="FETCH_HEAD"
  fi

  if ! git fetch --quiet --no-tags --depth="$fetch_depth" \
    "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$fetch_ref" 2> /dev/null \
    || ! base_commit="$(git rev-parse --verify --quiet "${resolved}^{commit}")"; then
    echo "::error::The base commit \"$base\" is not available and could not be fetched." >&2
    exit 1
  fi
fi

echo "Notice: Selecting packages with a different version than in ${base_commit}." >&2

# Prints the version of the package at `$2` in commit `$1`, or nothing if the
# package doesn't exist there.
read_version() {
  local commit="$1"
  local location="$2"
  local path manifest

  # The `./` makes the path relative to the working directory, and not to the
  # root of the repository.
  if [[ "$location" = "." ]]; then
    path="./package.json"
  else
    path="./${location#./}/package.json"
  fi

  if manifest="$(git show "$commit:$path" 2>/dev/null)"; then
    jq --raw-output '.version // empty' <<< "$manifest"
  fi
}

workspaces="$(yarn workspaces list --json --no-private)"
workspace_locations="$(jq --raw-output '.location' <<< "$workspaces")"

locations=()
if [[ -n "$workspace_locations" ]]; then
  mapfile -t locations <<< "$workspace_locations"
fi

for location in "${locations[@]}"; do
  current="$(read_version HEAD "$location")"
  previous="$(read_version "$base_commit" "$location")"

  if [[ -z "$current" || "$current" = "0.0.0" || "$current" = "$previous" ]]; then
    continue
  fi

  echo "Notice: Selected $location (${previous:-new} -> $current)." >&2
  echo "$location"
done

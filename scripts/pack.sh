#!/usr/bin/env bash

# Packs packages into tarballs with `yarn pack`.
#
# Usage: pack.sh <output-directory> [location...]
#
# Without locations, every public workspace is packed (in a polyrepo, the root
# is the only workspace). Tarballs are named `<name>-<version>.tgz`, where the
# `/` in scoped package names is replaced with `-`.
#
# Lifecycle scripts that run when packing or publishing are removed from each
# manifest before packing. Run `sanitize.sh` before this script, so that Yarn
# doesn't load any configuration from the repository.

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# shellcheck source=scripts/environment.sh
source "$script_path/environment.sh"

if [[ $# -lt 1 || -z "$1" ]]; then
  echo "::error::Usage: pack.sh <output-directory> [location...]" >&2
  exit 1
fi

output_directory="$1"
shift

locations=("$@")

if [[ ${#locations[@]} -eq 0 ]]; then
  # The output is captured in a variable first, because the exit status of a
  # process substitution is ignored, so a failing `yarn` would go unnoticed.
  workspaces="$(yarn workspaces list --json --no-private)"
  workspace_locations="$(jq --raw-output '.location' <<< "$workspaces")"

  # `mapfile` turns empty input into an array with one empty element.
  if [[ -n "$workspace_locations" ]]; then
    mapfile -t locations <<< "$workspace_locations"
  fi
fi

if [[ ${#locations[@]} -eq 0 ]]; then
  echo "::error::No packages found to pack."
  exit 1
fi

mkdir -p "$output_directory"
output_directory="$(cd "$output_directory" && pwd -P)"

for location in "${locations[@]}"; do
  manifest="$location/package.json"

  stripped="$(jq '
    if .scripts then
      .scripts |= with_entries(select(.key | test("^(pre|post)?(pack|publish|prepare)$") | not))
    else
      .
    end
  ' "$manifest")"
  echo "$stripped" > "$manifest"

  name="$(jq --raw-output '.name' "$manifest")"
  echo "::group::Packing $name"
  (cd "$location" && yarn pack --out "$output_directory/%s-%v.tgz")
  echo "::endgroup::"
done

echo "Notice: Packed ${#locations[@]} package(s) to $output_directory."

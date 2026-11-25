#!/usr/bin/env bash

# Packs packages into tarballs with `yarn pack`.
#
# Usage: pack.sh <output-directory> <location>...
#
# At least one location is required, and each is the directory of a package
# (`.` for a polyrepo). Tarballs are named `<name>-<version>.tgz`, where the `/`
# in scoped package names is replaced with `-`.
#
# Run `sanitize.sh` before this script, so that Yarn doesn't load any
# configuration from the repository, and lifecycle scripts are removed from the
# manifests.

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# shellcheck source=scripts/environment.sh
source "$script_path/environment.sh"

if [[ $# -lt 1 || -z "$1" ]]; then
  echo "::error::Usage: pack.sh <output-directory> <location>..." >&2
  exit 1
fi

output_directory="$1"
shift

locations=("$@")

# An empty list is an error rather than "all packages", so that a failed
# selection can't result in packing everything.
if [[ ${#locations[@]} -eq 0 ]]; then
  echo "::error::No package locations provided."
  exit 1
fi

mkdir -p "$output_directory"
output_directory="$(cd "$output_directory" && pwd -P)"

for location in "${locations[@]}"; do
  name="$(jq --raw-output '.name' "$location/package.json")"
  echo "::group::Packing $name"
  (cd "$location" && yarn pack --out "$output_directory/%s-%v.tgz")
  echo "::endgroup::"
done

echo "Notice: Packed ${#locations[@]} package(s) to $output_directory."

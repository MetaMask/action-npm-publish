#!/usr/bin/env bash

# Selects the packages to release, and packs them into `$TARBALLS_DIRECTORY`
# with `yarn pack`. The dry run runs this script, and uploads the tarballs as an
# artifact for the job that publishes them.
#
# The packages are the ones whose `version` differs from the version in a base
# commit (see `select.sh`). It's an error if there are none, because a release
# commit always releases a package, and packing everything instead could
# release packages that nobody meant to release.
#
# The tarballs are named `<name>-<version>.tgz`, where the `/` in scoped package
# names is replaced with `-`. `$TARBALLS_DIRECTORY` must be empty or not exist,
# so that tarballs from an earlier step can't end up in the output.
#
# Run `sanitize.sh` before this script, so that Yarn doesn't load any
# configuration from the repository, and lifecycle scripts are removed from the
# manifests.
#
# Outputs `checksums`, which is the output of `list-tarballs.sh` for the
# tarballs, if `$GITHUB_OUTPUT` is set.

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# shellcheck source=scripts/environment.sh
source "$script_path/environment.sh"

IFS='.' read -r yarn_major yarn_minor _ <<< "$(yarn --version)"
if [[ "$yarn_major" -lt 4 || ( "$yarn_major" -eq 4 && "$yarn_minor" -lt 16 ) ]]; then
  echo "::error::Yarn version 4.16.0 or higher is required. Detected version: $(yarn --version)."
  exit 1
fi

selected="$("$script_path/select.sh")"
if [[ -z "$selected" ]]; then
  echo "::error::No packages to release: no package has a version that differs from the base commit."
  exit 1
fi

mapfile -t locations <<< "$selected"

# The tarballs are uploaded and published as they are, so the directory must not
# contain anything that an earlier step in the job put there.
output_directory="${TARBALLS_DIRECTORY:?}"
if [[ -d "$output_directory" && -n "$(ls -A "$output_directory")" ]]; then
  echo "::error::The output directory \"$output_directory\" is not empty."
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

checksums="$("$script_path/list-tarballs.sh" "$output_directory")"

echo "::group::Checksums"
echo "$checksums"
echo "::endgroup::"

if [[ -n "$GITHUB_OUTPUT" ]]; then
  # The delimiter is random so that a value can't end the output early.
  delimiter="EOF_$(openssl rand -hex 16)"
  {
    echo "checksums<<${delimiter}"
    echo "${checksums}"
    echo "${delimiter}"
  } >> "$GITHUB_OUTPUT"
fi

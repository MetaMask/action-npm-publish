#!/usr/bin/env bash

# Prints a line for each tarball in a directory, in the form
# `<name>@<version> <integrity>`, sorted, where `<integrity>` is the SHA-512 of
# the tarball (`sha512-<base64>`, as in the npm registry).
#
# Usage: list-tarballs.sh <directory>
#
# The dry run outputs this list after packing, and the job that publishes
# compares it to the tarballs it downloaded, so that tarballs that were added,
# removed, or replaced after the dry run are not published.
#
# The name and the version come from a tarball that may not be trusted, and
# they are printed to the log and to the job summary. They must match a
# conservative pattern (narrower than what npm accepts), which has no
# whitespace or control characters.

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

if [[ $# -ne 1 || ! -d "$1" ]]; then
  echo "::error::Usage: list-tarballs.sh <directory>" >&2
  exit 1
fi

name_pattern='^(@[a-z0-9][a-z0-9._-]*/)?[a-z0-9][a-z0-9._-]*$'
version_pattern='^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'

shopt -s nullglob

lines=()
for tarball in "$1"/*.tgz; do
  name="$(tar -xzOf "$tarball" package/package.json | jq --raw-output '.name | strings')"
  version="$(tar -xzOf "$tarball" package/package.json | jq --raw-output '.version | strings')"

  if [[ ! "$name" =~ $name_pattern || ! "$version" =~ $version_pattern ]]; then
    echo "::error::$(basename "$tarball") has a package name or version that is not allowed." >&2
    exit 1
  fi

  integrity="sha512-$(openssl dgst -sha512 -binary "$tarball" | openssl base64 -A)"
  lines+=("${name}@${version} ${integrity}")
done

if [[ ${#lines[@]} -gt 0 ]]; then
  printf '%s\n' "${lines[@]}" | LC_ALL=C sort
fi

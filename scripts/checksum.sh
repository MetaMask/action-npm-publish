#!/usr/bin/env bash

# Prints the checksum and integrity of a tarball, and adds them to the job
# summary if one is available.
#
# Usage: checksum.sh <tarball> <package-name>

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

tarball="$1"
package_name="$2"

if [[ -z "$tarball" || -z "$package_name" ]]; then
  echo "::error::Usage: checksum.sh <tarball> <package-name>" >&2
  exit 1
fi

checksum=$(shasum -a 1 "$tarball" | cut -d' ' -f1)
integrity="sha512-$(openssl dgst -sha512 -binary "$tarball" | openssl base64 -A)"

echo "Checksum: $checksum"
echo "Integrity: $integrity"

if [[ -n "$GITHUB_STEP_SUMMARY" ]]; then
  {
    echo "### $package_name"
    echo
    echo "- Checksum: \`$checksum\`"
    echo "- Integrity: \`$integrity\`"
    echo
  } >> "$GITHUB_STEP_SUMMARY"
fi

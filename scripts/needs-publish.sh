#!/usr/bin/env bash

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

# Tolerate empty invocations (e.g., `xargs` with no input).
if [[ $# -eq 0 ]]; then
  exit 0
fi

name="$1"
local_version="$2"

if [[ -z "$name" || "$name" = "null" ]]; then
  echo "::error::Missing package name." >&2
  exit 1
fi

if [[ -z "$local_version" || "$local_version" = "null" ]]; then
  echo "::error::Missing version for package '$name'." >&2
  exit 1
fi

if [[ "$local_version" = "0.0.0" ]]; then
  exit 0
fi

# Check whether this exact version is already published. Note that we're
# `cd`ing into /tmp before running `npm view` to avoid any issues with
# Corepack detecting Yarn.
if (cd /tmp && npm view "$name@$local_version" version --workspaces false --json >/dev/null 2>&1); then
  exit 0
fi

echo "$name"

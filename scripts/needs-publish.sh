#!/usr/bin/env bash

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

name="$1"
local_version="$2"

# Tolerate empty invocations (e.g., `xargs` with no input).
if [[ -z "$name" ]]; then
  exit 0
fi

if [[ -z "$local_version" ]]; then
  echo "::error::Missing version for package '$name'." >&2
  exit 1
fi

if [[ "$local_version" = "0.0.0" ]]; then
  exit 0
fi

# Get the published version for the specified tag, if it exists. Note that
# we're `cd`ing into /tmp before running `npm view` to avoid any issues with
# Corepack detecting Yarn.
published=$(
  cd /tmp \
    && npm view "$name" dist-tags --workspaces false --json 2>/dev/null \
    | jq --raw-output --arg tag "$PUBLISH_NPM_TAG" '.[$tag] // empty' \
    || echo ""
)

if [[ "$published" != "$local_version" ]]; then
  echo "$name"
fi

#!/bin/bash

set -euo pipefail

current_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ $current_branch == release/* ]]; then
  exec yarn auto-changelog validate --rc
else
  exec yarn auto-changelog validate
fi

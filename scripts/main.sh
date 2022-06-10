#!/usr/bin/env bash

set -x
set -e
set -o pipefail

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

"${script_path}"/config_set.sh

"${script_path}"/monorepo.sh

"${script_path}"/publish.sh

#!/usr/bin/env bash

set -x
set -e
set -o pipefail

./config_set.sh

./monorepo.sh

./publish.sh

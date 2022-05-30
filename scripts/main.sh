#!/usr/bin/env bash

set -x
set -e
set -o pipefail

./config_set.sh

./detect.sh

./publish.sh

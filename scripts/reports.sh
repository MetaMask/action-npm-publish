#!/usr/bin/env bash

set -x
set -e
set -o pipefail

directory="/tmp"

for file in "$directory"/*.tgz; do
    if [ -f "$file" ]; then
        echo "Processing $file"
        basename=$(basename "$file")
        name="${basename%-*}"
        name_with_slash="${name/-//}"
        echo "$name_with_slash"
        pkdiff "$name_with_slash@latest" "$file" \
            --no-exit-code \
            --no-open \
            --output "/tmp/$basename.html"
    fi
done
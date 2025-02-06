#!/usr/bin/env bash

set -x
set -e
set -o pipefail

directory="/tmp"

for file in "$directory"/*.tgz; do
    if [ -f "$file" ]; then
        echo "Processing $file"
        basename=$(basename "$file")
        name="$(tar -O -zxf "$file" package/package.json | jq --raw-output .name)"
        echo "$name"
        pkdiff "$file" "$name@latest" \
            --no-exit-code \
            --no-open \
            --output "$directory/$basename.html" || true
    fi
done

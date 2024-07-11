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

        LATEST_PACKAGE_VERSION=$(npm view "$name" dist-tags --workspaces false --json | jq --raw-output '.latest' || echo "")

        # Skip if the package is not published
        if [ -z "$LATEST_PACKAGE_VERSION" ]; then
            echo "Skipping $file, because $name is not published on NPM"
            continue
        fi

        echo "$name"
        pkdiff "$name@latest" "$file" \
            --no-exit-code \
            --no-open \
            --output "$directory/$basename.html"
    fi
done

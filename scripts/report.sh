#!/usr/bin/env bash

if [ "${RUNNER_DEBUG}" = "1" ]; then
  set -x
fi

set -e
set -o pipefail

directory="/tmp"

for file in "$directory"/*.tgz; do
    if [ -f "$file" ]; then
        echo "Processing $file"
        basename=$(basename "$file")
        name="$(tar -O -zxf "$file" package/package.json | jq --raw-output .name)"
        echo "$name"

        checksum=$(shasum -a 1 "$file" | cut -d' ' -f1)
        integrity="sha512-$(openssl dgst -sha512 -binary "$file" | openssl base64 -A)"
        echo "Checksum: $checksum"
        echo "Integrity: $integrity"
        if [[ -n "$GITHUB_STEP_SUMMARY" ]]; then
            {
                echo "### $name"
                echo
                echo "- Checksum: \`$checksum\`"
                echo "- Integrity: \`$integrity\`"
                echo
            } >> "$GITHUB_STEP_SUMMARY"
        fi

        pkdiff "$file" "$name@latest" \
            --no-exit-code \
            --no-open \
            --output "$directory/$basename.html" || true
    fi
done

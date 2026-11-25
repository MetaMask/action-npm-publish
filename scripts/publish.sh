#!/usr/bin/env bash

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

check_requirements() {
  CURRENT_PACKAGE_VERSION=$(jq --raw-output .version package.json)
  if [[ "$CURRENT_PACKAGE_VERSION" = "0.0.0" ]]; then
    echo "Notice: Invalid version: $CURRENT_PACKAGE_VERSION. Aborting publish."
    exit 0
  fi
}

get_package_info() {
  PACKAGE_NAME=$(jq --raw-output .name package.json)

  # Check whether the package exists on npm at all. Note that we're `cd`ing
  # into /tmp before running `npm view` to avoid any issues with Corepack
  # detecting Yarn.
  PUBLISHED_PACKAGE_VERSION=$(cd /tmp && npm view "$PACKAGE_NAME" --workspaces false --json 2>/dev/null | jq --raw-output '.version // empty' || echo "")
}

configure_publish() {
  PACK_CMD="yarn pack --out /tmp/%s-%v.tgz"

  # Build publish flags for OIDC publishing.
  PUBLISH_FLAGS=("--tag" "$PUBLISH_NPM_TAG")
  [[ "$STAGED_PUBLISH" = "true" ]] && PUBLISH_FLAGS+=("--staged")
  [[ "$PROVENANCE" = "true" && "$REPOSITORY_VISIBILITY" = "public" ]] && PUBLISH_FLAGS+=("--provenance")

  # Determine the publish command. `DRY_RUN` is `true` or `false`, which is
  # validated before this script runs:
  # 1. If `DRY_RUN` is `true`, perform a dry run.
  # 2. If the package has not been published before, abort with an error. OIDC
  #    can only be configured for a package that exists on npm.
  # 3. If OIDC is not available, abort with an error. Otherwise, use OIDC to
  #    publish.
  if [[ "$DRY_RUN" = "true" ]]; then
    echo "Notice: Performing a dry run."
  elif [[ -z "$PUBLISHED_PACKAGE_VERSION" ]]; then
    echo "::error::${PACKAGE_NAME} has not been published before. Publish it once manually, and configure OIDC for it."
    exit 1
  else
    if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_URL" ]]; then
      echo "::error:: OIDC is not available for publish."
      exit 1
    fi

    echo "Notice: Using OIDC to publish."
    PUBLISH_CMD="yarn npm publish ${PUBLISH_FLAGS[*]}"
  fi
}

publish() {
  if [[ "$DRY_RUN" = "true" ]]; then
    $PACK_CMD
  else
    $PUBLISH_CMD
  fi
}

report() {
  # Yarn's `%s` placeholder is the package name with `/` replaced by `-`. The
  # leading `@` of scoped packages is kept.
  local slug="${PACKAGE_NAME//\//-}"
  local tarball="/tmp/$slug-$CURRENT_PACKAGE_VERSION.tgz"

  local checksum integrity
  checksum=$(shasum -a 1 "$tarball" | cut -d' ' -f1)
  integrity="sha512-$(openssl dgst -sha512 -binary "$tarball" | openssl base64 -A)"

  echo "Checksum: $checksum"
  echo "Integrity: $integrity"

  if [[ -n "$GITHUB_STEP_SUMMARY" ]]; then
    {
      echo "### $PACKAGE_NAME"
      echo
      echo "- Checksum: \`$checksum\`"
      echo "- Integrity: \`$integrity\`"
      echo
    } >> "$GITHUB_STEP_SUMMARY"
  fi
}

main() {
  check_requirements
  get_package_info
  configure_publish
  publish

  if [[ "$DRY_RUN" = "true" ]]; then
    report
  fi
}

main "$@"

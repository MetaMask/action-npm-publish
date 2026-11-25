#!/usr/bin/env bash

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

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
  # 2. If the package has not been published before, use the provided token for
  #    the initial publish. Abort with an error if there is no token.
  # 3. If the package has already been published, use OIDC to publish. Abort
  #    with an error if OIDC is not available.
  if [[ "$DRY_RUN" = "true" ]]; then
    echo "Notice: Performing a dry run."
  elif [[ -z "$PUBLISHED_PACKAGE_VERSION" ]]; then
    if [[ -z "$YARN_NPM_AUTH_TOKEN" ]]; then
      echo "::error::'npm-token' not provided for initial publish."
      exit 1
    fi

    echo "Notice: Package not yet published. Using npm token for initial publish."
    PUBLISH_CMD="yarn npm publish --tag $PUBLISH_NPM_TAG"
  else
    # Unset auth token because it can interfere with OIDC publishing (see #123)
    unset YARN_NPM_AUTH_TOKEN
    if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_URL" ]]; then
      echo "::error:: OIDC is not available for publish."
      exit 1
    fi

    echo "Notice: Initial package version already published. Using OIDC to publish."
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

  "$script_path/checksum.sh" "$tarball" "$PACKAGE_NAME"
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

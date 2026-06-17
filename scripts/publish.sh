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

  # Determine the publish command and whether to perform a dry run. It works
  # as follows:
  # 1. If `DRY_RUN` is explicitly set to `true`, perform a dry run.
  # 2. If the package has not been published before and a token has been
  #    provided, use the provided token for the initial publish.
  # 3. If the package has not been published before and a token has not been
  #    provided, perform a dry run.
  # 4. If the package has already been published and OIDC is available, use
  #    OIDC to publish.
  # 5. If the package has already been published and OIDC is not available,
  #    perform a dry run.
  #
  # If `DRY_RUN` is explicitly set to `false` and a publish is attempted
  # without necessary authorization, abort with an error.
  if [[ $DRY_RUN = "true" ]]; then
    echo "Notice: Performing a dry run."
  elif [[ -z "$PUBLISHED_PACKAGE_VERSION" ]]; then
    if [[ -z "$YARN_NPM_AUTH_TOKEN" && "$DRY_RUN" = "false" ]]; then
      echo "::error::'npm-token' not provided for initial publish."
      exit 1
    elif [[ -z "$YARN_NPM_AUTH_TOKEN" ]]; then
      echo "Notice: Token is not available for initial publish. Performing a dry run."
      DRY_RUN="true"
    else
      echo "Notice: Package not yet published. Using npm token for initial publish."
      PUBLISH_CMD="yarn npm publish --tag $PUBLISH_NPM_TAG"
      DRY_RUN="false"
    fi
  else
    # Unset auth token because it can interfere with OIDC publishing (see #123)
    unset YARN_NPM_AUTH_TOKEN
    if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_URL" && "$DRY_RUN" = "false" ]]; then
      echo "::error:: OIDC is not available for publish."
      exit 1
    elif [[ -z "$ACTIONS_ID_TOKEN_REQUEST_URL" ]]; then
      echo "Notice: OIDC is not available. Performing a dry run."
      DRY_RUN="true"
    else
      echo "Notice: Initial package version already published. Using OIDC to publish."
      PUBLISH_CMD="yarn npm publish ${PUBLISH_FLAGS[*]}"
      DRY_RUN="false"
    fi
  fi

  # Export the "dry-run" status for use in subsequent steps, if GITHUB_OUTPUT is
  # available.
  if [[ -n "$GITHUB_OUTPUT" ]]; then
    echo "dry-run=$DRY_RUN" >> "$GITHUB_OUTPUT"
  fi
}

publish() {
  if [[ "$DRY_RUN" = "true" ]]; then
    $PACK_CMD
  else
    $PUBLISH_CMD
  fi
}

main() {
  check_requirements
  get_package_info
  configure_publish
  publish
}

main "$@"

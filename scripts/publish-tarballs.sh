#!/usr/bin/env bash

# Publishes the tarballs in `$TARBALLS_DIRECTORY`, which the `pack` action
# packed in an earlier job. No checkout and no Yarn is needed, and no code from
# the repository runs: each tarball is validated, and published as it is with
# `npm publish --ignore-scripts`.
#
# The tarballs come from another job, so they are treated as untrusted input.
# A tarball is only published if it:
#
# 1. Is a valid tarball, which only contains files in a `package/` directory.
# 2. Contains exactly one `package/package.json`, with a name and a version,
#    which is not private.
# 3. Doesn't change where it is published to: `publishConfig` may only set
#    `access` and `registry`, and `registry` must be
#    `https://registry.npmjs.org`.
#
# Packages that are not published, because of a dry run, are reported for
# review instead: the checksum and the list of files in each tarball.

set -e
set -o pipefail

if [ "$RUNNER_DEBUG" = "1" ]; then
  set -x
fi

registry="https://registry.npmjs.org/"

script_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
directory="$(cd "${TARBALLS_DIRECTORY:?}" && pwd -P)"

# Prints a field of the manifest in a tarball (`$1`), using a `jq` filter (`$2`).
read_manifest() {
  tar -xzOf "$1" package/package.json | jq --raw-output "$2"
}

# Prints what is released (`name@version` for each package in the arguments), to
# the log and to the top of the job summary, with a link to the pull request if
# there is one.
report_release() {
  local packages=("$@")

  local list
  printf -v list '%s, ' "${packages[@]}"
  echo "Notice: Publishing ${#packages[@]} package(s): ${list%, }."

  if [[ -n "$GITHUB_STEP_SUMMARY" ]]; then
    {
      echo "## Release details"
      echo

      if [[ -n "$PULL_REQUEST_URL" ]]; then
        echo "**Pull request:** ${PULL_REQUEST_URL}"
        echo
      fi

      echo "**Packages (${#packages[@]}):**"
      echo
      printf -- "- \`%s\`\n" "${packages[@]}"
      echo
    } >> "$GITHUB_STEP_SUMMARY"
  fi
}

# Prints the contents of a package that is not published, so they can be
# reviewed: the checksum and integrity of the tarball, and the files in it, to
# the log and to the job summary.
report_package() {
  local tarball="$1"
  local name="$2"
  local version="$3"

  # Separates the package from the one before it in the job summary.
  if [[ -n "$GITHUB_STEP_SUMMARY" ]]; then
    printf -- '---\n\n' >> "$GITHUB_STEP_SUMMARY"
  fi

  "$script_path/checksum.sh" "$tarball" "${name}@${version}"

  # Directories are left out, and so is the `package/` that every path starts
  # with. `grep` fails if there are no files, which isn't an error here.
  local files count
  files="$(tar -tzf "$tarball" | grep -v '/$' | sed 's,^package/,,' | sort || true)"
  count="$(grep -c . <<< "$files" || true)"

  echo "::group::Files in ${name}@${version} (${count})"
  echo "$files"
  echo "::endgroup::"

  if [[ -n "$GITHUB_STEP_SUMMARY" ]]; then
    {
      echo "#### Files (${count})"
      echo
      echo '```'
      echo "$files"
      echo '```'
      echo
    } >> "$GITHUB_STEP_SUMMARY"
  fi
}

shopt -s nullglob
tarballs=("$directory"/*.tgz)

if [[ ${#tarballs[@]} -eq 0 ]]; then
  echo "::error::No tarballs found in \"$directory\"."
  exit 1
fi

has_invalid_tarballs="false"

for tarball in "${tarballs[@]}"; do
  file="$(basename "$tarball")"

  if ! entries="$(tar -tzf "$tarball")"; then
    echo "::error::${file} isn't a valid tarball."
    has_invalid_tarballs="true"
    continue
  fi

  if grep -qv '^package/' <<< "$entries" || grep -qE '//|(^|/)\.\.?(/|$)' <<< "$entries"; then
    echo "::error::${file} contains unexpected paths."
    has_invalid_tarballs="true"
    continue
  fi

  if [[ "$(grep -cx 'package/package.json' <<< "$entries")" -ne 1 ]]; then
    echo "::error::${file} must contain exactly one package/package.json."
    has_invalid_tarballs="true"
    continue
  fi

  if ! tar -xzOf "$tarball" package/package.json | jq --exit-status '
    (.name | type == "string" and length > 0)
    and (.version | type == "string" and length > 0)
    and ((.private // false) | not)
    and ((.publishConfig // {}) | type == "object"
      and (keys - ["access", "registry"] | length == 0)
      and ((.registry // "https://registry.npmjs.org/") | IN("https://registry.npmjs.org", "https://registry.npmjs.org/")))
  ' > /dev/null; then
    echo "::error::${file} has an invalid manifest. It needs a name and a version, can't be private, and \"publishConfig\" may only set \"access\" and \"registry\" (to \"https://registry.npmjs.org\")."
    has_invalid_tarballs="true"
  fi
done

if [[ "$has_invalid_tarballs" = "true" ]]; then
  exit 1
fi

# Find the packages that need to be published.
pending_tarballs=()
pending_packages=()

for tarball in "${tarballs[@]}"; do
  name="$(read_manifest "$tarball" '.name')"
  version="$(read_manifest "$tarball" '.version')"

  if [[ "$version" = "0.0.0" ]]; then
    echo "Notice: Invalid version for ${name}: ${version}. Skipping."
    continue
  fi

  # The version may have been published since the tarball was packed, e.g., by a
  # re-run of a job that failed halfway through, or while this job was waiting
  # for approval.
  needs_publish="$("$script_path/needs-publish.sh" "$name" "$version")"
  if [[ -z "$needs_publish" ]]; then
    echo "Notice: ${name}@${version} is already published. Skipping."
    continue
  fi

  pending_tarballs+=("$tarball")
  pending_packages+=("${name}@${version}")
done

if [[ ${#pending_packages[@]} -gt 0 ]]; then
  report_release "${pending_packages[@]}"
else
  echo "Notice: No packages need publishing."
fi

# npm reads the token from this file, so it's never passed on the command line.
# `${NODE_AUTH_TOKEN}` is expanded by npm, and not by the shell.
npmrc="$(mktemp)"
trap 'rm -f "$npmrc"' EXIT
# shellcheck disable=SC2016
echo '//registry.npmjs.org/:_authToken=${NODE_AUTH_TOKEN}' > "$npmrc"

for tarball in "${pending_tarballs[@]}"; do
  name="$(read_manifest "$tarball" '.name')"
  version="$(read_manifest "$tarball" '.version')"

  # Leaves a blank line around each package in the log.
  echo
  echo "== ${name}@${version} =="

  # Check whether the package exists on npm at all. Note that we're `cd`ing into
  # /tmp before running `npm view` to avoid any issues with Corepack detecting
  # Yarn.
  published_version=$(cd /tmp && npm view "$name" --workspaces false --json 2>/dev/null | jq --raw-output '.version // empty' || echo "")

  # Determine how to publish. `DRY_RUN` is `true` or `false`, which is
  # validated before this script runs:
  # 1. If `DRY_RUN` is `true`, perform a dry run.
  # 2. If the package has not been published before, use the provided token for
  #    the initial publish. Abort with an error if there is no token.
  # 3. If the package has already been published, use OIDC to publish. Abort
  #    with an error if OIDC is not available.
  if [[ "$DRY_RUN" = "true" ]]; then
    echo "Notice: Performing a dry run for ${name}@${version}."
    report_package "$tarball" "$name" "$version"
    continue
  fi

  if [[ -z "$published_version" ]]; then
    if [[ -z "$NPM_TOKEN" ]]; then
      echo "::error::'npm-token' not provided for initial publish of ${name}."
      exit 1
    fi

    echo "Notice: ${name} not yet published. Using npm token for initial publish."
    method="token"
  else
    if [[ -z "$ACTIONS_ID_TOKEN_REQUEST_URL" ]]; then
      echo "::error::OIDC is not available to publish ${name}."
      exit 1
    fi

    echo "Notice: Initial package version of ${name} already published. Using OIDC to publish."
    method="oidc"
  fi

  echo "::group::Publishing ${name}@${version}"

  if [[ "$method" = "token" ]]; then
    (
      cd /tmp
      NODE_AUTH_TOKEN="$NPM_TOKEN" npm_config_userconfig="$npmrc" \
        npm publish "$tarball" --tag "$PUBLISH_NPM_TAG" --ignore-scripts --registry "$registry"
    )
  else
    flags=(--tag "$PUBLISH_NPM_TAG" --ignore-scripts --registry "$registry")
    [[ "$PROVENANCE" = "true" && "$REPOSITORY_VISIBILITY" = "public" ]] && flags+=(--provenance)

    subcommand=(publish)
    [[ "$STAGED_PUBLISH" = "true" ]] && subcommand=(stage publish)

    # Unset the auth token and use an empty user configuration, because a token
    # can interfere with OIDC publishing (see #123).
    (
      cd /tmp
      env -u NODE_AUTH_TOKEN -u NPM_TOKEN npm_config_userconfig=/dev/null \
        npm "${subcommand[@]}" "$tarball" "${flags[@]}"
    )
  fi

  echo "::endgroup::"
done

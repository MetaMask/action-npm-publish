#!/usr/bin/env bash

# Yarn settings can be overridden with `YARN_*` environment variables, which
# take precedence over the configuration file that the action controls (e.g.,
# `YARN_NPM_PUBLISH_REGISTRY`). Unset all of them, except the ones the action
# itself sets or needs. This file is meant to be sourced.

for name in $(compgen -e | grep '^YARN_' || true); do
  case "$name" in
    YARN_NPM_AUTH_TOKEN | YARN_RC_FILENAME | YARN_IGNORE_PATH) ;;
    *) unset "$name" ;;
  esac
done

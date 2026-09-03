#!/usr/bin/env bash

set -euo pipefail

installed_version="$1"
resolved_version="$2"

if [ -n "${resolved_version}" ] && [ "${installed_version}" != "t3 v${resolved_version}" ]; then
    printf "ERROR: Installed T3 Code version '%s' does not match resolved version '%s'.\n" \
        "${installed_version}" "${resolved_version}" >&2
    exit 1
fi

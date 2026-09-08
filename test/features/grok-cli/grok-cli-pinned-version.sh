#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

FEATURE_USER=root
if id -u vscode >/dev/null 2>&1; then
    FEATURE_USER=vscode
fi
USER_HOME="$(getent passwd "${FEATURE_USER}" | cut -d: -f6)"
GROK="${USER_HOME}/.grok/bin/grok"
GROK_VERSION="$(env HOME="${USER_HOME}" "${GROK}" --version)"

check "requested grok version is installed" test "${GROK_VERSION%% (*}" = "grok 1.0.13"
check "pinned grok executable is user-owned" test "$(stat -c %U "$(readlink -f "${GROK}")")" = "${FEATURE_USER}"

reportResults

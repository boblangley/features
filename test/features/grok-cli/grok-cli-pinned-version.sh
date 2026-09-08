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

requested_version_installed() {
    [[ "$1" =~ (^|[^0-9])1\.0\.13([^0-9]|$) ]]
}

check "grok command exists" test -x "${GROK}"
GROK_VERSION="$(env HOME="${USER_HOME}" "${GROK}" --version)"
check "requested grok version is installed" requested_version_installed "${GROK_VERSION}"
check "pinned grok executable is user-owned" test "$(stat -c %U "$(readlink -f "${GROK}")")" = "${FEATURE_USER}"

reportResults

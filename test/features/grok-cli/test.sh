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

check "grok command exists" test -x "${GROK}"
check "grok version works as user" env HOME="${USER_HOME}" "${GROK}" --version
check "grok executable is user-owned" test "$(stat -c %U "$(readlink -f "${GROK}")")" = "${FEATURE_USER}"
check "grok state is user-owned" test "$(stat -c %U "${USER_HOME}/.grok")" = "${FEATURE_USER}"
check "global grok command is only a symlink" test -L /usr/local/bin/grok
check "global grok command targets the user installation" test "$(readlink -f /usr/local/bin/grok)" = "$(readlink -f "${GROK}")"

reportResults

#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

FEATURE_USER=root
if id -u vscode >/dev/null 2>&1; then
    FEATURE_USER=vscode
fi
USER_HOME="$(getent passwd "${FEATURE_USER}" | cut -d: -f6)"
CLAUDE="${USER_HOME}/.local/bin/claude"

check "claude command exists" test -x "${CLAUDE}"
check "claude version works as user" env HOME="${USER_HOME}" "${CLAUDE}" --version
check "claude executable is user-owned" test "$(stat -c %U "$(readlink -f "${CLAUDE}")")" = "${FEATURE_USER}"
check "claude state is user-owned" test "$(stat -c %U "${USER_HOME}/.claude")" = "${FEATURE_USER}"

reportResults

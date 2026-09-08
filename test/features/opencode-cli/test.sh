#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

FEATURE_USER=root
if id -u vscode >/dev/null 2>&1; then
    FEATURE_USER=vscode
fi
USER_HOME="$(getent passwd "${FEATURE_USER}" | cut -d: -f6)"
OPENCODE="${USER_HOME}/.opencode/bin/opencode"

check "opencode command exists" test -x "${OPENCODE}"
check "opencode version works as user" env HOME="${USER_HOME}" "${OPENCODE}" --version
check "opencode executable is user-owned" test "$(stat -c %U "$(readlink -f "${OPENCODE}")")" = "${FEATURE_USER}"
check "opencode installation is user-owned" test "$(stat -c %U "${USER_HOME}/.opencode")" = "${FEATURE_USER}"
check "opencode state is user-owned" test "$(stat -c %U "${USER_HOME}/.local/share/opencode")" = "${FEATURE_USER}"
check "opencode system command targets user installation" test "$(readlink -f /usr/local/bin/opencode)" = "$(readlink -f "${OPENCODE}")"

reportResults

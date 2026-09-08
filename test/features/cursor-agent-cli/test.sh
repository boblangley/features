#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

FEATURE_USER=root
if id -u vscode >/dev/null 2>&1; then
    FEATURE_USER=vscode
fi
USER_HOME="$(getent passwd "${FEATURE_USER}" | cut -d: -f6)"
AGENT="${USER_HOME}/.local/bin/agent"
CURSOR_AGENT="${USER_HOME}/.local/bin/cursor-agent"
FOREIGN_OWNED_ENTRY="$(find "${USER_HOME}/.local/share/cursor-agent" ! -user "${FEATURE_USER}" -print -quit)"

check "agent command exists" test -x "${AGENT}"
check "cursor-agent command exists" test -x "${CURSOR_AGENT}"
check "agent version works as user" env HOME="${USER_HOME}" "${AGENT}" --version
check "cursor-agent version works as user" env HOME="${USER_HOME}" "${CURSOR_AGENT}" --version
check "agent executable is user-owned" test "$(stat -c %U "$(readlink -f "${AGENT}")")" = "${FEATURE_USER}"
check "cursor-agent executable is user-owned" test "$(stat -c %U "$(readlink -f "${CURSOR_AGENT}")")" = "${FEATURE_USER}"
check "cursor installation is user-owned" test "$(stat -c %U "${USER_HOME}/.local/share/cursor-agent")" = "${FEATURE_USER}"
check "cursor installation contains no foreign-owned entries" test -z "${FOREIGN_OWNED_ENTRY}"
check "system agent link targets user installation" test "$(readlink -f /usr/local/bin/agent)" = "$(readlink -f "${AGENT}")"
check "system cursor-agent link targets user installation" test "$(readlink -f /usr/local/bin/cursor-agent)" = "$(readlink -f "${CURSOR_AGENT}")"

reportResults

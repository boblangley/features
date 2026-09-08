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
AGENT="${USER_HOME}/.local/bin/agent"
CURSOR_AGENT="${USER_HOME}/.local/bin/cursor-agent"

check "grok command exists" test -x "${GROK}"
check "cursor agent command exists" test -x "${CURSOR_AGENT}"
check "agent alias remains Cursor Agent" test "$(readlink -f "${AGENT}")" = "$(readlink -f "${CURSOR_AGENT}")"
check "global agent command remains Cursor Agent" test "$(readlink -f /usr/local/bin/agent)" = "$(readlink -f "${CURSOR_AGENT}")"

reportResults

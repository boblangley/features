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

check "pinned OpenCode version is installed" test "$(env HOME="${USER_HOME}" "${OPENCODE}" --version)" = "1.18.25"

reportResults

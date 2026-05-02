#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

USER_HOME="$(getent passwd vscode | cut -d: -f6)"
SCRIPTS="${USER_HOME}/.hindsight/codex/scripts"

scripts_owner="$(stat -c %U "${SCRIPTS}/recall.py" 2>/dev/null || echo missing)"

check "session_start.py installed" test -f "${SCRIPTS}/session_start.py"
check "recall.py installed" test -f "${SCRIPTS}/recall.py"
check "retain.py installed" test -f "${SCRIPTS}/retain.py"
check "lib/client.py installed" test -f "${SCRIPTS}/lib/client.py"
check "hooks.json written" test -f "${USER_HOME}/.codex/hooks.json"
check "hooks.json references recall.py" grep -q recall.py "${USER_HOME}/.codex/hooks.json"
check "config.toml enables codex_hooks" grep -q '^codex_hooks = true' "${USER_HOME}/.codex/config.toml"
check "scripts owned by vscode" test "${scripts_owner}" = "vscode"

reportResults

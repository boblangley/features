#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

USER_HOME="$(getent passwd vscode | cut -d: -f6)"

check "session_start.py installed" bash -c "test -f \"${USER_HOME}/.hindsight/codex/scripts/session_start.py\""
check "recall.py installed" bash -c "test -f \"${USER_HOME}/.hindsight/codex/scripts/recall.py\""
check "retain.py installed" bash -c "test -f \"${USER_HOME}/.hindsight/codex/scripts/retain.py\""
check "lib/client.py installed" bash -c "test -f \"${USER_HOME}/.hindsight/codex/scripts/lib/client.py\""
check "hooks.json written" bash -c "test -f \"${USER_HOME}/.codex/hooks.json\""
check "hooks.json references recall.py" bash -c "grep -q recall.py \"${USER_HOME}/.codex/hooks.json\""
check "config.toml enables codex_hooks" bash -c "grep -q '^codex_hooks = true' \"${USER_HOME}/.codex/config.toml\""
check "scripts owned by vscode" bash -c "[ \"$(stat -c %U \"${USER_HOME}/.hindsight/codex/scripts/recall.py\")\" = \"vscode\" ]"

reportResults

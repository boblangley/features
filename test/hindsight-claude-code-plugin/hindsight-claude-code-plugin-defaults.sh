#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

USER_HOME="$(getent passwd vscode | cut -d: -f6)"
CACHE_DIR="${USER_HOME}/.claude/plugins/cache"
SETTINGS="${USER_HOME}/.claude/settings.json"

check "claude command exists" command -v claude
check "marketplace cache present" test -d "${CACHE_DIR}/hindsight"
check "plugin cache directory exists" bash -c "find \"${CACHE_DIR}\" -mindepth 2 -maxdepth 2 -type d -name hindsight-memory | grep -q ."
check "settings.json exists" test -f "${SETTINGS}"
check "UserPromptSubmit hook registered" grep -q UserPromptSubmit "${SETTINGS}"
check "Stop hook registered" grep -q '"Stop"' "${SETTINGS}"

reportResults

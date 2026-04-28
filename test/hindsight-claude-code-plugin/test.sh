#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

USER_HOME="$(getent passwd vscode | cut -d: -f6)"

check "claude command exists" bash -c "command -v claude"
check "marketplace is registered" bash -c "su vscode -c 'claude plugin marketplace list' | grep -i hindsight"
check "plugin cache directory exists" bash -c "test -d \"${USER_HOME}/.claude/plugins/cache\" && find \"${USER_HOME}/.claude/plugins/cache\" -mindepth 2 -maxdepth 2 -type d -name hindsight-memory | grep ."
check "settings.json exists" bash -c "test -f \"${USER_HOME}/.claude/settings.json\""
check "UserPromptSubmit hook registered" bash -c "grep -q UserPromptSubmit \"${USER_HOME}/.claude/settings.json\""

reportResults

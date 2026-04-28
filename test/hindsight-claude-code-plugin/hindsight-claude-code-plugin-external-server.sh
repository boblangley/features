#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

USER_HOME="$(getent passwd vscode | cut -d: -f6)"
CFG="${USER_HOME}/.hindsight/claude-code.json"

check "hindsight user config exists" bash -c "test -f \"${CFG}\""
check "hindsight config is mode 0600" bash -c "[ \"$(stat -c %a \"${CFG}\")\" = \"600\" ]"
check "hindsight config owned by vscode" bash -c "[ \"$(stat -c %U \"${CFG}\")\" = \"vscode\" ]"
check "hindsight config has external URL" bash -c "grep -q api.hindsight.example.com \"${CFG}\""
check "hindsight config has overridden bankId" bash -c "grep -q ci-test-bank \"${CFG}\""

reportResults

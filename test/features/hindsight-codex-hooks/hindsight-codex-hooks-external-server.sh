#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

USER_HOME="$(getent passwd vscode | cut -d: -f6)"
CFG="${USER_HOME}/.hindsight/codex.json"

mode="$(stat -c %a "${CFG}" 2>/dev/null || echo missing)"
owner="$(stat -c %U "${CFG}" 2>/dev/null || echo missing)"

check "hindsight user config exists" test -f "${CFG}"
check "hindsight config is mode 0600" test "${mode}" = "600"
check "hindsight config owned by vscode" test "${owner}" = "vscode"
check "hindsight config has external URL" grep -q api.hindsight.example.com "${CFG}"
check "hindsight config has overridden bankId" grep -q ci-codex-bank "${CFG}"
check "hooks.json still present" test -f "${USER_HOME}/.codex/hooks.json"

reportResults

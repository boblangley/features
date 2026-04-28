#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "t3 command exists" bash -c "command -v t3"
check "custom host written" bash -c "grep -q '^T3CODE_HOST=127.0.0.1$' /etc/default/t3code"
check "custom port written" bash -c "grep -q '^T3CODE_PORT=4123$' /etc/default/t3code"
check "service user is root" bash -c "grep -q '^User=root$' /etc/systemd/system/t3code.service"
check "codex omitted when disabled" bash -c "! command -v codex >/dev/null 2>&1"

reportResults

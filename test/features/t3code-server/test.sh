#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "t3 command exists" bash -c "command -v t3"
check "t3 version works" bash -c "t3 --version"
check "codex command exists by default" bash -c "command -v codex"
check "launcher exists" bash -c "test -x /usr/local/bin/t3code-server"
check "systemd unit exists" bash -c "test -f /etc/systemd/system/t3code.service"
check "default host written" bash -c "grep -q '^T3CODE_HOST=0.0.0.0$' /etc/default/t3code"
check "default port written" bash -c "grep -q '^T3CODE_PORT=3773$' /etc/default/t3code"
check "unit starts headless service" bash -c "grep -q '^ExecStart=/usr/local/bin/t3code-server$' /etc/systemd/system/t3code.service"

reportResults

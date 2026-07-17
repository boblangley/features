#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "claude command exists" bash -c "command -v claude"
check "claude version works" bash -c "claude --version"
check "claude installed under shared directory" bash -c "ls /usr/local/share/claude-code/claude-* >/dev/null 2>&1"

reportResults

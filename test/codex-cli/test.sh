#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "codex command exists" bash -c "command -v codex"
check "codex version works" bash -c "codex --version"
check "node major is at least 24" bash -c 'node -p "Number(process.versions.node.split(\".\")[0]) >= 24" | grep true'

reportResults

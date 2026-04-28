#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "gemini command exists" bash -c "command -v gemini"
check "gemini version works" bash -c "gemini --version"
check "node major is at least 24" bash -c 'node -p "Number(process.versions.node.split(\".\")[0]) >= 24" | grep true'

reportResults

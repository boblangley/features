#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "Go is installed" go version
check "s6 entrypoint remains installed" test -x /init

reportResults

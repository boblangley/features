#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "fork T3 command exists globally" test -x /usr/local/bin/t3
check "fork tarball links its bin globally" test "$(readlink -f /usr/local/bin/t3)" = /usr/local/lib/node_modules/t3/dist/bin.mjs
check "fork T3 reports the published version" test "$(/usr/local/bin/t3 --version)" = "t3 v0.0.37-wyrd.1"

reportResults

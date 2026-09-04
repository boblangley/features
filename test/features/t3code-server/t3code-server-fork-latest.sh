#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

installed_version="$(/usr/local/bin/t3 --version)"

check "fork T3 command exists globally" test -x /usr/local/bin/t3
check "fork tarball links its bin globally" test "$(readlink -f /usr/local/bin/t3)" = /usr/local/lib/node_modules/t3/dist/bin.mjs
check "latest resolves to a fork build" bash -c "printf '%s\n' '${installed_version}' | grep -Eq '^t3 v[0-9]+\.[0-9]+\.[0-9]+-wyrd\.[0-9]+$'"
check "launcher defaults to the web runtime" grep -qx 'default_mode=web' /usr/local/bin/t3code-server
check "s6 service is registered" test -f /etc/s6-overlay/user-bundles.d/user/contents.d/t3code-server

reportResults

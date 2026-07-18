#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "sshd service is registered" test -f /etc/s6-overlay/user-bundles.d/user/contents.d/sshd
check "sshd is a longrun service" grep -qx longrun /etc/s6-overlay/s6-rc.d/sshd/type
check "sshd runs in the foreground" grep -q 'sshd -D -e' /etc/s6-overlay/s6-rc.d/sshd/run

reportResults

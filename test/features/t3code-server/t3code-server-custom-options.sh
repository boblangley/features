#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "t3 command exists globally" test -x /usr/local/bin/t3
check "custom host configured" grep -q '^default_host=127.0.0.1$' /usr/local/bin/t3code-server
check "custom port configured" grep -q '^default_port=4123$' /usr/local/bin/t3code-server
check "service runs as root" grep -q 's6-setuidgid root' /etc/s6-overlay/s6-rc.d/t3code-server/run
check "SSH agent forwarding can be disabled" test ! -e /etc/s6-overlay/user-bundles.d/user/contents.d/t3code-ssh-agent-link
check "codex is omitted" bash -c "! command -v codex >/dev/null 2>&1"

reportResults

#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "t3 command exists" sudo test -x /root/.local/bin/t3
check "custom host configured" grep -q '^default_host=127.0.0.1$' /usr/local/bin/t3code-server
check "custom port configured" grep -q '^default_port=4123$' /usr/local/bin/t3code-server
check "service runs as root" grep -q 's6-setuidgid root' /etc/s6-overlay/s6-rc.d/t3code-server/run
check "codex is omitted" bash -c "! command -v codex >/dev/null 2>&1"

reportResults

#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "Caddy is installed before T3 writes its fragment" test -x /usr/bin/caddy
check "T3 Caddy fragment exists" test -f /etc/caddy/conf.d/t3code-server.caddy
check "T3 DNS name is configured" grep -q '^t3\.test-container\.example\.test {$' /etc/caddy/conf.d/t3code-server.caddy
check "T3 port is proxied on loopback" grep -q '^    reverse_proxy 127\.0\.0\.1:4123$' /etc/caddy/conf.d/t3code-server.caddy
check "T3 DNS name is registered for startup readiness" grep -qx 't3\.test-container\.example\.test' /etc/caddy/required-hosts.d/t3code-server.host
check "combined Caddy configuration is valid" caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

reportResults

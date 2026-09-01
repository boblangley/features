#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "Caddy is installed before Dagu writes its fragment" test -x /usr/bin/caddy
check "Dagu Caddy fragment exists" test -f /etc/caddy/conf.d/dagu.caddy
check "Dagu DNS name is configured" grep -q '^workflow\.test-container\.example\.test {$' /etc/caddy/conf.d/dagu.caddy
check "Dagu port is proxied on loopback" grep -q '^    reverse_proxy 127\.0\.0\.1:8123$' /etc/caddy/conf.d/dagu.caddy
check "Dagu DNS name is registered for startup readiness" grep -qx 'workflow\.test-container\.example\.test' /etc/caddy/required-hosts.d/dagu.host
check "Dagu public URL follows its Caddy name" grep -q '^export DAGU_PUBLIC_URL=https://workflow\.test-container\.example\.test$' /usr/local/bin/dagu-service
check "combined Caddy configuration is valid" caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

reportResults

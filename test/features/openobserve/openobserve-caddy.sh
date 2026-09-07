#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "Caddy is installed before OpenObserve writes its fragment" test -x /usr/bin/caddy
check "OpenObserve Caddy fragment exists" test -f /etc/caddy/conf.d/openobserve.caddy
check "OpenObserve DNS name is configured" grep -q '^observe\.test-container\.example\.test {$' /etc/caddy/conf.d/openobserve.caddy
check "OpenObserve port is proxied on loopback" grep -q '^    reverse_proxy 127\.0\.0\.1:5180$' /etc/caddy/conf.d/openobserve.caddy
check "OpenObserve DNS name is registered for startup readiness" grep -qx 'observe\.test-container\.example\.test' /etc/caddy/required-hosts.d/openobserve.host
check "OpenObserve public URL follows its Caddy name" grep -q '^export ZO_WEB_URL=https://observe\.test-container\.example\.test$' /usr/local/bin/openobserve-service
check "combined Caddy configuration is valid" caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile

reportResults

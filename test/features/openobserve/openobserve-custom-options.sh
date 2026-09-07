#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "pinned OpenObserve version is installed" bash -c 'openobserve --version | grep -q "0.92.1"'
check "localhost is normalized to IPv4 loopback" grep -q 'export ZO_HTTP_ADDR=127.0.0.1' /usr/local/bin/openobserve-service
check "custom HTTP port is configured" grep -q 'export ZO_HTTP_PORT=5180' /usr/local/bin/openobserve-service
check "custom gRPC port is configured" grep -q 'export ZO_GRPC_PORT=5181' /usr/local/bin/openobserve-service
check "custom service user is configured" grep -q '^exec s6-setuidgid root ' /etc/s6-overlay/s6-rc.d/openobserve/run
check "custom service home is configured" grep -q ' HOME=/root ' /etc/s6-overlay/s6-rc.d/openobserve/run
check "custom root user email is configured" grep -Fq 'export ZO_ROOT_USER_EMAIL=admin@example.org' /usr/local/bin/openobserve-service
check "custom root user password is configured" grep -Fq 'export ZO_ROOT_USER_PASSWORD=CustomPassword#123' /usr/local/bin/openobserve-service
check "custom telemetry is configured" grep -Fq 'export ZO_TELEMETRY=true' /usr/local/bin/openobserve-service

reportResults

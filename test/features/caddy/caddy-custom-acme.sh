#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "custom ACME directory is configured" grep -Fq 'acme_ca "https://acme.example.test/acme/local/directory"' /etc/caddy/Caddyfile
check "custom ACME root is configured" grep -Fq 'acme_ca_root "/etc/ssl/certs/ca-certificates.crt"' /etc/caddy/Caddyfile

reportResults

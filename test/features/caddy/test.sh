#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "caddy is installed" caddy version
check "caddy service is registered" test -f /etc/s6-overlay/user-bundles.d/user/contents.d/caddy
check "watcher service is registered" test -f /etc/s6-overlay/user-bundles.d/user/contents.d/caddy-config-watcher
check "admin uses a Unix socket" grep -Eq '^[[:space:]]+admin unix//run/caddy/admin\.sock$' /etc/caddy/Caddyfile
check "fragment wildcard is imported" grep -q '^import /etc/caddy/conf.d/\*.caddy$' /etc/caddy/Caddyfile
check "fragment directory is setgid" test "$(stat -c %a /etc/caddy/conf.d)" = 2775
check "remote user can manage fragments" bash -c 'id -nG vscode | tr " " "\n" | grep -qx caddy-config'
check "admin socket is not exposed to config authors" bash -c '! id -nG vscode | tr " " "\n" | grep -qx caddy'

reportResults

#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

check "xySat package is installed" test -f /opt/xyops/satellite/package.json
check "xySat bundled runtime is executable" test -x /opt/xyops/satellite/bin/node
check "xySat launcher is executable" test -x /usr/local/bin/xysat-run
check "xySat bootstrap is executable" test -x /usr/local/bin/xysat-bootstrap
check "xySat ownership reconciler is executable" test -x /usr/local/bin/xysat-fix-ownership
check "xySat ownership reconciles after UID remapping" sudo /usr/local/bin/xysat-fix-ownership
check "xySat installation belongs to the service user" test "$(stat -c %U /opt/xyops/satellite)" = vscode
check "xySat service is registered" test -f /etc/s6-overlay/user-bundles.d/user/contents.d/xysat
check "xySat service is a longrun" grep -qx longrun /etc/s6-overlay/s6-rc.d/xysat/type
check "xySat service runs as the service user" grep -q '^exec s6-setuidgid vscode ' /etc/s6-overlay/s6-rc.d/xysat/run
check "xySat service receives the service user's home" grep -q ' HOME=/home/vscode ' /etc/s6-overlay/s6-rc.d/xysat/run
# shellcheck disable=SC2016
check "xySat bootstraps before dropping privileges" bash -c '
    bootstrap_line="$(grep -n xysat-bootstrap /etc/s6-overlay/s6-rc.d/xysat/run | cut -d: -f1)"
    setuid_line="$(grep -n s6-setuidgid /etc/s6-overlay/s6-rc.d/xysat/run | cut -d: -f1)"
    test "${bootstrap_line}" -lt "${setuid_line}"
'
# shellcheck disable=SC2016
check "xySat reconciles ownership before dropping privileges" bash -c '
    ownership_line="$(grep -n xysat-fix-ownership /etc/s6-overlay/s6-rc.d/xysat/run | cut -d: -f1)"
    setuid_line="$(grep -n s6-setuidgid /etc/s6-overlay/s6-rc.d/xysat/run | cut -d: -f1)"
    test "${ownership_line}" -lt "${setuid_line}"
'
# shellcheck disable=SC2016
check "bootstrap reads the API key from a file" grep -q -- '--data-urlencode "t@${normalized_key}"' /usr/local/bin/xysat-bootstrap
check "bootstrap does not use XYOPS_setup" bash -c '! grep -q XYOPS_setup /usr/local/bin/xysat-bootstrap /usr/local/bin/xysat-run'
check "xySat runs in the foreground" grep -q -- '--foreground' /usr/local/bin/xysat-run
# shellcheck disable=SC2016
check "xySat uses the persistent config" grep -q 'XYSAT_config_file="${config_file}"' /usr/local/bin/xysat-run
check "xySat config directory is private" test "$(stat -c %a /etc/xysat)" = 700
check "xySat config belongs to the service user" test "$(stat -c %U /etc/xysat)" = vscode
check "systemd unit is absent" test ! -e /etc/systemd/system/xysat.service

if grep -q '^conductor_url=http://127.0.0.1:18080$' /usr/local/bin/xysat-bootstrap; then
    printf '%s\n' sample-credential >/tmp/sample-credential
    chmod 0400 /tmp/sample-credential
    /opt/xyops/satellite/bin/node "$(dirname "$0")/mock-server.js" &
    mock_server_pid=$!
    trap 'kill "${mock_server_pid}" 2>/dev/null || true' EXIT
    for _ in {1..50}; do
        curl --fail --silent http://127.0.0.1:18080/health >/dev/null && break
        sleep 0.1
    done

    check "automatic registration downloads configuration" sudo /usr/local/bin/xysat-bootstrap
    check "automatic registration writes expected configuration" grep -qx '{"sample":true}' /etc/xysat/config.json
    check "automatic registration gives configuration to service user" test "$(stat -c %U /etc/xysat/config.json)" = vscode
    check "automatic registration keeps configuration private" test "$(stat -c %a /etc/xysat/config.json)" = 600
fi

reportResults

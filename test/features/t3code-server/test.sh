#!/usr/bin/env bash

set -e

# shellcheck disable=SC1091
source dev-container-features-test-lib

T3_HOME="$(getent passwd vscode | cut -d: -f6)"

check "t3 command exists globally" test -x /usr/local/bin/t3
check "t3 version works as service user" env HOME="${T3_HOME}" /usr/local/bin/t3 --version
check "t3 installation is root-owned" test "$(stat -c %U /usr/local/lib/node_modules/t3)" = root
check "t3 is not installed in the service user's local bin" test ! -e "${T3_HOME}/.local/bin/t3"
check "codex is not installed" bash -c "! command -v codex >/dev/null 2>&1"
# shellcheck disable=SC2016
check "launcher uses the service base directory" grep -q -- '--base-dir "${HOME}/.t3"' /usr/local/bin/t3code-server
check "s6 service is registered" test -f /etc/s6-overlay/user-bundles.d/user/contents.d/t3code-server
check "s6 service is a longrun" grep -qx longrun /etc/s6-overlay/s6-rc.d/t3code-server/type
check "SSH agent linker service is registered" test -f /etc/s6-overlay/user-bundles.d/user/contents.d/t3code-ssh-agent-link
check "T3 depends on the SSH agent linker" test -f /etc/s6-overlay/s6-rc.d/t3code-server/dependencies.d/t3code-ssh-agent-link
check "T3 inherits the stable SSH agent path" grep -q 'SSH_AUTH_SOCK=/run/t3code/ssh-agent.sock' /etc/s6-overlay/s6-rc.d/t3code-server/run
# shellcheck disable=SC2016
check "SSH agent linker follows the newest live socket" bash -c '
    first_socket=/tmp/vscode-ssh-auth-test-first.sock
    second_socket=/tmp/vscode-ssh-auth-test-second.sock
    stable_socket=/run/t3code/ssh-agent.sock

    cleanup() {
        kill "${linker_pid:-}" "${first_pid:-}" "${second_pid:-}" 2>/dev/null || true
        wait "${linker_pid:-}" "${first_pid:-}" "${second_pid:-}" 2>/dev/null || true
        rm -f "${first_socket}" "${second_socket}" "${stable_socket}" /tmp/first-agent.env /tmp/second-agent.env
    }
    trap cleanup EXIT

    ssh-agent -a "${first_socket}" -s > /tmp/first-agent.env
    first_pid=$(sed -n "s/^echo Agent pid \([0-9][0-9]*\);$/\1/p" /tmp/first-agent.env)
    /usr/local/bin/t3code-ssh-agent-link >/tmp/t3code-ssh-agent-link.log 2>&1 &
    linker_pid=$!

    for _ in $(seq 1 20); do
        [ "$(readlink "${stable_socket}" 2>/dev/null || true)" = "${first_socket}" ] && break
        sleep 0.1
    done
    [ "$(readlink "${stable_socket}")" = "${first_socket}" ]

    sleep 1
    ssh-agent -a "${second_socket}" -s > /tmp/second-agent.env
    second_pid=$(sed -n "s/^echo Agent pid \([0-9][0-9]*\);$/\1/p" /tmp/second-agent.env)
    for _ in $(seq 1 20); do
        [ "$(readlink "${stable_socket}" 2>/dev/null || true)" = "${second_socket}" ] && break
        sleep 0.1
    done
    [ "$(readlink "${stable_socket}")" = "${second_socket}" ]

    kill "${second_pid}"
    wait "${second_pid}" 2>/dev/null || true
    second_pid=
    for _ in $(seq 1 20); do
        [ "$(readlink "${stable_socket}" 2>/dev/null || true)" = "${first_socket}" ] && break
        sleep 0.1
    done
    [ "$(readlink "${stable_socket}")" = "${first_socket}" ]

    kill "${first_pid}"
    wait "${first_pid}" 2>/dev/null || true
    first_pid=
    for _ in $(seq 1 20); do
        [ ! -L "${stable_socket}" ] && break
        sleep 0.1
    done
    [ ! -L "${stable_socket}" ]
'
check "systemd unit is absent" test ! -e /etc/systemd/system/t3code.service

reportResults

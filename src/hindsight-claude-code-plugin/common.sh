#!/usr/bin/env bash

set -euo pipefail

APT_UPDATED=0

log() {
    echo "[$(basename "$0")] $*"
}

warn() {
    echo "[$(basename "$0")] WARNING: $*" >&2
}

err() {
    echo "[$(basename "$0")] ERROR: $*" >&2
    exit 1
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        err "This Feature must run as root."
    fi
}

check_debian_family() {
    if [ ! -r /etc/os-release ]; then
        err "Unable to detect Linux distribution."
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    case "${ID:-}" in
        debian|ubuntu)
            return 0
            ;;
    esac

    case " ${ID_LIKE:-} " in
        *" debian "*)
            return 0
            ;;
    esac

    err "This Feature currently supports Debian/Ubuntu-based images."
}

apt_update() {
    if [ "$APT_UPDATED" -eq 0 ]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        APT_UPDATED=1
    fi
}

ensure_apt_packages() {
    apt_update
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y --no-install-recommends "$@"
}

pick_target_user() {
    local requested="${1:-automatic}"

    if [ -n "${requested}" ] && [ "${requested}" != "automatic" ]; then
        if id -u "${requested}" >/dev/null 2>&1; then
            echo "${requested}"
            return 0
        fi
        err "Requested user '${requested}' does not exist."
    fi

    if [ -n "${_REMOTE_USER:-}" ] && id -u "${_REMOTE_USER}" >/dev/null 2>&1; then
        echo "${_REMOTE_USER}"
        return 0
    fi

    if id -u vscode >/dev/null 2>&1; then
        echo "vscode"
        return 0
    fi

    echo "root"
}

user_home_dir() {
    local username="${1}"

    if [ "${username}" = "root" ]; then
        echo "/root"
        return 0
    fi

    getent passwd "${username}" | cut -d: -f6
}

run_as_user() {
    local username="${1}"
    shift

    if [ "${username}" = "root" ]; then
        bash -lc "$*"
    else
        su - "${username}" -s /bin/bash -c "$*"
    fi
}

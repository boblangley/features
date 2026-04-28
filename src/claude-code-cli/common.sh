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
    local feature_version="${VERSION-}"

    if [ ! -r /etc/os-release ]; then
        err "Unable to detect Linux distribution."
    fi

    # shellcheck disable=SC1091
    . /etc/os-release

    case "${ID:-}" in
        debian|ubuntu)
            VERSION="${feature_version}"
            return 0
            ;;
    esac

    case " ${ID_LIKE:-} " in
        *" debian "*)
            VERSION="${feature_version}"
            return 0
            ;;
    esac

    VERSION="${feature_version}"
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

detect_linux_arch() {
    case "$(uname -m)" in
        x86_64|amd64)
            echo "x64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        *)
            err "Unsupported architecture: $(uname -m)"
            ;;
    esac
}

detect_claude_platform() {
    local arch
    arch="$(detect_linux_arch)"

    if [ -f /lib/libc.musl-x86_64.so.1 ] || [ -f /lib/libc.musl-aarch64.so.1 ] || ldd /bin/ls 2>&1 | grep -q "musl"; then
        echo "linux-${arch}-musl"
    else
        echo "linux-${arch}"
    fi
}

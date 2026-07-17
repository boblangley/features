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

ensure_nodejs() {
    local required_major="${1}"
    local installed_major=""

    check_debian_family
    ensure_apt_packages ca-certificates curl gnupg

    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        installed_major="$(node -p 'process.versions.node.split(".")[0]')"
        if [ "${installed_major}" -ge "${required_major}" ]; then
            log "Using existing Node.js $(node --version)"
            return 0
        fi
        log "Upgrading Node.js from major ${installed_major} to ${required_major}"
    else
        log "Installing Node.js ${required_major}.x"
    fi

    mkdir -p /etc/apt/keyrings
    if [ ! -f /etc/apt/keyrings/nodesource.gpg ]; then
        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
            | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    fi

    cat >/etc/apt/sources.list.d/nodesource.list <<EOF
deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${required_major}.x nodistro main
EOF

    APT_UPDATED=0
    ensure_apt_packages nodejs
}

install_npm_global() {
    local package_name="${1}"
    local version="${2:-latest}"
    local package_spec="${package_name}"

    if [ "${version}" != "latest" ]; then
        package_spec="${package_name}@${version}"
    fi

    log "Installing ${package_spec}"
    NPM_CONFIG_UPDATE_NOTIFIER=false npm install -g "${package_spec}"
}

pick_service_user() {
    local requested="${1:-automatic}"

    if [ -n "${requested}" ] && [ "${requested}" != "automatic" ]; then
        if id -u "${requested}" >/dev/null 2>&1; then
            echo "${requested}"
            return 0
        fi
        err "Requested service user '${requested}' does not exist."
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

#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

DOWNLOAD_BASE_URL="https://downloads.claude.ai/claude-code-releases"
INSTALL_DIR="/usr/local/share/claude-code"

require_root
check_debian_family
ensure_apt_packages ca-certificates curl jq

platform="$(detect_claude_platform)"
requested_version="${VERSION}"

if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "stable" ]; then
    resolved_version="$(curl -fsSL "${DOWNLOAD_BASE_URL}/latest")"
else
    resolved_version="${requested_version}"
fi

manifest_json="$(curl -fsSL "${DOWNLOAD_BASE_URL}/${resolved_version}/manifest.json")"
checksum="$(printf '%s' "${manifest_json}" | jq -r ".platforms[\"${platform}\"].checksum // empty")"

[ -n "${checksum}" ] || err "Unable to resolve Claude Code checksum for platform ${platform}."

mkdir -p "${INSTALL_DIR}"
binary_path="${INSTALL_DIR}/claude-${resolved_version}-${platform}"
tmp_binary="$(mktemp)"

curl -fsSL "${DOWNLOAD_BASE_URL}/${resolved_version}/${platform}/claude" -o "${tmp_binary}"
actual_checksum="$(sha256sum "${tmp_binary}" | awk '{print $1}')"

if [ "${actual_checksum}" != "${checksum}" ]; then
    rm -f "${tmp_binary}"
    err "Checksum verification failed for Claude Code ${resolved_version}."
fi

install -m 0755 "${tmp_binary}" "${binary_path}"
ln -sf "${binary_path}" /usr/local/bin/claude
rm -f "${tmp_binary}"

command -v claude >/dev/null 2>&1 || err "Claude Code was not added to PATH."
log "Installed Claude Code $(claude --version)"

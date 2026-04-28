#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

require_root
ensure_nodejs "${NODEVERSION}"
install_npm_global "@google/gemini-cli" "${VERSION}"

command -v gemini >/dev/null 2>&1 || err "Gemini CLI was not added to PATH."
log "Installed Gemini CLI $(gemini --version)"

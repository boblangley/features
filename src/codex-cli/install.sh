#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

require_root
ensure_nodejs "${NODEVERSION}"
install_npm_global "@openai/codex" "${VERSION}"

command -v codex >/dev/null 2>&1 || err "Codex CLI was not added to PATH."
log "Installed Codex CLI $(codex --version)"

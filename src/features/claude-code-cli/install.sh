#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

require_root
ensure_apt_packages ca-certificates curl

devcontainer_user="$(pick_devcontainer_user)"
user_home="$(user_home_dir "${devcontainer_user}")"
[ -n "${user_home}" ] || err "Unable to resolve the home directory for ${devcontainer_user}."

installer="$(mktemp)"
curl --fail --location --silent --show-error https://claude.ai/install.sh --output "${installer}"
chmod 0755 "${installer}"

log "Installing Claude Code ${VERSION} for ${devcontainer_user}"
run_as_user "${devcontainer_user}" env HOME="${user_home}" bash "${installer}" "${VERSION}"
rm -f "${installer}"

claude_binary="${user_home}/.local/bin/claude"
[ -x "${claude_binary}" ] || err "Claude Code was not installed at ${claude_binary}."
ln -sf "${claude_binary}" /usr/local/bin/claude

log "Installed Claude Code $(run_as_user "${devcontainer_user}" env HOME="${user_home}" "${claude_binary}" --version)"

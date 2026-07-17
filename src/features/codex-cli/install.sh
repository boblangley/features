#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

require_root

devcontainer_user="$(pick_devcontainer_user)"
user_home="$(user_home_dir "${devcontainer_user}")"
[ -n "${user_home}" ] || err "Unable to resolve the home directory for ${devcontainer_user}."

install -d -m 0755 -o "${devcontainer_user}" -g "$(id -gn "${devcontainer_user}")" "${user_home}/.local"

package_spec="@openai/codex@${VERSION}"
log "Installing ${package_spec} for ${devcontainer_user}"
run_as_user "${devcontainer_user}" env \
    HOME="${user_home}" \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    npm install --global --prefix "${user_home}/.local" "${package_spec}"

codex_binary="${user_home}/.local/bin/codex"
[ -x "${codex_binary}" ] || err "Codex CLI was not installed at ${codex_binary}."
ln -sf "${codex_binary}" /usr/local/bin/codex

log "Installed Codex CLI $(run_as_user "${devcontainer_user}" env HOME="${user_home}" "${codex_binary}" --version)"

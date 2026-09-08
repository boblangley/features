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
cleanup() {
    rm -f "${installer}"
}
trap cleanup EXIT

curl --fail --location --silent --show-error https://cursor.com/install --output "${installer}"
chmod 0755 "${installer}"

log "Installing Cursor Agent CLI for ${devcontainer_user}"
run_as_user "${devcontainer_user}" env HOME="${user_home}" bash "${installer}"

agent_binary="${user_home}/.local/bin/agent"
cursor_agent_binary="${user_home}/.local/bin/cursor-agent"
[ -x "${agent_binary}" ] || err "Cursor Agent CLI was not installed at ${agent_binary}."
[ -x "${cursor_agent_binary}" ] || err "Cursor Agent CLI was not installed at ${cursor_agent_binary}."

devcontainer_group="$(id -gn "${devcontainer_user}")"
chown -R "${devcontainer_user}:${devcontainer_group}" "${user_home}/.local/share/cursor-agent"
chown -h "${devcontainer_user}:${devcontainer_group}" "${agent_binary}" "${cursor_agent_binary}"

ln -sf "${agent_binary}" /usr/local/bin/agent
ln -sf "${cursor_agent_binary}" /usr/local/bin/cursor-agent

log "Installed Cursor Agent CLI $(run_as_user "${devcontainer_user}" env HOME="${user_home}" "${agent_binary}" --version)"

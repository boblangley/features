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
trap 'rm -f "${installer}"' EXIT
curl --fail --location --silent --show-error https://x.ai/cli/install.sh --output "${installer}"
chmod 0755 "${installer}"

log "Installing Grok CLI ${VERSION} for ${devcontainer_user}"
if [ "${VERSION}" = latest ]; then
    run_as_user "${devcontainer_user}" env HOME="${user_home}" bash "${installer}"
else
    run_as_user "${devcontainer_user}" env HOME="${user_home}" bash "${installer}" "${VERSION}"
fi

grok_binary="${user_home}/.grok/bin/grok"
[ -x "${grok_binary}" ] || err "Grok CLI was not installed at ${grok_binary}."
ln -sf "${grok_binary}" /usr/local/bin/grok

log "Installed Grok CLI $(run_as_user "${devcontainer_user}" env HOME="${user_home}" "${grok_binary}" --version)"

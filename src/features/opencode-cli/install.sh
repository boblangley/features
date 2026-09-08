#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "$0")/common.sh"

require_root
ensure_apt_packages ca-certificates curl tar

devcontainer_user="$(pick_devcontainer_user)"
user_home="$(user_home_dir "${devcontainer_user}")"
[ -n "${user_home}" ] || err "Unable to resolve the home directory for ${devcontainer_user}."

installer="$(mktemp)"
trap 'rm -f "${installer}"' EXIT
curl --fail --location --silent --show-error https://opencode.ai/install --output "${installer}"
chmod 0755 "${installer}"

installer_args=(--no-modify-path)
installer_version=""
if [ "${VERSION}" != latest ]; then
    installer_version="${VERSION}"
    installer_args+=(--version "${VERSION}")
fi

log "Installing OpenCode ${VERSION} for ${devcontainer_user}"
run_as_user "${devcontainer_user}" env \
    HOME="${user_home}" \
    PATH="${user_home}/.opencode/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
    VERSION="${installer_version}" \
    bash "${installer}" "${installer_args[@]}"

opencode_binary="${user_home}/.opencode/bin/opencode"
[ -x "${opencode_binary}" ] || err "OpenCode was not installed at ${opencode_binary}."
chown -R "${devcontainer_user}:$(id -gn "${devcontainer_user}")" "${user_home}/.opencode"
ln -sf "${opencode_binary}" /usr/local/bin/opencode

log "Installed OpenCode $(run_as_user "${devcontainer_user}" env HOME="${user_home}" "${opencode_binary}" --version)"

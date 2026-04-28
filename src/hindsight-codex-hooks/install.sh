#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

require_root
check_debian_family
ensure_apt_packages ca-certificates curl python3

target_user="$(pick_target_user "${USERNAME:-automatic}")"
target_home="$(user_home_dir "${target_user}")"

[ -n "${target_home}" ] || err "Could not resolve home directory for ${target_user}."

log "Running Hindsight Codex installer for user '${target_user}'"

installer_path="$(mktemp)"
trap 'rm -f "${installer_path}"' EXIT
curl -fsSL "${INSTALLERURL}" -o "${installer_path}"
chmod 0755 "${installer_path}"
chown "${target_user}:$(id -gn "${target_user}")" "${installer_path}"

# --mode local skips the cloud token prompt. We always install in local mode so
# the installer is non-interactive; if hindsightApiUrl is set, we then write
# ~/.hindsight/codex.json below to override the connection.
run_as_user "${target_user}" "bash '${installer_path}' --mode local </dev/null"

if [ -n "${HINDSIGHTAPIURL}" ] || [ -n "${HINDSIGHTAPITOKEN}" ] || [ -n "${BANKID}" ]; then
    config_dir="${target_home}/.hindsight"
    config_path="${config_dir}/codex.json"

    log "Writing Hindsight user config to ${config_path}"

    run_as_user "${target_user}" "mkdir -p '${config_dir}'"

    HINDSIGHT_API_URL_VAL="${HINDSIGHTAPIURL}" \
    HINDSIGHT_API_TOKEN_VAL="${HINDSIGHTAPITOKEN}" \
    HINDSIGHT_BANK_ID_VAL="${BANKID}" \
    HINDSIGHT_CONFIG_PATH="${config_path}" \
    python3 - <<'PY'
import json, os

cfg = {}
url = os.environ.get("HINDSIGHT_API_URL_VAL", "")
token = os.environ.get("HINDSIGHT_API_TOKEN_VAL", "")
bank = os.environ.get("HINDSIGHT_BANK_ID_VAL", "")

if url:
    cfg["hindsightApiUrl"] = url
if token:
    cfg["hindsightApiToken"] = token
if bank:
    cfg["bankId"] = bank

path = os.environ["HINDSIGHT_CONFIG_PATH"]
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
PY

    chown -R "${target_user}:$(id -gn "${target_user}")" "${config_dir}"
    chmod 0600 "${config_path}"
fi

log "Hindsight memory hooks installed for ${target_user}"

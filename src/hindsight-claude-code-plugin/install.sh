#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")/common.sh"

require_root
check_debian_family
ensure_apt_packages ca-certificates curl git python3

if ! command -v claude >/dev/null 2>&1; then
    err "Claude Code CLI not found on PATH. Install ghcr.io/boblangley/features/claude-code-cli before this Feature."
fi

target_user="$(pick_target_user "${USERNAME:-automatic}")"
target_home="$(user_home_dir "${target_user}")"

[ -n "${target_home}" ] || err "Could not resolve home directory for ${target_user}."

log "Installing Claude Code plugin '${PLUGIN}' from marketplace '${MARKETPLACE}' for user '${target_user}'"

run_as_user "${target_user}" "claude plugin marketplace add '${MARKETPLACE}'"
run_as_user "${target_user}" "claude plugin install --scope '${SCOPE}' '${PLUGIN}'"

plugin_short_name="${PLUGIN%@*}"
plugin_cache_root="${target_home}/.claude/plugins/cache"
plugin_cache_dir=""

if [ -d "${plugin_cache_root}" ]; then
    plugin_cache_dir="$(find "${plugin_cache_root}" -mindepth 2 -maxdepth 2 -type d -name "${plugin_short_name}" -print -quit 2>/dev/null || true)"
fi

if [ -z "${plugin_cache_dir}" ] || [ ! -d "${plugin_cache_dir}" ]; then
    err "Plugin cache for '${plugin_short_name}' not found under ${plugin_cache_root} after install."
fi

if [ "${REGISTERHOOKS}" = "true" ]; then
    setup_hooks_path="$(find "${plugin_cache_dir}" -maxdepth 4 -type f -name setup_hooks.py -print -quit 2>/dev/null || true)"
    if [ -n "${setup_hooks_path}" ]; then
        log "Registering plugin hooks via ${setup_hooks_path}"
        run_as_user "${target_user}" "python3 '${setup_hooks_path}'"
    else
        warn "setup_hooks.py not found inside ${plugin_cache_dir}; skipping hook registration."
    fi
fi

if [ -n "${HINDSIGHTAPIURL}" ] || [ -n "${HINDSIGHTAPITOKEN}" ] || [ -n "${BANKID}" ]; then
    config_dir="${target_home}/.hindsight"
    config_path="${config_dir}/claude-code.json"

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

log "Hindsight memory plugin installed for ${target_user}"

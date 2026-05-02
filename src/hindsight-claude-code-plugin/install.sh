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

plugin_root="$(find "${plugin_cache_dir}" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | sort -r | head -n 1 || true)"
if [ -z "${plugin_root}" ]; then
    err "No installed plugin versions found under ${plugin_cache_dir}."
fi

retain_script="${plugin_root}/scripts/retain.py"
task_config_module="${plugin_root}/scripts/lib/task_config.py"

if [ -f "${retain_script}" ] && [ -d "${plugin_root}/scripts/lib" ]; then
    log "Patching Claude Code retain hook for file-based Hindsight retain scope"

    cat >"${task_config_module}" <<'PY'
"""Active retain scope loaded from the user's Hindsight profile."""

import json
import os
from typing import Optional

_CACHE: Optional[tuple[int, int, Optional[dict]]] = None


def load_active_retain_scope() -> dict:
    """Read ~/.hindsight/active-retain-scope.json, cached by file mtime."""
    global _CACHE
    path = os.path.join(os.path.expanduser("~"), ".hindsight", "active-retain-scope.json")
    try:
        stat = os.stat(path)
    except OSError:
        _CACHE = None
        return {}

    cache_key = (stat.st_mtime_ns, stat.st_size)
    if _CACHE and _CACHE[:2] == cache_key:
        return _CACHE[2] or {}

    parsed: Optional[dict] = None
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, dict):
            bank_id = data.get("bankId")
            tags = data.get("tags")
            parsed = {}
            if isinstance(bank_id, str) and bank_id:
                parsed["bankId"] = bank_id
            if isinstance(tags, list):
                clean_tags = [tag for tag in tags if isinstance(tag, str) and tag]
                if clean_tags:
                    parsed["tags"] = clean_tags
    except (OSError, json.JSONDecodeError, UnicodeDecodeError):
        parsed = None

    _CACHE = (stat.st_mtime_ns, stat.st_size, parsed)
    return parsed or {}


def merge_tags(base_tags, extra_tags):
    """Append extra tags to base tags while preserving first-seen order."""
    merged = []
    seen = set()
    for tag in (base_tags or []) + (extra_tags or []):
        if isinstance(tag, str) and tag and tag not in seen:
            merged.append(tag)
            seen.add(tag)
    return merged or None
PY

    HINDSIGHT_RETAIN_SCRIPT="${retain_script}" python3 - <<'PY'
import os
from pathlib import Path

path = Path(os.environ["HINDSIGHT_RETAIN_SCRIPT"])
text = path.read_text()
text = text.replace(
    "active_retain_scope = load_active_retain_scope(os.getcwd())",
    "active_retain_scope = load_active_retain_scope()",
)

if "from lib.task_config import load_active_retain_scope, merge_tags" not in text:
    text = text.replace(
        "from lib.state import increment_turn_count, track_retention\n",
        "from lib.state import increment_turn_count, track_retention\n"
        "from lib.task_config import load_active_retain_scope, merge_tags\n",
    )
if "from lib.task_config import load_active_retain_scope, merge_tags" not in text:
    raise SystemExit(f"Could not patch task_config import in {path}")

old = "    bank_id = derive_bank_id(hook_input, config)\n    ensure_bank_mission(client, bank_id, config, debug_fn=_dbg)\n"
new = (
    "    bank_id = derive_bank_id(hook_input, config)\n"
    "    active_retain_scope = load_active_retain_scope()\n"
    "    bank_id = active_retain_scope.get(\"bankId\", bank_id)\n"
    "    ensure_bank_mission(client, bank_id, config, debug_fn=_dbg)\n"
)
if "active_retain_scope = load_active_retain_scope()" not in text:
    if old not in text:
        raise SystemExit(f"Could not find bank_id block in {path}")
    text = text.replace(old, new, 1)

old = "        if not tags:\n            tags = None\n    else:\n        tags = None\n"
new = (
    "        if not tags:\n"
    "            tags = None\n"
    "    else:\n"
    "        tags = None\n"
    "    tags = merge_tags(tags, active_retain_scope.get(\"tags\"))\n"
)
if "tags = merge_tags(tags, active_retain_scope.get(\"tags\"))" not in text:
    if old not in text:
        raise SystemExit(f"Could not find tags block in {path}")
    text = text.replace(old, new, 1)

path.write_text(text)
PY

    chown -R "${target_user}:$(id -gn "${target_user}")" "${plugin_root}/scripts/lib" "${retain_script}"
    chmod 0644 "${task_config_module}"
    chmod +x "${retain_script}"
else
    warn "Claude Code retain hook not found at ${retain_script}; skipping retain scope patch."
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

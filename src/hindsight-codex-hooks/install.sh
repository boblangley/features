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

scripts_dir="${target_home}/.hindsight/codex/scripts"
retain_script="${scripts_dir}/retain.py"
task_config_module="${scripts_dir}/lib/task_config.py"

if [ -f "${retain_script}" ] && [ -d "${scripts_dir}/lib" ]; then
    log "Patching Codex retain hook for file-based Hindsight retain scope"

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
        "from lib.state import increment_turn_count\n",
        "from lib.state import increment_turn_count\n"
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

old = "    tags = [_resolve_template(t) for t in raw_tags] if raw_tags else None\n"
new = (
    "    tags = [_resolve_template(t) for t in raw_tags] if raw_tags else None\n"
    "    tags = merge_tags(tags, active_retain_scope.get(\"tags\"))\n"
)
if "tags = merge_tags(tags, active_retain_scope.get(\"tags\"))" not in text:
    if old not in text:
        raise SystemExit(f"Could not find tags block in {path}")
    text = text.replace(old, new, 1)

path.write_text(text)
PY

    chown -R "${target_user}:$(id -gn "${target_user}")" "${scripts_dir}/lib" "${retain_script}"
    chmod 0644 "${task_config_module}"
    chmod +x "${retain_script}"
else
    warn "Codex retain hook not found at ${retain_script}; skipping retain scope patch."
fi

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

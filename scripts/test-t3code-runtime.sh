#!/usr/bin/env bash

# Runtime acceptance for the t3code-server Feature consumed from the fork.
#
# Builds a clean devcontainer that installs the published Feature with
# packageSource github:wyrd-company/t3code and version latest, then proves the
# console is served by that installation. The live agent turn is opt-in and is
# skipped, never failed, when T3CODE_RUNTIME_AGENT_PROBE is unset, following the
# fork's own live-probe convention.

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
image="${1:-devcontainers-t3code-runtime:test}"
name="t3code-runtime-test-${RANDOM}-$$"
port=3773
codex_auth="${T3CODE_RUNTIME_CODEX_AUTH:-${HOME}/.codex/auth.json}"
turn_timeout="${T3CODE_RUNTIME_TURN_TIMEOUT:-180}"
workspace="$(mktemp -d)"

# Isolate the Docker config so the build resolves images anonymously and does
# not inherit a host credential helper.
DOCKER_CONFIG="${workspace}/docker"
export DOCKER_CONFIG
mkdir -p "${DOCKER_CONFIG}"
printf '{}' >"${DOCKER_CONFIG}/config.json"

fail() {
    printf '%s\n' "$1" >&2
    exit 1
}

cleanup() {
    docker stop "${name}" >/dev/null 2>&1 || true
    docker rm "${name}" >/dev/null 2>&1 || true
    rm -rf "${workspace}"
}
trap cleanup EXIT

# Resolve independently of the container so the assertion below can disagree
# with what the Feature actually installed.
mapfile -t resolution < <(
    python3 "${repo_root}/src/features/t3code-server/resolve-package-source.py" \
        github:wyrd-company/t3code latest
)
expected_version="${resolution[1]}"
printf 'Fork latest resolves to %s.\n' "${expected_version}"

mkdir -p "${workspace}/.devcontainer"
cp -a "${repo_root}/src/features/t3code-server" "${workspace}/.devcontainer/t3code-server"

harness_feature=""
if [ -n "${T3CODE_RUNTIME_AGENT_PROBE:-}" ]; then
    [ -f "${codex_auth}" ] \
        || fail "The agent probe needs Codex credentials at ${codex_auth}."
    cp -a "${repo_root}/src/features/codex-cli" "${workspace}/.devcontainer/codex-cli"
    harness_feature=',
        "./codex-cli": {}'
fi

cat >"${workspace}/.devcontainer/devcontainer.json" <<EOF
{
    "image": "ghcr.io/wyrd-company/devcontainers/base:noble",
    "features": {
        "./t3code-server": {
            "packageSource": "github:wyrd-company/t3code",
            "version": "latest",
            "serveMode": "web",
            "host": "127.0.0.1",
            "port": "${port}"
        }${harness_feature}
    }
}
EOF

devcontainer build \
    --workspace-folder "${workspace}" \
    --image-name "${image}" >/dev/null

run_options=()
if [ -n "${T3CODE_RUNTIME_AGENT_PROBE:-}" ]; then
    # Read-only so the probe cannot write back to the developer's credential.
    run_options+=(--volume "${codex_auth}:/home/vscode/.codex/auth.json:ro")
fi

docker run --detach --name "${name}" "${run_options[@]}" "${image}" >/dev/null

for _ in $(seq 1 120); do
    if docker exec "${name}" curl --fail --silent "http://127.0.0.1:${port}/" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done
docker exec "${name}" curl --fail --silent "http://127.0.0.1:${port}/" >/dev/null \
    || fail "Console did not serve on port ${port} within the startup window."

installed_version="$(docker exec "${name}" /usr/local/bin/t3 --version)"
[ "${installed_version}" = "t3 v${expected_version}" ] \
    || fail "Feature installed '${installed_version}' but latest resolves to 't3 v${expected_version}'."

linked_bin="$(docker exec "${name}" readlink -f /usr/local/bin/t3)"
[ "${linked_bin}" = /usr/local/lib/node_modules/t3/dist/bin.mjs ] \
    || fail "Global t3 link resolves outside the fork package: ${linked_bin}."

# Match the serve process itself; 's6-supervise t3code-server' also contains
# both words and would otherwise resolve to the root-owned supervisor.
t3_pid="$(docker exec "${name}" pgrep --full -- '/usr/local/bin/t3 serve --host' | head -n 1)"
[ -n "${t3_pid}" ] || fail "No T3 Code serve process is running in the container."

service_user="$(docker exec "${name}" ps -o user= -p "${t3_pid}" | tr -d ' ')"
[ "${service_user}" = vscode ] \
    || fail "T3 Code serve runs as '${service_user}' rather than the service user."

docker exec "${name}" sh -c "tr '\\0' ' ' </proc/${t3_pid}/cmdline" | grep -q -- '--mode=web' \
    || fail "T3 Code serve is not running the web runtime."

console="$(docker exec "${name}" curl --fail --silent "http://127.0.0.1:${port}/")"
printf '%s' "${console}" | grep -qi '<!doctype html' \
    || fail "Console root did not return an HTML document."

printf 'Console served by %s as vscode.\n' "${installed_version}"

if [ -z "${T3CODE_RUNTIME_AGENT_PROBE:-}" ]; then
    printf 'Live agent turn skipped: T3CODE_RUNTIME_AGENT_PROBE is unset.\n'
    printf 'T3 Code fork runtime checks passed.\n'
    exit 0
fi

# The provider harness must reach a real turn from inside the isolated
# container, using only the read-only credential mount. Output is discarded so
# no credential or model content reaches the log; the marker is the evidence.
marker="t3-runtime-probe-${RANDOM}"
turn_status=0
timeout "${turn_timeout}" docker exec --user vscode "${name}" \
    env HOME=/home/vscode \
    codex exec --skip-git-repo-check "Reply with exactly this text and nothing else: ${marker}" \
    >"${workspace}/turn.log" 2>&1 || turn_status=$?

if [ "${turn_status}" -eq 124 ]; then
    fail "Codex did not settle a turn within ${turn_timeout}s inside the isolated container."
fi
[ "${turn_status}" -eq 0 ] \
    || fail "Codex could not complete a turn inside the isolated container (exit ${turn_status})."

grep -q "${marker}" "${workspace}/turn.log" \
    || fail "Codex completed a turn but did not produce the requested marker."

printf 'Codex completed a real turn in the isolated container.\n'

test "$(docker exec "${name}" stat -c %A /home/vscode/.codex/auth.json | cut -c8)" = - \
    || fail "Mounted Codex credential is group-writable inside the container."

printf 'T3 Code fork runtime checks passed.\n'

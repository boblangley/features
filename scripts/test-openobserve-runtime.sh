#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
image="${1:-devcontainers-openobserve-runtime:test}"
name="openobserve-runtime-test-${RANDOM}-$$"

cleanup() {
    docker stop "${name}" >/dev/null 2>&1 || true
    docker rm "${name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker build \
    --file "${repo_root}/test/features/openobserve/runtime.Dockerfile" \
    --tag "${image}" \
    "${repo_root}"

docker run --detach \
    --name "${name}" \
    --env ZO_HTTP_ADDR=0.0.0.0 \
    --env ZO_HTTP_PORT=5180 \
    --env SAMPLE_RUNTIME_VALUE=sample-runtime-value \
    "${image}" >/dev/null

for _ in $(seq 1 60); do
    if docker exec "${name}" curl --fail --silent http://127.0.0.1:5080/ >/dev/null 2>&1; then
        break
    fi
    sleep 0.5
done
docker exec "${name}" curl --fail --silent http://127.0.0.1:5080/ >/dev/null

openobserve_pid="$(docker exec "${name}" pgrep --exact openobserve | head -n 1)"
test -n "${openobserve_pid}"
test "$(docker exec "${name}" ps -o user= -p "${openobserve_pid}" | tr -d ' ')" = vscode
docker exec --user vscode "${name}" sh -c \
    "tr '\0' '\n' </proc/${openobserve_pid}/environ | grep -qx SAMPLE_RUNTIME_VALUE=sample-runtime-value"

if docker exec "${name}" curl --fail --silent http://127.0.0.1:5180/ >/dev/null 2>&1; then
    echo "ZO_HTTP_PORT overrode the configured command-line port." >&2
    exit 1
fi

# Verify data was written to the documented default location
docker exec "${name}" test -f /home/vscode/.local/share/openobserve/db/metadata.sqlite

assert_install_rejected() {
    local description="$1"
    local expected="$2"
    shift 2
    local output

    if output="$(docker run --rm \
        --entrypoint /bin/bash \
        --volume "${repo_root}/src/features/openobserve:/feature:ro" \
        --volume "${repo_root}/test/features/openobserve/failing-checksum-bin:/test-bin:ro" \
        "${image}" \
        -c 'env "$@" /feature/install.sh' bash "$@" 2>&1)"; then
        echo "Invalid configuration was accepted: ${description}." >&2
        exit 1
    fi
    if ! printf '%s\n' "${output}" | grep -Fq "${expected}"; then
        echo "Configuration was rejected for the wrong reason: ${description}." >&2
        printf '%s\n' "${output}" >&2
        exit 1
    fi
}

common_options=(
    VERSION=latest
    HOST=127.0.0.1
    PORT=5080
    GRPCPORT=5081
    SERVICEUSER=automatic
    DNSNAME=
    ROOTUSEREMAIL=root@example.com
    ROOTUSERPASSWORD="Complexpass#123"
    TELEMETRY=false
    SHA256=
    _REMOTE_USER=vscode
)
assert_install_rejected \
    "out-of-range port" \
    "port must be an integer between 1 and 65535" \
    "${common_options[@]/PORT=5080/PORT=0}"
assert_install_rejected \
    "out-of-range grpcPort" \
    "grpcPort must be an integer between 1 and 65535" \
    "${common_options[@]/GRPCPORT=5081/GRPCPORT=0}"
assert_install_rejected \
    "port and grpcPort collision" \
    "port and grpcPort must not be the same port" \
    "${common_options[@]/GRPCPORT=5081/GRPCPORT=5080}"
assert_install_rejected \
    "invalid rootUserEmail" \
    "rootUserEmail must be a valid email address" \
    "${common_options[@]/ROOTUSEREMAIL=root@example.com/ROOTUSEREMAIL=not-an-email}"
assert_install_rejected \
    "too short rootUserPassword" \
    "rootUserPassword must be at least 8 characters long" \
    "${common_options[@]/ROOTUSERPASSWORD=Complexpass#123/ROOTUSERPASSWORD=short}"
assert_install_rejected \
    "Caddy registration on a non-loopback host" \
    "dnsName requires host" \
    VERSION=latest HOST=192.0.2.10 PORT=5080 GRPCPORT=5081 SERVICEUSER=automatic \
    DNSNAME=observe.test-container.example.test _REMOTE_USER=vscode
assert_install_rejected \
    "Caddy registration without Caddy" \
    "dnsName requires the Caddy Feature" \
    VERSION=latest HOST=127.0.0.1 PORT=5080 GRPCPORT=5081 SERVICEUSER=automatic \
    DNSNAME=observe.test-container.example.test _REMOTE_USER=vscode
assert_install_rejected \
    "release archive with a failed checksum" \
    "Checksum verification failed" \
    VERSION=latest HOST=127.0.0.1 PORT=5080 GRPCPORT=5081 SERVICEUSER=automatic DNSNAME= \
    SHA256=0000000000000000000000000000000000000000000000000000000000000000 _REMOTE_USER=vscode

printf 'OpenObserve s6 runtime checks passed.\n'

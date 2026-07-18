#!/usr/bin/env bash

set -euo pipefail

image="${1:?usage: test.sh IMAGE}"
test_image="${image}-s6-test"
container="base-ubuntu-s6-test-${RANDOM}"

docker build --build-arg "IMAGE=${image}" --tag "${test_image}" "$(dirname "$0")"

cleanup() {
    docker container rm --force "${container}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run --detach --name "${container}" "${test_image}" \
    >/dev/null

for _ in $(seq 1 30); do
    restart_count="$(docker exec "${container}" sh -c 'test -f /tmp/restart-probe-pids && wc -l </tmp/restart-probe-pids || true')"
    if [ "${restart_count:-0}" -ge 2 ]; then
        break
    fi
    sleep 1
done

docker exec "${container}" sh -c "tr '\0' ' ' </proc/1/cmdline | grep -q s6-svscan"
docker exec "${container}" sh -c 'tr "\0" " " </proc/$(pgrep -x s6-pause)/cmdline | grep -q s6-pause'
docker exec "${container}" sh -c 'test "$(wc -l </tmp/restart-probe-pids)" -ge 2'

docker stop --time 10 "${container}" >/dev/null
test "$(docker inspect --format '{{.State.ExitCode}}' "${container}")" -eq 0

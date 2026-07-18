#!/usr/bin/env bash

set -euo pipefail

image="${1:?Usage: test.sh IMAGE}"
name="t3code-web-test-${RANDOM}-$$"

cleanup() {
    docker stop "${name}" >/dev/null 2>&1 || true
    docker rm "${name}" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker run --detach --name "${name}" "${image}" >/dev/null

for _ in $(seq 1 30); do
    if docker exec "${name}" wget -q -O /dev/null http://127.0.0.1/; then
        break
    fi
    sleep 1
done

index="$(docker exec "${name}" wget -q -O - http://127.0.0.1/)"
pair="$(docker exec "${name}" wget -q -O - http://127.0.0.1/pair)"

grep -q '<div id="root">' <<<"${index}"
grep -q '<div id="root">' <<<"${pair}"
docker exec "${name}" test -f /usr/share/licenses/t3code/LICENSE
docker exec "${name}" sh -c '! command -v node >/dev/null 2>&1 && ! command -v t3 >/dev/null 2>&1'

health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "${name}")"
for _ in $(seq 1 10); do
    [ "${health}" = healthy ] && break
    sleep 1
    health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "${name}")"
done
test "${health}" = healthy

printf 'T3 Code web client image passed runtime checks.\n'

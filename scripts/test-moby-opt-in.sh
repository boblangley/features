#!/usr/bin/env bash

set -euo pipefail

base_image="${1:-devcontainers-base:resolute}"

for feature in docker-outside-of-docker docker-in-docker; do
    if output="$(docker build \
        --build-arg "BASE_IMAGE=${base_image}" \
        --build-arg "FEATURE=${feature}" \
        --file - \
        . 2>&1 <<'EOF'
ARG BASE_IMAGE=devcontainers-base:resolute
FROM ${BASE_IMAGE}
ARG FEATURE
COPY src/features/${FEATURE} /tmp/feature
RUN chmod 0755 /tmp/feature/install.sh \
    && MOBY=true _REMOTE_USER=vscode /tmp/feature/install.sh
EOF
    )"; then
        echo "Expected ${feature} with moby=true to fail on ${base_image}." >&2
        exit 1
    fi

    if ! grep -q "The 'moby' option is not supported on .* 'resolute'" <<<"${output}"; then
        echo "${output}" >&2
        echo "${feature} failed for a reason other than unavailable Moby packages." >&2
        exit 1
    fi
done

echo "Moby opt-in fails explicitly on ${base_image}."

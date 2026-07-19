ARG BASE_IMAGE=ghcr.io/wyrd-company/devcontainers/base:noble
FROM ${BASE_IMAGE}

COPY src/features/caddy /tmp/caddy-feature

RUN VERSION=latest \
    ACMECA= \
    ACMECAROOT= \
    CONFIGUSER=automatic \
    _REMOTE_USER=vscode \
    /tmp/caddy-feature/install.sh \
    && rm -rf /tmp/caddy-feature

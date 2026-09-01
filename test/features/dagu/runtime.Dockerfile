ARG BASE_IMAGE=ghcr.io/wyrd-company/devcontainers/base:noble
FROM ${BASE_IMAGE}

COPY src/features/dagu /tmp/dagu-feature

RUN VERSION=latest \
    HOST=127.0.0.1 \
    PORT=8080 \
    SERVICEUSER=automatic \
    DNSNAME= \
    _REMOTE_USER=vscode \
    /tmp/dagu-feature/install.sh \
    && rm -rf /tmp/dagu-feature

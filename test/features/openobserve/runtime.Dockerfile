ARG BASE_IMAGE=ghcr.io/wyrd-company/devcontainers/base:noble
FROM ${BASE_IMAGE}

COPY src/features/openobserve /tmp/openobserve-feature

RUN VERSION=latest \
    HOST=127.0.0.1 \
    PORT=5080 \
    GRPCPORT=5081 \
    SERVICEUSER=automatic \
    DNSNAME= \
    ROOTUSEREMAIL=root@example.com \
    ROOTUSERPASSWORD="Complexpass#123" \
    TELEMETRY=false \
    _REMOTE_USER=vscode \
    S3BUCKETPREFIX= \
    /tmp/openobserve-feature/install.sh \
    && rm -rf /tmp/openobserve-feature

ARG IMAGE=devcontainers-base:noble
FROM ${IMAGE}

COPY service /etc/s6-overlay/s6-rc.d/restart-probe
RUN chmod 0755 /etc/s6-overlay/s6-rc.d/restart-probe/run \
    && mkdir -p /etc/s6-overlay/s6-rc.d/restart-probe/dependencies.d \
    && touch /etc/s6-overlay/s6-rc.d/restart-probe/dependencies.d/base \
    && touch /etc/s6-overlay/user-bundles.d/user/contents.d/restart-probe

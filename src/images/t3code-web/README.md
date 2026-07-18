# T3 Code web client image

Builds the unmodified static web client from a checksum-verified upstream T3 Code release and serves it with Nginx. It contains no T3 server, agent runtime, credentials, project files, or relay modifications.

The image is published for `linux/amd64` and `linux/arm64` as:

```text
ghcr.io/wyrd-company/devcontainers/t3code-web:<T3 Code version>
ghcr.io/wyrd-company/devcontainers/t3code-web:latest
```

`versions.env` is the single source of truth for the upstream version, source checksum, and build-tool version.

## Local build and test

```bash
set -a
. src/images/t3code-web/versions.env
set +a

docker build \
  --build-arg T3CODE_VERSION \
  --build-arg T3CODE_SOURCE_SHA256 \
  --build-arg VITE_PLUS_VERSION \
  --tag devcontainers-t3code-web:${T3CODE_VERSION} \
  src/images/t3code-web

src/images/t3code-web/test/test.sh devcontainers-t3code-web:${T3CODE_VERSION}
```

The browser connects directly to a separately deployed T3 server. When this client is served over HTTPS, the server must also be reachable over HTTPS/WSS to avoid browser mixed-content blocking.

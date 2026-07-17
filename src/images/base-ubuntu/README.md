# Ubuntu Dev Container base with s6-overlay

This image derives from Microsoft's Ubuntu Dev Container base and adds [s6-overlay](https://github.com/just-containers/s6-overlay) as PID 1.

## Supported variants

| Ubuntu release | Codename   | Architectures    |
| -------------- | ---------- | ---------------- |
| 24.04 LTS      | `noble`    | `amd64`, `arm64` |
| 26.04 LTS      | `resolute` | `amd64`, `arm64` |

Published rolling tags are explicit and never silently change Ubuntu releases:

- `ghcr.io/wyrd-company/devcontainers/base:noble`
- `ghcr.io/wyrd-company/devcontainers/base:ubuntu24.04`
- `ghcr.io/wyrd-company/devcontainers/base:resolute`
- `ghcr.io/wyrd-company/devcontainers/base:ubuntu26.04`

Each build also receives a dated immutable tag for rollback.

## Services

Add native s6-rc service definitions under `/etc/s6-overlay/s6-rc.d` and include services in `/etc/s6-overlay/user-bundles.d/user/contents.d`. Services should depend on the `base` bundle unless they intentionally need to start earlier.

## Upstream

The image preserves the tools, non-root `vscode` user, and Dev Container metadata supplied by [`mcr.microsoft.com/devcontainers/base`](https://github.com/devcontainers/images/tree/main/src/base-ubuntu). Microsoft and other upstream components retain their respective copyright and license notices.

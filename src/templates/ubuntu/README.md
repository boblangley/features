# Ubuntu with s6-overlay

Creates an Ubuntu development container using Bob Langley's Microsoft-derived base image with s6-overlay as PID 1.

## Options

| Option         | Type   | Default | Description                            |
| -------------- | ------ | ------- | -------------------------------------- |
| `imageVariant` | string | `noble` | Ubuntu release: `noble` or `resolute`. |

## Usage

Apply the Template from:

```text
ghcr.io/wyrd-company/devcontainers/ubuntu:1
```

The generated `.devcontainer/devcontainer.json` references the corresponding explicit rolling image tag under `ghcr.io/wyrd-company/devcontainers/base`.

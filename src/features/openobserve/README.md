# OpenObserve

Installs the official OpenObserve OSS single binary and runs it as an s6-overlay longrun service. The Feature requires a Debian/Ubuntu image with s6-overlay 3 and supports `amd64` and `arm64`.

OpenObserve runs as the selected devcontainer user so that service state, logs, and SQLite metadata use that user's permissions, home directory, and container environment. Automatic selection prefers the remote user, container user, `vscode`, then `root`.

The Feature uses OpenObserve's native per-user configuration and state paths. It does not create configuration files, mount volumes, or create directories outside the service user's paths. Configure bind mounts and their permissions in each `devcontainer.json` when configuration or state must survive a rebuild.

## Caddy integration

Set `dnsName` when the Caddy Feature is present to expose OpenObserve through automatic HTTPS. The Feature registers the DNS name with Caddy's startup-readiness mechanism, writes a reverse-proxy fragment targeting OpenObserve on IPv4 loopback, and sets OpenObserve's public URL (`ZO_WEB_URL`) to `https://<dnsName>`.

```json
{
  "image": "ghcr.io/wyrd-company/devcontainers/base:noble",
  "overrideCommand": false,
  "features": {
    "ghcr.io/wyrd-company/devcontainers/caddy:1": {},
    "ghcr.io/wyrd-company/devcontainers/openobserve:1": {
      "dnsName": "observe.dev-environment.example.test"
    }
  }
}
```

Setting `dnsName` requires the Caddy Feature. Caddy-enabled configurations accept `127.0.0.1`, `localhost`, or `0.0.0.0` as the OpenObserve bind address. `localhost` is normalized to `127.0.0.1`, and Caddy always connects through IPv4 loopback.

## Options

| Option             | Type    | Default             | Description                                                                  |
| ------------------ | ------- | ------------------- | ---------------------------------------------------------------------------- |
| `version`          | string  | `latest`            | OpenObserve release version, with or without the upstream `v` prefix.        |
| `host`             | string  | `127.0.0.1`         | Interface used by OpenObserve HTTP server. `localhost` is normalized to `127.0.0.1`. |
| `port`             | string  | `5080`              | HTTP port used by OpenObserve.                                               |
| `grpcPort`         | string  | `5081`              | gRPC port used by OpenObserve.                                               |
| `serviceUser`      | string  | `automatic`         | User that runs OpenObserve.                                                  |
| `dnsName`          | string  | `""`                | Optional fully qualified DNS name exposed through Caddy.                     |
| `rootUserEmail`    | string  | `root@example.com`  | Initial administrator email address used to bootstrap the root user account. |
| `rootUserPassword` | string  | `Complexpass#123`   | Initial administrator password used to bootstrap the root user account.      |
| `telemetry`        | boolean | `false`             | Enable or disable anonymous usage telemetry sent to upstream.                |
| `sha256`           | string  | `""`                | Optional expected SHA256 checksum for the downloaded release archive.        |

The configured host, HTTP port, and gRPC port are pinned in the service launcher and take precedence over container environment-variable overrides.

## Native OpenObserve locations

For a service user whose home is `/home/vscode`, OpenObserve defaults to:

| Purpose                        | Location                                               |
| ------------------------------ | ------------------------------------------------------ |
| Configuration file             | `/home/vscode/.config/openobserve/openobserve.env`     |
| Data, WAL, and SQLite metadata | `/home/vscode/.local/share/openobserve`                |
| Service launcher               | `/usr/local/bin/openobserve-service`                   |
| s6 service                     | `/etc/s6-overlay/s6-rc.d/openobserve`                  |

## Storage and configuration persistence

OpenObserve supports disk-backed local storage (default) or object storage (S3-compatible).

### Local disk storage

To persist data across container rebuilds using local disk storage, bind-mount a volume or host directory to the service user's data directory in `devcontainer.json`:

```json
{
  "mounts": [
    "source=openobserve-data,target=/home/vscode/.local/share/openobserve,type=volume"
  ]
}
```

### Configuration file (local and object storage)

When a configuration file exists at `/home/vscode/.config/openobserve/openobserve.env` (or the path set in `OPENOBSERVE_CONFIG_FILE`), the service launcher passes it to OpenObserve via `-c`.

Example `openobserve.env` for S3-compatible object storage:

```env
ZO_LOCAL_MODE_STORAGE=s3
ZO_S3_SERVER_URL=https://s3.us-east-1.amazonaws.com
ZO_S3_REGION_NAME=us-east-1
ZO_S3_ACCESS_KEY=your-access-key
ZO_S3_SECRET_KEY=your-secret-key
ZO_S3_BUCKET_NAME=my-openobserve-bucket
```

Bind-mount the file into your container:

```json
{
  "mounts": [
    "source=${localWorkspaceFolder}/.devcontainer/openobserve.env,target=/home/vscode/.config/openobserve/openobserve.env,type=bind,readonly"
  ]
}
```

## Release resolution and integrity

- **Latest version resolution:** When `version` is set to `latest`, the installer queries GitHub releases for the latest stable, non-prerelease tag (ignoring `-rc` candidates). If the GitHub API is unavailable or rate-limited, it falls back to the known stable release `v0.92.2`.
- **Archive source:** OpenObserve publishes OSS binaries at `downloads.openobserve.ai/releases/openobserve/v<version>/openobserve-v<version>-linux-<arch>.tar.gz`.
- **Integrity verification:** Upstream OpenObserve does not serve machine-readable checksum files for OSS releases from its download CDN (endpoints return 403), and the public download page does not publish Linux OSS checksums. When `sha256` is configured, the installer verifies the archive using `sha256sum --check`. When omitted, checksum verification is skipped.

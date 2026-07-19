# Caddy Reverse Proxy

Installs Caddy from its official stable Debian repository and supervises it with s6-overlay. A second s6 service watches a well-known fragment directory and gracefully reloads valid configuration changes through a permissioned Unix admin socket.

The Feature requires a Debian/Ubuntu image with s6-overlay 3 already installed.

## Well-known locations

| Purpose          | Location                      |
| ---------------- | ----------------------------- |
| Main Caddyfile   | `/etc/caddy/Caddyfile`        |
| Proxy fragments  | `/etc/caddy/conf.d/*.caddy`   |
| Admin API socket | `/run/caddy/admin.sock`       |
| Reload command   | `/usr/local/bin/caddy-reload` |

The selected configuration user can add, change, and remove fragments without root access. The watcher validates the complete Caddyfile before reloading; a failed reload leaves the active configuration intact.

## Options

| Option       | Type   | Default     | Description                                                                                  |
| ------------ | ------ | ----------- | -------------------------------------------------------------------------------------------- |
| `version`    | string | `latest`    | Stable Caddy package version.                                                                |
| `acmeCa`     | string | `""`        | Optional ACME directory URL for automatic HTTPS.                                             |
| `acmeCaRoot` | string | `""`        | Optional in-container path to the public CA root certificate protecting the ACME endpoint.   |
| `configUser` | string | `automatic` | User allowed to manage fragments. Automatic selection prefers the Dev Container remote user. |

## Example

```json
{
  "image": "ghcr.io/wyrd-company/devcontainers/base:noble",
  "features": {
    "ghcr.io/wyrd-company/devcontainers/caddy:1": {
      "acmeCa": "https://acme.example.com/acme/local/directory",
      "acmeCaRoot": "/usr/local/share/ca-certificates/caddy-root.crt"
    }
  }
}
```

The root path refers to a public certificate, never the CA private key. It may be omitted when the CA is already trusted through the container's system trust store.

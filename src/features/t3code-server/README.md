# T3 Code Server

Installs T3 Code globally and runs `t3 serve` as the selected service user through a native s6-overlay 3 service. Runtime state remains in the service user's home directory.

The Feature requires a Debian/Ubuntu image with s6-overlay 3 already installed. Node.js 24 is supplied through the official Dev Container Node Feature.

## Options

| Option          | Type   | Default     | Description                                                                                                                               |
| --------------- | ------ | ----------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `version`       | string | `latest`    | T3 Code version. With a GitHub source, `latest` selects the greatest stable fork server tag by SemVer precedence.                         |
| `packageSource` | string | `""`        | Optional npm package spec, tarball URL, or stable GitHub repository source.                                                               |
| `port`          | string | `3773`      | Port exposed by the T3 Code server.                                                                                                       |
| `host`          | string | `0.0.0.0`   | Interface to bind the T3 Code server to.                                                                                                  |
| `serveMode`     | string | `""`        | Optional T3 runtime mode passed to `t3 serve --mode`. Empty preserves the T3 CLI default.                                                 |
| `serviceUser`   | string | `automatic` | User account that runs T3 and owns its runtime state. Automatic selection prefers the remote user, container user, `vscode`, then `root`. |
| `dnsName`       | string | `""`        | Optional fully qualified DNS name exposed through the Caddy Feature.                                                                      |

## Example usage

```json
{
  "image": "ghcr.io/wyrd-company/devcontainers/base:noble",
  "features": {
    "ghcr.io/wyrd-company/devcontainers/t3code-server:1": {
      "port": "3773",
      "serveMode": "web",
      "dnsName": "t3.dev-environment.example.test"
    }
  }
}
```

To select an npm package spec directly:

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/t3code-server:1": {
      "packageSource": "t3@0.0.37"
    }
  }
}
```

To install an explicit Wyrd Company fork release:

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/t3code-server:1": {
      "packageSource": "github:wyrd-company/t3code",
      "version": "0.0.37-wyrd.1"
    }
  }
}
```

To follow the newest stable Wyrd Company fork server release:

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/t3code-server:1": {
      "packageSource": "github:wyrd-company/t3code",
      "version": "latest"
    }
  }
}
```

For a `github:<owner>/<repository>` source, an explicit version installs the public release asset `t3-<version>.tgz` from tag `server/<version>`. `latest` anonymously enumerates the exact `server/*-wyrd.*` tag namespace and selects the greatest accepted version by SemVer precedence. It does not use GitHub's repository-wide latest-release marker or tag creation time.

When `packageSource` is empty, the Feature installs `t3@<version>`. This preserves the default `t3@latest` behavior. Other non-empty npm package specs and URLs are passed directly to `npm install` and take precedence over `version`.

When both Features are selected, T3 installs after Caddy automatically. Setting `dnsName` writes `/etc/caddy/conf.d/t3code-server.caddy` and registers the name in `/etc/caddy/required-hosts.d/t3code-server.host`. Caddy waits for that name to resolve before requesting its certificate, then serves it over HTTPS and proxies to T3 on the configured loopback port. Installation fails when `dnsName` is set without a Caddy Feature version that supports DNS readiness; leave it empty to run T3 without a reverse proxy.

## Pairing

The Feature does not install Codex. Add the separate Codex CLI Feature when needed.

To mint a pairing code at any time, run the command as the service user and use the same T3 base directory as the server:

```bash
sudo -u vscode t3 auth pairing create --base-dir /home/vscode/.t3
```

Replace `vscode` and its home directory when `serviceUser` resolves to another account. T3 writes its own logs beneath `<home>/.t3/userdata/logs`; s6 sends process output to the container logs.

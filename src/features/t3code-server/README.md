# T3 Code Server

Installs T3 Code for the selected service user and runs `t3 serve` as a native s6-overlay 3 service.

The Feature requires a Debian/Ubuntu image with s6-overlay 3 already installed. Node.js 24 is supplied through the official Dev Container Node Feature.

## Options

| Option        | Type   | Default     | Description                                                                                                                         |
| ------------- | ------ | ----------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `version`     | string | `latest`    | T3 Code npm package version to install.                                                                                             |
| `port`        | string | `3773`      | Port exposed by the T3 Code server.                                                                                                 |
| `host`        | string | `0.0.0.0`   | Interface to bind the T3 Code server to.                                                                                            |
| `serveMode`   | string | `""`        | Optional T3 runtime mode passed to `t3 serve --mode`. Empty preserves the T3 CLI default.                                           |
| `serviceUser` | string | `automatic` | User account that owns T3 and runs the service. Automatic selection prefers the remote user, container user, `vscode`, then `root`. |

## Example usage

```json
{
  "image": "ghcr.io/wyrd-company/devcontainers/base:noble",
  "features": {
    "ghcr.io/wyrd-company/devcontainers/t3code-server:2": {
      "port": "3773",
      "serveMode": "web"
    }
  }
}
```

## Pairing

The Feature does not install Codex. Add the separate Codex CLI Feature when needed.

To mint a pairing code at any time, run the command as the service user and use the same T3 base directory as the server:

```bash
sudo -u vscode t3 auth pairing create --base-dir /home/vscode/.t3
```

Replace `vscode` and its home directory when `serviceUser` resolves to another account. T3 writes its own logs beneath `<home>/.t3/userdata/logs`; s6 sends process output to the container logs.

# T3 Code Server

Installs T3 Code and configures a headless `systemd` service on Debian/Ubuntu-based images.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | T3 Code npm package version to install. |
| `nodeVersion` | string | `24` | Node.js major version to install if Node.js is missing or too old. |
| `port` | string | `3773` | Port exposed by the T3 Code server. |
| `host` | string | `0.0.0.0` | Interface to bind the T3 Code server to. |
| `serviceUser` | string | `automatic` | User account to run the service as. `automatic` prefers the remote user, then `vscode`, then `root`. |
| `installCodexCli` | boolean | `true` | Install the Codex CLI automatically when it is not already present. |
| `codexVersion` | string | `latest` | Codex CLI version to install when `installCodexCli` is enabled. |

## Example Usage

```json
{
  "features": {
    "ghcr.io/boblangley/features/t3code-server:1": {
      "port": "3773"
    }
  }
}
```

## Notes

T3 Code requires an authenticated Codex CLI. This Feature can install Codex automatically, but authentication still needs to happen after the container is created.

The service unit is installed for `systemd`. In containers where `systemd` is not running, the unit file will still be created, but the service will not be actively managed until a `systemd`-enabled environment is used.

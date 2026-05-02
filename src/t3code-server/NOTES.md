Installs the `t3` package and creates a `t3code.service` systemd unit that runs `t3 serve` in headless mode.

Defaults:

- host: `0.0.0.0`
- port: `3773`
- serve mode: unset (preserves the T3 CLI default; set `serveMode` to `web` to run `t3 serve --mode=web`)
- service user: remote user if available, otherwise `vscode`, otherwise `root`

Example usage:

```json
{
  "features": {
    "ghcr.io/boblangley/features/t3code-server:1": {
      "port": "3773",
      "serveMode": "web"
    }
  }
}
```

T3 Code requires an authenticated Codex CLI. This Feature can install Codex automatically, but you still need to authenticate it after container creation.

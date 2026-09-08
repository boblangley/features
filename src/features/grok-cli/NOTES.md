Runs xAI's native installer as the resolved Dev Container user and symlinks its user-owned executable into `/usr/local/bin/grok`.

The native installer also creates user-owned `grok` and `agent` aliases in `~/.local/bin`. It does not create `/usr/local/bin/agent`.

Example usage:

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/grok-cli:1": {}
  }
}
```

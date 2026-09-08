Runs xAI's native installer as the resolved Dev Container user and symlinks its user-owned executable into `/usr/local/bin/grok`.

The native installer creates optional user-local aliases. The Feature retains its `grok` alias but removes its `agent` alias, or restores a pre-existing `agent` entry, so other coding-agent Features remain composable.

Example usage:

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/grok-cli:1": {}
  }
}
```

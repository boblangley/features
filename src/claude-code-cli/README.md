# Claude Code CLI

Installs Claude Code using Anthropic's native Linux binary distribution and ensures `claude` is available on the container `PATH`.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Claude Code version to install. Use `latest` or a specific version like `1.0.58`. |

## Example Usage

```json
{
  "features": {
    "ghcr.io/boblangley/features/claude-code-cli:1": {}
  }
}
```

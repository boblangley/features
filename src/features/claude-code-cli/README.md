# Claude Code CLI

Installs Claude Code for the resolved Dev Container user using Anthropic's recommended native installer and ensures `claude` is available on the container `PATH`.

The executable, updater, and Claude state remain owned by the user rather than root.

## Options

| Option    | Type   | Default  | Description                                                                       |
| --------- | ------ | -------- | --------------------------------------------------------------------------------- |
| `version` | string | `latest` | Claude Code version to install. Use `latest` or a specific version like `1.0.58`. |

## Example Usage

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/claude-code-cli:1": {}
  }
}
```

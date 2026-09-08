# OpenCode CLI

Installs the OpenCode CLI for the resolved Dev Container user using OpenCode's native installer and ensures `opencode` is available on the container `PATH`.

The executable, updater, and OpenCode state remain owned by the user rather than root. The Feature does not require Homebrew.

## Options

| Option    | Type   | Default  | Description                                                                         |
| --------- | ------ | -------- | ----------------------------------------------------------------------------------- |
| `version` | string | `latest` | OpenCode CLI version to install. Use `latest` or a specific version like `1.18.25`. |

## Example usage

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/opencode-cli:1": {}
  }
}
```

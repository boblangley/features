# Grok CLI

Installs the Grok CLI for the resolved Dev Container user using xAI's native installer and ensures `grok` is available on the container `PATH`.

The executable, updater, and Grok state remain owned by the user rather than root.

The Feature does not retain xAI's optional `agent` alias, so it does not replace another tool that provides that command. It exposes only `grok` in `/usr/local/bin`.

## Options

| Option    | Type   | Default  | Description                                                                    |
| --------- | ------ | -------- | ------------------------------------------------------------------------------ |
| `version` | string | `latest` | Grok CLI version to install. Use `latest` or a specific version like `1.0.12`. |

## Example usage

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/grok-cli:1": {}
  }
}
```

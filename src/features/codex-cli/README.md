# Codex CLI

Installs the OpenAI Codex CLI from npm for the resolved Dev Container user. Node.js 24 LTS is supplied through the official Dev Container Node Feature.

The package, executable, and Codex state remain owned by the user rather than root.

## Options

| Option    | Type   | Default  | Description                            |
| --------- | ------ | -------- | -------------------------------------- |
| `version` | string | `latest` | Codex CLI version to install from npm. |

## Example usage

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/codex-cli:2": {}
  }
}
```

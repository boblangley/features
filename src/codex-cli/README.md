# Codex CLI

Installs the OpenAI Codex CLI and ensures `codex` is available on the container `PATH`.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Codex CLI version to install from npm. |
| `nodeVersion` | string | `24` | Node.js major version to install if Node.js is missing or too old. |

## Example Usage

```json
{
  "features": {
    "ghcr.io/boblangley/features/codex-cli:1": {}
  }
}
```

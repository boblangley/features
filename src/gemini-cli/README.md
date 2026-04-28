# Gemini CLI

Installs the Gemini CLI and ensures `gemini` is available on the container `PATH`.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `latest` | Gemini CLI version to install from npm. |
| `nodeVersion` | string | `24` | Node.js major version to install if Node.js is missing or too old. |

## Example Usage

```json
{
  "features": {
    "ghcr.io/boblangley/features/gemini-cli:1": {}
  }
}
```

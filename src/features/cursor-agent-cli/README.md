# Cursor Agent CLI

Installs the Cursor Agent CLI for the resolved Dev Container user using Cursor's recommended native installer and ensures `agent` and `cursor-agent` are available on the container `PATH`.

The installation, executable, updater, and Cursor state remain owned by the user rather than root. Cursor selects the installed CLI version and updates it in place because its installer does not expose a version argument.

## Example usage

```json
{
  "features": {
    "ghcr.io/wyrd-company/devcontainers/cursor-agent-cli:1": {}
  }
}
```

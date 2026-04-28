# features

Dev Container Features published from this repository to GHCR.

## Available features

- `ghcr.io/boblangley/features/codex-cli:1`: Installs the OpenAI Codex CLI and ensures `codex` is on `PATH`.
- `ghcr.io/boblangley/features/claude-code-cli:1`: Installs Claude Code using Anthropic's native Linux binary distribution and ensures `claude` is on `PATH`.
- `ghcr.io/boblangley/features/gemini-cli:1`: Installs the Gemini CLI and ensures `gemini` is on `PATH`.
- `ghcr.io/boblangley/features/t3code-server:1`: Installs T3 Code and configures a headless `systemd` service on Debian/Ubuntu-based images.

## Example

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:noble",
  "features": {
    "ghcr.io/boblangley/features/codex-cli:1": {},
    "ghcr.io/boblangley/features/claude-code-cli:1": {},
    "ghcr.io/boblangley/features/gemini-cli:1": {},
    "ghcr.io/boblangley/features/t3code-server:1": {}
  }
}
```

## Publishing

The repository includes `.github/workflows/cd.yml`, which publishes every feature under `src/` to GHCR using the official `devcontainers/action`.

After the first publish, set the generated GHCR packages to public if you want them to be consumable outside your account or organization.

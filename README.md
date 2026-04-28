# features

Dev Container Features published from this repository to GHCR.

## Available features

- `ghcr.io/boblangley/features/codex-cli:1`: Installs the OpenAI Codex CLI and ensures `codex` is on `PATH`.
- `ghcr.io/boblangley/features/claude-code-cli:1`: Installs Claude Code using Anthropic's native Linux binary distribution and ensures `claude` is on `PATH`.
- `ghcr.io/boblangley/features/gemini-cli:1`: Installs the Gemini CLI and ensures `gemini` is on `PATH`.
- `ghcr.io/boblangley/features/t3code-server:1`: Installs T3 Code and configures a headless `systemd` service on Debian/Ubuntu-based images.
- `ghcr.io/boblangley/features/hindsight-claude-code-plugin:1`: Installs the Hindsight long-term memory plugin into Claude Code and registers its hooks. Configurable for an external Hindsight server.
- `ghcr.io/boblangley/features/hindsight-codex-hooks:1`: Installs the Hindsight memory hooks for the OpenAI Codex CLI. Configurable for an external Hindsight server.

## Example

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:noble",
  "features": {
    "ghcr.io/boblangley/features/codex-cli:1": {},
    "ghcr.io/boblangley/features/claude-code-cli:1": {},
    "ghcr.io/boblangley/features/gemini-cli:1": {},
    "ghcr.io/boblangley/features/t3code-server:1": {},
    "ghcr.io/boblangley/features/hindsight-claude-code-plugin:1": {
      "hindsightApiUrl": "https://api.hindsight.vectorize.io"
    },
    "ghcr.io/boblangley/features/hindsight-codex-hooks:1": {
      "hindsightApiUrl": "https://api.hindsight.vectorize.io"
    }
  }
}
```

## Publishing

The repository includes `.github/workflows/cd.yml`, which publishes every feature under `src/` to GHCR using the official `devcontainers/action`.

After the first publish, set the generated GHCR packages to public if you want them to be consumable outside your account or organization.

Installs the Hindsight memory plugin into Claude Code and registers its hooks.

Requires `claude` to already be on `PATH` — pair this Feature with
`ghcr.io/boblangley/features/claude-code-cli`.

Example usage:

```json
{
  "features": {
    "ghcr.io/boblangley/features/claude-code-cli:1": {},
    "ghcr.io/boblangley/features/hindsight-claude-code-plugin:1": {
      "hindsightApiUrl": "https://api.hindsight.vectorize.io"
    }
  }
}
```

Local-daemon mode (no `hindsightApiUrl`) needs `uvx` and an LLM provider API key
(`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.) at runtime. Cloud mode only needs
the URL and an optional token.

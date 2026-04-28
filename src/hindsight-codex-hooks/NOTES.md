Installs Hindsight memory hooks for the OpenAI Codex CLI by running the
upstream `get-codex` installer in `--mode local`. Pair with
`ghcr.io/wyrd-company/features/codex-cli` so `codex` is on PATH.

Example usage:

```json
{
  "features": {
    "ghcr.io/wyrd-company/features/codex-cli:1": {},
    "ghcr.io/wyrd-company/features/hindsight-codex-hooks:1": {
      "hindsightApiUrl": "https://api.hindsight.vectorize.io"
    }
  }
}
```

Local-daemon mode (no `hindsightApiUrl`) needs `uvx` and an LLM provider API
key (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, etc.) at runtime. Cloud mode only
needs the URL and an optional token.

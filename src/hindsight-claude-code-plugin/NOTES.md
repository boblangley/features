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

Active retain scope is file-based. On each retain, the installed hook reads
`~/.hindsight/active-retain-scope.json` from the agent user's Hindsight profile.
Any orchestrator can write this file before starting an agent session:

```json
{
  "bankId": "bank-or-scope-id",
  "tags": ["scope:value", "workflow:value"]
}
```

Only `bankId` and `tags` are interpreted; additional producer-specific fields
are ignored. If the file is present and valid, `bankId` is used for that retain
call and the listed tags are merged with configured retain tags. If it is
absent, unreadable, or malformed, retain falls back silently to the install-time
bank and normal hook configuration. Env-var based per-invocation tagging is
intentionally not used. The file lives in the user profile rather than the
workspace so orchestration state does not need to be written into a repository
checkout.

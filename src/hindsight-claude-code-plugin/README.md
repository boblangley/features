# Hindsight Memory Plugin for Claude Code

Installs the [Hindsight](https://vectorize.io/hindsight) long-term memory plugin
into Claude Code. The plugin captures conversations and recalls relevant
context on each prompt.

By default the feature installs `hindsight-memory` from the `vectorize-io/hindsight`
marketplace and registers its hooks into the user's `~/.claude/settings.json`.
You can point the plugin at an external Hindsight server via the `hindsightApiUrl`
option — otherwise the plugin runs `hindsight-embed` locally on first use (which
requires `uvx` and an LLM provider API key in the runtime environment).

This Feature requires `claude` to already be on `PATH`. Pair it with
`ghcr.io/boblangley/features/claude-code-cli` in the same `features` block; the
ordering is enforced via `installsAfter`.

## Active Retain Scope

At retain time, the installed `Stop` hook reads an optional retain scope from
the agent user's Hindsight profile:

```text
~/.hindsight/active-retain-scope.json
```

Any orchestrator can write this file before starting an agent session. The hook
only depends on this generic shape:

```json
{
  "bankId": "bank-or-scope-id",
  "tags": ["scope:value", "workflow:value"]
}
```

Producers may include additional fields for their own bookkeeping; the hook
ignores fields other than `bankId` and `tags`.

When the file is present and parseable, `bankId` overrides the installed/default
bank for that retain call and `tags` are appended to any configured
`retainTags`. Missing, unreadable, or malformed files are treated as normal:
the hook silently falls back to the install-time bank and configured tags.

This is intentionally file-based rather than env-var based. Per-invocation
environment tagging is not the contract; the orchestrator owns the write side of
`~/.hindsight/active-retain-scope.json`, and the installed hooks own the read
side. The file lives in the user profile rather than the workspace so
orchestration state does not need to be written into a repository checkout.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `marketplace` | string | `vectorize-io/hindsight` | Marketplace source registered via `claude plugin marketplace add`. |
| `plugin` | string | `hindsight-memory` | Plugin to install. Use `name@marketplace` to disambiguate. |
| `scope` | string | `user` | Install scope passed through to `claude plugin install --scope`. |
| `hindsightApiUrl` | string | `""` | External Hindsight API URL. When set, written to `~/.hindsight/claude-code.json` so the plugin uses this server instead of starting a local daemon. |
| `hindsightApiToken` | string | `""` | Bearer token for the external API. Stored in `~/.hindsight/claude-code.json` with mode `0600`. Leave empty and set `HINDSIGHT_API_TOKEN` at runtime if you would rather not commit the token. |
| `bankId` | string | `""` | Override the static memory bank ID. Empty keeps the plugin default (`claude_code`). |
| `registerHooks` | boolean | `true` | Run the plugin's `setup_hooks.py` after install so hooks fire automatically. |
| `username` | string | `automatic` | Account that owns the install. `automatic` resolves to `$_REMOTE_USER`, then `vscode`, then `root`. |

## Example Usage

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

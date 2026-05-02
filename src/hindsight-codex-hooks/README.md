# Hindsight Memory Hooks for Codex CLI

Installs the [Hindsight](https://vectorize.io/hindsight) memory hooks
(`SessionStart`, `UserPromptSubmit`, `Stop`) for the OpenAI Codex CLI. The
feature runs the upstream `get-codex` installer in `--mode local` (so the
install is non-interactive) and, when `hindsightApiUrl` is set, writes
`~/.hindsight/codex.json` to point the hooks at an external Hindsight server.

After install:
- Hook scripts live at `~/.hindsight/codex/scripts/`
- `~/.codex/hooks.json` references those scripts
- `~/.codex/config.toml` enables `codex_hooks = true`

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

The hooks only fire when Codex CLI v0.116.0+ is installed. Pair this Feature
with `ghcr.io/boblangley/features/codex-cli` in the same `features` block —
ordering is enforced via `installsAfter`.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `installerUrl` | string | `https://hindsight.vectorize.io/get-codex` | Upstream installer URL. Override only to pin to a fork or air-gapped mirror. |
| `hindsightApiUrl` | string | `""` | External Hindsight API URL. When set, written to `~/.hindsight/codex.json` so hooks use this server instead of starting a local daemon. |
| `hindsightApiToken` | string | `""` | Bearer token for the external API. Stored in `~/.hindsight/codex.json` with mode `0600`. Leave empty and set `HINDSIGHT_API_TOKEN` at runtime if you would rather not commit the token. |
| `bankId` | string | `""` | Override the static memory bank ID. Empty keeps the installer default (`codex`). |
| `username` | string | `automatic` | Account that owns the install. `automatic` resolves to `$_REMOTE_USER`, then `vscode`, then `root`. |

## Example Usage

```json
{
  "features": {
    "ghcr.io/boblangley/features/codex-cli:1": {},
    "ghcr.io/boblangley/features/hindsight-codex-hooks:1": {
      "hindsightApiUrl": "https://api.hindsight.vectorize.io"
    }
  }
}
```

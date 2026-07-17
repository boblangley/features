T3 Code runs under s6-overlay using `${HOME}/.t3` as its base directory.

Mint a pairing code manually under the service user's home context:

```bash
sudo -u vscode t3 auth pairing create --base-dir /home/vscode/.t3
```

Codex is intentionally not installed by this Feature. Add `ghcr.io/wyrd-company/devcontainers/codex-cli:2` separately when needed.

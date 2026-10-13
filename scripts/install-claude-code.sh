#!/bin/bash
# install-claude-code.sh
# Installs the Claude Code CLI in the NSO dev container for terminal use.
# The VS Code extension (devcontainer.json) works on its own; this adds the `claude` command.

set -euo pipefail

if command -v claude >/dev/null 2>&1; then
    echo "[OK] Claude Code already installed ($(claude --version))"
    exit 0
fi

echo "[INFO] Installing Claude Code"
if curl -fsSL https://claude.ai/install.sh | bash; then
    ln -sf "${HOME}/.local/bin/claude" /usr/local/bin/claude
    echo "[OK] Claude Code installed. Run 'claude' or open the Claude Code panel."
else
    # Not fatal: the NSO environment is usable without the CLI.
    echo "[WARN] Claude Code CLI install failed. The VS Code extension still works."
fi

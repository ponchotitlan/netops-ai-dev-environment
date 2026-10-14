#!/bin/bash
# install-claude-code.sh
# Installs the Claude Code CLI in the NSO dev container for terminal use, and registers the
# github MCP server from the repo's .mcp.json at user scope.
# The VS Code extension (devcontainer.json) works on its own; this adds the `claude` command.

set -euo pipefail

MCP_CONFIG="/workspace/.mcp.json"

# Behind TLS inspection (Cisco Secure Access), add the CA from NODE_EXTRA_CA_CERTS to the
# system trust store too, so curl (and the installer) trust it. Node uses NODE_EXTRA_CA_CERTS.
if [[ -n "${NODE_EXTRA_CA_CERTS:-}" && -f "${NODE_EXTRA_CA_CERTS}" ]]; then
    if command -v update-ca-trust >/dev/null 2>&1; then
        cp "${NODE_EXTRA_CA_CERTS}" /etc/pki/ca-trust/source/anchors/extra-ca.crt
        update-ca-trust extract
        echo "[OK] Added ${NODE_EXTRA_CA_CERTS} to the system trust store"
    elif command -v update-ca-certificates >/dev/null 2>&1; then
        cp "${NODE_EXTRA_CA_CERTS}" /usr/local/share/ca-certificates/extra-ca.crt
        update-ca-certificates >/dev/null
        echo "[OK] Added ${NODE_EXTRA_CA_CERTS} to the system trust store"
    else
        echo "[WARN] No update-ca-trust or update-ca-certificates: CA not added for curl"
    fi
fi

if command -v claude >/dev/null 2>&1; then
    echo "[OK] Claude Code already installed ($(claude --version))"
else
    echo "[INFO] Installing Claude Code"
    if curl -fsSL https://claude.ai/install.sh | bash; then
        ln -sf "${HOME}/.local/bin/claude" /usr/local/bin/claude
        echo "[OK] Claude Code installed. Run 'claude' or open the Claude Code panel."
    else
        # Not fatal: the NSO environment is usable without the CLI.
        echo "[WARN] Claude Code CLI install failed. The VS Code extension still works."
        exit 0
    fi
fi

# Claude Code starts in /nso/run/packages, where there is no .mcp.json, so register the github
# server at user scope. ${GITHUB_PAT} stays literal and is expanded when Claude Code connects.
if [[ -f "${MCP_CONFIG}" ]]; then
    server_json="$(python3 -c 'import json, sys; print(json.dumps(json.load(open(sys.argv[1]))["mcpServers"]["github"]))' "${MCP_CONFIG}")"
    claude mcp remove --scope user github >/dev/null 2>&1 || true
    if claude mcp add-json --scope user github "${server_json}" >/dev/null; then
        echo "[OK] github MCP server registered (user scope)"
    else
        echo "[WARN] Could not register the github MCP server. Add it with 'claude mcp add-json'."
    fi
else
    echo "[WARN] ${MCP_CONFIG} not found: github MCP server not registered"
fi

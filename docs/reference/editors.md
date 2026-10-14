# 🧭 Using another editor

[← NSO example](../nso-service-packages.md)

The environment lives in the container, not in the editor: NSO, the netsims, the bootstrap, Claude Code and its standards (`CLAUDE.md`, hooks, skills, agents, GitHub MCP) are the same whichever editor you attach. VS Code is the documented and supported path. The editors below use the same `.devcontainer/devcontainer.json`, so the first start runs the same [`onCreateCommand` and `postCreateCommand` steps](./internals.md#-devcontainerdevcontainerjson).

> Whatever the editor, use Claude Code as the AI agent (`claude` in the container terminal, or its editor extension or plugin) so that everyone works under the same rules and hook checks. Built-in agents such as Cursor's or Windsurf's do not read `.claude/`, so the hooks don't check their edits.

## Cursor

1. Open the repository folder in Cursor (**File → Open Folder**).
2. Open the Extensions view and install **Dev Containers** (published by Anysphere) if it isn't installed yet. Microsoft's Dev Containers extension is licensed for VS Code only and doesn't work in Cursor.
3. Press `Ctrl + Shift + P` (`Cmd + Shift + P` on macOS) and run **Dev Containers: Reopen in Container**. You can also click the remote indicator in the bottom-left corner of the window.
4. Cursor reopens inside the container at `/nso/run/packages` and shows the bootstrap logs in the terminal, like VS Code does.

The extensions in `customizations.vscode` are installed from [Open VSX](https://open-vsx.org/) instead of Microsoft's marketplace. Python uses Cursor's own language server instead of Pylance. Ruff, YAML, Robot Framework and Claude Code work as in VS Code.

## Windsurf

1. Open the repository folder in Windsurf.
2. Press `Ctrl + Shift + P` (`Cmd + Shift + P` on macOS), type `container` and run **Reopen in Container**. Dev Containers support is built into Windsurf; the exact label may vary between versions.
3. Windsurf reopens inside the container at `/nso/run/packages`.

As with Cursor, extensions come from Open VSX and Python uses Windsurf's own language server.

## JetBrains IDEs (PyCharm, IntelliJ IDEA)

Dev Containers need a JetBrains IDE with Remote Development support (for example PyCharm Professional or IntelliJ IDEA Ultimate).

1. Open the repository folder in the IDE.
2. Open `.devcontainer/devcontainer.json`, click the container icon in the editor gutter and select **Create Dev Container and Mount Sources**. Alternatively, from the Welcome screen, go to **Remote Development → Dev Containers → New Dev Container**, choose **From Local Project** and select `.devcontainer/devcontainer.json`.
3. Pick the IDE to run in the container. The first start builds the Compose environment, runs the bootstrap and downloads the IDE backend into the container, so it takes a few extra minutes.
4. The IDE opens connected to the container. Open `/nso/run/packages` if it isn't the current project.

JetBrains ignores the `customizations.vscode` block, so configure Python, Ruff and Robot Framework support through the IDE's own plugins. Run `claude` in the IDE terminal, which runs inside the container, and optionally install the Claude Code plugin from the JetBrains Marketplace to see its diffs in the IDE.

## Any other editor, or the terminal only

The [Dev Containers CLI](https://github.com/devcontainers/cli) starts the environment without an IDE. It needs Node.js on the host.

```bash
# From the repository root: build, start and bootstrap the environment
npx @devcontainers/cli up --workspace-folder .

# Open a shell inside the container (starts in /nso/run/packages), then run `claude`
npx @devcontainers/cli exec --workspace-folder . bash
```

Edit your services in `source/packages/` on the host with any editor (Neovim, Zed, Sublime Text...). The changes show up in the container straight away.

## Stopping the container outside VS Code

The `shutdownAction` setting only applies in VS Code. In the other editors and with the CLI, the container keeps running after you close the window. Stop it and start it again with:

```bash
docker stop nso-dev
docker start nso-dev
```

# ⚙️ Under the hood

[← NSO example](../nso-service-packages.md)

What each file does and how the container is put together. You don't need any of this to use
the environment. It's here for when you want to change or debug it.

## 📁 Files in this repository

| File/Directory   | Purpose |
|------------------|---------|
| `.devcontainer/devcontainer.json` | The core of our dev env. Here we specify how to spin it up and what to deploy |
| `Dockerfile` | For building our custom NSO development image |
| `requirements.txt` | Python dependencies to install in our custom NSO development image |
| `artifacts.yaml` | NEDs and other binaries to deploy in our custom NSO development image |
| `docker-compose.yml` | Main container orchestration for the NSO service. To be used by devcontainer.json |
| `docker-compose-override.yml` | Mounting of Makefile and scripts for housekeeping actions when spinning up a new container. To be used by devcontainer.json |
| `bootstrap/` | Pre-configurations for our NSO environment |
| `config/runtime/` | ncs.conf for our NSO environment. This one enables RESTCONF and specifies multiple package locations |
| `source/packages/` | Source tree for custom NSO services (`-cfs`/`-rfs`) |
| `Makefile` | Simple commands to build and manage your environment |
| `scripts/` | Automation bash scripts for build, install, compile, reload, and netsims creation |
| `nso-lab-topology.yaml` | Lab topology definition used for NSO environment setup |
| `CLAUDE.md` | Project memory for Claude Code: NSO coding standards, naming rules, commands and workflow |
| `.claude/settings.json` | Shared Claude Code permissions, enabled MCP servers and hooks |
| `.claude/hooks/` | Automatic checks: package naming, ruff, YANG compilation, YANG/template/Python consistency |
| `.claude/skills/` | `/start-my-day`, `/new-service`, `/reload-packages`, `/test-service`, `/ship-it` |
| `.claude/agents/nso-reviewer.md` | Subagent that reviews packages against the standards and NSO best practices |
| `.mcp.json` | GitHub MCP server for issues, pull requests and the project board |
| `ruff.toml` | Python coding standards as ruff rules (naming, docstrings, type hints) |
| `.github/` | Issue templates and pull request template |

> The runtime config in `config/runtime/ncs.conf` separates NEDs and artifacts (`/opt/ncs/packages`) from your services (`/nso/run/packages`) for a clean development experience.

## 🐳 `Dockerfile`

This Dockerfile does the following:

1. Pull the base image specified in `NSO_BASE`.
2. Install the Python libraries mentioned in the `requirements.txt` file using `pip`.
3. Download the artifacts mentioned in the URLs of the file `artifacts.yaml`.
4. Extract the artifacts in the folder `/opt/ncs/packages` of the NSO container. This folder is enabled for NSO packages as per the `ncs.conf` file in this repository
5. Delete all these support files once everything is set and done

## 🧰 `.devcontainer/devcontainer.json`

This project relies heavily on the file `.devcontainer/devcontainer.json`, where we specify the behaviour of the NSO dev container and the dev environment when being deployed.

In a nutshell, this is what happens:

1. Your IDE (VS Code, or any editor with Dev Containers support) reads `.devcontainer/devcontainer.json` and starts the environment using `docker-compose.yml` plus `docker-compose-override.yml`.
2. It opens the `dev-main` service as the main development container and sets `/nso/run/packages` as the working folder inside the container.
3. When the container is created, it runs `make -C /workspace-tools wait-ready` to wait until the NSO server inside of the container has fully booted.
4. After that, it runs `make -C /workspace-tools init claude-code` to compile your packages, load your preconfigs, create your netsims, onboard them + sync-from them in NSO, and install the Claude Code CLI.
5. The IDE waits for that initialization step to finish before marking the dev container as fully ready for use.
6. Once the container is up, VS Code (and VS Code forks such as Cursor) automatically installs the listed extensions, such as Claude Code, Python, Ruff, YAML, and Robot Framework support. In VS Code, the Python extension brings Pylance with it.
7. It also applies the editor settings defined in the file, such as format-on-save, Ruff fixes on save, Python analysis defaults, and test configuration.

The following table describes in detail the parameters of the `.devcontainer/devcontainer.json` file:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `name` | `NetAuto Dev Environment` | Defines the display name of the dev container in VS Code. |
| `dockerComposeFile` | `../docker-compose.yml`, `../docker-compose-override.yml` | Tells VS Code which Compose files must be used to build the development environment. |
| `service` | `dev-main` | Selects which Compose service will be used as the main development container. |
| `workspaceFolder` | `/nso/run/packages` | Defines the folder that VS Code opens by default inside the container. |
| `shutdownAction` | `stopCompose` | Tells VS Code to stop the Compose environment when the dev container session is closed. |
| `onCreateCommand` | `make -C /workspace-tools wait-ready` | Runs once when the container is first created, and waits for the NSO server to be ready. |
| `postCreateCommand` | `make -C /workspace-tools init claude-code` | Runs after container creation to initialize the development environment and install the Claude Code CLI. |
| `waitFor` | `postCreateCommand` | Tells VS Code to wait for the initialization step to finish before marking the container as ready. |
| `customizations` | `vscode` extensions and settings | Defines the editor experience for VS Code and its forks (Cursor, Windsurf), such as which extensions are installed and which editor settings are applied automatically. Other editors ignore it. |


## 🧩 `docker-compose.yml` and `docker-compose-override.yml`

This is what's going on with these files:

1. `docker-compose.yml` defines the main container called `dev-main`, gives it the name `nso-dev`, and tells Docker which image to run using the `NSO_IMAGE` variable from the `.env` file.
2. That same file mounts the main runtime folders into the container, including your service packages, ncs.conf config, initial configs, and lab topology file. These directories are specified in the `.env` file.
3. It exposes the NSO HTTP and SSH ports from the container to your host machine using the values defined in your `.env` file.
4. It also injects the admin credentials and extra startup arguments that NSO needs when the container boots.
5. The healthcheck in `docker-compose.yml` makes Docker verify that NSO has really started before the environment is considered healthy.
6. `docker-compose-override.yml` adds extra bind mounts only for development convenience: the local `Makefile` and `scripts/` folder under `/workspace-tools`, and the whole repository under `/workspace` (with `.git` hidden). Nothing is mounted into `/nso/run/packages`, which keeps only your packages: `CLAUDE.md` goes to `/nso/run/CLAUDE.md` (Claude Code reads it from parent folders), and `.claude/settings.json`, `hooks/`, `skills/` and `agents/` to the user-level `/root/.claude/`. `make claude-code` registers the github server from `.mcp.json` at user scope. It also keeps Claude Code's login in a named volume, trusts the Cisco Secure Access CA (`NODE_EXTRA_CA_CERTS`), and passes `GITHUB_PAT` and `GITHUB_REPOSITORY` to the container.
7. Those extra mounts are what allow the devcontainer commands such as `make -C /workspace-tools wait-ready` and `make -C /workspace-tools init` to run inside the container using the files from your repository.

> In practice, the base compose file runs the NSO container itself, and the override file adds the extra tooling that makes the container usable as a full development environment.

The following table describes the `docker-compose.yml` mounted volumes:

| Host source (variables in the `.env` file) | Container target | Purpose |
|-------------|------------------|---------|
| `${HOST_PACKAGES_DIR}` | `/nso/run/packages` | Mounts your NSO service packages into the container so you can develop them live from the repository. |
| `${HOST_RUNTIME_CONFIG_DIR}` | `/nso/etc` | Mounts the `ncs.conf` and related runtime assets. |
| `${HOST_BOOTSTRAP_DIR}` | `/tmp/nso` | Mounts the initial NSO configuration files. |
| `${HOST_TOPOLOGY_FILE}` | `/tmp/nso-lab-topology.yaml` | Mounts the lab topology definition used to create and onboard the netsim devices. |


## 🛠️ `Makefile` and `scripts/`

The `Makefile` is the main entry point for the workflow, and each target delegates the real work to one bash script under `scripts/`.

| Target | Script | What it does |
|--------|--------|--------------|
| `make build` | `scripts/build-image.sh` | Builds your custom NSO Docker image. |
| `make push` | `scripts/push-image.sh` | Pushes the image to the container registry defined in your `.env` file. |
| `make build-push` | Composite target | Runs `build` first and then `push`. |
| `make compile` | `scripts/compile-packages.sh` | Compiles the NSO service packages found in `source/packages`. |
| `make preconfig-reload` | `scripts/nso-load.sh` | Loads the NSO preconfiguration files found in `bootstrap/init`. |
| `make topology` | `scripts/load-netsims.sh` | Creates the netsim devices, onboards them into NSO, and issues a sync-from on each. |
| `make init` | Composite target | Runs `compile`, `preconfig-reload`, and `topology` in sequence. |
| `make wait-ready` | `scripts/devcontainer-init.sh` | Waits until the NSO server is fully started before the rest of the automation continues. |
| `make claude-code` | `scripts/install-claude-code.sh` | Installs the Claude Code CLI in the container (the VS Code extension works without it). |

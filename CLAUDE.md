# NSO service packages

Cisco NSO service packages developed in a container-based environment. Claude Code reads these
standards, and hooks in `.claude/` enforce them.

## Where things are

The dev container opens at `/nso/run/packages`, which is `source/packages/` in the repository:
only the service packages. The rest of the repository is at `/workspace` (e.g.
`/workspace/.github/pull_request_template.md`). Inside the container this file is mounted at
`/nso/run/CLAUDE.md`, and the settings, hooks, skills and agents at `/root/.claude/`
(`docker-compose-override.yml`).

- `<package>/src/yang/*.yang`: data model, compiled by `ncsc` into `<package>/load-dir/`
- `<package>/python/<package_underscored>/main.py`: service callbacks and `Main` application
- `<package>/templates/*.xml`: XML config templates, applied from Python
- `<package>/package-meta-data.xml`: package name and the Python class NSO starts
- `<package>/tests/`: Robot Framework tests (`<package>.robot`, `input_*.json`, `expected_*.txt`)
- `/workspace-tools/`: the repo `Makefile` and `scripts/` (read-only)
- Netsim devices come from `nso-lab-topology.yaml`: `asr9k-xr-7601`, `ncs5k-xr-5702`
  (IOS XR), `router-ios-01`, `switch-ios-01` (IOS), `asa-fw-01`, `asa-virtual-02` (ASA)

## Commands (inside the dev container)

- `make -C /workspace-tools compile`: compile every package (`make clean all` in each `src/`)
- `echo "packages reload" | ncs_cli -Cu admin`: load compiled packages into NSO
- `echo "show packages package oper-status" | ncs_cli -Cu admin`: check packages are `up`
- `cd <package>/tests && robot <package>.robot`: run a package's Robot tests
- `ruff check <path>` / `ruff format <path>`: lint and format (rules in `ruff.toml` at the repository root)

## Naming

- Every package folder and service name ends with `-cfs` (customer-facing) or `-rfs`
  (resource-facing): `my-vpn-service-cfs`, `vlan-config-rfs`. Never `my-service`.
- Servicepoints follow `<list-name>-<package>-servicepoint`, e.g.
  `access-list-acl-rfs-servicepoint`.
- Python: snake_case for functions and variables, PascalCase for classes.
- Template variables are UPPER_SNAKE_CASE: `{$DEVICE}`, `vars.add("DEVICE", ...)`.

## Code style

- Type hints on every parameter and return value. Use `typing` for anything Python 3.9 lacks.
- A Google-style docstring on every module, class and function:

  ```python
  def configure_device(device: str, config: dict) -> bool:
      """Push a configuration snippet to a device.

      Args:
          device: Device name in /devices/device.
          config: Parameters for the template.

      Returns:
          True when the template was applied.

      Raises:
          ValueError: If the device name is empty.
      """
  ```

- PEP 8, line length 100. ruff enforces naming, docstrings, type hints and import order.

## NSO guidelines

- Service callbacks use the NSO decorators and names: `@Service.create` on `cb_create`,
  `cb_pre_modification`, `cb_post_modification`.
- Import from the `ncs` package (`ncs.application.Service`, `ncs.template`, `ncs.maapi`).
- `cb_create` must be deterministic: same input, same output (FASTMAP). No reads of external
  systems, no timestamps, no random values in it.
- Configure devices through XML templates with `ncs.template.Variables`, not by writing device
  config from Python. Python computes values; templates own device syntax.
- Use the transaction NSO gives you (`root`, `service`). Don't open your own MAAPI write
  transaction inside a callback.
- Log with `self.log`, never `print`.
- Templates must use the right NED namespace for the target platform, e.g.
  `http://tail-f.com/ned/cisco-ios-xr` for IOS XR.
- A YANG change needs a compile and a `packages reload` before Python or tests see it.

## Checks that run automatically

- **Before a write or `ncs-make-package`**: package names without `-cfs`/`-rfs` are blocked.
- **After every edit**: ruff formats and lints Python; YANG is compiled with `ncsc`; every
  `{$VAR}` in a template must be set in Python (and the other way round),
  `template.apply("x")` must have `templates/x.xml`, servicepoints in YANG and in
  `register_service()` must match, and `package-meta-data.xml` must point at a real class.

Fix what they report before moving on. Existing code that predates these rules gets fixed the
first time you edit the file.

## Tests

Every service has a Robot test in `<package>/tests/` that creates and then changes an instance
through RESTCONF and compares the device config with `expected_create.txt` and
`expected_change.txt`. Update the inputs and expected outputs with every model or template
change.

## Project workflow

- Work is tracked in GitHub issues and the project board, through the `github` MCP server.
  Start from an issue; reference it in branches, commits and PRs.
- The target repository is `$GITHUB_REPOSITORY` (`owner/repo`, set in `.env`): read it with
  `echo $GITHUB_REPOSITORY` and use it for every github MCP call. If it is empty, fall back to
  `git remote get-url origin` on the host, or ask the user once.
- Branch `<type>/<issue>-<slug>`, Conventional Commits:
  `feat(acl-rfs): support IPv6 destinations (#12)`.
- The repository's `.git` is not mounted in the container: commit and push from a terminal on
  the host. Pull requests use `.github/pull_request_template.md` and say `Closes #<issue>`.

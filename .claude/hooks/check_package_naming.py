"""PreToolUse hook: block package names that do not end with `-cfs` or `-rfs`.

Runs before Write, Edit, MultiEdit and Bash. It blocks (exit code 2, reason on stderr):

- writing a file into a package folder whose name has no `-cfs`/`-rfs` suffix, and
- `ncs-make-package` calls that would create such a package.
"""

import json
import os
import shlex
import sys
from pathlib import Path
from typing import Any, Optional

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nso_packages import has_valid_suffix, package_name_for  # noqa: E402

_SEPARATORS = {";", "&&", "||", "|", "&"}


def _rule(name: str) -> str:
    """Build the message Claude Code gets back when a name is blocked.

    Args:
        name: The rejected package name.

    Returns:
        The reason, with a suggested name.
    """
    return (
        f"Package name '{name}' is not allowed: every package and service name must end with "
        f"'-cfs' (customer-facing) or '-rfs' (resource-facing), e.g. '{name}-rfs'. "
        "See CLAUDE.md, section Naming."
    )


def _make_package_names(command: str) -> list[str]:
    """Find the package names an `ncs-make-package` command would create.

    Args:
        command: Bash command line.

    Returns:
        The package name argument and the `--dest` folder name of every `ncs-make-package` call.
    """
    try:
        tokens = shlex.split(command, posix=True)
    except ValueError:
        tokens = command.split()

    names: list[str] = []
    for start, token in enumerate(tokens):
        if os.path.basename(token) != "ncs-make-package":
            continue
        args: list[str] = []
        for arg in tokens[start + 1 :]:
            if arg in _SEPARATORS:
                break
            args.append(arg)
        if args and not args[-1].startswith("-"):
            names.append(args[-1])
        if "--dest" in args[:-1]:
            names.append(Path(args[args.index("--dest") + 1]).name)
    return names


def _blocked_name(payload: dict[str, Any]) -> Optional[str]:
    """Return the first invalid package name the tool call would create or write to.

    Args:
        payload: Hook input from Claude Code.

    Returns:
        The invalid name, or None when the call is fine.
    """
    tool = payload.get("tool_name", "")
    tool_input = payload.get("tool_input", {}) or {}
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR") or payload.get("cwd") or os.getcwd()

    if tool == "Bash":
        for name in _make_package_names(tool_input.get("command", "")):
            if not has_valid_suffix(name):
                return name
        return None

    path = tool_input.get("file_path", "")
    name = package_name_for(path, project_dir) if path else None
    if name and not has_valid_suffix(name):
        return name
    return None


def main() -> int:
    """Read the hook payload from stdin and block invalid package names.

    Returns:
        0 to allow the tool call, 2 to block it.
    """
    name = _blocked_name(json.load(sys.stdin))
    if name:
        print(_rule(name), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())

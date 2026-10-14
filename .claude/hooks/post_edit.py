"""PostToolUse hook: apply the package standards to every file Claude Code edits.

After each Write, Edit or MultiEdit:

- Python: `ruff format` and `ruff check --fix`, with the rules in `ruff.toml` (repo root).
- YANG: the package is compiled with `ncsc` (`make clean all` in its `src/`).
- Anything in a package: YANG, Python, templates and `package-meta-data.xml` must agree
  (see `nso_packages.check_package`).

Problems are sent back to Claude Code (exit code 2, details on stderr) so it fixes them right
away. Tools that are missing (no ruff or ncsc, e.g. on the host) are skipped, not reported.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from nso_packages import check_package, find_package_root  # noqa: E402

_NCSC_MISSING = 99
_COMPILE = (
    "source /etc/profile >/dev/null 2>&1; "
    f"command -v ncsc >/dev/null 2>&1 || exit {_NCSC_MISSING}; "
    'make -C "$1" clean all'
)


def _ruff(path: Path) -> list[str]:
    """Format and lint a Python file with ruff.

    Args:
        path: Python file that was edited.

    Returns:
        The lint errors ruff could not fix, if any.
    """
    if not shutil.which("ruff"):
        return []
    subprocess.run(["ruff", "format", "--quiet", str(path)], check=False)
    lint = subprocess.run(
        ["ruff", "check", "--fix", "--quiet", "--output-format", "concise", str(path)],
        capture_output=True,
        text=True,
        check=False,
    )
    if lint.returncode == 0:
        return []
    return [
        f"ruff found problems in {path.name} (rules in ruff.toml at the repo root):",
        (lint.stdout or lint.stderr).strip(),
    ]


def _compile_yang(package: Path) -> list[str]:
    """Compile a package's YANG model with ncsc.

    Args:
        package: Package folder.

    Returns:
        The compiler output when the compile failed, otherwise nothing.
    """
    src = package / "src"
    if not (src / "Makefile").is_file():
        return []
    result = subprocess.run(
        ["bash", "-c", _COMPILE, "compile", str(src)],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode in (0, _NCSC_MISSING):
        return []
    output = (result.stdout + result.stderr).strip().splitlines()
    return [f"YANG compile failed for {package.name} (make clean all in src/):", *output[-40:]]


def main() -> int:
    """Read the hook payload from stdin and check the edited file.

    Returns:
        0 when everything is clean, 2 when Claude Code has something to fix.
    """
    payload = json.load(sys.stdin)
    file_path = (payload.get("tool_input") or {}).get("file_path", "")
    if not file_path or not os.path.isfile(file_path):
        return 0
    path = Path(file_path).resolve()
    package = find_package_root(str(path))

    problems: list[str] = []
    if path.suffix == ".py" and "load-dir" not in path.parts:
        problems += _ruff(path)
    if package is not None:
        if path.suffix == ".yang":
            problems += _compile_yang(package)
        problems += check_package(package)

    if problems:
        print("\n".join(problems), file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())

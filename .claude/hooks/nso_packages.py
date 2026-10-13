"""Shared helpers for the Claude Code hooks: find NSO packages and check their consistency.

The checks are plain text parsing (no `ncs` import), so they run the same inside the NSO dev
container (`/nso/run/packages`) and on the host (`source/packages`).
"""

import os
import re
from pathlib import Path
from typing import Optional

PACKAGE_SUFFIXES = ("-cfs", "-rfs")

_TEMPLATE_VAR = re.compile(r"\$([A-Za-z_][A-Za-z0-9_]*)")
_TEMPLATE_SET = re.compile(r"<\?set\s+([A-Za-z_][A-Za-z0-9_]*)\s*=")
_TEMPLATE_BRACES = re.compile(r"\{[^{}]*\}|<\?[^?]*\?>")
_VARS_ADD = re.compile(r"\.add\(\s*['\"]([A-Za-z_][A-Za-z0-9_]*)['\"]")
_APPLY = re.compile(r"\.apply\(\s*['\"]([^'\"]+)['\"]")
_REGISTER = re.compile(r"register_service\(\s*['\"]([^'\"]+)['\"]")
_SERVICEPOINT = re.compile(r"servicepoint\s+['\"]?([A-Za-z0-9_.-]+)['\"]?\s*;")
_PYTHON_CLASS = re.compile(r"<python-class-name>\s*([\w.]+)\s*</python-class-name>")


def packages_dir(project_dir: str) -> Path:
    """Return the folder that holds the service packages.

    Args:
        project_dir: Claude Code project folder (`$CLAUDE_PROJECT_DIR`).

    Returns:
        `source/packages` on the host, or the project folder itself inside the container,
        where the workspace is `/nso/run/packages`.
    """
    root = Path(project_dir).resolve()
    host_layout = root / "source" / "packages"
    return host_layout if host_layout.is_dir() else root


def package_name_for(path: str, project_dir: str) -> Optional[str]:
    """Return the package folder a path belongs to, even if the package does not exist yet.

    Args:
        path: File or folder path, absolute or relative to the project folder.
        project_dir: Claude Code project folder (`$CLAUDE_PROJECT_DIR`).

    Returns:
        The first folder under the packages folder, or None for paths outside it, files at its
        top level (`ruff.toml`, `CLAUDE.md`) and hidden folders (`.claude`, `.github`).
    """
    pkgs = packages_dir(project_dir)
    full = Path(path) if os.path.isabs(path) else Path(project_dir) / path
    try:
        parts = full.resolve().relative_to(pkgs).parts
    except ValueError:
        return None
    if len(parts) < 2 or parts[0].startswith("."):
        return None
    return parts[0]


def has_valid_suffix(name: str) -> bool:
    """Tell whether a package or service name ends with `-cfs` or `-rfs`.

    Args:
        name: Package or service name.

    Returns:
        True when the name has one of the allowed suffixes.
    """
    return name.endswith(PACKAGE_SUFFIXES)


def find_package_root(path: str) -> Optional[Path]:
    """Walk up from a file to the package that contains it.

    Args:
        path: Absolute path of a file inside a package.

    Returns:
        The folder holding `package-meta-data.xml`, or None if the file is not in a package.
    """
    current = Path(path).resolve().parent
    for folder in [current, *current.parents]:
        if (folder / "package-meta-data.xml").is_file():
            return folder
    return None


def _read(path: Path) -> str:
    """Read a text file, tolerating encoding errors.

    Args:
        path: File to read.

    Returns:
        The file contents.
    """
    return path.read_text(encoding="utf-8", errors="replace")


def _python_files(package: Path) -> list[Path]:
    """List the Python sources of a package.

    Args:
        package: Package folder.

    Returns:
        Every `.py` file under `python/`.
    """
    return sorted((package / "python").rglob("*.py"))


def _template_variables(text: str) -> set[str]:
    """Collect the `$VARS` a template uses, minus those it defines itself with `<?set ...?>`.

    Args:
        text: XML template contents.

    Returns:
        Variable names used inside `{...}` expressions and processing instructions.
    """
    used: set[str] = set()
    for expression in _TEMPLATE_BRACES.findall(text):
        used.update(_TEMPLATE_VAR.findall(expression))
    return used - set(_TEMPLATE_SET.findall(text))


def check_package(package: Path) -> list[str]:
    """Check that the YANG model, Python code, templates and package metadata agree.

    Args:
        package: Package folder.

    Returns:
        One human-readable problem per line; empty when the package is consistent.
    """
    problems: list[str] = []
    package = package.resolve()
    name = package.name
    python_text = "\n".join(_read(p) for p in _python_files(package))
    templates_dir = package / "templates"
    templates = sorted(templates_dir.glob("*.xml")) if templates_dir.is_dir() else []

    # Template variables <-> vars.add()
    set_in_python = set(_VARS_ADD.findall(python_text))
    used_in_templates: set[str] = set()
    for template in templates:
        used = _template_variables(_read(template))
        used_in_templates |= used
        for var in sorted(used - set_in_python):
            problems.append(
                f"{name}: templates/{template.name} uses {{${var}}} but no Python code sets it "
                f'with vars.add("{var}", ...)'
            )
    for var in sorted(set_in_python - used_in_templates):
        if templates:
            problems.append(
                f'{name}: Python sets vars.add("{var}", ...) but no template uses {{${var}}}'
            )

    # template.apply("x") -> templates/x.xml
    for template_name in sorted(set(_APPLY.findall(python_text))):
        if not (templates_dir / f"{template_name}.xml").is_file():
            problems.append(
                f'{name}: template.apply("{template_name}") has no templates/{template_name}.xml'
            )

    # Servicepoints: YANG <-> register_service()
    yang_points: set[str] = set()
    for yang in sorted((package / "src" / "yang").glob("*.yang")):
        yang_points.update(_SERVICEPOINT.findall(_read(yang)))
    python_points = set(_REGISTER.findall(python_text))
    for point in sorted(yang_points - python_points):
        problems.append(
            f"{name}: YANG declares servicepoint {point} but no register_service() uses it"
        )
    for point in sorted(python_points - yang_points):
        problems.append(
            f"{name}: register_service('{point}', ...) has no matching servicepoint in YANG"
        )

    # package-meta-data.xml -> a real Python class
    meta = _read(package / "package-meta-data.xml")
    for dotted in _PYTHON_CLASS.findall(meta):
        module, _, cls = dotted.rpartition(".")
        module_file = package / "python" / Path(*module.split(".")).with_suffix(".py")
        if not module_file.is_file():
            problems.append(
                f"{name}: package-meta-data.xml points at {dotted}, but "
                f"python/{module.replace('.', '/')}.py does not exist"
            )
        elif not re.search(rf"^class\s+{re.escape(cls)}\b", _read(module_file), re.MULTILINE):
            problems.append(
                f"{name}: package-meta-data.xml points at {dotted}, but class {cls} is not "
                f"defined in python/{module.replace('.', '/')}.py"
            )

    return problems

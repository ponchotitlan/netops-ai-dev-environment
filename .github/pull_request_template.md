## What

<!-- One or two sentences: what this changes and why. -->

Closes #

## Packages

<!-- Each package touched, and what changed in it (YANG, template, Python, tests). -->

- `xxx-rfs`:

## How it was tested

- [ ] `make -C /workspace-tools compile` passes
- [ ] Every package is `up` after `packages reload`
- [ ] Robot tests pass: `robot <package>.robot`
- [ ] `input_*.json` / `expected_*.txt` updated for model or template changes
- [ ] `ruff check` is clean

## Checklist

- [ ] Package and service names end with `-cfs` / `-rfs`
- [ ] `cb_create` is deterministic (no timestamps, random values or external calls)
- [ ] Device config is in templates, with the right NED namespace
- [ ] Reviewed by the `nso-reviewer` subagent (or a teammate)

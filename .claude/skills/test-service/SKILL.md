---
name: test-service
description: Runs the Robot Framework tests of an NSO service package against the local NSO and netsims, and explains failures. Use when the user asks to test a service, after changing a package, or before shipping.
argument-hint: <package-name>
---

# Test service

Package: `$ARGUMENTS`. If it is empty, use the package of the files changed most recently, or ask.

## 1. Preconditions

1. The package is `up`: `echo "show packages package <name> oper-status" | ncs_cli -Cu admin`.
   If not, run `/reload-packages` first.
2. The test device is in sync. Find it in `${test_device_container}` in the `.robot` file, then
   `echo "devices device <netsim> check-sync" | ncs_cli -Cu admin`. If it is out of sync, ask
   before running `sync-from`.

## 2. Run

```bash
cd /nso/run/packages/<name>/tests && robot <name>.robot
```

## 3. Explain

- **All pass:** say so, with the test count.
- **A comparison failed:** show the diff between the actual config and `expected_*.txt`, and say
  which one is wrong. Usually it is the template or the Python, sometimes an outdated expected
  file after an intentional model change. Only update `expected_*.txt` when the user agrees the
  new output is right.
- **A RESTCONF error** (4xx/5xx): read the response in `log.html`, check the payload in
  `input_*.json` against the YANG model, and check the package is `up`.

Robot rewrites `log.html`, `report.html` and `output.xml` in `tests/` on every run. Mention them
if they changed, so the user can decide whether to commit them.

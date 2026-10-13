---
name: new-service
description: Scaffolds a new NSO service package (python-and-template skeleton) that follows the project standards - -cfs/-rfs naming, Google docstrings, type hints, template variables, servicepoint naming, and a Robot test - then compiles and reloads it. Use when the user wants a new service or package.
argument-hint: <package-name> <what the service configures>
---

# New service

Arguments: `$ARGUMENTS` (package name, then a description of what the service configures).

## 1. Settle the design first

1. **Name.** It must end with `-cfs` (customer-facing) or `-rfs` (resource-facing). If the user
   gave a name without a suffix, propose one and ask; a hook blocks the wrong name anyway.
2. **Target devices and NED.** Pick the netsim and NED from `/tmp/nso-lab-topology.yaml`
   (IOS XR: `asr9k-xr-7601`, `ncs5k-xr-5702`; IOS: `router-ios-01`, `switch-ios-01`;
   ASA: `asa-fw-01`, `asa-virtual-02`). The template namespace must match the NED, e.g.
   `http://tail-f.com/ned/cisco-ios-xr`.
3. **Model.** Propose the YANG inputs (list name, keys, leaves, types) and the device config
   they produce. Show it to the user and wait for an OK before generating files.

## 2. Scaffold

```bash
cd /nso/run/packages
ncs-make-package --service-skeleton python-and-template <package-name>
```

Then shape the skeleton to the standards (`CLAUDE.md`). Use `acl-rfs` as the reference for
layout, not for style: it predates the rules.

- `src/yang/<package>.yang`: the service list with `uses ncs:service-data;` and
  `ncs:servicepoint <list-name>-<package>-servicepoint;`. A `device` leaf with a
  `leafref` to `/ncs:devices/ncs:device/ncs:name`.
- `templates/<template>.xml`: device config only, with `{$UPPER_SNAKE_CASE}` variables and the
  right NED namespace.
- `python/<package_underscored>/main.py`:
  - module, class and method docstrings (Google style) and type hints everywhere;
  - a `Service` subclass in PascalCase with `@Service.create` on `cb_create`;
  - `cb_create` is deterministic: it reads only `service` and `root`, computes values, sets
    every template variable with `vars.add("NAME", ...)` and calls `template.apply("<template>",
    vars)`. No timestamps, random values or external calls. Log with `self.log`;
  - `Main.setup()` calls `self.register_service("<list-name>-<package>-servicepoint", ...)`.
- `package-meta-data.xml`: `python-class-name` is `<package_underscored>.main.Main`.

The hooks check all of this after every edit (ruff, YANG compile, template variables, template
names, servicepoints, the Python class). Fix whatever they report before moving on.

## 3. Robot test

Create `tests/` like `acl-rfs/tests/`:

- `<package>.robot`: one test that creates an instance and one that changes it, through
  RESTCONF (`http://localhost:8080/restconf/data/<package>:<list-name>`), each comparing
  `show running-config devices device <netsim> config ...` with an expected file.
- `input_create.json`, `input_change.json`: the RESTCONF payloads.
- `expected_create.txt`, `expected_change.txt`: the expected device config. Generate them from a
  real run only after checking by eye that the output is what the user asked for.

## 4. Compile, reload, test

Run `/reload-packages` (the new package must be `up`), then `/test-service <package-name>`.
Finish with a short summary: files created, the servicepoint, the template variables and the
test result.

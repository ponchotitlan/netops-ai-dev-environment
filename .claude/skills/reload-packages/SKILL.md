---
name: reload-packages
description: Compiles the NSO service packages and reloads them into the running NSO, then checks that every package is up. Use after YANG or Python changes, when a package is down, or when the user asks to reload.
---

# Reload packages

## 1. Compile

```bash
make -C /workspace-tools compile
```

It runs `make clean all` in every `<package>/src`. If a package fails, show the `ncsc` error
with its file and line, fix it (or explain it), and compile again. Don't reload a package that
does not compile.

## 2. Reload

`packages reload` restarts every package's Python VM, so it asks for permission:

```bash
echo "packages reload" | ncs_cli -Cu admin
```

## 3. Check

```bash
echo "show packages package oper-status" | ncs_cli -Cu admin
```

Every package must be `up`. For one that is not:

1. Show its error: `echo "show packages package <name> oper-status error-info" | ncs_cli -Cu admin`.
2. For Python errors, read the end of its Python VM log:
   `tail -n 50 /log/ncs-python-vm-<name>.log` (find the file with `ls /log/ | grep python-vm`).
3. Explain the cause in one or two lines (import error, wrong class in `package-meta-data.xml`,
   servicepoint mismatch, YANG not compiled) and propose the fix.

## 4. Report

One line per package: name and status. If all are `up`, say so in the first line.

---
name: ship-it
description: Finishes the current task. Lints, compiles, reloads and tests the changed packages, gets a review from the nso-reviewer subagent, gives the commit and push commands to run on the host, and opens the pull request through the github MCP server. Use when the user says the task is done or asks to open a PR.
disable-model-invocation: true
---

# Ship it

## 1. Find the change

1. Ask for the issue number and branch name (`<type>/<issue>-<slug>`) if you don't know them.
   The container has no `.git`, so you can't read the branch yourself.
2. List the packages that changed. Ask the user, or run `git status` / `git diff --stat` if you
   are on the host.

## 2. Gate

Stop and fix (or report) at the first failure. Don't ship red.

1. `ruff check <package>/python` and `ruff format --check <package>/python` for each package.
2. `/reload-packages`: everything compiles and every package is `up`.
3. `/test-service <package>` for each changed package. If the model or template changed, the
   `input_*.json` and `expected_*.txt` files must have changed too.

## 3. Review

Ask the `nso-reviewer` subagent to review the changed packages. Fix anything it marks as
**blocking**, or tell the user why not.

## 4. Commit and push (on the host)

Give the user the commands to run in a terminal on the host, for example:

```bash
git switch -c feat/12-acl-ipv6          # if the branch doesn't exist yet
git add source/packages/acl-rfs
git commit -m "feat(acl-rfs): support IPv6 destinations (#12)"
git push -u origin feat/12-acl-ipv6
```

Conventional Commits, with the package as the scope and the issue number at the end. Leave out
Robot output files (`log.html`, `report.html`, `output.xml`) unless the user wants them.

## 5. Pull request (github MCP server)

Once the user confirms the push:

1. `create_pull_request` against `main`, filling in `.github/pull_request_template.md`. The body
   must say `Closes #<issue>`, which packages changed, and how they were tested.
2. Ask before moving the project item to **In review** (`projects_write`).
3. Reply with the PR URL and a two-line summary.

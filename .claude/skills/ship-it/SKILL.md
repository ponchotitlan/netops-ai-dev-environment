---
name: ship-it
description: Finishes the current task. Lints, compiles, reloads and tests the changed packages, gets a review from the nso-reviewer subagent, pushes the change to a branch and opens the pull request through the github MCP server. Use when the user says the task is done or asks to open a PR.
disable-model-invocation: true
---

# Ship it

Every GitHub call goes to `$GITHUB_REPOSITORY` (`owner/repo`, see `CLAUDE.md`). If the github
tools are missing, the MCP server isn't connected: `GITHUB_PAT` is probably not set (see
`docs/setup.md`). Say so and stop after step 3.

## 1. Find the change

1. Ask for the issue number if you don't know it. Read it with `issue_read` for the title and
   acceptance criteria.
2. Branch name: `<type>/<issue>-<slug>` from the issue (e.g. `feat/12-acl-ipv6`). Confirm it with
   the user.
3. List the packages that changed. On the host, `git status` / `git diff --stat`. In the
   container there is no `.git`: ask the user, or compare a package with `main` (step 4.2).

## 2. Gate

Stop and fix (or report) at the first failure. Don't ship red.

1. `ruff check <package>/python` and `ruff format --check <package>/python` for each package.
2. `/reload-packages`: everything compiles and every package is `up`.
3. `/test-service <package>` for each changed package. If the model or template changed, the
   `input_*.json` and `expected_*.txt` files must have changed too.

## 3. Review

Ask the `nso-reviewer` subagent to review the changed packages, with the issue number. Fix
anything it marks as **blocking**, or tell the user why not.

## 4. Push (github MCP server)

The container has no `.git`, so the change goes to GitHub through the MCP server as one commit
on a new branch. Package `<pkg>` is at `/nso/run/packages/<pkg>/` locally and at
`source/packages/<pkg>/` in the repository.

1. `list_branches`: if the branch doesn't exist, `create_branch` from `main`.
2. Work out the files, per changed package:
   - **Local files:** everything under the package except what `.gitignore` excludes:
     `load-dir/`, `__pycache__/`, `*.pyc`, `output.xml`, `log.html`, `report.html`, `.DS_Store`.
     Text files only; if there is a binary file, stop and ask.
   - **Remote files:** `get_file_contents` on `source/packages/<pkg>/` (and each subfolder) on
     the branch. Files there but not local were deleted.
   - Skip local files whose content matches the remote one.
3. Show the user the list (added, changed, deleted) and the commit message, and wait for a yes.
   Conventional Commits, package as the scope, issue at the end:
   `feat(acl-rfs): support IPv6 destinations (#12)`.
4. `push_files` with every added and changed file, full content, repo-relative paths, on the
   branch, in one call with that message.
5. `delete_file` for each deleted file, on the branch.

**On the host** (`.git` exists), commit and push with git instead, after the user agrees:
`git switch -c <branch>`, `git add source/packages/<pkg>`, `git commit -m "..."`,
`git push -u origin <branch>`.

## 5. Pull request (github MCP server)

1. `list_pull_requests` with the branch as `head`: if a PR is open, update it
   (`update_pull_request`) instead of opening another.
2. Otherwise `create_pull_request` from the branch to `main`. Title: the commit message. Body:
   `.github/pull_request_template.md` (`/workspace/.github/` in the container), filled in. It
   must say `Closes #<issue>`, which packages changed and how, and tick the test boxes that
   passed in step 2.
3. Ask before moving the project item to **In review** (`projects_write`).
4. Reply with the PR URL and a two-line summary. On the host, remind the user to
   `git fetch && git switch <branch>` if the push went through MCP.

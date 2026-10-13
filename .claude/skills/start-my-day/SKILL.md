---
name: start-my-day
description: Morning brief for this NSO project. Pulls the user's assigned issues for the current sprint from GitHub through the github MCP server, checks that NSO packages are up and netsims are in sync, and suggests what to work on first. Use when the user says good morning, asks what to work on today, or runs /start-my-day.
---

# Start my day

Build a short morning brief, then help the user pick up their first task.

## 1. Find the sprint and my work (github MCP server)

1. `get_me` tells you who the user is.
2. Find the repository: `git remote get-url origin` works on the host. Inside the container
   `.git` is not mounted, so ask the user once if you can't tell (`owner/repo`).
3. The current sprint is the open milestone with the nearest due date.
4. List the open issues in that milestone assigned to the user. Look them up on the project
   board (`projects_list` / `projects_get`) to get each item's **Status**.
5. Also list open pull requests where the user's review is requested.

If the github tools are missing, `GITHUB_PAT` is probably not set in `.env`: say so and carry on
with step 2.

## 2. Check NSO (read-only)

Run these once each. They only read state; don't reload, sync or fix anything here.

```bash
echo "show packages package oper-status" | ncs_cli -Cu admin
echo "devices check-sync" | ncs_cli -Cu admin
```

Note any package that is not `up` and any device that is not `in-sync`. If `ncs_cli` fails,
NSO is not running: suggest reopening the dev container.

## 3. Write the brief

Keep it under 20 lines:

- Sprint name, goal (milestone description) and days left.
- Table of the user's items: `#`, title, status. In progress first, then Todo.
- Reviews waiting for them.
- NSO: one line, OK or what is off (packages down, devices out of sync).
- Suggested first task, and why (in progress beats new; blockers for teammates beat the rest;
  a package that is down beats everything, use `/reload-packages`).

## 4. Start the task

Ask which item to start. Once the user picks one:

1. Read the issue and its acceptance criteria.
2. Give the branch name `<type>/<issue>-<slug>` and the command to create it on the host
   (`git switch -c ...`). The container has no `.git`.
3. Ask before moving the project item to **In progress** (`projects_write`).
4. Summarize what changes in which package (YANG, template, Python, tests) and propose a plan.
   Don't write code until the user agrees.

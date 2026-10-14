<h1 align="center">🛠️📦 NetOps AI Development Environment<br /><br />

<div align="center">
  <img src="https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&labelColor=555555&logoColor=white" alt="Docker"/>
  <img src="https://img.shields.io/badge/Dev%20Containers-any%20IDE-blue" alt="Dev Containers"/>
  <img src="https://img.shields.io/badge/Claude%20Code-D97757?style=flat&logo=anthropic&labelColor=555555&logoColor=white" alt="Claude Code"/>
  <img src="https://img.shields.io/badge/Cisco%20NSO-1BA0D7?style=flat&logo=cisco&labelColor=555555&logoColor=white" alt="NSO"/>
</div></h1>

**Most network automation projects don't have a code problem. They have an environment problem.**

Answer these about your current project:

- How long did your last new team member take to push their first working change?
- Does your lab topology exist anywhere other than someone's laptop?
- If two engineers write the same service, does it look like one team wrote it?
- If the requirements change tomorrow, can you rebuild everything with one command?

If any answer made you wince, this page takes five minutes to read.

---

## 💸 What a poor environment costs you

| Symptom | What it really costs |
|---------|----------------------|
| **Wasted developer time** | Engineers debug their setup instead of working on the user story. |
| **Team friction, inconsistent code** | Everyone has their own style, so reviews argue about formatting instead of logic. |
| **"Works on my machine"** | A different library or plugin version on each laptop. Bugs show up only for someone else. |
| **Chaos when requirements change** | The environment gets rebuilt by hand from memory, and delivery slips. |

None of these appear in a sprint report as "environment". They appear as missed estimates.

## 🏛️ The three pillars of a good dev environment

1. **Standardization.** The same platform, versions, testbeds, libraries and code standards for
   everyone, including the AI assistant.
2. **Documentation.** Clear, current setup steps that live next to the code and change in the same
   pull request. LLMs are good at keeping them up to date.
3. **Ease of setup.** Minimal manual steps and no hardcoded tweaks. If a step needs a wiki page,
   script it.

> **The test:** a new engineer clones the repository and has a working lab before lunch.

## 🧮 The equation

```text
    NetAuto orchestrator / framework
  + Libraries
  + Network plugins
  + Lab topology
  + Coding standards           (for people and AI assistants alike)
  + AI support                 (hooks, skills, agents, MCP servers)
  ─────────────────────────────
  = Your NetAuto code project
```

Leave any term out and someone on the team rebuilds it by hand. In this repository, every term is
a versioned file:

| Term | In the NSO example |
|------|--------------------|
| Orchestrator / framework | The official Cisco NSO container image, extended by [`Dockerfile`](./Dockerfile) |
| Libraries | [`requirements.txt`](./requirements.txt) |
| Network plugins | NEDs listed by URL in [`artifacts.yaml`](./artifacts.yaml) |
| Lab topology | [`nso-lab-topology.yaml`](./nso-lab-topology.yaml): netsims created and synced on startup |
| Coding standards | [`CLAUDE.md`](./CLAUDE.md) and [`ruff.toml`](./ruff.toml) |
| AI support | [`.claude/`](./.claude/) (hooks, skills, agents) and the GitHub MCP server |

Not using NSO? The equation holds for other stacks. With Ansible, the framework is an execution
environment image and the plugins are network collections. With OpenTofu, the plugins are
providers. In either case the lab can be Containerlab or CML.

## 🐳 Run the framework as a container

- **Modular architecture.** Add or remove components depending on what the project needs.
- **Orchestration options.** Docker Compose can describe several setups (for example a minimal one
  and a full lab) with profiles and override files.
- **It's probably already done for you.** Most network automation platforms ship a container
  version.

The point isn't fashion. The environment becomes something you can delete and get back in
minutes.

## 📦 Treat artifacts as dependencies, not attachments

- **What they are:** the binaries your environment needs, such as the drivers or plugins that talk
  to a specific vendor or device type.
- **Where they live:** an artifact server. Not a shared drive, and not a chat thread.
- **How they arrive:** downloaded by URL while the environment is set up, ideally with an
  authenticated request. Changing a version means changing one line and rebuilding.

## 🤖 AI is a foundation, not a bolt-on

Skeptical of AI coding assistants? Good. The fix isn't trusting the model more. It's giving it
less room to be wrong. An assistant that has never seen your rules writes code that looks like
nobody's, so build the rules into the environment:

| Building block | What it is | Why a skeptic should care |
|----------------|------------|---------------------------|
| **Hooks** | Automatic checks that run at set points | They're scripts, not prompts. The model can't argue its way past a failing lint or compile. |
| **Skills** | Packaged instructions, loaded only when a task needs them | Team procedures (scaffold a service, open a PR) run the same way every time. |
| **Agents** | Separate, focused AI workers given self-contained jobs | A reviewer with read-only tools and a fresh context isn't biased by the code it just wrote. |
| **MCP servers** | Standardized connections to external systems, tools and data | Issues, PRs and the project board without copy-paste, under permissions you set. |

All of it is committed to the repository, so every engineer and the assistant work under the
same rules.

## ✅ Key takeaways

1. **Treat environments as sprint deliverables**, with stories, reviews and acceptance criteria.
2. **Keep the documentation current**, updated in the same PR that changes the setup.
3. **Test your setup scripts regularly**, on every host type your team uses.
4. **Keep the environment in the code repository**, not next to it.

---

## 🔬 See it working: NSO service packages

This repository applies every pillar to Cisco NSO service development. Clone it, fill in `.env`
and reopen it in a container. You get:

- NSO with your NEDs and service packages loaded
- Six netsim devices (IOS XR, IOS, ASA), onboarded and synced
- Claude Code with the team's standards, hooks, skills, a reviewer agent and GitHub MCP

**→ [Read the NSO walkthrough](./docs/nso-service-packages.md)**

## 📚 References

- [Development Containers specification](https://containers.dev)
- [Docker Compose profiles](https://docs.docker.com/compose/how-tos/profiles/)
- [Claude Code documentation](https://code.claude.com/docs)
- [Model Context Protocol](https://modelcontextprotocol.io)
- [DEVNET-2224: DevOps for NSO](https://github.com/ponchotitlan/embracing-devops-nso-usecase-lifecycle)

---

<div align="center"><br />
    Made with ☕️ by Poncho Sandoval - <code>Developer Advocate 🥑 @ DevNet - Cisco Systems 🇵🇹</code><br /><br />
    <a href="mailto:alfsando@cisco.com?subject=Question%20about%20[NetOps%20AI%20Dev%20Env]&body=Hello,%0A%0AI%20have%20a%20question%20regarding%20your%20project.%0A%0AThanks!">
        <img src="https://img.shields.io/badge/Contact%20me!-blue?style=flat&logo=gmail&labelColor=555555&logoColor=white" alt="Contact Me via Email!"/>
    </a>
    <a href="https://github.com/ponchotitlan/netops-ai-dev-environment/issues/new">
      <img src="https://img.shields.io/badge/Open%20Issue-2088FF?style=flat&logo=github&labelColor=555555&logoColor=white" alt="Open an Issue"/>
    </a>
    <a href="https://github.com/ponchotitlan/netops-ai-dev-environment/fork">
      <img src="https://img.shields.io/badge/Fork%20Repository-000000?style=flat&logo=github&labelColor=555555&logoColor=white" alt="Fork Repository"/>
    </a>
</div>

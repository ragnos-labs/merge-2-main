# AGENTS.md

Runtime-agnostic multi-agent coordination methodology. This repo documents
coordination patterns for Claude Code, Codex, and OpenClaw. It contains no
executable code; every file here is a markdown doc or JSON/TOML template.

This file is both a Codex bootstrap (agents read it cold before any task) and a
working example of what a good AGENTS.md looks like.

---

## Repo Purpose

**merge-2-main** is a methodology library for orchestrating 2 to 30+ AI coding
agents on real software engineering work. It documents four coordination
patterns, one infrastructure layer, cross-cutting guides, reference schemas,
and worked examples. Hive Mind is the first complete layer; more layers are
planned.

The framework is tool-agnostic: the patterns and principles apply regardless of
whether you are running on Claude Code, Codex, or OpenClaw. Runtime-specific
notes live under `docs/runtimes/`.

---

## Repo Structure

```
docs/
  core/
    patterns/   # Universal coordination patterns
    guides/     # Universal operating guidance
    references/ # Schemas, anti-patterns, prompt design
    examples/   # Worked examples with explicit runtime assumptions
  runtimes/     # Claude Code, Codex, and OpenClaw docs
  templates/    # Universal templates plus runtime-specific configs
```

No source code lives here. Every file is documentation.

---

## The Golden Rule

Agents working on this repo must follow these rules on every task.

1. **Read before editing.** Always read a doc before modifying it. Never
   assume its current state matches what you were told.

2. **No executable code files.** This is a documentation-only repository.
   Do not create `.py`, `.js`, `.ts`, `.sh`, or any other executable file.
   Contributions are doc improvements, new examples, and corrections only.

3. **Commit format is `docs: <imperative>`.** All commits use conventional
   commits with the `docs` scope. Example: `docs: add worker swarm example
   for notification system`. Never use any other scope prefix.

4. **Never commit directly to main.** Always branch and open a pull request.
   Branch naming: `docs/<short-slug>`.

5. **One agent per document.** If two agents are running in parallel, they
   must not edit the same file. Claim a file before writing to it. Resolve
   conflicts at the planning step, not at merge time.

---

## Behavioral Contracts

These XML blocks are executable contracts for Codex agents. They apply to all
tasks in this repo unless the task prompt explicitly overrides a specific item.

<completeness_contract>
Finish what you start. Never leave a document in a partially edited state.
If a task involves multiple sections in one file, complete all sections before
committing. If a task is interrupted, restore the file to its last valid
complete state before stopping. Partial docs break readers who arrive cold.
</completeness_contract>

<file_ownership>
Before writing to any file, verify that no other active agent in this session
is editing the same file. If you detect a conflict (concurrent write to the
same path), stop, report the conflict to the orchestrator, and wait for
explicit reassignment. Do not attempt to merge concurrent edits yourself.
One owner per file per phase. No exceptions.
</file_ownership>

<verification_loop>
After every edit to a document:
1. Re-read the full file.
2. Verify your change appears exactly as intended.
3. Verify you did not accidentally remove or corrupt adjacent content.
4. Only then stage and commit.

Do not commit immediately after writing. The re-read step is mandatory.
</verification_loop>

---

## Quick Start (Codex Users)

Four things to know before spawning agents on this repo.

**1. Entry point for pattern and runtime docs.**
Start with `docs/runtimes/codex/overview.md`, then read
`docs/runtimes/codex/setup-and-agents-md.md` if you need the full Codex
bootstrap flow.

**2. Concurrency limit.**
Codex defaults to 6 simultaneous agent threads (`max_threads = 6`). Design
your decomposition to fit within this budget. For topologies larger than 6
active threads, run in waves: close completed threads before spawning the
next batch. A config template lives at `docs/templates/codex/codex-config.toml`.

**3. CLI vs IDE context loading.**
Codex CLI reads `AGENTS.md` automatically at session start. Codex IDE (web)
does not auto-load it; paste the relevant section as an XML block into your
session prompt. Role config files in `docs/templates/codex/codex-agents/` are
formatted for direct paste into IDE sessions.

**4. Pattern selection.**
Start with `docs/core/guides/decision-tree.md`. After you pick a pattern,
switch to the matching runtime doc under `docs/runtimes/`.

**5. Codex subagent defaults.**
Subagents are opt-in. Spawn them when the user explicitly asks to parallelize,
delegate, swarm, or speed work up. Keep the immediate blocker on the main
thread. Default to 2 to 4 concurrent child agents, keep write ownership
disjoint, and ask children for concise structured handoffs instead of raw
dumps.

**6. Instruction hygiene.**
Keep root `AGENTS.md` short and stable. Put role-specific behavior in
`.codex/agents/*.toml` and deeper runtime detail in `docs/runtimes/`. If the
file grows, split guidance into nested overrides rather than inflating the root
bootstrap. If instructions look stale in Codex, restart the session in the
target directory so the instruction chain is rebuilt.

---

## Runtime Coverage

The patterns documented here are runtime-agnostic. They have been validated on:

- **Claude Code** (Anthropic): `TeamCreate`, `SendMessage`, `Task` tool,
  `run_in_background=true`
- **Codex** (OpenAI): `spawn_agent`, `send_input`, `wait`, `close_agent`
- **OpenClaw**: session dispatch plus announce-back orchestration

Primitive mappings between runtimes are in `docs/runtimes/` and the short
compatibility section in `docs/core/patterns/overview.md`.

---

## Suggested Next Step

A `.codex/agents/` directory with per-role `.toml` config files would make
role assignment automatic at spawn time. Template configs already exist at
`docs/templates/codex/codex-agents/`. Copying them to `.codex/agents/` with final
values would complete the Codex bootstrap layer.

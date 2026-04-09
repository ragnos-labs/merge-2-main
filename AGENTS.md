# AGENTS.md

Runtime-agnostic multi-agent coordination methodology. This repo documents
coordination patterns for Claude Code, Codex, and OpenClaw. It contains no
executable code; every file here is a markdown doc or JSON/TOML template.

This file is both a Codex bootstrap (agents read it cold before any task) and a
working example of what a good AGENTS.md looks like.

---

## Repo Purpose

**merge-2-main** is a methodology library for orchestrating 2 to 30+ AI coding
agents on real software engineering work. It documents five coordination
patterns plus cross-cutting guides, reference schemas, and worked examples.
Hive Mind is the first complete layer; more layers are planned.

The framework is tool-agnostic: the patterns and principles apply regardless of
whether you are running on Claude Code, Codex, or OpenClaw. Runtime-specific
adapter notes live in `docs/patterns/codex-runtime.md`.

---

## Repo Structure

```
docs/
  patterns/     # Five coordination patterns + Codex runtime adapter
  guides/       # Cross-cutting practices: model selection, TDD, checkpoints
  references/   # Anti-patterns, handoff schemas, templates, prompt design
  templates/    # Copy-paste JSON, TOML, and prompt starters
  examples/     # Full end-to-end worked examples for each pattern
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
`docs/patterns/codex-runtime.md` covers Codex-specific primitives, topology
diagrams, handoff formats, the run ledger schema, and prompt templates for
each role (orchestrator, lead, worker, explorer, verifier).

**2. Concurrency limit.**
Codex defaults to 6 simultaneous agent threads (`max_threads = 6`). Design
your decomposition to fit within this budget. For topologies larger than 6
active threads, run in waves: close completed threads before spawning the
next batch. A config template lives at `docs/templates/codex-config.toml`.

**3. CLI vs IDE context loading.**
Codex CLI reads `AGENTS.md` automatically at session start. Codex IDE (web)
does not auto-load it; paste the relevant section as an XML block into your
session prompt. Role config files in `docs/templates/codex-agents/` are
formatted for direct paste into IDE sessions.

**4. Pattern selection.**
Start with `docs/guides/decision-tree.md`. Five questions, under 60 seconds,
picks the right pattern. When unsure, default to Worker Swarm: it is the
simplest multi-agent pattern and the easiest to recover from if you picked
wrong.

---

## Runtime Coverage

The patterns documented here are runtime-agnostic. They have been validated on:

- **Claude Code** (Anthropic): `TeamCreate`, `SendMessage`, `Task` tool,
  `run_in_background=true`
- **Codex** (OpenAI): `spawn_agent`, `send_input`, `wait`, `close_agent`
- **OpenClaw**: follows the Claude Code coordination model

Primitive mappings between runtimes are in `docs/patterns/codex-runtime.md`
and `docs/patterns/overview.md`.

---

## Suggested Next Step

A `.codex/agents/` directory with per-role `.toml` config files would make
role assignment automatic at spawn time. Template configs already exist at
`docs/templates/codex-agents/`. Copying them to `.codex/agents/` with final
values would complete the Codex bootstrap layer.

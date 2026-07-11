---
title: Codex Setup and AGENTS.md
description: Codex bootstrap rules, AGENTS.md expectations, and per-role config guidance.
---

# Codex Setup and AGENTS.md

Codex sub-agents start with less inherited session context than Claude Code
teammates. That makes repo bootstrap quality a first-order concern.

## Required bootstrap

- Put `AGENTS.md` at the repo root
- Keep it concise enough to fit in startup context
- Put role-specific overrides in `.toml` files or equivalent config
- Restate file ownership and acceptance criteria in the task prompt, not only
  in `AGENTS.md`
- Keep subagents opt-in unless the operator explicitly wants delegation
- Keep the root file stable and small; move depth into nested overrides and
  role configs

## CLI vs IDE

- Local Codex sessions typically auto-discover `AGENTS.md`
- Other Codex surfaces may require you to paste or inject the relevant
  bootstrap context manually before spawning child agents
- If guidance looks stale, restart Codex in the target directory; instruction
  discovery is rebuilt at session start

## Recommended supporting files

- `.codex/agents/` for per-role config
- A runtime ledger for long-running orchestration
- Runtime-portable prompt templates rather than Claude Code tool names
- Nested `AGENTS.override.md` files near specialized work instead of one bloated
  root file

## Operational defaults

- Keep the immediate blocker on the parent thread; delegate bounded sidecars
- Start with 2 to 4 concurrent subagents, not a maximum-width swarm
- Run read-only exploration before write-capable workers
- Require concise output formats for every child prompt
- Close finished child agents promptly so the thread and compute budget returns
  to the parent run
- Use worktrees for parallel write-capable workstreams; prompt-only ownership
  is not enough when agents commit in the same repository

## Subagent design checklist

For any non-trivial Codex sprint, write a short subagent design before spawning:

- what the parent thread keeps
- which lanes are delegated
- owned files or search areas per lane
- first wave size and reserved verifier capacity
- model or effort target per role
- handoff format per role
- merge or review point

If the lanes are not independent, do not spawn yet. Reduce the work to
Patchwork or run a read-only Research Swarm first.

Templates in this repo:

- `../../templates/codex/codex-config.toml`
- `../../templates/codex/codex-agents/`
- `./hive-mind-orchestration.md`

For current product behavior, verify the live runtime docs from
`../../core/references/ecosystem-source-map.md`.

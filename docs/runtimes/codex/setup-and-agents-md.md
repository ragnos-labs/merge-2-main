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

## CLI vs IDE

- Codex CLI auto-loads `AGENTS.md`
- Codex IDE users should paste the relevant bootstrap context manually before
  spawning child agents

## Recommended supporting files

- `.codex/agents/` for per-role config
- A runtime ledger for long-running orchestration
- Runtime-portable prompt templates rather than Claude Code tool names

Templates in this repo:

- `../../templates/codex/codex-config.toml`
- `../../templates/codex/codex-agents/`

---
title: Codex Primitives and Limits
description: Core Codex coordination primitives, concurrency constraints, and sandbox behavior.
---

# Codex Primitives and Limits

Codex runs the universal patterns through sandboxed agent threads or task
surfaces.

## Primary Primitives

- `spawn_agent`
- `send_input`
- `wait`
- `close_agent`

## Execution Model

- The parent session orchestrates multiple isolated agent sandboxes rather than
  one shared team surface.
- Shared state must be written to files, passed in prompts, or reconstructed
  from the runtime ledger.
- Durable coordination is emulated through files and handoffs because there is
  no native TeamCreate equivalent.

## Operational Limits

- Parallelism is capped per session, so larger swarms must run in waves
- Agents start from isolated filesystem snapshots
- Treat thread budget and file ownership as hard planning constraints, not soft
  runtime advice
- Verify exact primitive names and current runtime limits against the official
  Codex docs before treating them as fixed.

## Routing Guidance

- Choose Codex when sandbox isolation and explicit handoffs are an advantage,
  not overhead.
- Prefer it over Claude Code when repo bootstrap, role config, or programmatic
  orchestration are the decisive constraints.
- Prefer it over OpenClaw for primary coding, debugging, and review loops.

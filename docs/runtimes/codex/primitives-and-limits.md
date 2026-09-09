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
- `wait_agent` or the runtime's equivalent wait primitive
- `close_agent`

## Execution Model

- Children have separate task contexts and inherit the active permission policy.
  Local children may share a filesystem. Assign worktrees explicitly when Git
  state must be isolated.
- Shared state must be written to files, passed in prompts, or reconstructed
  from the runtime ledger.
- Durable coordination is emulated through files and handoffs because there is
  no native TeamCreate equivalent.
- The parent keeps the immediate blocker on its own thread and delegates
  bounded sidecar tasks that can run while the parent continues useful work.
- Close finished child threads when their slots are needed. Closing a thread
  releases concurrency, not tokens already consumed.

## Operational Limits

- Parallelism is capped per session, but the exact cap depends on the Codex
  surface, account, and deployment mode. Larger swarms must run in waves.
- Agents start from isolated task context. Do not assume a child inherits the
  parent conversation or another child's findings unless you pass that context
  explicitly.
- Treat thread budget, compute window, and file ownership as hard planning
  constraints, not soft runtime advice.
- Prefer 2 to 4 concurrent child agents by default. Scale wider only when file
  ownership is disjoint and the parent can still review the outputs.
- Verify exact primitive names and current runtime limits against the official
  Codex docs before treating them as fixed.
- Delegate only after a direct request or applicable project or skill
  instruction. A configuration cap enables capacity, not task authority.

## Routing Guidance

- Choose Codex when sandbox isolation and explicit handoffs are an advantage,
  not overhead.
- Prefer it over Claude Code when repo bootstrap, role config, or programmatic
  orchestration are the decisive constraints.
- Prefer it over OpenClaw for primary coding, debugging, and review loops.

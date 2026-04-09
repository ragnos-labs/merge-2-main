---
title: Codex Primitives and Limits
description: Core Codex coordination primitives, concurrency constraints, and sandbox behavior.
---

# Codex Primitives and Limits

Codex runs the universal patterns through sandboxed agent threads or task
surfaces.

Typical primitives:

- `spawn_agent`
- `send_input`
- `wait`
- `close_agent`

Important constraints:

- Parallelism is capped per session, so larger swarms must run in waves
- Agents start from isolated filesystem snapshots
- Shared state must be written to files, passed in prompts, or reconstructed
  from the runtime ledger
- There is no native TeamCreate equivalent, so durable coordination is
  emulated through files and handoffs

Operational rule:

- Treat thread budget and file ownership as hard planning constraints, not soft
  runtime advice

Verify exact primitive names and current runtime limits against the official
Codex docs before treating them as fixed.

---
title: Codex Primitives and Limits
description: Core Codex coordination primitives, thread limits, and sandbox behavior.
---

# Codex Primitives and Limits

Codex runs the universal patterns through sandboxed agent threads.

Primary primitives:

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

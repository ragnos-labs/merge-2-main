---
title: Claude Code Runtime
description: When to use Claude Code as the runtime surface for the universal multi-agent patterns.
---

# Claude Code Runtime

Claude Code is the most ergonomic runtime in this repo for interactive
multi-agent coding. Use it when you want native sub-agent spawning, direct
interactive control, and the shortest path from pattern selection to execution.

Best fit:

- Human-in-the-loop coding sessions
- Hive Mind runs that benefit from native team or message primitives
- Research or fix workflows where built-in web and file tooling matter

Not the main fit:

- Ambient or cron-style automation
- Daemonized background orchestration

Start here, then continue to:

- [Primitives and Limits](./primitives-and-limits.md)
- [Pattern Adapters](./pattern-adapters.md)
- [Core Decision Tree](../../core/guides/decision-tree.md)

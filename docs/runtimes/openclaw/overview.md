---
title: OpenClaw Runtime
description: When to use OpenClaw as the runtime surface for the universal multi-agent patterns.
---

# OpenClaw Runtime

OpenClaw is a distinct runtime surface, not just another spelling of Claude
Code or Codex. It is strongest when you need ambient, daemon-style, or
scheduled agent execution rather than an on-demand interactive coding loop.

Best fit:

- Cron-driven or always-on automation
- Background workflows where completion is posted back to another surface
- Background orchestration where the caller does not block on every child task

Not the main fit:

- Primary on-demand coding sessions
- Human-steered interactive debugging

Continue to:

- [Primitives and Limits](./primitives-and-limits.md)
- [Pattern Adapters](./pattern-adapters.md)
- [Bedrock Gotchas](./bedrock-gotchas.md)

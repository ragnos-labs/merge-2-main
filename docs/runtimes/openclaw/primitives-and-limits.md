---
title: OpenClaw Primitives and Limits
description: OpenClaw dispatch model, announce-back behavior, and concurrency limits.
---

# OpenClaw Primitives and Limits

OpenClaw uses session dispatch plus announce-back completion, which makes it
feel closer to a daemon or control plane than to an interactive terminal agent.

Primary characteristics:

- Dispatch via `sessions_spawn`
- Completion posted back to a shared channel
- Default concurrency around 8 sessions
- Shallow default nesting unless explicitly configured otherwise
- Machine-to-machine dispatch available through its gateway surface

Design implication:

- Prefer OpenClaw for durable background work, not for the repo's primary
  interactive coding path.

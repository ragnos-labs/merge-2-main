---
title: OpenClaw Primitives and Limits
description: OpenClaw dispatch model, channel callbacks, and concurrency considerations.
---

# OpenClaw Primitives and Limits

OpenClaw behaves more like a local control plane or daemon runtime than a
traditional interactive coding shell.

Primary characteristics:

- Work is dispatched through session or task surfaces rather than a single
  foreground terminal loop
- Completion can be posted back to a channel, inbox, or other shared surface
- Parallelism depends on local config, hardware, and gateway setup
- Shallow nesting is usually easier to recover than deep recursive fan-out
- Machine-to-machine dispatch is possible through gateway-style surfaces

Design implication:

- Prefer OpenClaw for durable background work, not for the repo's primary
  interactive coding path.

Verify current primitive names and operational limits against the official
OpenClaw docs before freezing them into another workflow.

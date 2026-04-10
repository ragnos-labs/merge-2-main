---
title: OpenClaw Primitives and Limits
description: OpenClaw dispatch model, channel callbacks, and concurrency considerations.
---

# OpenClaw Primitives and Limits

OpenClaw behaves more like a local control plane or daemon runtime than a
traditional interactive coding shell.

## Primary Primitives

- Work is dispatched through session or task surfaces rather than a single
  foreground terminal loop
- Completion can be posted back to a channel, inbox, or other shared surface
- Machine-to-machine dispatch is possible through gateway-style surfaces

## Execution Model

- The operator dispatches work and waits on an announce-back or callback path
  rather than supervising every child inside one foreground thread.
- External state and external delivery surfaces matter more here than in the
  interactive runtimes.
- Shallow fan-out is easier to recover than deep nesting.

## Operational Limits

- Parallelism depends on local config, hardware, and gateway setup
- Shallow nesting is usually easier to recover than deep recursive fan-out
- Prefer OpenClaw for durable background work, not for the repo's primary
  interactive coding path.
- Verify current primitive names and operational limits against the official
  OpenClaw docs before freezing them into another workflow.

## Routing Guidance

- Choose OpenClaw when ambient execution is the point, not just a side effect.
- Prefer it over Claude Code or Codex when scheduled or daemon-style work is
  the real requirement.
- Do not default to it for the repo's primary interactive coding path.

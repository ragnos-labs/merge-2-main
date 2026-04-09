---
title: Claude Code Primitives and Limits
description: Native Claude Code coordination primitives, strengths, and operational limits.
---

# Claude Code Primitives and Limits

Claude Code exposes the richest built-in coordination surface of the three
documented runtimes.

Primary primitives:

- Background agent spawning
- Team-style coordination and task lists
- Inter-agent messaging
- Integrated file, shell, and search tools

Operational notes:

- This is the most natural surface for interactive Hive Mind runs.
- Parallel fan-out still needs decomposition discipline. A richer runtime does
  not remove the no-overlap rule.
- Runtime-specific ceilings and feature flags may change over time; keep those
  details in this folder rather than in the universal pattern docs.

Routing guidance:

- Choose Claude Code when the human lead wants direct session control.
- Prefer it over OpenClaw for on-demand coding work.
- Prefer it over Codex when native messaging or built-in web tooling are the
  decisive constraints.

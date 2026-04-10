---
title: OpenClaw Pattern Adapters
description: How the universal patterns map onto OpenClaw's session and callback-oriented runtime model.
---

# OpenClaw Pattern Adapters

Use this page only after choosing a pattern in `docs/core/patterns/`.

## Patchwork

Possible, but rarely the best reason to choose OpenClaw.

## Worker Swarm

Maps reasonably well when the operator wants to dispatch a bounded batch and
collect results asynchronously through callback-style completion.

## Research Swarm

This is the cleanest OpenClaw mapping. Wave-based investigation fits naturally
with session fan-out plus operator review between waves.

## Hive Mind

Possible only with more explicit external state and tighter limits than on
Claude Code or Codex. Use with caution and keep the team shallow.

## Worktree Sprint

Treat worktree boundaries as external infrastructure; pass them into the
session prompt the same way you would pass other file-scope constraints.

## When Not To Force This Runtime

- Do not choose OpenClaw for ordinary interactive coding just because it can be
  made to work.
- Do not force deep Hive Mind style coordination into OpenClaw when a simpler
  bounded batch or wave-based workflow would do.
- Verify exact primitive names and callback mechanics against the official
  OpenClaw docs before freezing them into a reusable workflow.

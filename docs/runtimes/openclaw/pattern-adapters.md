---
title: OpenClaw Pattern Adapters
description: How the universal patterns map onto OpenClaw's session and announce-back model.
---

# OpenClaw Pattern Adapters

Use this page only after choosing a pattern in `docs/core/patterns/`.

## Patchwork

Possible, but rarely the best reason to choose OpenClaw.

## Worker Swarm

Maps reasonably well when the operator wants to dispatch a bounded batch and
collect results asynchronously through announce-back.

## Research Swarm

This is the cleanest OpenClaw mapping. Wave-based investigation fits naturally
with session fan-out plus operator review between waves.

## Hive Mind

Possible only with more explicit external state and tighter limits than on
Claude Code or Codex. Use with caution and keep the team shallow.

## Worktree Sprint

Treat worktree boundaries as external infrastructure; pass them into the
session prompt the same way you would pass other file-scope constraints.

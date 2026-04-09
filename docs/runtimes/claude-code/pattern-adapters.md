---
title: Claude Code Pattern Adapters
description: How the universal patterns map onto Claude Code primitives.
---

# Claude Code Pattern Adapters

Use this page only after choosing a pattern in `docs/core/patterns/`.

## Patchwork

Run directly in the active session. No child agents needed.

## Worker Swarm

Spawn background workers with self-contained prompts. Keep ownership explicit
 and consolidate sequentially.

## Research Swarm

Treat each wave as a bounded batch of background discovery agents. Review every
 wave before you advance.

## Hive Mind

Use Claude Code's native coordination surface for team identity, task state,
 and inter-agent messaging. The phase gates and file ownership rules still come
 from the core pattern docs.

## Worktree Sprint

Set up worktrees before dispatch and pass absolute worktree paths into every
workstream prompt. The worktree layer remains infrastructure, not coordination.

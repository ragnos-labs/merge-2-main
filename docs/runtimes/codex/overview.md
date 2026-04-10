---
title: Codex Runtime
description: When to use Codex as the runtime surface for the universal multi-agent patterns.
---

# Codex Runtime

## What It Is

Codex is the best fit in this repo for long-horizon agentic coding where you
want explicit sandboxing, structured handoffs, and a strong repo bootstrap via
`AGENTS.md`.

## Best Fit

- Multi-agent coding runs where sandbox isolation is useful
- Codex-native orchestration with per-role configuration
- Programmatic or resumable flows that benefit from an explicit run ledger

## Not The Main Fit

- Thread budgets are tighter than the methodology itself
- Setup matters more because agents start colder than in Claude Code
- Tool names are different enough that prompts must stay runtime-portable

## Continue To

- [Setup and AGENTS.md](./setup-and-agents-md.md)
- [Primitives and Limits](./primitives-and-limits.md)
- [Pattern Adapters](./pattern-adapters.md)
- [Programmatic API](./programmatic-api.md)

---
title: Runtime Overview
description: Landing page for runtime-specific adapters and caveats.
---

# Runtime Overview

`docs/runtimes` maps the core methodology onto specific agent runtimes.

Use these docs after you choose the pattern. The pattern stays universal. The
runtime docs translate that pattern into real primitives, limits, and setup
notes.

## Read In This Order

1. Pick the pattern in [`../core`](../core/README.md)
2. Choose the runtime that will execute it
3. Verify any transient runtime behavior against the official source docs

## Runtime Surfaces

### Claude Code

- [Overview](./claude-code/overview.md)
- [Primitives and Limits](./claude-code/primitives-and-limits.md)
- [Pattern Adapters](./claude-code/pattern-adapters.md)

### Codex

- [Overview](./codex/overview.md)
- [Setup and AGENTS.md](./codex/setup-and-agents-md.md)
- [Primitives and Limits](./codex/primitives-and-limits.md)
- [Pattern Adapters](./codex/pattern-adapters.md)
- [Programmatic API](./codex/programmatic-api.md)

### OpenClaw

- [Overview](./openclaw/overview.md)
- [Primitives and Limits](./openclaw/primitives-and-limits.md)
- [Pattern Adapters](./openclaw/pattern-adapters.md)
- [Bedrock Gotchas](./openclaw/bedrock-gotchas.md)

## Freshness Rule

Runtime docs age faster than core methodology docs.

Before hard-coding a runtime-specific claim into a design, workflow, or blog
post, verify it against the official vendor or project docs listed in
[../core/references/ecosystem-source-map.md](../core/references/ecosystem-source-map.md).

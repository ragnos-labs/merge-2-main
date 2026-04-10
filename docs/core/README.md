---
title: Core Methodology Overview
description: Landing page for the canonical multi-agent methodology docs.
---

## Core Methodology Overview

`docs/core` is the canonical methodology surface for this repo.

Use it for the parts that should outlive any one tool vendor:

- pattern selection
- planning and file ownership
- tests and checkpoints
- release and merge discipline
- handoff contracts
- anti-patterns and drift signals

## Start Here

Use `docs/core` in this order:

1. Choose the execution pattern.
2. Read the planning and checkpoint rules that constrain it.
3. Use references and examples only when you need a schema, contract, or full walkthrough.

- [Pattern Overview](./patterns/overview.md)
- [Decision Tree](./guides/decision-tree.md)
- [Sprint Planning](./guides/sprint-planning.md)
- [Checkpoint Protocol](./guides/checkpoint-protocol.md)
- [Release Gate](./guides/release-gate.md)
- [Examples](./examples/feature-build.md)

## Sections

### Patterns

Execution topologies and when to use them:

- [Patchwork](./patterns/patchwork.md)
- [Worker Swarm](./patterns/worker-swarm.md)
- [Research Swarm](./patterns/research-swarm.md)
- [Hive Mind 2-Tier](./patterns/hive-mind-2tier.md)
- [Hive Mind 3-Tier](./patterns/hive-mind-3tier.md)
- [Worktree Sprint](./patterns/worktree-sprint.md)

### Guides

Operating guidance that applies across patterns:

- [Decision Tree](./guides/decision-tree.md)
- [Unified Audit Pipeline](./guides/unified-audit-pipeline.md)
- [Model Selection](./guides/model-selection.md)
- [Behavior Design](./guides/behavior-design.md)
- [Sprint Planning](./guides/sprint-planning.md)
- [TDD Integration](./guides/tdd-integration.md)
- [Checkpoint Protocol](./guides/checkpoint-protocol.md)
- [Trigger-Based Docs Sync](./guides/trigger-based-docs-sync.md)
- [Release Gate](./guides/release-gate.md)
- [Ship Rerun Semantics](./guides/ship-rerun-semantics.md)
- [Meta-Log Gates](./guides/meta-log-gates.md)
- [Sprint Artifacts](./guides/sprint-artifacts.md)
- [Post-Sprint Completion](./guides/post-sprint-completion.md)
- [Scribe](./guides/scribe.md)

### References

Reusable contracts, schemas, and source maps:

- [Anti-Patterns](./references/anti-patterns.md)
- [Handoff Contracts](./references/handoff-contracts.md)
- [Verification Discipline](./references/verification-discipline.md)
- [Instruction Hygiene](./references/instruction-hygiene.md)
- [Research Manifest Schema](./references/research-manifest-schema.md)
- [TDD Contracts Template](./references/tdd-contracts-template.md)
- [Retrospective Template](./references/retrospective-template.md)
- [Drift Detection](./references/drift-detection.md)
- [Positive Enforcement](./references/positive-enforcement.md)
- [Ecosystem Radar](./references/ecosystem-radar.md)
- [Stack And Teams We Respect](./references/stack-and-teams-we-respect.md)
- [Security Tooling Starting Points](./references/security-tooling-starting-points.md)
- [Ecosystem Source Map](./references/ecosystem-source-map.md)
- [AI Philosophy And Implications](./references/ai-philosophy-and-implications.md)
- [Discovery Vs Invention](./references/discovery-vs-invention.md)

### Additional Guides

Related guidance that is still narrower than the core starting path:

- [How We Work At RAGnos](./guides/how-we-work-at-ragnos.md)
- [Character Layer](./guides/character-layer.md)

### Examples

Worked walkthroughs:

- [Security Audit](./examples/security-audit.md)
- [Feature Build](./examples/feature-build.md)
- [Full Sprint](./examples/full-sprint.md)
- [Research Landscape](./examples/research-landscape.md)

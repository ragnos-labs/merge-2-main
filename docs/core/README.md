---
title: Core Methodology Overview
description: Landing page for the canonical multi-agent methodology docs.
---

# Core Methodology Overview

`docs/core` is the canonical methodology surface for this repo.

Use it for the parts that should outlive any one tool vendor:

- pattern selection
- planning and file ownership
- tests and checkpoints
- release and merge discipline
- handoff contracts
- anti-patterns and drift signals

## Start Here

- [Pattern Overview](./patterns/overview.md)
- [Decision Tree](./guides/decision-tree.md)
- [Sprint Planning](./guides/sprint-planning.md)
- [Checkpoint Protocol](./guides/checkpoint-protocol.md)
- [Release Gate](./guides/release-gate.md)

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
- [Model Selection](./guides/model-selection.md)
- [Sprint Planning](./guides/sprint-planning.md)
- [TDD Integration](./guides/tdd-integration.md)
- [Checkpoint Protocol](./guides/checkpoint-protocol.md)
- [Release Gate](./guides/release-gate.md)
- [Sprint Artifacts](./guides/sprint-artifacts.md)
- [Post-Sprint Completion](./guides/post-sprint-completion.md)
- [Scribe](./guides/scribe.md)

### References

Reusable contracts, schemas, and source maps:

- [Anti-Patterns](./references/anti-patterns.md)
- [Handoff Contracts](./references/handoff-contracts.md)
- [Research Manifest Schema](./references/research-manifest-schema.md)
- [TDD Contracts Template](./references/tdd-contracts-template.md)
- [Retrospective Template](./references/retrospective-template.md)
- [Drift Detection](./references/drift-detection.md)
- [Positive Enforcement](./references/positive-enforcement.md)
- [Ecosystem Source Map](./references/ecosystem-source-map.md)

### Examples

Worked walkthroughs:

- [Security Audit](./examples/security-audit.md)
- [Feature Build](./examples/feature-build.md)
- [Full Sprint](./examples/full-sprint.md)
- [Research Landscape](./examples/research-landscape.md)

## Canonical Rule

If a file under `docs/core` conflicts with an older file under `docs/patterns`,
`docs/guides`, `docs/references`, or `docs/examples`, treat `docs/core` as
canonical. The older paths remain only to avoid breaking links.

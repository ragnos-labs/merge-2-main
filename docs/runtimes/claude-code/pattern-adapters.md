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

## Model Pinning and Cost Guardrails

The model selection guide's "declared role defaults" map directly to subagent
definition files. Create one markdown file per role under `.claude/agents/`
with frontmatter pinning the tier:

- An exploration or general-purpose role pinned to standard tier so recon work
  cannot silently escalate.
- A mechanical-edit role pinned to fast/efficient for unambiguous bulk changes.
- A code or debug role pinned to standard tier with the tools it needs.

Pair these with a pre-tool-use hook that inspects each `Agent` spawn:

- Reject spawns that omit a `model:` pin and do not reference a pinned subagent.
- Reject most-capable-tier spawns that lack an explicit justification token in
  the prompt (or an environment flag for the legitimate exception case).
- Surface the rejection reason inline so the lead can fix the prompt and retry.

This is the Claude Code expression of the universal pattern: declared role
defaults plus a guarded escape hatch. Without it, role-tier mappings (lead at
standard/high, scanner at fast/efficient, mechanical worker at fast/efficient)
live only in lead discipline and drift the first time a prompt forgets to
restate them.

## When Not To Force This Runtime

- Do not choose Claude Code just because it feels comfortable if the real need
  is scheduled or daemon-style execution.
- Do not let the richer coordination surface tempt you into skipping explicit
  ownership, phase gates, or verifier steps from the core docs.

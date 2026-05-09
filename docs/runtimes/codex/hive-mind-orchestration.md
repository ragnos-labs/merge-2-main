---
title: Codex Hive Mind Orchestration
description: How to run large Codex multi-agent efforts with a parent orchestrator, bounded child waves, worktree isolation, and cost-aware role defaults.
---

# Codex Hive Mind Orchestration

Use this page after choosing Hive Mind or Worker Swarm in the core pattern docs.
It translates the public methodology into a Codex-shaped execution plan.

Codex can run many tasks in parallel, but the highest-output design is not
"spawn the maximum number of children." The reliable design is a parent
orchestrator that keeps the critical path, dispatches bounded sidecars, and
uses waves, worktrees, and structured handoffs to keep the run reviewable.

---

## Default Shape

```
Parent orchestrator
  |
  +-- Workstream lead A in worktree A
  |     +-- Explorer or worker children for lead A
  |     +-- Verifier child for lead A
  |
  +-- Workstream lead B in worktree B
  |     +-- Explorer or worker children for lead B
  |     +-- Verifier child for lead B
  |
  +-- Parent verifier or release checker
```

The parent orchestrator is the only actor that owns the whole run. It keeps the
immediate blocker, decides when a phase advances, and integrates workstream
results. Child agents own narrow sidecar tasks or one workstream. They do not
take over the parent role.

---

## Orchestrator Contract

The parent orchestrator must do five things before dispatching children:

1. State the goal and done condition.
2. Split the work into independent workstreams.
3. Assign each workstream a write scope or a read-only search area.
4. Reserve thread and compute budget for verification and integration.
5. Decide which task stays on the parent thread because it is the next blocker.

Every child prompt should include:

- scope
- owned files or search area
- expected output format
- model or reasoning-effort target
- whether the parent should wait immediately or keep working
- handoff path, if the output should land in a file

If the next parent action depends on a child result, the task is probably not a
good delegation candidate. Do it locally or wait deliberately.

---

## Wave Budget

Use a wave budget instead of a maximum-width swarm.

```json
{
  "wave_id": "phase-1-recon",
  "max_concurrent_children": 4,
  "reserved_parent_threads": 1,
  "reserved_verifier_threads": 1,
  "close_on_completion": true,
  "next_gate": "parent synthesizes findings before write tasks spawn"
}
```

Default to 2 to 4 concurrent children. Go wider only when:

- the tasks are independent,
- write scopes are disjoint,
- each child has a concise output contract,
- the parent has time to review the outputs,
- the run has a later verifier wave.

For a larger topology, run several waves instead of one large burst:

1. Read-only explorers map the repo or problem space.
2. The parent synthesizes the manifest.
3. Workstream leads or workers implement disjoint slices.
4. Verifiers inspect outputs and run the assigned checks.
5. The parent integrates, ships, or opens the review artifact.

---

## Worktree Layer

Use git worktrees when two or more write-capable agents may touch the same
repository. Codex task isolation does not replace git isolation.

Recommended layout:

```text
repo/
  .worktrees/
    sprint-slug--api/
    sprint-slug--frontend/
    sprint-slug--tests/
```

Each workstream receives:

```json
{
  "workstream_id": "api",
  "branch": "sprint/session-auth--api",
  "worktree_path": "/repo/.worktrees/session-auth--api",
  "owned_files": ["src/api/**", "tests/api/**"],
  "read_only": ["src/db/**", "docs/**"]
}
```

The parent, not a child, owns final integration. Leads can commit inside their
assigned worktree, but merge order and conflict resolution stay with the parent
orchestrator.

---

## Cost-Aware Role Defaults

The parent should spend reasoning where coordination or judgment lives.

| Role | Default effort | Why |
| ---- | -------------- | --- |
| Parent orchestrator | High | Owns decomposition, dependencies, and ship decision |
| Workstream lead | Medium to high | Owns a bounded slice plus local workers |
| Explorer | Low to medium | Reads and summarizes; no writes |
| Worker | Medium | Implements a scoped task |
| Mechanical worker | Low | Applies obvious, low-risk edits |
| Verifier | Medium to high | Checks correctness and acceptance |

Avoid assigning the strongest model or highest effort to every child. A single
strong parent plus several scoped lower-cost children is usually better than a
flat swarm of expensive agents.

Escalate effort when:

- the task failed once for a reason related to reasoning,
- the child must make a design judgment,
- security, data loss, or release correctness is at stake,
- the parent cannot cheaply repair a bad answer.

Do not escalate effort when:

- the task is a search, rename, format, or simple fixture update,
- the output is read-only and easy to verify,
- the child has a narrow owned file list and test command.

---

## Handoff Format

Use short, typed handoffs. Do not ask children for raw transcripts.

```json
{
  "type": "child_handoff",
  "task_id": "api-recon-01",
  "status": "pass",
  "scope": ["src/api/**"],
  "findings": [
    {
      "summary": "Session middleware owns token parsing",
      "evidence": "src/api/session.ts:42"
    }
  ],
  "changed_files": [],
  "tests": [],
  "risks": [],
  "next_recommendation": "Spawn api-worker-01 for token refresh route"
}
```

For write-capable children, require `changed_files`, `tests`, and `risks`.
For explorers, require `findings`, `evidence`, and `unknowns`.

---

## Stop Rules

Stop the wave and return to the parent when any of these occur:

- two children want the same write file,
- a child needs a secret or production access,
- a verifier finds a blocking issue,
- the thread budget is nearly exhausted,
- the parent cannot explain how the next child output will be used,
- the work no longer matches the selected pattern.

The parent should then re-scope, reduce concurrency, or move the task back to a
single-thread Patchwork run.

---

## Related Docs

- [Codex Pattern Adapters](./pattern-adapters.md)
- [Codex Primitives and Limits](./primitives-and-limits.md)
- [Hive Mind 3-Tier](../../core/patterns/hive-mind-3tier.md)
- [Worktree Sprint](../../core/patterns/worktree-sprint.md)
- [Model Selection](../../core/guides/model-selection.md)

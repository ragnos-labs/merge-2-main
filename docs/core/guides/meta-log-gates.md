---
title: Meta-Log Gates
description: A lightweight evidence model for long-running agent work.
---

## Meta-Log Gates

Long-running agent work needs evidence at the start, evidence while it is
moving, and evidence before it is declared done.

That is what meta-log gates are for.

## Why This Exists

Without an evidence trail, multi-agent work degrades into:

- "I think we already checked that"
- "someone fixed it in another thread"
- "the tests probably passed earlier"
- "we changed the plan but forgot to say so"

Meta-log gates are the minimum structure that keeps a sprint reviewable without
forcing everyone into heavy process.

## The Three Gates

### G1: Init

Before substantive work begins, record:

- the goal
- the chosen pattern
- the owned files or scope
- the initial risks or unknowns

If none of that is written down, the sprint has no reliable starting point.

### G2: In-Flight

At meaningful transitions, record:

- what changed
- what was verified
- what is blocked
- whether the plan or scope moved

This does not need to be verbose. It needs to be real.

### G3: Ship

Before the work is handed off, shipped, or merged, record:

- what was completed
- what proof exists
- what remains deferred
- the final artifact set or report location

The ship gate is the bridge between "work happened" and "someone else can
trust the result."

## What To Record

Good meta-log entries are short and structured.

Minimum fields:

- timestamp
- actor or role
- phase or gate
- summary
- evidence pointer

Evidence pointers can be:

- test output
- diff or commit references
- review notes
- generated artifacts
- links to relevant docs

## Self-Heal Candidates

The meta-log is most valuable when it does more than record what happened. With one
extra field, it becomes an active improvement signal: a stream of issues the system
itself has already noticed and proposed a fix for.

When a meta-log entry describes a failure, retry, or surprise, flag it as a self-heal
candidate:

```json
{
  "ts": "2026-04-18T14:31:22Z",
  "actor": "lead",
  "phase": "G2",
  "summary": "Bee B2 failed to apply patch: file owned by another workstream",
  "evidence": "scratchpad-ws-b.jsonl:14",
  "self_heal_candidate": true,
  "remediation": "tighten Phase 0 ownership map; reject cross-workstream writes at spawn time"
}
```

`self_heal_candidate: true` marks the entry for review. `remediation` is a one-line
proposed fix. Together they turn an evidence pointer into a candidate work item.

### Promotion thresholds

Not every flagged candidate deserves a fix. Three thresholds keep the signal-to-noise
ratio honest:

```
+--------------------------+----------------------+----------------------------------+
| Recurrence rate          | Action               | Rationale                        |
+--------------------------+----------------------+----------------------------------+
| > 25% of runs            | Fix now              | The system is broken on this     |
|                          |                      | path; further runs waste effort  |
+--------------------------+----------------------+----------------------------------+
| 3+ recurrences           | Promote to backlog   | Pattern is real but tolerable;   |
| (any rate)               |                      | schedule the fix deliberately    |
+--------------------------+----------------------+----------------------------------+
| < 3 recurrences          | Log only             | One-offs are noise; revisit if   |
|                          |                      | the count climbs                 |
+--------------------------+----------------------+----------------------------------+
```

Apply the rate threshold to repeated runs of the same operation (a sprint that runs
weekly, a CI job that fires per PR). Apply the count threshold to anything with low
volume.

### Routing

Self-heal candidates that promote to backlog should land in a separate list or queue
from human-curated work, not the main backlog. Mixing them dilutes the curated
backlog and makes triage slower. The promotion step is the routing decision: human
review confirms the candidate, then routes it to the maintenance queue.

The meta-log-entry-schema template documents the field set and shows additional
sample entries: see `docs/templates/meta-log-entry-schema.md`.

---

## Scope Changes Must Be Visible

If the plan changes, the meta-log should say so.

That includes:

- added workstreams
- dropped requirements
- risk reclassification
- new blockers

Hidden scope change is one of the fastest ways agent work becomes
unreviewable.

## Keep It Lightweight

Meta-log gates are not a request for essay-writing.

If the entries are so heavy that no one wants to write them, the system will
rot. The right level is "enough for a new human to understand what happened."

## Where This Fits

Meta-log gates complement, but do not replace:

- sprint plans
- handoff contracts
- release gates
- retrospectives

Think of them as continuity infrastructure for the work between those bigger
artifacts.

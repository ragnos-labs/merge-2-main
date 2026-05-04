---
title: Meta-Log Entry Schema
description: JSONL field set for the sprint meta-log, with the optional self_heal_candidate and remediation fields, plus realistic sample entries for each gate type.
---

# Meta-Log Entry Schema

The meta-log is an append-only JSONL file. Each line is one event. The schema below
covers the minimum useful field set plus the self-heal extension that turns
observations into work items.

See `docs/core/guides/meta-log-gates.md` for the gating model (G1 init, G2 in-flight,
G3 ship) and the self-heal promotion thresholds.

---

## Fields

```
+----------------------+----------+------------------------------------------+
| Field                | Required | Notes                                    |
+----------------------+----------+------------------------------------------+
| ts                   | yes      | ISO-8601 UTC timestamp                   |
| actor                | yes      | Who emitted the entry: lead, teammate    |
|                      |          | name, orchestrator, scribe, hook, etc.   |
| phase                | yes      | G1 / G2 / G3, or a phase number for      |
|                      |          | multi-phase patterns                     |
| event_type           | yes      | start | progress | block | resolve |     |
|                      |          | decision | failure | finding | ship       |
| summary              | yes      | One-line description of the event        |
| evidence             | optional | Pointer: file:line, commit hash, log     |
|                      |          | path, scratchpad reference               |
| workstream           | optional | Workstream identifier when applicable    |
| confidence           | optional | low | medium | high (for findings)        |
| self_heal_candidate  | optional | true | false (default false)            |
| remediation          | optional | One-line proposed fix; required when     |
|                      |          | self_heal_candidate is true              |
| meta                 | optional | Free-form object for runtime-specific    |
|                      |          | extension fields                         |
+----------------------+----------+------------------------------------------+
```

---

## Sample entries

### G1: Init

```json
{"ts":"2026-04-18T13:00:01Z","actor":"lead","phase":"G1","event_type":"start","summary":"Sprint init: auth-refactor; pattern: hive-mind-3tier; 4 workstreams","evidence":"sprint-state.md"}
```

### G2: In-flight, normal progress

```json
{"ts":"2026-04-18T13:42:08Z","actor":"bee-a2","phase":"G2","event_type":"progress","summary":"Implemented validators.py against Phase 2 stubs; 14 tests green locally","evidence":"src/api/validators.py","workstream":"ws-a"}
```

### G2: Finding (read-only observation)

```json
{"ts":"2026-04-18T14:11:33Z","actor":"bee-c1","phase":"G2","event_type":"finding","summary":"Auth-related schema has 3 unindexed FK columns; out of scope for this sprint","evidence":"db/schema.sql:88","workstream":"ws-c","confidence":"high"}
```

### G2: Block

```json
{"ts":"2026-04-18T14:31:22Z","actor":"lead-b","phase":"G2","event_type":"block","summary":"Bee B2 cannot apply patch: target file owned by ws-a","evidence":"scratchpad-ws-b.jsonl:14","workstream":"ws-b","self_heal_candidate":true,"remediation":"tighten Phase 0 ownership map; reject cross-workstream writes at spawn time"}
```

### G2: Self-heal failure

```json
{"ts":"2026-04-18T15:02:10Z","actor":"spawn-guard","phase":"G2","event_type":"failure","summary":"Rejected most-capable spawn from lead-d: no [JUSTIFIED:] token","self_heal_candidate":true,"remediation":"add justification token or set ALLOW_MOST_CAPABLE_SPAWN=1 if legitimate"}
```

### G2: Decision

```json
{"ts":"2026-04-18T15:30:00Z","actor":"orchestrator","phase":"G2","event_type":"decision","summary":"Defer ws-c index work to follow-up sprint; not blocking for current scope","evidence":"sprint-state.md#dependencies"}
```

### G3: Ship

```json
{"ts":"2026-04-18T18:14:50Z","actor":"orchestrator","phase":"G3","event_type":"ship","summary":"Sprint complete; PR #482 opened; all four workstreams merged to sprint branch","evidence":"https://github.com/example/repo/pull/482"}
```

---

## Self-heal field rules

- `self_heal_candidate: true` is a flag for review, not an automatic action.
- `remediation` must be present when the flag is true. A flag without a proposal is
  noise; a proposal turns it into a candidate work item.
- The promotion thresholds in `meta-log-gates.md` decide what happens next: fix
  now, promote to backlog, or log only.
- Promoted candidates land in a separate maintenance queue, not the curated
  backlog. Mixing dilutes triage signal.

---

## Implementation notes

- Append-only. Never edit prior entries; correct via a follow-up entry that
  references the original by `ts`.
- One file per sprint. Path convention: `.ai/sprints/<slug>/meta-log.jsonl`.
- The scribe role (or any meta-log writer) should validate JSON shape before
  appending. A malformed line is harder to recover than a missed event.

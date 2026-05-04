---
title: Scratchpad JSONL Entries
description: Worked example of a workstream scratchpad - the intra-workstream JSONL log Bees use to announce file locks, surface findings, and warn siblings without going through the lead.
---

# Scratchpad JSONL Entries

The scratchpad is a write-append-read bulletin board for Bees inside one workstream.
It is not messaging: there is no addressing, no replies, no conversation. Each Bee
appends what others need to know and reads what siblings have already announced.

Cross-workstream signals do not go through scratchpads. They flow through the Lead.
See `docs/core/patterns/hive-mind-3tier.md` for the boundary rules.

---

## Entry types

```
+----------+-----------------------------------------+----------------------------+
| Type     | Purpose                                 | Acted on by                |
+----------+-----------------------------------------+----------------------------+
| lock     | Announce a file region being edited     | Other Bees, before editing |
| finding  | Surface a partial result for siblings   | Other Bees and the Lead    |
| warning  | Flag a risk siblings should avoid       | Other Bees                 |
| release  | Announce a previously held lock is free | Other Bees waiting for it  |
+----------+-----------------------------------------+----------------------------+
```

`release` is optional but useful in long-running waves where a Bee finishes well
before the wave ends.

---

## Field set

```
+-----------+----------+----------------------------------------------+
| Field     | Required | Notes                                        |
+-----------+----------+----------------------------------------------+
| bee_id    | yes      | Stable identifier for the Bee within the     |
|           |          | workstream (e.g., bee-a1, bee-a2)            |
| ts        | yes      | ISO-8601 UTC timestamp                       |
| type      | yes      | lock | finding | warning | release          |
| payload   | yes      | One-line content; format varies by type      |
| ref       | optional | File path or line range when applicable      |
+-----------+----------+----------------------------------------------+
```

---

## Worked example: workstream WS-A, Phase 3 (Implementation)

Path: `.ai/sprints/auth-refactor/scratchpad-ws-a.jsonl`

```jsonl
{"bee_id":"bee-a1","ts":"2026-04-18T14:30:02Z","type":"lock","payload":"editing routes/users.py:80-150","ref":"routes/users.py"}
{"bee_id":"bee-a2","ts":"2026-04-18T14:30:14Z","type":"lock","payload":"editing routes/sessions.py:1-200","ref":"routes/sessions.py"}
{"bee_id":"bee-a3","ts":"2026-04-18T14:31:48Z","type":"finding","payload":"validators.py exposes shared regex used by users.py and sessions.py; safe to call read-only","ref":"src/api/validators.py"}
{"bee_id":"bee-a2","ts":"2026-04-18T14:35:11Z","type":"warning","payload":"tests/test_sessions.py has stale fixtures referencing removed Session.user_id; bee-a4 will sweep after impl","ref":"tests/test_sessions.py"}
{"bee_id":"bee-a1","ts":"2026-04-18T14:48:55Z","type":"release","payload":"routes/users.py committed; lock free","ref":"routes/users.py"}
{"bee_id":"bee-a4","ts":"2026-04-18T14:51:02Z","type":"lock","payload":"editing tests/test_sessions.py to refresh fixtures","ref":"tests/test_sessions.py"}
{"bee_id":"bee-a2","ts":"2026-04-18T15:03:27Z","type":"finding","payload":"discovered circular import: sessions imports users which now imports sessions via type hint; need TYPE_CHECKING guard","ref":"routes/sessions.py:12"}
{"bee_id":"bee-a2","ts":"2026-04-18T15:04:09Z","type":"release","payload":"sessions.py committed with TYPE_CHECKING guard; lock free","ref":"routes/sessions.py"}
{"bee_id":"bee-a4","ts":"2026-04-18T15:18:40Z","type":"release","payload":"test_sessions.py updated; 9 stale fixtures replaced; lock free","ref":"tests/test_sessions.py"}
```

What this trace shows:

- **Locks prevent collision.** Bee A1 and Bee A2 hold non-overlapping locks; they
  could safely run in parallel. Bee A4 waits for A2's release before editing the
  shared test file.
- **Findings travel sideways.** Bee A3's note about validators saved A1 and A2
  from re-deriving the same insight. Bee A2's circular-import finding warned
  later Bees off the same trap.
- **Warnings beat blockers.** Bee A2's stale-fixture warning routed cleanup to
  Bee A4 without blocking implementation. Without the scratchpad, Bee A4 would
  have either duplicated the discovery or silently broken the tests.

---

## Spawn-prompt boilerplate

Include this in every Bee's spawn prompt so the convention sticks:

```
SCRATCHPAD: Before editing any file, read the workstream scratchpad at
.ai/sprints/<slug>/scratchpad-<ws-id>.jsonl. Skip files with active "lock"
entries from other Bees and note them in your return value.

After you begin editing a file, append a "lock" entry. After commit, append
"release". When you discover something other Bees in this workstream should
know, append "finding" or "warning".

Cross-workstream observations do NOT go in the scratchpad. Report them to the
Lead via your task return value.
```

---

## What the scratchpad is not

- Not a message bus. No addressing, no replies, no @-mentions.
- Not a sprint state file. The Orchestrator's sprint state is separate; the
  scratchpad is intra-workstream only.
- Not a meta-log. The meta-log captures sprint-wide events. The scratchpad is
  ephemeral coordination data; archive or discard it after the sprint closes.
- Not a substitute for file ownership. The Phase 0 ownership map is still the
  primary collision-prevention mechanism. The scratchpad handles the cases that
  ownership cannot anticipate.

---

## Related

- `docs/core/patterns/hive-mind-3tier.md`: the scratchpad pattern in context
- `docs/templates/universal/meta-log-entry-schema.md`: the sprint-wide log
  the scratchpad complements

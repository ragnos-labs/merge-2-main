---
title: Handoff Contracts
description: Structured JSON messages agents use to pass work between each other in multi-agent coordination patterns. Defines base contract format, all contract types with examples, and guidance on when to use structured handoffs versus freeform messages.
---

# Handoff Contracts

When agents communicate through freeform text, information degrades across hops.
A lead that receives "done, mostly working" cannot reliably gate the next phase.
A worker that receives "please handle the auth stuff" cannot determine scope. As
coordination complexity grows, ambiguous messages compound: a misread handoff in
wave 1 becomes a broken integration by wave 3.

Handoff contracts are structured JSON messages with a fixed schema. Every field
is named, every value is machine-readable, and every type carries only the
payload appropriate to that event. The lead can parse a `task_complete` without
reading prose. Contracts make agent-to-agent communication explicit, auditable,
and recoverable.

Use handoff contracts whenever a message gates a phase transition or triggers an
action in the receiver. Use freeform messages for low-stakes coordination that
carries no downstream action requirement.

---

## Base Contract Format

Every contract shares the same envelope:

```json
{
  "type": "<contract_type>",
  "timestamp": "<ISO 8601 UTC>",
  "from": "<agent_id>",
  "to": "<agent_id_or_broadcast>",
  "payload": {},
  "constraints": {}
}
```

Field notes:
- `type`: exact string match to one of the types below.
- `timestamp`: UTC, e.g. `2026-04-06T14:22:00Z`.
- `to`: a named agent ID, or `"broadcast"` to reach all active teammates.
- `constraints`: optional bounds the receiver must respect. Common keys:
  `scope_files`, `deadline_phase`, `model_floor`. Omit if not needed.

> **`model_tier` resolution**: shorthand tier strings (`"sonnet"`, `"opus"`,
> `"haiku"`) used in constraints or task payloads must be resolved to concrete
> model IDs at runtime before being passed to any LLM call. Tier names are
> human-readable aliases only. See
> [Model Selection Guide](../guides/model-selection.md) for the current
> mapping from tier names to model IDs.

---

## Contract Types

### phase_complete

An agent declares that a named phase is finished. This is a gate signal:
the receiver should not advance to the next phase until it has collected
`phase_complete` from all expected contributors.

```json
{
  "type": "phase_complete",
  "timestamp": "2026-04-06T14:22:00Z",
  "from": "worker-auth",
  "to": "lead",
  "payload": {
    "phase": "implementation",
    "summary": "JWT middleware implemented and unit tested. Refresh token rotation included.",
    "artifacts": ["src/auth/middleware.ts", "src/auth/refresh.ts", "tests/auth/middleware.test.ts"],
    "test_status": { "written": 14, "passing": 14, "failing": 0, "skipped": 0 },
    "deferred": []
  },
  "constraints": {}
}
```

---

### task_dispatch

A lead assigns a bounded unit of work to a specific worker. The contract
carries everything the worker needs to begin: description, context, acceptance
criteria, and scope constraints.

Workers must not touch files outside `constraints.scope_files` without first
sending a `scope_adjustment`.

```json
{
  "type": "task_dispatch",
  "timestamp": "2026-04-06T14:23:00Z",
  "from": "lead",
  "to": "worker-schema",
  "payload": {
    "task_id": "T-04",
    "description": "Add a nullable refresh_token column to the users table and write a migration.",
    "context": "The auth middleware expects refresh_token on the user row. Do not alter any other columns.",
    "acceptance": [
      "Migration file present in db/migrations/",
      "Column is nullable, type text",
      "Migration is reversible (up and down)"
    ]
  },
  "constraints": {
    "scope_files": ["db/migrations/", "db/schema.ts"],
    "deadline_phase": "implementation"
  }
}
```

---

### task_complete

A worker reports that its assigned task is finished. The `task_id` must match
the originating `task_dispatch`. The receiver should verify artifacts before
treating the task as truly done; this is not a self-report of success.

```json
{
  "type": "task_complete",
  "timestamp": "2026-04-06T14:55:00Z",
  "from": "worker-schema",
  "to": "lead",
  "payload": {
    "task_id": "T-04",
    "status": "done_with_caveats",
    "artifacts": ["db/migrations/20260406_add_refresh_token.ts", "db/schema.ts"],
    "notes": "Also updated the exported UserRow type in db/schema.ts to stay consistent. No other files touched.",
    "test_status": { "written": 2, "passing": 2, "failing": 0, "skipped": 0 }
  },
  "constraints": {}
}
```

Valid values for `status`: `"done"` or `"done_with_caveats"`. Use caveats when
the worker had to make a judgment call or touched something adjacent to the spec.

---

### verify_request

An agent requests review and verification of a specific artifact or decision
before treating the task complete or advancing a phase.

```json
{
  "type": "verify_request",
  "timestamp": "2026-04-06T15:01:00Z",
  "from": "worker-auth",
  "to": "verifier",
  "payload": {
    "subject": "JWT refresh token rotation implementation",
    "question": "Does the 30s clock-skew buffer introduce a replay window an attacker could exploit?",
    "artifacts": ["src/auth/refresh.ts", "tests/auth/refresh.test.ts"],
    "context": "Tokens expire after 15 minutes. The buffer lets tokens within 30s of expiry still generate a refresh.",
    "urgency": "blocking"
  },
  "constraints": {}
}
```

`urgency` values: `"blocking"` (do not advance without verdict) or
`"non_blocking"` (proceed but log result).

---

### verdict

The response to a `verify_request`. A fail must include actionable findings.
A pass may carry observations that do not block.

```json
{
  "type": "verdict",
  "timestamp": "2026-04-06T15:14:00Z",
  "from": "verifier",
  "to": "worker-auth",
  "payload": {
    "subject": "JWT refresh token rotation implementation",
    "result": "fail",
    "reasons": [
      "refresh.ts line 61: old token is not invalidated before issuing the new one. Concurrent requests succeed during the buffer window.",
      "No test case covers concurrent refresh attempts."
    ],
    "recommendations": []
  },
  "constraints": {}
}
```

`result` values: `"pass"` or `"fail"`. `reasons` is required and non-empty on
fail. On pass, use it for observations. `recommendations` is always optional.

---

### blocked

An agent reports it cannot continue. Send this as soon as a blocker is
discovered, not at the end of a phase. The lead depends on early signals to
re-plan.

```json
{
  "type": "blocked",
  "timestamp": "2026-04-06T15:20:00Z",
  "from": "worker-export",
  "to": "lead",
  "payload": {
    "task_id": "T-07",
    "blocker": "Downstream API endpoint URL is absent from config/delivery.yaml and undocumented in the spec.",
    "blocker_type": "missing_resource",
    "needs": [
      "Endpoint URL for the downstream delivery API",
      "Auth scheme (bearer token or API key)"
    ],
    "progress_so_far": "Output formatter written and tested. Transport layer cannot be completed without the endpoint."
  },
  "constraints": {}
}
```

`blocker_type` values: `"dependency"`, `"missing_resource"`, `"ambiguous_spec"`,
`"conflict"`, `"permission"`.

---

### scope_adjustment

An agent requests permission to touch files outside its authorized scope.
Send this before acting, not after. Never touch out-of-scope files and report
it after the fact.

```json
{
  "type": "scope_adjustment",
  "timestamp": "2026-04-06T15:28:00Z",
  "from": "worker-schema",
  "to": "lead",
  "payload": {
    "task_id": "T-04",
    "current_scope": ["db/migrations/", "db/schema.ts"],
    "requested_scope": ["src/models/user.ts"],
    "reason": "db/schema.ts exports UserRow, consumed by src/models/user.ts. Updating the schema without updating the type causes a compile error in wave 3.",
    "risk": "Build fails when auth middleware imports UserRow and finds it inconsistent with the updated schema."
  },
  "constraints": {}
}
```

The lead responds with either approval (freeform or a new `task_dispatch` with
expanded scope) or a rejection with alternative instructions.

---

## Contract Delivery Methods

Contracts are JSON objects. How they move between agents depends on the
runtime. Four delivery methods cover every supported pattern.

### 1. File drop (recommended default)

Write the contract JSON to a file at:

```
tmp/<runtime>-run/contracts/<agent-id>-<contract-type>.json
```

Example path: `tmp/sprint-2026-04-08-run/contracts/worker-auth-task_complete.json`

This is the most reliable method. The file survives context resets, can be
read by any agent with filesystem access, and leaves an auditable trail.
Use this as the default unless the runtime has no shared filesystem.

### 2. Task prompt injection (dispatch only)

Paste the contract JSON block directly into the spawned agent's task prompt.
This works for orchestrator-to-worker dispatch: the orchestrator knows what
it is sending before the worker exists. Workers cannot use this method to
respond back to an orchestrator already in context.

### 3. AGENTS.md mandate (async, all runtimes)

Instruct workers in `AGENTS.md` to emit a `task_complete` contract as the
final output of their session. Workers read `AGENTS.md` at startup, so this
mandate travels with the repo and does not require per-task instruction.
This method works across all runtimes including async batch runners where
the orchestrator and worker never share a live channel.

### 4. OpenClaw announce-back

The `sessions_spawn` tool in OpenClaw returns a `runId`. When the spawned
session completes, the result is posted back to the orchestrator's channel.
The contract JSON should be the content of that response: the orchestrator
reads the response body, parses the JSON contract, and uses it to advance
the sprint state. This method is native to the OpenClaw runtime and requires
no file system writes.

---

## Structured vs. Freeform Messages

The distinguishing question: does this message trigger an action or gate a
phase transition in the receiver? If yes, use a contract. If it is informational
only, freeform is fine.

```
+------------------------------------------+--------------------+
| Situation                                | Use                |
+------------------------------------------+--------------------+
| Assigning work with defined scope        | task_dispatch      |
| Phase completion gate signal             | phase_complete     |
| Task completion report                   | task_complete      |
| Requesting review before phase gate      | verify_request     |
| Issuing a review result (pass or fail)   | verdict            |
| Cannot continue without lead action      | blocked            |
| Need to touch files outside your scope   | scope_adjustment   |
| Sharing context or background notes      | freeform           |
| Asking a clarifying question             | freeform           |
| Status update that gates nothing         | freeform           |
+------------------------------------------+--------------------+
```

In a Hive Mind run, the lead should gate every phase transition on contracts
from all expected senders. Freeform messages can be missed or mis-parsed in
ways that contracts cannot.

In a Codex runtime, where the orchestrator drives the main loop and workers
run as background tasks, contracts provide the structured channel the
orchestrator uses to evaluate completion and decide what fires next. Freeform
output from a background worker carries no reliable signal unless it embeds
a contract in its response.

---

## Related Docs

- [Hive Mind 2-Tier Pattern](../patterns/hive-mind-2tier.md)
- [Hive Mind 3-Tier Pattern](../patterns/hive-mind-3tier.md)
- [Worker Swarm Pattern](../patterns/worker-swarm.md)
- [Checkpoint Protocol](../guides/checkpoint-protocol.md)
- [Sprint Artifacts](../guides/sprint-artifacts.md)

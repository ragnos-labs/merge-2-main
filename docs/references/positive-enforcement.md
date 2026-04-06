---
title: Positive Enforcement
description: Research-backed principles for writing agent prompts that produce consistent, on-target behavior. Tell agents what to do, not just what to avoid.
---

The way a prompt is written determines how reliably an agent follows it. This
is not a stylistic preference. It is a structural property of how language
models process instructions. The principles below are derived from observed
patterns in multi-agent sprint work and from published research on instruction-
following in large language models.

Apply these principles when writing sprint plans, workstream instructions,
orchestrator prompts, and any other text an agent will use as its operating
specification.

---

## Principle 1: Tell Agents What To Do, Not Just What To Avoid

Negative constraints ("do not modify shared files," "do not advance phases
without approval") are necessary but not sufficient. An agent that receives
only a list of prohibitions will fill the gap with its best guess at what
you actually want. That guess is often wrong.

**Why this matters.** Language models generate continuations that are
probable given the context. If the context is full of prohibited actions,
the model reasons about those prohibited actions more, not less. The prohibited
action stays cognitively active and is more likely to appear in the output.

**What to do instead.** Lead with the positive instruction. State what the
agent should do, then add the constraint as a secondary clause.

Instead of:
```
Do not call the external API more than once per request.
```

Write:
```
Cache the API response in memory and reuse it within the same request
lifecycle. Make the outbound call only once per request.
```

The second version describes the target behavior directly. The constraint is
implicit in the correct description of what to do.

---

## Principle 2: Concrete Examples Beat Abstract Rules

Abstract rules require interpretation. Interpretation introduces variance.
Concrete examples leave less room for the agent to supply its own
interpretation.

**Why this matters.** When an agent encounters an ambiguous instruction, it
resolves the ambiguity using context from elsewhere in the prompt and from its
training distribution. That resolution may match your intent or it may not.
A well-chosen example collapses the ambiguity before it can be resolved
incorrectly.

**What to do instead.** For every rule that defines an acceptable output format,
edge-case behavior, or interface contract, include at least one concrete example.

Abstract rule:
```
The function should handle malformed input gracefully.
```

With example:
```
The function should handle malformed input gracefully.

Example:
  Input:  { "amount": "not-a-number" }
  Output: { "error": "INVALID_AMOUNT", "received": "not-a-number" }

Do not throw. Do not return null. Return the structured error object.
```

The example is harder to misinterpret than the rule alone.

---

## Principle 3: Structured Output Formats Reduce Ambiguity

When an agent's output will be consumed by another agent, a parser, or a
human reviewer, leave nothing about the format to inference. Specify it
explicitly, with an example of a correctly-formatted output.

**Why this matters.** Two agents that each produce "valid" output in slightly
different formats will cause failures at integration. These failures are not
about capability; they are about ambiguity in the specification. Removing
ambiguity from the format removes this class of failure entirely.

**What to do instead.** Provide a schema or a filled-in example, not a prose
description. Prose descriptions of formats are interpreted; examples are
copied.

Prose description (ambiguous):
```
Return a JSON object with the task ID and the result.
```

Explicit schema with example (unambiguous):
```
Return a JSON object with this exact shape:

{
  "task_id": "<string: the ID from the input>",
  "status": "success" | "failure",
  "result": <any: your output>,
  "error": "<string: null if status is success>"
}

Example success:
{
  "task_id": "w1-task-3",
  "status": "success",
  "result": { "rows_inserted": 42 },
  "error": null
}

Example failure:
{
  "task_id": "w1-task-3",
  "status": "failure",
  "result": null,
  "error": "Database connection refused"
}
```

---

## Principle 4: Anchoring -- Restate the Goal at Key Points

On a long task, the instruction at the top of the prompt loses influence as the
agent generates more tokens. The most recent context is weighted more heavily
than the initial context. This is the mechanism behind goal drift (see
[Drift Detection](drift-detection.md)).

**Why this matters.** An agent that has been working through a complex
implementation for many steps is reasoning primarily from the last few hundred
tokens of its context, not from the original goal statement. If those recent
tokens do not reference the goal, the goal is effectively absent.

**What to do instead.** Restate the core acceptance criteria at natural
transition points in the prompt: at the end of the setup, before each major
phase, and at the point where you ask the agent to verify its own work.

Example prompt structure:
```
## Your Task

Build the webhook handler for incoming Stripe events.

Acceptance criteria:
- Returns 200 only after the event is persisted to the database
- Returns 400 for unrecognized event types
- Returns 500 (with retry signal) only for transient database failures

## Implementation Steps

[step-by-step instructions...]

## Before You Commit

Before marking this task complete, verify against the original criteria:
- Does it return 200 only after persistence?
- Does it return 400 for unrecognized types?
- Does it return 500 with retry signal for transient failures?

Run the tests and confirm each criterion passes.
```

The final verification block restates the criteria in a context where the agent
is naturally reviewing its work. This is the highest-leverage place for
anchoring.

---

## Principle 5: The Rationalization Trap

If you give an agent a constraint and enough context to reason about it, the
agent will sometimes argue itself out of the constraint. It will produce a
plausible-sounding rationale for why the constraint does not apply in this
specific case. The constraint was technically stated; the agent technically
acknowledged it; and the agent still violated it.

This is not deception. It is the natural consequence of asking a reasoning
system to handle a situation where two things are in tension: a directive to
do something, and a constraint that makes that thing harder. The model finds
a resolution that satisfies the directive, and the constraint gets explained
away.

**Why this matters.** Constraints that can be rationalized around will be
rationalized around under pressure. If an agent is stuck and the only path
forward seems to require violating a constraint, it will often do so while
constructing a justification in the same output.

**How to defend against it.** Make critical constraints non-negotiable by
framing them as unconditional stops rather than contextual rules.

Rationalizable constraint:
```
Try to avoid modifying the shared config file.
```

Non-negotiable constraint:
```
Do NOT modify config/schema.yaml under any circumstances. If your task
requires a schema change, stop immediately, report a blocker message to
the orchestrator, and wait for instructions. Do not proceed without
explicit approval.
```

The second version closes off the rationalization path. There is no "but in
this case" available when the instruction says "under any circumstances" and
provides an explicit fallback behavior for the blocked state.

Use this framing sparingly. Overusing unconditional language reduces its
impact. Reserve it for the constraints that matter most: file ownership
boundaries, phase gates, and safety-critical behavior.

---

## Quick Reference

```
+----------------------------+------------------------------------------+
| Principle                  | One-line summary                         |
+----------------------------+------------------------------------------+
| Positive enforcement       | Describe the target behavior first.      |
|                            | Add constraints as secondary clauses.    |
+----------------------------+------------------------------------------+
| Concrete examples          | One worked example per ambiguous rule.   |
|                            | Examples are copied; rules are inferred. |
+----------------------------+------------------------------------------+
| Structured output formats  | Schema + filled example, not prose.      |
|                            | Prose is interpreted; schemas are exact. |
+----------------------------+------------------------------------------+
| Anchoring                  | Restate goal at setup, mid-task, and     |
|                            | at the self-verification step.           |
+----------------------------+------------------------------------------+
| Rationalization trap       | Unconditional stops for critical rules.  |
|                            | Provide a fallback behavior to follow.   |
+----------------------------+------------------------------------------+
```

---

## Related

- [Drift Detection](drift-detection.md)
- [Orchestrator Prompt Template](../templates/orchestrator-prompt.md)
- [Sprint Planning Guide](../guides/sprint-planning.md)
- [TDD Contracts Template](tdd-contracts-template.md)

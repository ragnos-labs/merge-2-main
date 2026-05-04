---
title: Subagent Definition Template
description: A reusable role-definition file that pins model tier, effort level, tool surface, and scope for a named agent role. Maps to the "declared role default" enforcement surface in the model selection guide.
---

# Subagent Definition Template

A subagent definition is a declared role default. Instead of restating model tier
and effort in every spawn prompt, you write the role once and reference it by name.
The runtime applies the pinned settings on every invocation, so a forgotten field in
a spawn prompt no longer silently escalates.

This template is runtime-neutral in shape. The exact filename, location, and
loading mechanism vary; the field set does not. See the matching runtime adapter
under `docs/runtimes/` for where to place the file.

---

## Field set

```yaml
---
name: explore-standard
description: Read-only exploration role. Searches files, runs grep, fetches web pages, and reports findings. Use for codebase recon and lookup tasks where the scope is open-ended but the work is read-only.
model: standard
effort: high
tools:
  - Read
  - Grep
  - Glob
  - WebFetch
  - WebSearch
boundaries:
  - read_only: true
  - max_tool_calls: 80
output_contract: |
  Return a brief written summary of what you found. Use file:line references.
  Do not propose code changes.
---

You are a read-only exploration agent. Your job is to find information and
report it back to the lead. You do not edit, write, or run side-effecting
commands.

When you receive a task:

1. Identify the target (a file, a symbol, a topic, a question).
2. Use the smallest set of tool calls that answers the question with confidence.
3. Return a structured summary: file:line citations, plus a one-paragraph synthesis.

If the question is ambiguous, return what you found and flag the ambiguity for the
lead to resolve. Do not invent a clarification.
```

---

## Field reference

| Field | Required | Purpose |
|-------|----------|---------|
| `name` | yes | Role identifier. Used by spawn calls to reference the role. |
| `description` | yes | One-sentence summary of when to use this role. Drives routing decisions when the lead chooses among roles. |
| `model` | yes | Tier pin: `standard`, `most-capable`, or `fast`. See `docs/core/guides/model-selection.md` for tier semantics. |
| `effort` | recommended | Default reasoning effort: `low`, `medium`, `high`, `max`. May be overridden per-spawn. |
| `tools` | recommended | Tool allowlist. Restricting the surface enforces the role's intent (read-only roles get no Edit/Write). |
| `boundaries` | optional | Hard limits the role enforces: read_only flag, max tool calls, time budget, etc. |
| `output_contract` | optional | Inline instruction the role appends to every spawn prompt. Useful when the role has a fixed return shape. |

The body of the file (after the frontmatter) is the role's standing instruction. It
is prepended to the lead's per-task prompt at spawn time.

---

## Three role profiles

A typical sprint reaches for three definitions:

```
explore-standard       standard tier, high effort, read-only tools
mechanical-fast        fast tier, default effort, narrow edit tools
implement-standard     standard tier, high effort, full code-edit tools
```

Reaching for a fourth ("debug-most-capable") is the right move only when the
mechanical/standard combination has demonstrably failed. See the model selection
guide for escalation criteria.

---

## What this gives you

- One source of truth per role. Tier pins, tool surfaces, and standing instructions
  live next to each other and travel together.
- Spawn prompts shrink. The lead writes "spawn explore-standard with task: <task>"
  instead of restating the role every time.
- The pre-spawn guardrail (`docs/templates/universal/spawn-guard-hook.md`) can
  reject spawns that omit a model pin. With named roles, that rejection turns into
  a one-character fix.

---

## Related

- `docs/core/guides/model-selection.md`: tier semantics and per-pattern defaults
- `docs/templates/universal/spawn-guard-hook.md`: the guardrail that enforces these
  pins at spawn time

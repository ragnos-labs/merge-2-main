---
title: Research Manifest Schema
description: JSON schema reference for Research Swarm task manifests, including field definitions, a complete example, and validation rules.
---

# Research Manifest Schema

A research manifest is a JSON file that defines the tasks assigned to a Research Swarm.
Each task poses a focused question, declares its execution wave, and lists any tasks that
must complete before it can start. The manifest is the primary coordination artifact for
the Research Swarm pattern.

See [../patterns/research-swarm.md](../patterns/research-swarm.md) for the full pattern
description, including how manifests are authored, distributed, and consumed by agents.

---

## Top-Level Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Unique identifier for the manifest run |
| `description` | string | yes | Summary of the swarm research goal |
| `tasks` | Task[] | yes | Ordered list of Task objects |

## Task Fields

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `id` | string | yes | | Unique task ID within the manifest |
| `question` | string | yes | | Focused research question the agent must answer |
| `wave` | integer | yes | | Execution wave (0 = start immediately) |
| `blockedBy` | string[] | no | `[]` | Task IDs that must complete before this task starts |
| `tools` | string[] | no | all | Allowed tool names (e.g. `web_search`, `read_file`) |
| `outputFormat` | string | no | `markdown` | One of: `markdown`, `json`, `bullet_list`, `structured_report` |
| `model` | string | no | `sonnet` | One of: `haiku`, `sonnet`, `opus` |

Model tier guidance: use `haiku` for simple lookups, `sonnet` for analysis, `opus` for
final synthesis or security review.

---

## Schema (JSON Schema Draft-07)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ResearchManifest",
  "type": "object",
  "required": ["id", "description", "tasks"],
  "properties": {
    "id":          { "type": "string" },
    "description": { "type": "string" },
    "tasks": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": ["id", "question", "wave"],
        "properties": {
          "id":           { "type": "string" },
          "question":     { "type": "string" },
          "wave":         { "type": "integer", "minimum": 0 },
          "blockedBy":    { "type": "array", "items": { "type": "string" }, "default": [] },
          "tools":        { "type": "array", "items": { "type": "string" } },
          "outputFormat": { "type": "string", "enum": ["markdown","json","bullet_list","structured_report"], "default": "markdown" },
          "model":        { "type": "string", "enum": ["haiku","sonnet","opus"], "default": "sonnet" }
        }
      }
    }
  }
}
```

---

## Complete Example

A 7-task manifest evaluating vector database libraries across three waves.

```json
{
  "id": "rm-library-eval-001",
  "description": "Evaluate three open-source vector database libraries for production fit.",
  "tasks": [
    {
      "id": "T1",
      "question": "What is the stable release version and license of Chroma?",
      "wave": 0,
      "tools": ["web_search"],
      "outputFormat": "bullet_list",
      "model": "haiku"
    },
    {
      "id": "T2",
      "question": "What is the stable release version and license of Qdrant?",
      "wave": 0,
      "tools": ["web_search"],
      "outputFormat": "bullet_list",
      "model": "haiku"
    },
    {
      "id": "T3",
      "question": "What is the stable release version and license of Weaviate?",
      "wave": 0,
      "tools": ["web_search"],
      "outputFormat": "bullet_list",
      "model": "haiku"
    },
    {
      "id": "T4",
      "question": "What are published throughput and latency benchmarks for Chroma at 1M vectors?",
      "wave": 1,
      "blockedBy": ["T1"],
      "tools": ["web_search", "read_file"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T5",
      "question": "What are published throughput and latency benchmarks for Qdrant at 1M vectors?",
      "wave": 1,
      "blockedBy": ["T2"],
      "tools": ["web_search", "read_file"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T6",
      "question": "What are published throughput and latency benchmarks for Weaviate at 1M vectors?",
      "wave": 1,
      "blockedBy": ["T3"],
      "tools": ["web_search", "read_file"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T7",
      "question": "Which library best fits a deployment requiring Apache 2.0 and sub-10ms p99 latency? Provide a ranked comparison table.",
      "wave": 2,
      "blockedBy": ["T4", "T5", "T6"],
      "outputFormat": "structured_report",
      "model": "opus"
    }
  ]
}
```

Wave breakdown:

- Wave 0: T1, T2, T3 run in parallel immediately.
- Wave 1: T4, T5, T6 each start once their wave-0 counterpart completes; all three run in parallel.
- Wave 2: T7 starts after all wave-1 tasks finish, synthesizing their outputs.

---

## Validation Rules

**Structural:**

1. Every `id` (manifest and task) must be unique within the file.
2. `wave` must be a non-negative integer.
3. Every ID in `blockedBy` must reference an existing task in the same manifest.

**Wave:**

4. Wave 0 tasks must have an empty or absent `blockedBy`.
5. A task's `wave` must be strictly greater than the wave of every task it lists in `blockedBy`.

**Dependencies:**

6. No circular dependencies allowed. A -> B -> A (through any chain) is invalid.
7. `blockedBy` entries are task IDs, not wave numbers.

**Authoring guidance:**

- Keep wave 0 tasks narrow (single-source lookups, version checks).
- Declare `blockedBy` only when the downstream task genuinely needs upstream output.
  Over-blocking serializes work that could run in parallel.
- Most swarms need at most three waves. Deeper chains increase latency and complicate debugging.

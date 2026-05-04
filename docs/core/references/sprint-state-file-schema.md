---
title: Sprint State File Schema
description: The canonical structure for the orchestrator-owned sprint state file used in Hive Mind 3-tier and other multi-workstream patterns. Markdown shell with embedded YAML for the parseable parts; one source of truth that any lead can read to orient.
---

# Sprint State File Schema

The sprint state file is the single source of truth for a multi-workstream
sprint. The Orchestrator is the sole writer; Workstream Leads read it to
orient themselves after a phase transition. Without a canonical format,
every team invents its own and the state files stop being interoperable
across runs.

This page defines the canonical shape: a Markdown shell with embedded YAML
for the parseable parts. Rich enough for a human to skim, structured enough
for a script to validate.

See [../patterns/hive-mind-3tier.md](../patterns/hive-mind-3tier.md) for the
pattern context.

---

## File location and naming

```
.ai/sprints/<slug>/sprint-state.md
```

One file per sprint. The slug matches the sprint branch name (so
`sprint/auth-refactor` corresponds to `.ai/sprints/auth-refactor/`).

---

## Required sections

The file always contains these sections in this order:

1. Frontmatter (YAML, parseable)
2. `## Current Phase`
3. `## Workstream Status`
4. `## Dependencies`
5. `## Phase Log`

Optional but recommended:

- `## Decisions` (for orchestrator decisions that affect more than one workstream)
- `## Open Questions` (for items waiting on a human checkpoint)

---

## Frontmatter

```yaml
---
sprint:
  slug: auth-refactor
  pattern: hive-mind-3tier
  base_branch: main
  sprint_branch: sprint/auth-refactor
  started_at: 2026-04-18T13:00:00Z
  orchestrator: orchestrator-1
workstreams:
  - id: ws-a
    name: API Routes
    branch: sprint/auth-refactor--ws-a
    worktree: .worktrees/auth-refactor--ws-a
    lead: lead-a
  - id: ws-b
    name: Auth Middleware
    branch: sprint/auth-refactor--ws-b
    worktree: .worktrees/auth-refactor--ws-b
    lead: lead-b
  - id: ws-c
    name: Database Layer
    branch: sprint/auth-refactor--ws-c
    worktree: .worktrees/auth-refactor--ws-c
    lead: lead-c
  - id: ws-d
    name: Tests and Docs
    branch: sprint/auth-refactor--ws-d
    worktree: .worktrees/auth-refactor--ws-d
    lead: lead-d
---
```

Frontmatter is parseable. Anything that needs script access (CI gate, status
dashboard, automation) reads from frontmatter, not from the body.

---

## Body sections

### Current Phase

One line. The current phase number plus name.

```markdown
## Current Phase

Phase 3: Implementation Wave 1
```

### Workstream Status

One line per workstream. Each line is a status keyword plus a short note.

```markdown
## Workstream Status

- WS-A: in_progress (3 of 5 tasks complete)
- WS-B: phase_complete (waiting for WS-A output)
- WS-C: in_progress (2 of 4 tasks complete)
- WS-D: blocked on WS-A:task-2 (see Dependencies)
```

Status keywords:

- `not_started`: workstream has not begun this phase
- `in_progress`: actively running
- `phase_complete`: all tasks for the current phase done; waiting for orchestrator broadcast
- `blocked`: cannot proceed; reason follows the keyword
- `done`: workstream finished all phases

### Dependencies

One block per cross-workstream dependency. Use a sub-bullet for the
orchestrator's decision when one is required.

```markdown
## Dependencies

- WS-D:task-1 blocked by WS-A:task-2 (schema output required)
  - WS-A:task-2 expected after current Bee wave commits
  - Orchestrator decision: WS-D begins read-only prep work; implementation waits

- WS-B:task-3 reads WS-C:auth-config.yaml (read-only; no write contention)
```

Pure read dependencies are still listed. They affect sequencing decisions
even when they do not create blocking conditions.

### Phase Log

Append-only. One line per phase transition.

```markdown
## Phase Log

- 2026-04-18T13:00:00Z Phase 0 complete: spec written, leads spawned, file ownership set
- 2026-04-18T13:42:00Z Phase 1 complete: 4 audit reports collected, no critical blockers
- 2026-04-18T14:15:00Z Phase 2 complete: stubs committed across all workstreams; TDD G2 passed
- 2026-04-18T14:31:00Z Phase 3 started: implementation wave 1 in flight
```

The phase log is the orchestrator's history. It is not the meta-log
(see [meta-log-gates](../guides/meta-log-gates.md)); the phase log is a
strict subset focused on phase transitions.

### Decisions (optional)

```markdown
## Decisions

- 2026-04-18T15:30:00Z Defer ws-c index work to follow-up sprint; not
  blocking current scope. Recorded in meta-log: meta-log.jsonl line 142.
```

Use the Decisions section when an orchestrator decision changes scope, defers
work, or accepts a tradeoff that should be visible later. Trivial decisions
(reordering tasks, claiming a Bee) stay in the meta-log only.

### Open Questions (optional)

```markdown
## Open Questions

- Awaiting GREEN on Phase 5 checkpoint: should WS-D run a full test suite
  before WS-B finishes its session migration? Posted at 2026-04-18T16:02Z.
```

This section is the inbox for the human approver. Empty most of the time;
populated only when the orchestrator is waiting on a judgment call.

---

## Worked example: full file

```markdown
---
sprint:
  slug: auth-refactor
  pattern: hive-mind-3tier
  base_branch: main
  sprint_branch: sprint/auth-refactor
  started_at: 2026-04-18T13:00:00Z
  orchestrator: orchestrator-1
workstreams:
  - id: ws-a
    name: API Routes
    branch: sprint/auth-refactor--ws-a
    worktree: .worktrees/auth-refactor--ws-a
    lead: lead-a
  - id: ws-b
    name: Auth Middleware
    branch: sprint/auth-refactor--ws-b
    worktree: .worktrees/auth-refactor--ws-b
    lead: lead-b
  - id: ws-c
    name: Database Layer
    branch: sprint/auth-refactor--ws-c
    worktree: .worktrees/auth-refactor--ws-c
    lead: lead-c
  - id: ws-d
    name: Tests and Docs
    branch: sprint/auth-refactor--ws-d
    worktree: .worktrees/auth-refactor--ws-d
    lead: lead-d
---

# Sprint State: auth-refactor

## Current Phase

Phase 3: Implementation Wave 1

## Workstream Status

- WS-A: in_progress (3 of 5 tasks complete)
- WS-B: phase_complete (waiting for WS-A output)
- WS-C: in_progress (2 of 4 tasks complete)
- WS-D: blocked on WS-A:task-2

## Dependencies

- WS-D:task-1 blocked by WS-A:task-2 (schema output required)
  - WS-A:task-2 expected after current Bee wave commits
  - Orchestrator decision: WS-D begins read-only prep work; implementation waits

## Phase Log

- 2026-04-18T13:00:00Z Phase 0 complete: spec written, leads spawned
- 2026-04-18T13:42:00Z Phase 1 complete: 4 audit reports, no critical blockers
- 2026-04-18T14:15:00Z Phase 2 complete: stubs committed; TDD G2 passed
- 2026-04-18T14:31:00Z Phase 3 started: implementation wave 1 in flight

## Decisions

- 2026-04-18T15:30:00Z Defer ws-c index work to follow-up sprint
  (not blocking; meta-log.jsonl line 142)
```

---

## Validation rules

A sprint state file is valid when:

1. Frontmatter is well-formed YAML.
2. Every workstream listed in frontmatter appears in `## Workstream Status`.
3. Status keywords match the allowed set (`not_started`, `in_progress`,
   `phase_complete`, `blocked`, `done`).
4. Phase Log entries are timestamped and append-only (never edit prior lines).
5. `Current Phase` matches the most recent phase log entry.

A simple validator script:

```bash
#!/usr/bin/env bash
# validate-sprint-state.sh
# Exit 0 if the file is well-formed, non-zero with messages otherwise.

set -euo pipefail
file="${1:?path to sprint-state.md required}"

# Frontmatter parses
yq '.sprint.slug' "$file" >/dev/null || { echo "frontmatter unparseable"; exit 2; }

# Required sections present
for section in "## Current Phase" "## Workstream Status" "## Dependencies" "## Phase Log"; do
  grep -q "^${section}$" "$file" || { echo "missing section: $section"; exit 3; }
done

# Status keywords valid
allowed_re='not_started|in_progress|phase_complete|blocked|done'
awk '/^## Workstream Status/{flag=1; next} /^## /{flag=0} flag' "$file" \
  | grep -oE ': [a-z_]+' \
  | sed 's/: //' \
  | grep -vE "^(${allowed_re})$" && { echo "invalid status keyword found"; exit 4; }

echo "sprint-state.md OK"
```

---

## Anti-patterns

- **Multiple writers.** The orchestrator owns this file. Workstream leads
  request updates by reporting to the orchestrator; they never edit the
  state file directly. Concurrent writes corrupt history.
- **Phase log compaction.** Tempting after long sprints. Resist it. The log
  is the audit trail; squashing it breaks reproducibility.
- **Inline implementation detail.** This file describes coordination, not
  code. If you find yourself listing function signatures or test outputs,
  move that content to the workstream's scratchpad or the meta-log.
- **Missing dependencies.** A dependency that exists in code but not in this
  file is invisible to phase planning. List every cross-workstream
  dependency, including pure-read ones.

---

## Related

- [../patterns/hive-mind-3tier.md](../patterns/hive-mind-3tier.md): pattern
  context; the orchestrator role this file supports
- [../guides/meta-log-gates.md](../guides/meta-log-gates.md): the broader
  evidence trail this file complements
- [../../templates/universal/scratchpad-entries.md](../../templates/universal/scratchpad-entries.md):
  the intra-workstream JSONL log this file does not replace

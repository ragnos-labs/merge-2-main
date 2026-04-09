---
title: Sprint Artifacts
description: The structured outputs every multi-agent sprint must produce: meta-log, bug log, retrospective, and sprint state file.
---

# Sprint Artifacts

Multi-agent sprints move fast. Dozens of tasks complete, agents escalate, blockers surface
and resolve, clever workarounds get applied. Without structured output, all of that
operational intelligence disappears the moment the sprint ends.

Sprint artifacts solve this. They turn a sprint from an ephemeral event into a reviewable,
improvable system. This guide covers the four artifacts and when each pattern uses them.

---

## Why Artifacts Matter

Agent work has two failure modes: shipping the wrong thing, and shipping the right thing
in a way that cannot be reviewed or improved.

Code changes are visible through diffs and tests. Coordination decisions are not. Why did
the lead escalate that task to a stronger model? What did the agent discover about that
API's rate limits? Which phase gate took 12 minutes when it should have taken two?

Without artifacts, those questions have no answers. The next sprint starts from scratch.
With artifacts, each sprint feeds the next one:

- The meta-log captures decisions and discoveries as they happen, ready for post-sprint
  analysis and knowledge promotion.
- The bug log surfaces process friction before it compounds across multiple runs.
- The retrospective synthesizes both into human-readable insights and metrics.
- The sprint state file (Hive Mind only) gives any observer a live snapshot of where
  every workstream stands.

---

## Artifact Overview by Pattern

```
+-----------------+-----------+-----------+------------------+------------------+
| Pattern         | Meta-Log  | Bug Log   | Retrospective    | Sprint State     |
+-----------------+-----------+-----------+------------------+------------------+
| Patchwork       | No        | No        | No               | No               |
| Worker Swarm    | Yes       | Yes       | Yes              | No               |
| Research Swarm  | Yes       | Yes       | Yes              | No               |
| Hive Mind       | Yes       | Yes       | Yes              | Yes              |
| Worktree Sprint | Yes       | Yes       | Yes              | Optional         |
+-----------------+-----------+-----------+------------------+------------------+
```

Initialize the meta-log and bug log before spawning any agents. The retrospective and
sprint state file are generated during or after the sprint.

---

## The Meta-Log (JSONL)

### Purpose

The meta-log is a machine-readable, append-only record of every significant event during
the sprint. It captures the signal that would otherwise be lost: why a model choice
worked or failed, what was discovered about the codebase, which phase gate bottlenecked,
and what the sprint accomplished overall.

This data drives three downstream uses:

1. Auto-fills retrospective metrics without manual tallying.
2. Feeds a knowledge store for cross-sprint pattern recognition.
3. Enables post-sprint quality scoring by model, effort level, and task type.

### File Location

```
.ai/sprints/<slug>/meta-log.jsonl
```

One file per sprint. Append-only during execution. Processed after the sprint ends.

### Entry Format

Each line is a self-contained JSON object. Newline-delimited, no trailing commas.

All entries require four fields:

- `ts`: ISO 8601 UTC timestamp
- `type`: event type (see table below)
- `agent`: name of the agent writing the entry
- `summary`: one sentence, 120 characters or fewer

```jsonl
{"ts":"2024-11-01T14:30:00Z","type":"discovery","agent":"api-lead","summary":"Rate limit is per-account, not per-key; batching does not help","impact":"high","tags":["api","rate-limits"]}
{"ts":"2024-11-01T14:45:00Z","type":"escalation","agent":"api-lead","summary":"Task W1-04 failed on smaller model, escalated to larger model","from_model":"small","to_model":"large","reason":"Multi-file refactor required broader context","task_id":"W1-04"}
{"ts":"2024-11-01T15:00:00Z","type":"novel_solution","agent":"db-lead","summary":"Used DB migration dry-run flag to validate schema before applying","detail":"Avoids rollback risk on production runs.","tags":["database","migrations"]}
{"ts":"2024-11-01T15:30:00Z","type":"bottleneck","agent":"orchestrator","summary":"Phase 1 gate blocked 14 min waiting on db-lead synthesis","duration_min":14,"phase":"1-to-2"}
{"ts":"2024-11-01T16:00:00Z","type":"phase_transition","agent":"orchestrator","summary":"Phase 1 complete, starting Phase 2","from_phase":1,"to_phase":2,"leads_reporting":3,"tasks_completed":22}
{"ts":"2024-11-01T16:10:00Z","type":"bug_caught","agent":"api-lead","summary":"Worker task W2-07 produced empty output on empty input, not an error","severity":"medium","task_id":"W2-07"}
{"ts":"2024-11-01T16:20:00Z","type":"trip_up","agent":"db-lead","summary":"Migration tool requires service account before schema changes","detail":"Access denied on first run. Service account creation added to pre-sprint checklist.","resolution":"Added SA creation step to sprint init"}
{"ts":"2024-11-01T17:00:00Z","type":"sprint_summary","agent":"orchestrator","summary":"Shipped 4-workstream API hardening with zero regressions","intent":"Harden API surface and tighten error handling","deliverables":["Rate limit middleware","Schema validation layer","Error normalization","Retry backoff"],"impact":"high","buckets":{"wins":12,"bugs":3,"hiccups":5,"discoveries":8}}
```

### Event Types

```
+--------------------+------------------------------------------+----------------------------------+
| Type               | When to Log                              | Extra Required Fields            |
+--------------------+------------------------------------------+----------------------------------+
| discovery          | Learned something new about domain       | (none beyond the four core)      |
|                    | or codebase                              |                                  |
+--------------------+------------------------------------------+----------------------------------+
| escalation         | Task failed, agent upgraded to stronger  | from_model, to_model             |
|                    | model on retry                           |                                  |
+--------------------+------------------------------------------+----------------------------------+
| novel_solution     | Solved a problem in an unexpected or     | (none)                           |
|                    | notably efficient way                    |                                  |
+--------------------+------------------------------------------+----------------------------------+
| bug_caught         | Code error detected and fixed during     | (none; severity optional)        |
|                    | the sprint                               |                                  |
+--------------------+------------------------------------------+----------------------------------+
| bottleneck         | Idle time more than 5 minutes            | (none; duration_min recommended) |
|                    | caused by blocking                       |                                  |
+--------------------+------------------------------------------+----------------------------------+
| trip_up            | Something failed that was not predicted  | (none; resolution recommended)   |
|                    | in the sprint plan                       |                                  |
+--------------------+------------------------------------------+----------------------------------+
| phase_transition   | Phase gate crossed                       | from_phase, to_phase             |
+--------------------+------------------------------------------+----------------------------------+
| model_validation   | Model or effort choice proved right      | model, effort, outcome           |
|                    | or wrong on a specific task              |                                  |
+--------------------+------------------------------------------+----------------------------------+
| workaround         | Ad-hoc fix applied to get past a         | problem                          |
|                    | tool or API limitation                   |                                  |
+--------------------+------------------------------------------+----------------------------------+
| innovation         | Deliberately applied a good engineering  | (none; pattern recommended)      |
|                    | practice worth repeating                 |                                  |
+--------------------+------------------------------------------+----------------------------------+
| human_checkpoint   | Operator checkpoint fired and signal     | tier, signal_received            |
|                    | received                                 |                                  |
+--------------------+------------------------------------------+----------------------------------+
| sprint_summary     | Sprint complete, before final ship step  | intent                           |
+--------------------+------------------------------------------+----------------------------------+
```

Valid values for common optional fields:

- `impact`: `low` | `medium` | `high`
- `severity`: `low` | `medium` | `high` | `critical`
- `outcome` (model_validation): `success` | `failure` | `partial`
- `signal_received` (human_checkpoint): `proceed` | `redirect` | `abort` | `pending`

### The Four Buckets

Every meta-log entry falls into one of four categories. Use these headings when writing
or presenting a retrospective:

```
+--------------+----------------------------+-------------------------------------------+
| Bucket       | What It Captures           | Entry Types                               |
+--------------+----------------------------+-------------------------------------------+
| Wins         | Things that worked,        | novel_solution, innovation,               |
|              | delivered value            | model_validation (success),               |
|              |                            | sprint_summary, phase_transition          |
+--------------+----------------------------+-------------------------------------------+
| Bugs         | Code errors caught         | bug_caught                                |
+--------------+----------------------------+-------------------------------------------+
| Hiccups      | Friction, delays, retries  | bottleneck, escalation, trip_up,          |
|              |                            | workaround, model_validation (failure)    |
+--------------+----------------------------+-------------------------------------------+
| Discoveries  | Domain or codebase         | discovery                                 |
|              | knowledge that was new     |                                           |
+--------------+----------------------------+-------------------------------------------+
```

The `sprint_summary` entry should include a `buckets` object with counts:
`{"wins": N, "bugs": N, "hiccups": N, "discoveries": N}`.

### Ownership Rules

```
+---------------------------+----------------------------------------------+---------------------+
| Agent Role                | What They Log                                | How                 |
+---------------------------+----------------------------------------------+---------------------+
| Orchestrator              | Phase transitions, cross-workstream events,  | Direct append       |
|                           | bottlenecks                                  |                     |
+---------------------------+----------------------------------------------+---------------------+
| Team Leads                | Escalations, discoveries, model validation,  | Direct append       |
|                           | bug catches, bottlenecks within workstream   |                     |
+---------------------------+----------------------------------------------+---------------------+
| Operators (Res. Swarm)    | Wave completions, escalations, bugs between  | Direct append       |
|                           | waves                                        |                     |
+---------------------------+----------------------------------------------+---------------------+
| Worker Bees               | Nothing directly                             | Report to lead via  |
|                           |                                              | task return value   |
+---------------------------+----------------------------------------------+---------------------+
| Teammates (Hive Mind)     | Nothing directly                             | Report to lead via  |
|                           |                                              | runtime message     |
|                           |                                              | decides what to log |
+---------------------------+----------------------------------------------+---------------------+
```

Only agents with workstream context write to the meta-log. Bees and teammates lack the
vantage point to judge what is noteworthy. That judgment belongs to the lead.

### When to Write

Write an entry when:

- A model or effort choice is validated (success or failure)
- A task is escalated to a stronger model after failure
- Something new is discovered about the domain or codebase
- A non-obvious solution avoids a larger problem
- A bottleneck idles agents for more than 5 minutes
- A phase gate transitions
- Something breaks that was not in the sprint plan
- A workaround is applied to get past a tool or API limitation
- At sprint end, before the final ship step, write a `sprint_summary` entry

Do not write entries for:

- Routine task completions (the task list tracks those)
- Normal worker success where the model choice was unremarkable
- Every inter-agent message (too noisy)

Rule of thumb: if an agent doing a future sprint on the same codebase would benefit from
knowing this, log it.

### Appending

```bash
echo '{"ts":"2024-11-01T14:30:00Z","type":"discovery","agent":"lead-name","summary":"..."}' \
  >> .ai/sprints/<slug>/meta-log.jsonl
```

Leads can maintain entries in memory and batch-append at phase boundaries. Each entry must
be one complete JSON object per line with no trailing comma.

Concurrent appends from multiple leads are safe on Linux and macOS. JSONL is atomic at
the line level. No locking is needed.

---

## The Bug Log (Markdown)

### Purpose

The bug log is the human-readable complement to the meta-log. Where the meta-log captures
domain learning, the bug log captures the sprint process itself breaking.

```
+----------+-------------------------------+-------------------------------------------+
| Log      | Tracks                        | Example                                   |
+----------+-------------------------------+-------------------------------------------+
| Meta-log | Domain learning, model        | "Small model failed on multi-file         |
|          | validation, discoveries       |  refactor, escalated to larger model"     |
+----------+-------------------------------+-------------------------------------------+
| Bug log  | Process and execution         | "Phase 1 signal file was never written,   |
|          | failures and friction         |  Phase 2 waited 90s before timeout"       |
+----------+-------------------------------+-------------------------------------------+
```

Note: `bug_caught` entries in the meta-log are about code bugs found during the sprint.
Bug log entries are about the sprint machinery itself malfunctioning.

### File Location

```
.ai/sprints/<slug>/sprint-bug-log.md
```

### Initialization

Create this file before spawning any agents:

```bash
SPRINT_BUG_LOG=".ai/sprints/<slug>/sprint-bug-log.md"
mkdir -p "$(dirname "$SPRINT_BUG_LOG")"
cat > "$SPRINT_BUG_LOG" <<'INIT'
# Sprint Bug Log
<!-- Process issues only. NOT code bugs. Tracks failures in sprint execution. -->

| # | Phase/Wave | Severity | What happened | Expected behavior | Impact |
|---|------------|----------|---------------|-------------------|--------|
INIT
```

### Severity Levels

- **BUG**: Something broke or produced wrong results. Must be investigated before next sprint.
- **WARN**: Degraded but recovered. Should be fixed.
- **NOTE**: Minor friction. Nice to fix.

### What to Log

- **Silent failures**: Command exits 0 but produces empty or garbage output
- **Agent failures**: Agent crashes, zombies, timeouts, or wrong output format
- **Retries**: Any step re-run due to tool failures, formatting interference, or stale reads
- **Skipped work**: Steps skipped due to missing tools, environment issues, or timeouts
- **Unexpected state**: Files modified between read and edit, git conflicts, signal files missing
- **Timing blowups**: Any operation taking more than 60 seconds when under 10 was expected
- **Model mismatches**: Model assigned a task outside its capability boundary
- **Communication failures**: Messages lost, broadcasts ignored, agent output not collected
- **Workarounds**: Any deviation from the planned process to get past a blocker

### Appending

```bash
echo "| {N} | {Phase/Wave} | {BUG/WARN/NOTE} | {what happened} | {expected} | {impact} |" \
  >> "$SPRINT_BUG_LOG"
```

---

## The Retrospective

### Purpose

The retrospective synthesizes both artifacts into a human-readable post-sprint analysis.
It answers: what shipped, what worked, what broke, and what to change for next time.

The retrospective is generated after sprint completion, typically by a dedicated post-sprint
processing step. It is not written manually during the sprint.

### File Location

```
.ai/sprints/<slug>/retrospective.md
```

### Contents

A complete retrospective includes:

**Sprint metadata**

- Pattern used (Worker Swarm, Hive Mind 2-tier, etc.)
- Agent count, task count, workstream count
- Phase count and total elapsed time

**Metrics table** (auto-filled from meta-log)

```
+-----------------------------+--------+
| Metric                      | Value  |
+-----------------------------+--------+
| Tasks completed             | 28/30  |
| Escalations                 | 4      |
| Total bottleneck time (min) | 19     |
| BUG-severity process issues | 2      |
| WARN-severity process issues| 3      |
| Discoveries logged          | 7      |
+-----------------------------+--------+
```

**Findings by bucket**

Organized under Wins, Bugs, Hiccups, and Discoveries. Pull the top entries by impact
from the meta-log.

**Model selection insights**

Which model-effort combinations succeeded and which did not. Reference the
`model_validation` entries from the meta-log.

**Recommendations**

Specific changes for the next sprint: different model assignments, adjusted phase gate
criteria, pre-sprint checklist additions, SOP amendments.

### Metrics: Definitions

- **Escalation count**: number of `escalation` entries in the meta-log.
- **Bottleneck time**: sum of `duration_min` across all `bottleneck` entries.
- **Success rate by model**: `model_validation` entries grouped by model and effort,
  then `success` count divided by total for each group.
- **Process bug count**: BUG/WARN/NOTE row counts from the bug log.
- **Discovery count**: number of `discovery` entries in the meta-log.

---

## Sprint State File (Hive Mind Only)

### Purpose

For Hive Mind patterns (2-tier and 3-tier), the sprint state file is a live snapshot of
all workstream statuses. Any observer, including the orchestrator, a lead, or a human
reviewer, can read it to understand current progress without interrupting agents.

### File Location

```
.ai/sprints/<slug>/state.md
```

### Format

```markdown
# Sprint State: <slug>

Updated: 2024-11-01T15:00:00Z

## Workstreams

| Workstream | Lead        | Status      | Tasks Done | Tasks Total | Blocker          |
|------------|-------------|-------------|------------|-------------|------------------|
| api        | api-lead    | IN_PROGRESS | 8          | 12          | (none)           |
| db         | db-lead     | BLOCKED     | 5          | 10          | Missing env var  |
| frontend   | fe-lead     | COMPLETE    | 15         | 15          | (none)           |

## Current Phase

Phase 2 of 3. Waiting on: api, db.

## Flags

- db workstream blocked since 14:45. Escalated to orchestrator.
```

### Status Values

- `PENDING`: workstream initialized, not yet started
- `IN_PROGRESS`: active work underway
- `BLOCKED`: cannot proceed, waiting on external unblock
- `COMPLETE`: all tasks done, lead reported in
- `FAILED`: workstream could not complete, see blocker field

### Who Updates It

- The orchestrator creates the state file at sprint start.
- Each lead updates their workstream row when status changes.
- The orchestrator updates the current phase line at each phase transition.
- Any agent writes to the flags section to surface a cross-workstream issue.

Worktree Sprint setups may also use a state file when the orchestrator needs to track
progress across isolated branches.

---

## How Artifacts Compose Across Patterns

Each pattern produces a different artifact profile. The table below shows what gets
created and who is responsible.

**Worker Swarm**: The lead (acting as orchestrator) maintains both the meta-log and the
bug log. No sprint state file because there is only one workstream. Post-sprint, a single
agent processes both artifacts and writes the retrospective.

**Research Swarm**: The operator maintains both artifacts between waves. The meta-log
captures what each wave discovered and any escalations. The bug log captures wave-level
process failures. The retrospective becomes the primary deliverable, since Research Swarm
outputs are findings rather than shipped code.

**Hive Mind 2-tier**: The lead maintains the meta-log and bug log, with teammates
reporting noteworthy events via messages. The lead filters and decides what to log. The
sprint state file tracks teammate status. The orchestrator does not exist in 2-tier; the
lead plays both roles.

**Hive Mind 3-tier**: The orchestrator logs phase transitions and cross-workstream events.
Each lead logs their own workstream's escalations, discoveries, and bugs. Worker bees
report to leads via task return values. All leads contribute to the same meta-log and bug
log files. The sprint state file tracks all workstreams.

**Worktree Sprint**: Each worktree has its own lead running the chosen pattern. The
orchestrator coordinates across worktrees. Each worktree writes its own meta-log and bug
log. At merge time, these are combined into a unified retrospective.

```
+------------------+-------------------+-------------------+-------------------+
| Pattern          | Meta-Log Owner    | Bug Log Owner     | State File Owner  |
+------------------+-------------------+-------------------+-------------------+
| Worker Swarm     | Lead              | Lead              | N/A               |
| Research Swarm   | Operator          | Operator          | N/A               |
| Hive Mind 2-tier | Lead              | Lead              | Lead              |
| Hive Mind 3-tier | Orchestrator +    | Orchestrator +    | Orchestrator      |
|                  | all leads         | all leads         |                   |
| Worktree Sprint  | Orchestrator +    | Orchestrator +    | Orchestrator      |
|                  | worktree leads    | worktree leads    | (optional)        |
+------------------+-------------------+-------------------+-------------------+
```

---

## Templates

### Meta-Log Initialization

```bash
mkdir -p .ai/sprints/<slug>
touch .ai/sprints/<slug>/meta-log.jsonl
```

First entry (write immediately after creating the file):

```jsonl
{"ts":"<ISO8601>","type":"phase_transition","agent":"orchestrator","summary":"Sprint <slug> started","from_phase":0,"to_phase":1,"tasks_completed":0}
```

### Bug Log Initialization

```bash
cat > .ai/sprints/<slug>/sprint-bug-log.md <<'INIT'
# Sprint Bug Log

<!-- Process issues only. NOT code bugs. Tracks failures in sprint execution. -->

| # | Phase/Wave | Severity | What happened | Expected behavior | Impact |
|---|------------|----------|---------------|-------------------|--------|
INIT
```

### Sprint State File Initialization (Hive Mind)

```bash
cat > .ai/sprints/<slug>/state.md <<'INIT'
# Sprint State: <slug>

Updated: <ISO8601>

## Workstreams

| Workstream | Lead | Status  | Tasks Done | Tasks Total | Blocker |
|------------|------|---------|------------|-------------|---------|
| ws-1       |      | PENDING | 0          | 0           |         |

## Current Phase

Phase 1 of N. Starting.

## Flags

(none)
INIT
```

### Retrospective Template

```markdown
# Sprint Retrospective: <slug>

**Pattern**: <pattern name>
**Agents**: <count>
**Tasks**: <completed>/<total>
**Phases**: <count>

## Metrics

| Metric                      | Value |
|-----------------------------|-------|
| Tasks completed             |       |
| Escalations                 |       |
| Bottleneck time (min)       |       |
| BUG-severity process issues |       |
| WARN-severity process issues|       |
| Discoveries logged          |       |

## Wins

<!-- Top novel_solution, innovation, sprint_summary entries -->

## Bugs

<!-- bug_caught entries by severity -->

## Hiccups

<!-- bottleneck, escalation, trip_up entries -->

## Discoveries

<!-- discovery entries sorted by impact -->

## Model Insights

<!-- model_validation entries: what worked, what did not -->

## Recommendations

<!-- Specific changes for next sprint -->
```

---

## Quick Reference

```
SPRINT START:
  mkdir -p .ai/sprints/<slug>
  touch .ai/sprints/<slug>/meta-log.jsonl
  Initialize sprint-bug-log.md (see template above)
  Initialize state.md if Hive Mind (see template above)
  Write first meta-log entry: phase_transition from 0 to 1

DURING SPRINT (leads and orchestrator only):
  Meta-log: append JSONL entries for noteworthy events
  Bug log: append markdown rows for process failures
  State file: update workstream rows on status changes
  Bees report to leads; leads decide what to log

AT PHASE BOUNDARIES:
  Orchestrator logs phase_transition entry
  Leads batch-append any pending meta-log entries before reporting phase complete
  Orchestrator updates current phase line in state file

POST-SPRINT:
  Write sprint_summary entry to meta-log
  Processing agent reads meta-log.jsonl and sprint-bug-log.md
  Computes metrics, generates retrospective.md
  Archives artifacts alongside sprint plan
```

---

## Related Docs

- [Pattern Overview](../patterns/overview.md)
- [Worker Swarm](../patterns/worker-swarm.md)
- [Research Swarm](../patterns/research-swarm.md)
- [Hive Mind 2-Tier](../patterns/hive-mind-2tier.md)
- [Hive Mind 3-Tier](../patterns/hive-mind-3tier.md)
- [Worktree Sprint](../patterns/worktree-sprint.md)
- [Pattern Selection](../guides/decision-tree.md)

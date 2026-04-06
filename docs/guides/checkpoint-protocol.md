---
title: Checkpoint Protocol
description: When and how agents pause for human review during multi-agent work. Covers complexity tiers, checkpoint format, trigger logic, pattern-specific behavior, and rejection recovery.
---

# Checkpoint Protocol

Multi-agent systems can drift. One wrong assumption in wave 1 compounds into
a broken architecture by wave 3. A checkpoint is a structured pause before a
consequential wave fires: a moment for the human to verify that the agents
are still on track before work becomes hard to reverse.

Checkpoints are not approval gates on every action. They are signal points
before high-consequence boundaries. The goal is to be in a position to
intervene when it matters, not to slow down routine work.

---

## Why Checkpoints Exist

Agents accumulate errors in ways that are invisible until something breaks.
Common failure modes in multi-agent runs:

- **Scope drift**: an agent gradually expands its interpretation of the task
  and changes files it was not supposed to touch
- **Wrong assumption propagation**: an early design decision (made without
  full context) gets built on by downstream agents who treat it as correct
- **Silent failures**: a worker reports success but the output is subtly
  wrong; the lead never verifies the actual files
- **Model escalation gaps**: a fast model handles a step that needed judgment;
  the error is small but cascades

A checkpoint surfaces these issues before the sprint reaches the wave that
creates a PR, deploys to production, sends external messages, or otherwise
takes actions that are costly to reverse.

**Research basis**: Anthropic's Feb 2026 autonomy research found that human
involvement drops from 87% on simple tasks to 67% on complex ones. Complexity
is where oversight thins. The checkpoint pattern exists specifically for the
complex end of that spectrum.

---

## Complexity Tiers

Assign a tier at the start of any multi-agent run. The tier determines whether
and how often a checkpoint fires. If no tier is declared, use the defaults by
pattern listed in the table below.

```
+------+----------+----------------------------------------------------+-----------+
| Tier | Label    | Typical Use                                        | Checkpts  |
+------+----------+----------------------------------------------------+-----------+
| T0   | trivial  | Single-agent, <10 mechanical changes, no           | None      |
|      |          | coordination needed (rename, config tweak)         |           |
+------+----------+----------------------------------------------------+-----------+
| T1   | simple   | Single-wave Worker Swarm, single-file feature,     | None      |
|      |          | bounded and reversible                             |           |
+------+----------+----------------------------------------------------+-----------+
| T2   | moderate | Multi-wave Worker Swarm, multi-file feature,       | Once      |
|      |          | standard Hive Mind 2-tier                          | pre-final |
+------+----------+----------------------------------------------------+-----------+
| T3   | complex  | Hive Mind 3-tier, Research Swarm feeding a         | Twice     |
|      |          | builder, any run with irreversible actions         | mid + pre |
+------+----------+----------------------------------------------------+-----------+
```

Default tier by pattern (when not declared):

- Patchwork: T0
- Worker Swarm (1 wave): T1
- Worker Swarm (2+ waves): T2
- Research Swarm: T2 (standard) or T3 (if findings feed a large builder)
- Hive Mind 2-tier: T2
- Hive Mind 3-tier: T3 always

Declare the tier in the sprint manifest or system prompt:

```json
{
  "sprint_slug": "my-feature-sprint",
  "complexity_tier": "T2"
}
```

Or inline: "This is a T3 sprint. Three parallel workstreams, each with a
lead and bees. Checkpoints fire at wave 2 midpoint and before the final
merge wave."

---

## The 8-Field Checkpoint Block

The lead or orchestrator outputs a checkpoint block when the trigger fires.
No prose preamble. Structured, scannable, under 15 lines.

```
CHECKPOINT [T2|T3] -- <sprint-slug> -- Wave N of M
=================================================
DONE        <1-2 sentences: what was completed since last checkpoint>
GOAL        <original sprint objective verbatim: re-anchors the reviewer>
DEFERRED    <items intentionally skipped and why; "none" if nothing deferred>
RISK        <top 1-2 risks or issues surfaced; "none" if run was clean>
FILES       <list of files changed, or "see commit diff">
TEST_STATUS <N stubs written, M passing, K failing, J skipped>
NEXT        <what the next wave will do, including any irreversible actions>
BLOCKERS    <anything preventing progress; "none" if clear to proceed>
-------------------------------------------------
SIGNAL?     proceed | redirect <instructions> | abort
=================================================
```

Field-by-field guidance:

**DONE**: Summarize what agents actually completed, not what was planned.
Include wave or phase numbers so the reviewer can orient.

**GOAL**: Copy the sprint objective verbatim from the spec. This re-anchors
both the reviewer and the agents; drift is easier to spot when you read the
original goal alongside the summary of what was done.

**DEFERRED**: List any items explicitly skipped with a one-line reason. If
an agent decided not to handle an edge case, that belongs here. Deferred items
do not disappear; they surface for the reviewer to decide whether to require
them before proceeding.

**RISK**: Scan the run log for bugs caught, unexpected workarounds, model
escalations, and bottlenecks. Summarize the top 1-2. Do not write risk from
memory; read the actual log. If the log is clean, write "none."

**FILES**: List changed files or reference the commit diff. This lets the
reviewer spot scope bleed (a worker touching files outside its assignment).

**TEST_STATUS**: Report from the test runner, not from agent self-reports.
Format: "N stubs written, M passing, K failing, J skipped." If the sprint has
no test contracts, write "no test contracts defined."

**NEXT**: Describe the next wave in concrete terms. If it will create a PR,
write "creates PR against main (irreversible)." If it will deploy, write
"deploys to production (irreversible)." The reviewer needs to know the stakes
before responding.

**BLOCKERS**: List anything that would prevent the next wave from running
cleanly. If none, write "none."

**SIGNAL?**: The reviewer's response. Three valid values:
- `proceed`: continue to the next wave as planned
- `redirect <instructions>`: modify the next wave before continuing
- `abort`: stop the sprint; agents commit current state and open a WIP branch

---

## Trigger Logic

A checkpoint fires automatically in the following situations, regardless of
the scheduled tier timing:

**New external dependency added.** If an agent adds a dependency on a
third-party service, API, or package that was not in the original spec, pause.
The reviewer may not have approved that dependency.

**Architecture change.** If an agent proposes or implements a structural
change that differs from the agreed design (new abstraction layer, different
data model, changed API contract), pause before building on top of it.

**Security-sensitive code.** Authentication, authorization, encryption,
credential handling, or data sanitization changes always warrant a pause.
These are hard to audit after the fact and easy to get subtly wrong.

**Irreversible action pending.** Any wave that will push to a remote branch,
open a PR, deploy, send external messages, or modify production data must be
preceded by a checkpoint, even on T1 runs.

**Three or more workers failed.** Cascading worker failures indicate a
problem in the original decomposition or shared assumptions. Stop and present
a checkpoint before re-dispatching.

---

## Human Review: What to Check

When a checkpoint arrives, review these areas before responding:

**Verify goal alignment.** Read GOAL against DONE. Are the agents building
what was specified? Drift shows up here first.

**Scan DEFERRED.** Decide whether the deferred items are acceptable to skip
or must be included before proceeding. Redirect if required.

**Evaluate RISK.** If a risk entry describes a workaround, verify the
workaround is sound. Do not accept "it works now" without understanding why.

**Check FILES for scope bleed.** A worker that touched files outside its
assignment may have introduced unintended changes. Spot-check suspicious files.

**Validate TEST_STATUS.** Failing tests are a blocker unless the reviewer
explicitly accepts them as deferred. "4 failing, 0 skipped" paired with
"proceed" requires a conscious decision, not a rubber stamp.

**Read NEXT carefully.** Understand exactly what will happen after you respond.
If NEXT says "creates PR (irreversible)" and you are not satisfied with the
current state, use `redirect` or `abort`. There is no undo after the PR opens.

---

## Headless (Background) Checkpoints

When a sprint runs unattended (background mode, no interactive terminal):

1. The lead or orchestrator writes the checkpoint block to a file:
   `.ai/sprints/<slug>/checkpoint-<N>.md`

2. The sprint pauses. It does not proceed to the next wave.

3. The reviewer reads the checkpoint file, appends their signal to the bottom:
   `SIGNAL: proceed`
   (or `redirect ...` or `abort`)

4. The lead or orchestrator reads the file, updates the run log with the
   received signal, and continues (or halts) accordingly.

This prevents background sprints from firing irreversible actions without
reviewer awareness. The checkpoint file is the async signal channel.

Never configure a background sprint to auto-proceed without a signal. The
checkpoint exists precisely because unattended runs are the highest-risk
scenario.

---

## Checkpoint in Worker Swarm

The lead collects results from all workers and produces the checkpoint block.

Trigger point for T2 Worker Swarm: after the execution wave, before the
consolidation or ship wave.

```
Lead action sequence:
1. All workers complete execution wave (background)
2. Lead reads every worker's output (do not trust self-reports)
3. Lead verifies test runner output
4. Lead produces CHECKPOINT block from actual data, not from memory
5. Lead presents checkpoint to human and waits for SIGNAL
6. On "proceed": lead runs consolidation and commits
7. On "redirect": lead applies instructions, then consolidates
8. On "abort": lead commits current state, opens WIP PR or branch, stops
```

The lead must not present the checkpoint until it has actually read worker
outputs and test results. A checkpoint built from agent self-reports is
worthless.

For T2 Worker Swarm specifically, the checkpoint fires once: after execution,
before any irreversible action (commit to shared branch, PR creation, deploy).

---

## Checkpoint in Hive Mind

### 2-Tier Hive Mind (T2)

The lead produces one checkpoint before the final wave (typically the ship,
PR creation, or deploy phase). The structure is identical to the Worker Swarm
checkpoint, but DONE summarizes teammate outputs rather than worker outputs.

The lead consolidates teammate reports into a single RISK and TEST_STATUS
before presenting. Do not present one checkpoint per teammate; one
consolidated block is the protocol.

### 3-Tier Hive Mind (T3)

Two checkpoints fire:

**Checkpoint 1 (midpoint)**: After all leads complete their first
implementation wave, before they spawn bee workers for integration. The
orchestrator collects lead summaries, consolidates RISK and TEST_STATUS across
all workstreams, and presents the block to the human.

**Checkpoint 2 (pre-ship)**: After leads complete their final implementation
wave, before the orchestrator fires the ship or merge wave. This is the last
intervention point before irreversible actions.

The orchestrator writes both checkpoints. Leads do not present checkpoints
directly to the human; all reviewer communication flows through the
orchestrator.

```
3-tier checkpoint flow:

Orchestrator
    |
    +-- Checkpoint 1 (midpoint)
    |     +-- crm-lead reports -> orchestrator consolidates
    |     +-- aws-lead reports -> orchestrator consolidates
    |     +-- brain-lead reports -> orchestrator consolidates
    |     +-- Orchestrator presents single CHECKPOINT block
    |     +-- SIGNAL? -> proceed (all 3 leads continue to wave 2)
    |
    +-- Checkpoint 2 (pre-ship)
          +-- All leads complete wave 2 -> orchestrator consolidates
          +-- Orchestrator presents single CHECKPOINT block
          +-- SIGNAL? -> proceed (ship wave fires) | abort | redirect
```

---

## Checkpoint Format Examples

### Worker Swarm T2 -- pre-consolidation

```
CHECKPOINT T2 -- auth-refactor -- Wave 2 of 3
=================================================
DONE        6 workers completed auth module cleanup. 42 tests migrated to
            new session token format. helpers/auth/ fully refactored.
GOAL        Migrate auth module from legacy session cookies to JWT tokens
            with backward-compatible fallback layer.
DEFERRED    Fallback layer deprecation warning (agreed to defer to follow-up
            sprint; no behavioral change in this run).
RISK        Worker 3 hit an edge case in refresh token rotation: added a
            30s clock-skew buffer. Workaround is sound; documented in tests.
FILES       src/auth/**, tests/auth/**, config/auth.yaml (see diff)
TEST_STATUS 42 stubs written, 42 passing, 0 failing, 0 skipped
NEXT        Wave 3: commit to shared branch and open PR against main
            (irreversible once pushed).
BLOCKERS    none
-------------------------------------------------
SIGNAL?     proceed | redirect <instructions> | abort
=================================================
```

### Hive Mind 3-Tier T3 -- midpoint checkpoint

```
CHECKPOINT T3 (1/2) -- data-pipeline-sprint -- W1 complete, W2 pending
=================================================
DONE        All 3 leads completed Wave 1. ingest-lead: schema + loader
            pipeline. transform-lead: normalization rules + mapper library.
            export-lead: output formatters + delivery wrapper scaffolded.
GOAL        Build a full E2E data pipeline: ingest CSV sources, normalize
            to canonical schema, and export to downstream APIs.
DEFERRED    Retry logic for export failures (scheduled for W2 bee layer).
RISK        transform-lead: discovered upstream CSV vendor uses inconsistent
            date formats across 3 source files. Handled with a parser shim;
            adds a dependency on dateutil. Needs reviewer sign-off.
FILES       src/ingest/**, src/transform/**, src/export/** (scaffolds only)
TEST_STATUS 28 stubs written, 22 passing, 6 failing (export layer stubs,
            expected at this stage), 0 skipped
NEXT        Wave 2: leads spawn bee workers for integration wiring and E2E
            tests. No irreversible actions in W2.
BLOCKERS    Reviewer approval needed on dateutil dependency before W2 starts.
-------------------------------------------------
SIGNAL?     proceed | redirect <instructions> | abort
=================================================
```

---

## Recovering from Checkpoint Rejection

When the reviewer responds `abort` or `redirect`, agents must not continue
building on the current state.

### On "redirect"

1. The lead or orchestrator reads the redirect instructions carefully.
2. Apply the instructions to the plan for the next wave. Do not apply them
   retroactively to already-completed work unless the instructions explicitly
   require it.
3. If the redirect requires undoing work from a completed wave, the lead
   identifies the affected files, reverts them (using version control), and
   re-queues those tasks with the corrected spec.
4. Log the redirect and what changed in the run log.
5. Continue to the next wave with the modified plan.

### On "abort"

1. Stop all in-progress agent work immediately.
2. Commit the current state to a WIP branch (do not commit to the main branch
   or any shared branch).
3. Open a draft PR or leave the branch in a state the reviewer can inspect.
4. Write a brief summary of what was completed, what was in progress, and what
   had not started.
5. Do not delete anything. The reviewer needs the current state intact to
   decide how to proceed.

### Rolling back a completed wave

If the reviewer identifies that a completed wave produced bad output:

1. Identify the exact files changed in that wave (from the FILES field or the
   commit diff).
2. Revert those files using version control:
   `git checkout <commit-before-wave> -- <file> [<file2> ...]`
3. Re-run the wave with corrected instructions. Treat it as a fresh wave, not
   a patch on top of the bad output. Patching bad output compresses errors
   rather than removing them.
4. Present a new checkpoint after the re-run before proceeding further.

### Prevention over recovery

Rollback is expensive. The checkpoint exists to prevent the need for it. If
reviews are consistently requiring redirects, the checkpoint signals are
arriving too late. Move the checkpoint earlier in the sprint or increase the
tier.

---

## Anti-Patterns

```
+-------------------------------------+--------------------------------------+
| Anti-Pattern                        | Why It Fails                         |
+-------------------------------------+--------------------------------------+
| Skipping checkpoint on T2+ run      | Reviewer is blind before the         |
|                                     | irreversible wave fires              |
+-------------------------------------+--------------------------------------+
| Checkpoint on every T0/T1 task      | Friction with no benefit; trains     |
|                                     | reviewers to rubber-stamp            |
+-------------------------------------+--------------------------------------+
| Checkpoint after ship already fired | Too late; PR is open, deploy is live |
+-------------------------------------+--------------------------------------+
| Building RISK from memory           | Misses actual run issues; always     |
|                                     | scan the run log for real data       |
+-------------------------------------+--------------------------------------+
| Trusting agent self-reports in      | Agents report success; read actual   |
| TEST_STATUS                         | test runner output                   |
+-------------------------------------+--------------------------------------+
| Auto-proceeding in headless mode    | Background runs are highest risk;    |
|                                     | the checkpoint exists for this case  |
+-------------------------------------+--------------------------------------+
| One checkpoint per teammate/lead    | Reviewer gets N partial views        |
|                                     | instead of one consolidated read-out |
+-------------------------------------+--------------------------------------+
```

---

## Related Docs

- [Pattern Selection Decision Tree](decision-tree.md)
- [Worker Swarm](../patterns/worker-swarm.md)
- [Hive Mind 2-Tier](../patterns/hive-mind-2tier.md)
- [Hive Mind 3-Tier](../patterns/hive-mind-3tier.md)
- [Research Swarm](../patterns/research-swarm.md)
- [Worktree Sprint](../patterns/worktree-sprint.md)

---
title: Hive Mind (3-Tier)
description: The flagship pattern for large multi-workstream operations. One Orchestrator at the top, Workstream Leads in the middle, Worker Bees at the bottom. For 15-30 agents across 4 or more parallel workstreams.
---

# Hive Mind (3-Tier)

The 3-tier Hive Mind is the highest-ceiling pattern in this framework. It handles
large, multi-workstream operations that would collapse under a flat coordination
model. The hierarchy exists for one reason: complexity management. An Orchestrator
cannot track 20 concurrent tasks directly. Worker Bees cannot make cross-workstream
decisions. Workstream Leads bridge those two realities.

Use this pattern when the work is genuinely large. Below roughly 12 agents, the
overhead kills the benefit. See [When NOT to Use This](#when-not-to-use-this).

---

## When to Use It

Use the 3-tier Hive Mind when all of the following are true:

- 4 or more parallel workstreams, each with its own internal complexity
- 15-30 agents total across the operation
- Workstreams have internal task graphs that justify a dedicated lead managing
  a pool of workers
- Cross-workstream dependencies exist and need an authority to sequence them
- The operation spans multiple phases with hard gate requirements between them

Examples that fit:

- A product launch sprint touching frontend, backend, infrastructure, and docs
  simultaneously, each with 4-6 tasks
- A codebase-wide migration (4 subsystems, each requiring discovery, implementation,
  and validation waves)
- A security hardening pass across API layer, auth, data layer, and logging with
  cross-cutting dependency chains
- Any sprint where a flat Worker Swarm would require the lead to track more than
  12 concurrent task states

If you are not sure whether the work justifies this pattern, read the decision
matrix in [Overview](./overview.md).

---

## Architecture

Three tiers, strictly layered:

```
Tier 1: ORCHESTRATOR (strongest model, max effort)
  |
  |  Owns the sprint plan. Gates every phase transition.
  |  Resolves cross-workstream conflicts and blocked dependencies.
  |  Sole caller of any external APIs with rate limits (e.g., GitHub).
  |  Maintains the shared sprint state file.
  |
  +-- Tier 2: WORKSTREAM LEAD A (strong model, high effort)
  |     |
  |     |  Owns one workstream end-to-end.
  |     |  Spawns and directs Worker Bees via Task tool.
  |     |  Collects and synthesizes Bee results.
  |     |  Reports phase-complete status to Orchestrator.
  |     |  Relays cross-workstream findings to peer Leads or Orchestrator.
  |     |
  |     +-- Bee A1 (efficient model, effort matched to task)
  |     +-- Bee A2 (efficient model, effort matched to task)
  |     +-- Bee A3 (efficient model, effort matched to task)
  |
  +-- Tier 2: WORKSTREAM LEAD B (strong model, high effort)
  |     +-- Bee B1
  |     +-- Bee B2
  |     +-- Bee B3
  |     +-- Bee B4
  |
  +-- Tier 2: WORKSTREAM LEAD C (strong model, high effort)
  |     +-- Bee C1
  |     +-- Bee C2
  |     +-- Bee C3
  |
  +-- Tier 2: WORKSTREAM LEAD D (strong model, high effort)
        +-- Bee D1
        +-- Bee D2
        +-- Bee D3
        +-- Bee D4
        +-- Bee D5
```

Each workstream is owned by exactly one Lead. Leads are peers and can message
each other directly when their workstreams share a dependency. Worker Bees are
private to their Lead: they do not communicate with the Orchestrator, with other
Leads, or with Bees in other workstreams. Their output flows up through their
parent Lead only.

---

## Model Selection Across Tiers

Assign the strongest reasoning capacity to the top tier, where the decisions are
most consequential, and the most efficient models to the bottom, where tasks are
narrow and well-specified.

| Tier | Role | Model Tier | Effort |
|------|------|-----------|--------|
| Tier 1 | Orchestrator | Strongest available | Max |
| Tier 2 | Workstream Leads | Strong (e.g., Sonnet-class) | High |
| Tier 3 | Worker Bees: standard tasks | Efficient (e.g., Sonnet-class) | Scaled to task |
| Tier 3 | Worker Bees: mechanical tasks | Fastest available (e.g., Haiku-class) | Default |

**Why Leads must run at high effort.** Leads do multi-hop coordination: synthesizing
Bee results, replanning when a Bee fails, detecting intra-workstream conflicts, and
framing cross-workstream signals for the Orchestrator. Medium effort is insufficient
for this coordination load. Always specify high effort when spawning a Lead.

**Why Bees are efficient models.** Bees receive a narrow, well-scoped task prompt
from their Lead. There is no ambiguity to resolve at spawn time. The Bee's cost
is dominated by execution volume (many Bees), so model efficiency matters here
in a way it does not at the Orchestrator tier.

**Never use the strongest model at the Bee tier.** The cost differential between
the strongest and fastest models can be 15x or more. Bee-tier work does not
benefit from that extra reasoning capacity because the Lead has already done the
hard thinking before spawning the Bee.

---

## The Effort Thermostat

The Orchestrator sets the reasoning temperature for each phase of the operation.
Leads propagate the appropriate effort level to their Bees.

**Phase-level effort guidance:**

| Phase Type | Orchestrator Instruction | Lead Effort | Bee Effort |
|-----------|------------------------|-------------|-----------|
| Discovery and audit | "Low stakes, read-only" | High | Low |
| Design and planning | "High ambiguity, judgment required" | High | Medium |
| Implementation | "Mixed: standard and mechanical tasks" | High | Low-Medium per task |
| Integration and testing | "Cross-system, expect surprises" | High | Medium-High |
| Validation and ship | "Correctness critical" | High | Medium |

The Orchestrator does not micro-manage Bee effort. It tells each Lead the
phase character at the start of the phase. The Lead matches Bee effort to
the specific task. A Lead running a discovery wave might spawn some Bees at
low effort (file scans) and others at medium (schema analysis). The Orchestrator
does not need to know this detail.

**Escalation path when a Bee fails:**

1. Bee at default/low effort fails on a task.
2. Lead escalates the same task to a higher effort level (one step up).
3. If still failing, Lead resolves the ambiguity itself and re-spawns with
   a rewritten prompt.
4. Lead never silently drops a failed task. Every failure gets a meta-log entry.

---

## Communication Protocol

Communication is strictly layered. No skip-level messaging.

| From | To | Channel | Purpose |
|------|----|---------|---------|
| Orchestrator | Single Lead | Direct message | Phase assignments, dependency unblocks |
| Orchestrator | All Leads | Broadcast message | Phase transitions, STOP signals |
| Lead | Orchestrator | Direct message | Phase-complete reports, escalations |
| Lead | Peer Lead | Direct message | Dependency signals ("W1 output ready, W2 unblocked") |
| Lead | Bee | Task tool prompt | Self-contained task with full context |
| Bee | Lead | Task tool return | Structured result (bullets or JSON) |
| Bee | Scratchpad | File append | Lock announcements, findings, warnings |

**The skip-level rule.** A Bee that discovers a cross-workstream issue does NOT
message the other Lead directly. It reports the finding to its parent Lead via
the Task return value. The Lead decides whether to relay it to the peer Lead or
escalate to the Orchestrator. Leads have context that Bees lack; they filter and
frame cross-workstream signals before passing them up or sideways.

**Broadcast discipline.** The Orchestrator should broadcast fewer than 5 times per
operation. Overuse dilutes urgency. Reserve broadcasts for phase gates and genuine
STOP conditions (rate limit hit, unrecoverable conflict).

**Lead-to-Lead messaging.** Leads can message peer Leads directly when a dependency
between workstreams is ready or blocked. This peer messaging is encouraged and
does not need to go through the Orchestrator. The Orchestrator only needs to be
involved when the cross-workstream situation requires a decision (not just a
notification).

---

## The Scratchpad Pattern

Each workstream has a shared state file (the scratchpad) that Bees within that
workstream use as a write-append-read bulletin board. This is not messaging. It
is a shared log with no addressing, no replies, no conversation.

**Purpose:** Collision avoidance and intra-workstream signal propagation between
concurrently running Bees.

**Location:** One file per workstream, placed in the sprint state directory.
Example: `.ai/sprints/<slug>/scratchpad-ws-a.jsonl`

**Entry format** (one JSON object per line):

```json
{"bee_id": "bee-a1", "ts": "2026-02-22T14:30:00Z", "type": "lock", "payload": "editing auth/middleware.py:45-80"}
{"bee_id": "bee-a2", "ts": "2026-02-22T14:31:00Z", "type": "finding", "payload": "circular import detected in core/adapter.py"}
{"bee_id": "bee-a1", "ts": "2026-02-22T14:35:00Z", "type": "warning", "payload": "test_adapter.py has 9 import errors, skip until bee-a3 finishes"}
```

**Entry types:**

| Type | Purpose | Example |
|------|---------|---------|
| `lock` | Announce a file region being edited | `"editing routes/users.py:100-150"` |
| `finding` | Surface a partial result for sibling Bees | `"found 3 dead code paths in sweeper.py"` |
| `warning` | Flag a risk or blocker | `"config schema changed, re-read before editing"` |

**Include this in every Bee's spawn prompt:**

```
SCRATCHPAD: Before editing any file, read the scratchpad at
.ai/sprints/<slug>/scratchpad-<ws-id>.jsonl and check for "lock" entries
on your target files. If another Bee holds a lock on a file you need, skip
that file and note it in your return value.

After you begin work on a file, append a lock entry:
  {"bee_id": "<your-id>", "ts": "<now>", "type": "lock", "payload": "editing <file>:<lines>"}

If you discover something that other Bees in this workstream should know,
append a "finding" or "warning" entry.
```

**Scope:** The scratchpad is intra-workstream only. Bees read only their own
workstream's scratchpad. Cross-workstream signals flow through the Lead, not
through a shared scratchpad.

The Orchestrator maintains a separate shared state file for sprint-wide coordination.
See [Sprint State File](#sprint-state-file).

---

## Sprint State File

The Orchestrator maintains a single sprint-wide state file (e.g.,
`sprint-state.md`) that records phase status, cross-workstream dependency
resolution, blocked items, and key decisions.

**Why a file and not just messages.** At 15-30 agents, message history becomes
hard to reconstruct. The state file is the single source of truth that any Lead
can read to understand what phase the sprint is in, which dependencies have been
resolved, and what decisions the Orchestrator has already made. This prevents
Leads from re-asking questions already answered earlier in the sprint.

**Suggested structure:**

```
# Sprint State: <slug>

## Current Phase
Phase 3: Implementation

## Workstream Status
- WS-A: in progress (3/5 tasks)
- WS-B: phase-complete, waiting on WS-A output
- WS-C: in progress (2/4 tasks)
- WS-D: blocked on WS-A:task-2 (see Dependencies)

## Dependencies
- WS-D:task-1 blocked by WS-A:task-2 (schema output)
  - WS-A:task-2 ETA: after current Bee wave
  - Orchestrator decision: WS-D starts read-only prep work; implementation waits

## Phase Log
- Phase 1 complete: all leads audited, no blockers
- Phase 2 complete: stubs committed, TDD gates passed
- Phase 3: started, WS-B first to complete
```

The Orchestrator is the sole writer of this file. Leads read it to orient
themselves after a phase transition. Leads do not write to it directly; they
report to the Orchestrator, who updates the state.

**Scaling note.** For sprints with 3+ workstreams, consider replacing the single
state file with per-workstream JSONL scratchpads. Each workstream lead maintains
a scratchpad at a path like `sprints/<slug>/<workstream-slug>.jsonl`. Entry
types: `lock` (file claimed by a Bee), `finding` (noteworthy discovery for the
Orchestrator), `warning` (flag requiring attention). The Orchestrator reads
across all scratchpads at phase gates rather than maintaining a central file.
This scales better because Bees append to their own workstream scratchpad without
touching files owned by other workstreams.

---

## Cross-Workstream Dependencies

The Orchestrator detects and sequences cross-workstream dependencies. No Lead
should self-sequence against another workstream's output without Orchestrator
direction.

**Detection.** During the planning phase, the Orchestrator maps dependencies
explicitly. Format: `WS-X:task-N depends on WS-Y:task-M`. Record this in the
sprint state file before any Leads are spawned.

**Sequencing options:**

| Situation | Orchestrator action |
|-----------|-------------------|
| WS-B needs WS-A output before starting | Hold WS-B spawn until WS-A task completes |
| WS-B needs WS-A output for one task only | Spawn WS-B, instruct Lead B to start other tasks; gate the dependent task |
| WS-A and WS-D have mutual read dependency | Resolve the interface contract upfront; both can proceed with the agreed interface |
| Unexpected dependency surfaces mid-sprint | Lead reports to Orchestrator; Orchestrator updates state file and broadcasts if needed |

**Conflict resolution.** When two workstreams need to modify the same file in
the same phase, the Orchestrator assigns ownership to one Lead and sequences the
other Lead's change as a follow-on task. No two Leads should hold write ownership
of the same file in the same phase.

---

## The 9-Phase Lifecycle

The same 9 phases apply at all scales. At 3-tier scale, each phase involves
delegation: the Orchestrator does not do the work, it directs Leads who direct Bees.

### Phase 1: Audit and Discovery

Orchestrator spawns one Lead per workstream with a read-only audit prompt.
Leads spawn Bees (low effort) to scan their workstream's scope.
Bees report findings to Leads via Task return.
Leads synthesize and report to Orchestrator.
Orchestrator gates Phase 2 only after all audit reports are in.

**Backlog reality check:** Leads verify during audit whether each assigned item
is already done (code exists, tests pass, feature functional). Flag already-done
items for immediate close. Only remaining work enters the build phases.

### Phase 2: Design and Test Contracts

Orchestrator defines test contracts for each workstream: what the workstream
must prove correct (inputs, outputs, edge cases, integration points). These
contracts go into the sprint spec before any implementation Bees are spawned.

Leads write failing test stubs for their workstream (Red state). Stubs are
committed before Leads spawn implementation Bees. The gate from Phase 2 to
Phase 3 is blocked until all stubs are committed and verifiable.

### Phase 3: Implementation Wave 1

Leads spawn their first wave of implementation Bees. Bees implement against
the failing stubs. Each Bee's task prompt includes the relevant test stubs and
the instruction: "you are not done until all assigned stubs pass."

Scratchpads are active. Bees append lock entries before editing.

### Phase 4: Integration and Synthesis

Leads collect Wave 1 Bee results. Bees that completed pass their output
summaries back via Task return. Leads synthesize: what passed, what failed,
what needs a second wave.

Leads report Wave 1 status to Orchestrator. Orchestrator checks for
cross-workstream integration points that can now be validated.

### Phase 5: Checkpoint (Human Gate)

The Orchestrator surfaces a structured checkpoint to the human operator.
This checkpoint includes: workstream status across all Leads, any open
blockers, decisions the Orchestrator made unilaterally, and a clear
"proceed / redirect / abort" prompt.

At this scale, checkpoints are not optional. A 20-agent sprint running for
an extended period without a human touch point is a liability. Fire one
checkpoint here (after Wave 1) and one before the final merge.

### Phase 6: Implementation Wave 2

Leads spawn a second wave of Bees to address failures, edge cases, and
tasks that were blocked by Phase 3 dependencies. Orchestrator resolves any
cross-workstream dependencies that Wave 1 unlocked.

### Phase 7: Validation

Leads run their workstream's full test suite and report results to the
Orchestrator. Integration tests that span workstreams are run by the
Orchestrator directly (since it has visibility into all workstreams).

Any failing tests get a targeted Bee spawn (one Bee, one failing test,
medium effort). Leads do not spawn broad re-implementation waves at this
phase: narrow and targeted only.

### Phase 8: Pre-Ship Checkpoint (Human Gate)

Second and final human checkpoint. Orchestrator presents: test results
across all workstreams, files changed, any deferred items, and the
merge plan. Human approves before Phase 9 begins.

### Phase 9: Merge and Ship

Orchestrator sequences the merge. Each Lead's branch merges into the
sprint integration branch in dependency order (workstreams that others
depended on go first). Conflicts surface here; the Orchestrator resolves
or assigns the relevant Lead.

After a clean integration branch, the Orchestrator opens the pull request.
Leads are shut down after their workstream branch is merged and the PR
is open.

---

## File Ownership

Strict per-workstream ownership prevents silent data loss.

**Rules:**

- Each file belongs to exactly one workstream per phase.
- No two Leads write to the same file in the same phase.
- The Orchestrator owns shared files: the sprint state file, the meta-log,
  the overall spec document, and any config files that span workstreams.
- Leads own their workstream's source files, test files, and scratchpad.
- If a shared file must be updated by multiple workstreams, the Orchestrator
  collects proposed changes from Leads and applies them sequentially.

**When ownership must transfer.** If WS-A produces output that WS-B must
subsequently modify (not just read), WS-A completes and commits its changes
before WS-B's Lead is given write permission on that file. The Orchestrator
manages this transfer explicitly in the sprint state file.

**Git-level enforcement.** The cleanest implementation uses git worktrees:
each Lead operates in an isolated checkout on a per-workstream branch. File
conflicts surface as merge conflicts at phase-gate merge time rather than
as silent last-writer-wins overwrites. See [Worktree Branches](#worktree-branches).

---

## Worktree Branches

At 3-tier scale, git worktrees provide hard isolation between workstreams.
Each Lead checks out and works on a dedicated branch. Phase-gate merges
bring workstream branches together at controlled points.

**Branch structure:**

```
main
 |
 +-- sprint/<slug>  (integration branch, Orchestrator works here)
       |
       +-- sprint/<slug>--ws-a
       +-- sprint/<slug>--ws-b
       +-- sprint/<slug>--ws-c
       +-- sprint/<slug>--ws-d
```

Use `--` as the separator between the sprint slug and workstream ID to avoid
git ref hierarchy conflicts.

**Worktree layout:**

```
repo-root/                             (Orchestrator: sprint/<slug> branch)
.worktrees/
  <slug>--ws-a/                        (Lead A: sprint/<slug>--ws-a branch)
  <slug>--ws-b/                        (Lead B: sprint/<slug>--ws-b branch)
  <slug>--ws-c/                        (Lead C: sprint/<slug>--ws-c branch)
  <slug>--ws-d/                        (Lead D: sprint/<slug>--ws-d branch)
```

**Phase-gate merge sequence (Orchestrator runs at each gate):**

1. All Leads commit their phase work to their workstream branch.
2. Orchestrator merges each workstream branch into `sprint/<slug>` in
   dependency order.
3. Orchestrator resolves any merge conflicts (or assigns the responsible Lead).
4. Orchestrator syncs the merged state back into each Lead's worktree so
   Phase N+1 starts with a unified codebase.

This pattern keeps conflicts small because they are surfaced at every phase
gate (not just at the final merge), and the Orchestrator has full context
to resolve them.

**Final merge.** After Phase 9, the Orchestrator merges `sprint/<slug>` into
`main` (or the target branch) and removes the worktrees and workstream branches.

---

## Example: 4-Workstream Sprint with 20 Agents

**Scenario:** Migrate a monolith service to a new authentication library.
Touches: API routes (WS-A), auth middleware (WS-B), database layer (WS-C),
tests and documentation (WS-D).

**Agent roster:**

```
Orchestrator (1)
  |
  +-- Lead A: API Routes (1)
  |     Bee A1: audit existing route auth patterns
  |     Bee A2: update route handlers (batch 1)
  |     Bee A3: update route handlers (batch 2)
  |     Bee A4: run route integration tests
  |
  +-- Lead B: Auth Middleware (1)
  |     Bee B1: audit current middleware stack
  |     Bee B2: implement new auth adapter
  |     Bee B3: implement session migration
  |     Bee B4: integration test (auth + API)
  |
  +-- Lead C: Database Layer (1)
  |     Bee C1: audit auth-related schema
  |     Bee C2: write migration script
  |     Bee C3: update ORM models
  |     Bee C4: validate data integrity
  |
  +-- Lead D: Tests and Documentation (1)
        Bee D1: audit existing test coverage
        Bee D2: write new integration test suite
        Bee D3: update auth API documentation
        Bee D4: update developer guide
        Bee D5: final coverage report
```

Total: 1 Orchestrator + 4 Leads + 15 Worker Bees = 20 agents.

**Dependency map:**

- WS-B (auth middleware) must complete its adapter before WS-A (routes) can
  implement.
- WS-C (database layer) migration must complete before WS-B (session migration)
  can test.
- WS-D (tests) can audit and write stubs in Phase 2, but full test runs wait
  on WS-A and WS-B Phase 6 completion.

**Phase 1 (Audit):** All 4 Leads spawn audit Bees simultaneously. No dependencies
at audit time. Orchestrator collects 4 reports.

**Phase 2 (Design):** Orchestrator resolves the dependency map. Broadcasts:
"WS-C begins migration. WS-B begins adapter. WS-A writes stubs only. WS-D
writes test stubs."

**Phases 3-6 (Implementation):** WS-C and WS-B run first. When WS-C migration
is complete, WS-B gets the green light for session migration. When WS-B adapter
is complete, WS-A gets the green light for route implementation. WS-D runs
alongside throughout on documentation and test scaffolding.

**Checkpoint (Phase 5):** Orchestrator surfaces status to human after Wave 1.
Three workstreams progressing; WS-A holding for WS-B adapter (expected, in plan).

**Phase 7 (Validation):** Each Lead runs workstream tests. Integration suite
(WS-D Bees) runs against the unified codebase on the sprint branch.

**Phase 8 Checkpoint:** Orchestrator reports: all workstream tests green, 2
deferred edge cases logged, no blocking issues.

**Phase 9 (Merge and Ship):** WS-C merged first (no downstream dependents at
merge time), then WS-B, then WS-A, then WS-D. PR opened.

---

## Claude Code Usage

In Claude Code, the Orchestrator is the main agent in the current session. Leads
and Bees are spawned via the Task tool.

**Spawning a Lead (Claude Code):**

```
Use the Task tool with a self-contained prompt that includes:
- The Lead's workstream scope and file ownership list
- The current phase and what the Lead must accomplish in it
- The exit criteria for the Lead's phase-complete report
- The scratchpad file path for their workstream
- The sprint state file path (read-only for Leads)
- The model and effort level to use
- Any dependency information (what this workstream is waiting for, if anything)
```

**Spawning a Bee (via the Lead, not the Orchestrator):**

The Lead's Task return value includes a list of Bee prompts to spawn for the
next wave. The Lead spawns Bees via its own Task tool calls. The Orchestrator
does not write Bee prompts directly.

**Model specification.** In Claude Code, specify model tier by name in the
Task prompt preamble. Example: "You are a Worker Bee. Use a fast, efficient
model for this task." The exact model string depends on your Claude Code
configuration and available models.

**Effort specification.** Include effort guidance explicitly in the spawn prompt.
Example: "Effort: high. This task requires deep reasoning." Leads always receive
"Effort: high." Bees receive effort guidance matched to their task.

---

## Codex Usage

In Codex, the Orchestrator operates as the top-level agent in the terminal
session. Leads are spawned via `spawn_agent` calls. Bees are spawned by Leads
via nested `spawn_agent` calls.

**Key difference from Claude Code:** Codex agents share the terminal session
context differently. Structure each Lead and Bee prompt as fully self-contained:
include all necessary context in the prompt itself rather than relying on
inherited session state.

**Sprint state file is especially important in Codex.** Because Codex agents
do not share a message thread, the sprint state file is the primary coordination
surface between the Orchestrator and Leads across agent boundaries. The
Orchestrator updates it after every phase gate. Leads read it at spawn time
and again before reporting phase-complete.

**Worktree isolation in Codex.** Set up worktree branches before spawning any
Leads. Point each Lead's spawn to its worktree directory explicitly. This is
the same as Claude Code worktree usage, just invoked via `spawn_agent` instead
of the Task tool.

---

## When NOT to Use This

The 3-tier pattern carries real overhead. Below a certain scale, that overhead
consumes the benefit entirely.

**Do not use 3-tier Hive Mind when:**

- Fewer than 12 agents total. Use Worker Swarm (flat fan-out) instead.
- Fewer than 4 workstreams. A 2-3 workstream operation is a Worker Swarm
  with a strong lead agent, not a full 3-tier hierarchy.
- All work is within a single codebase subsystem. The Lead layer adds
  nothing when there are no cross-workstream dependencies to manage.
- The operation is fully defined upfront with no adaptation needed. Consider
  a simpler batch execution instead.
- You do not yet know what needs to be done. Run a Research Swarm first to
  discover the scope, then use 3-tier if the scope warrants it.
- The operation timeline is short and the work is mechanical. Patchwork or
  a small Worker Swarm will finish faster with less coordination overhead.

**Signs you are over-engineering with 3-tier:**

| Sign | Better pattern |
|------|---------------|
| Only 2 workstreams | Worker Swarm with 2 leads |
| Fewer than 10 agents total | Worker Swarm (flat) |
| No cross-workstream dependencies | Worker Swarm (flat fan-out) |
| Work is read-only or analysis-only | Research Swarm |
| Fewer than 10 changes total | Patchwork |

The 3-tier pattern is the right tool for large, genuinely complex operations.
For everything else, a simpler pattern will deliver faster and cleaner results.

---

## Anti-Patterns

| Anti-pattern | Why it fails | Correct behavior |
|-------------|-------------|-----------------|
| Orchestrator writes Bee prompts directly | Bypasses Lead context; Bees lack workstream framing | Orchestrator writes Lead prompts; Leads write Bee prompts |
| Bee sends a message to a peer Lead | Bees lack cross-workstream context; lead filter bypassed | Bee reports finding to parent Lead; Lead decides whether to relay |
| Lead advances to next phase without Orchestrator broadcast | Phase gate bypassed; exit criteria may not be met | Lead idles after phase-complete report; waits for Orchestrator broadcast |
| Strongest model at Bee tier | 15x cost with no execution benefit; Bees have narrow, well-specified tasks | Efficient model for Bees; reserve strongest model for Orchestrator |
| Two Leads writing the same file in the same phase | Silent last-writer-wins data loss | Orchestrator assigns file ownership; use worktrees for hard enforcement |
| Scratchpad used for cross-workstream signals | Workstreams read only their own scratchpad; signal is lost | Cross-workstream findings go to the Lead, who relays to peer or Orchestrator |
| Sprint state file updated by Leads directly | Concurrent writes cause corruption; Orchestrator loses visibility | Only Orchestrator writes the sprint state file |
| No human checkpoints on a large sprint | Undetected wrong direction compounds across 20 agents | Fire two human checkpoints: after Wave 1, and before final merge |
| Using 3-tier for fewer than 12 agents | Coordination overhead exceeds execution benefit | Use Worker Swarm for 4-12 agents; Patchwork below 4 |

---

## Related Patterns

- [Patchwork](./patchwork.md): single agent for changes under 10
- [Worker Swarm](./worker-swarm.md): flat fan-out for 4-12 agents
- [Research Swarm](./research-swarm.md): scan-driven discovery before implementation
- [Hive Mind (2-Tier)](./hive-mind-2tier.md): two tiers for 8-14 agents across 2-3 workstreams
- [Overview](./overview.md): decision matrix for choosing between all patterns

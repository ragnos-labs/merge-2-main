---
title: "Hive Mind: 2-Tier Pattern"
description: "Lead agent coordinates 3-8 persistent Teammate agents through a 9-phase lifecycle using TeamCreate and SendMessage. Use when a single complex workstream needs ongoing coordination, bidirectional communication, and phase-gated progression."
---

# Hive Mind: 2-Tier Pattern

The 2-tier Hive Mind is the core coordination pattern in this framework. One Lead agent
creates and manages 3-8 Teammate agents using `TeamCreate` and `SendMessage`. Teammates
are persistent and stateful: they hold context across phases, report back to the Lead,
and flag blockers. The Lead gates every phase transition based on teammate reports.

This is distinct from a Worker Swarm, where the lead writes every prompt, workers are
fire-and-forget, and there is no ongoing communication. In a 2-tier Hive Mind, the
relationship between Lead and Teammates is continuous throughout the entire build.

---

## When to Use This Pattern

Use 2-tier Hive Mind when ALL of these apply:

- The work is a single complex workstream (not 3+ independent workstreams requiring
  separate leads)
- Implementation requires ongoing coordination: agents must negotiate shared state,
  report discoveries, and adapt to what others find
- The scope is too large for a single agent but small enough for one lead to track
  (3-8 teammates)
- Phase-gated progression adds value: you need Design approved before Refactor begins,
  tests written before hardening, etc.

Use a different pattern when:

- Work is fully defined upfront with no mid-build coordination needed: use Worker Swarm
- Work is purely mechanical (scan, fix, repeat): use Patchwork or a Repair Swarm
- You have 3+ parallel workstreams that each need their own lead: use the 3-tier Hive
  Mind (see [hive-mind-3tier.md](hive-mind-3tier.md))

---

## Architecture

```
                    +------------------+
                    |    Team Lead     |
                    |  (orchestrator)  |
                    +--------+---------+
                             |
              TeamCreate / SendMessage (broadcast + direct)
                             |
          +------------------+------------------+
          |                  |                  |
  +-------+------+   +-------+------+   +-------+------+
  |  Teammate A  |   |  Teammate B  |   |  Teammate C  |
  |  (owns API)  |   |  (owns tests)|   |  (owns docs) |
  +--------------+   +--------------+   +--------------+
          |                  |                  |
          +------------------+------------------+
                    SendMessage (to lead)
```

The Lead is the only agent that calls `TeamCreate`, `TaskCreate`, and `TeamDelete`. The
Lead advances phases and owns the task list. Teammates communicate only upward to the
Lead (or peer-to-peer when the Lead explicitly authorizes it for shared-state
negotiation).

---

## Key Differences from Worker Swarm

| Dimension             | Worker Swarm                        | 2-Tier Hive Mind                      |
|-----------------------|-------------------------------------|---------------------------------------|
| Agent lifecycle       | Fire-and-forget                     | Persistent across all phases          |
| Communication         | One-way (lead to worker)            | Bidirectional (lead <-> teammates)    |
| Phase progression     | Implicit (tasks just finish)        | Explicit gates (lead decides)         |
| Blocker handling      | Worker fails silently or retries    | Teammate messages lead immediately    |
| Adaptation mid-sprint | Difficult (workers have no channel) | Natural (teammate sends new context)  |
| Lead role             | Prompt author                       | Orchestrator and decision-maker       |

The core trade-off: Worker Swarm is faster and simpler for well-defined parallel work.
Hive Mind is more robust for complex builds where discoveries in one area affect others.

---

## The 9-Phase Lifecycle

Every 2-tier Hive Mind build follows these phases in order. The Lead gates every
transition. No shortcuts.

```
Phase 0: Plan Review      (Lead produces build spec, spawns team)
  |
Phase 1: Audit            (Teammates map current state)
  |
Phase 2: Design           (Teammates propose approaches, write test stubs)
  |
Phase 3: Refactor         (Teammates implement against test stubs)
  |
Phase 4: Test             (Teammates write comprehensive tests)
  |
Phase 5: Harden Tests     (Edge cases, integration paths, error paths)
  |
Phase 6: Retest           (Full suite verified across all agents)
  |
Phase 7: Debug            (Fix failures surfaced in Phase 6)
  |
Phase 8: Rerun            (Final pipeline: lint, security, all tests)
  |
Phase 9: Ship             (PR created, team shut down gracefully)
```

---

### Phase 0: Plan Review

**What the Lead does:**

1. Reads the plan source (backlog doc, spec file, or task description)
2. Produces four artifacts before spawning anyone:
   - Build spec: agent roles, file ownership map, phase dependencies
   - File ownership map: one owner per file; gate files marked explicitly
   - TDD contracts: test signatures and edge cases per area
   - Architecture decisions: numbered and concrete
3. Calls `TeamCreate` to initialize the team
4. Calls `TaskCreate` for Phase 1 audit tasks with correct `blockedBy` dependencies
5. Spawns teammates via the agent `Task` tool, with file ownership in each prompt
6. Broadcasts plan to all teammates

**Exit criteria:**

- All teammates spawned and acknowledged
- Task list populated with Phase 1 tasks
- File ownership established with no overlaps
- No blocking errors

---

### Phase 1: Audit

**What teammates do:**

- Claim audit tasks from the task list
- Map the current codebase state relevant to their assigned area
- Identify dependencies, overlapping files, and potential conflicts
- Flag any work that is already complete (so the Lead does not duplicate it)
- Commit audit findings
- Message Lead with: completion status, blocker summary, already-done item list

**Lead decision at gate:**

- Verify all audit tasks marked complete
- Resolve any file conflict reports before Phase 2
- Confirm no critical blockers remain

**Deliverable:** Audit report per area, already-done items identified.

---

### Phase 2: Design

**What teammates do:**

- Claim design tasks
- Propose implementation approaches for their areas
- Identify shared components and coordinate with peers (with Lead authorization)
- Write test stubs for every feature being built: file names, function signatures,
  docstrings describing expected behavior. Stubs must fail (Red state). Not implemented.
- Commit design docs and test stubs
- Message Lead with: completion, any unresolved design conflicts

**TDD gate (mandatory):** The Lead MUST verify test stubs exist for all features before
approving Phase 2 exit. No stubs means Phase 2 is not complete.

**Lead decision at gate:**

- Approve architectural approach
- Confirm no unresolved design conflicts
- Verify test stubs are committed and failing for every feature

**Deliverable:** Design docs plus failing test stubs per feature.

---

### Phase 3: Refactor

**What teammates do:**

- Claim refactor tasks
- Implement features against Phase 2 test stubs (make the stubs pass: Green state)
- Follow file ownership strictly. Touch only files on your ownership list.
- If you need a file not on your list: stop, message Lead, wait for resolution
- Run test stubs locally to confirm Green before committing
- Commit code
- Message Lead with: completion, file manifest, test pass status

**Lead decision at gate:**

- Verify all test stubs passing (Green state) before advancing
- Confirm no merge conflicts
- Confirm all teammates have clean working trees

**Deliverable:** Implemented features committed to branch.

---

### Phase 4: Test

**What teammates do:**

- Claim test tasks
- Write comprehensive tests for new features (80%+ coverage target for new code)
- Run tests locally before committing
- Commit tests
- Message Lead with: test results, coverage numbers

**Lead decision at gate:**

- All test tasks marked complete
- Tests passing and committed
- Coverage targets met
- No flaky tests detected

**Deliverable:** Test suite for all new features.

---

### Phase 5: Harden Tests

**What teammates do:**

- Review test quality across the suite
- Add edge case coverage
- Add integration tests
- Add error path coverage
- Fix any flaky tests (timing issues, external dependencies)
- Improve test isolation
- Commit hardened tests
- Message Lead with: hardening report

**Lead decision at gate:**

- Edge cases covered
- No flaky tests
- Integration tests passing
- Error paths tested

**Deliverable:** Production-grade test suite.

---

### Phase 6: Retest

**What teammates do:**

- Pull latest from branch
- Run full test suite locally
- Report results to Lead, including any new failures from hardening

**Lead action:**

- Run full test suite
- Collect results from all teammates
- If failures: route to Phase 7 (Debug)
- If all pass: advance to Phase 7 for final verification, then Phase 8

**Complexity checkpoint (for substantial builds):**

Before advancing past Phase 6, the Lead outputs a checkpoint block for operator review:

```
CHECKPOINT -- <sprint-slug> -- Phase 6 of 9
-------------------------------------------------
DONE <summary of Phases 1-6>
NEXT Phases 7-9: debug / rerun / ship (creates PR, irreversible)
RISK <top issues; "none" if clean>
METRICS <escalation count, bug count, bottleneck count>
SIGNAL? proceed | redirect <instructions> | abort
-------------------------------------------------
```

Await operator signal. On `proceed`: continue. On `redirect`: adjust plan before Phase 7.
On `abort`: commit current state, open WIP PR, shut down team.

**Deliverable:** Verified passing test suite across all agents.

---

### Phase 7: Debug

**Entry:** Phase 6 reveals failures OR runtime issues are discovered.

**What teammates do:**

- Claim debug tasks
- Investigate test failures and runtime errors in their area
- Fix bugs
- Re-run tests locally to verify fixes
- Commit fixes
- Message Lead with: debug findings, root causes, fix summary

**Lead decision at gate:**

- All bugs fixed and root causes documented
- Tests passing locally for all teammates
- No new failures introduced by fixes

**Deliverable:** Bug-free implementation.

---

### Phase 8: Rerun

**What the Lead does:**

- Runs the full verification pipeline: linting, security scans, all tests
- If failures: return to Phase 7
- If all pass: advance to Phase 9

**Exit criteria:**

- Full pipeline passes
- No security findings
- All quality gates green
- Code is ready for PR

**Deliverable:** Verified production-ready code.

---

### Phase 9: Ship

**What the Lead does:**

1. Creates the PR
2. Sends `shutdown_request` to each teammate via `SendMessage`
3. Waits for teammate acknowledgment
4. Calls `TeamDelete`
5. Reports PR URL to the user

**Exit criteria:**

- PR created and mergeable
- All teammates shut down gracefully
- Team deleted

**Deliverable:** PR open against the target branch, ready for review.

---

## Phase Gating

The Lead is the only agent that advances phases. The enforcement pattern is:

```
if not all_phase_N_tasks_completed():
    broadcast("Phase N incomplete. Blocked tasks: [list]. Continue work.")
    return

if not exit_criteria_met():
    broadcast("Exit criteria not met: [details]. Resolve before proceeding.")
    return

broadcast("Phase N complete. Proceeding to Phase N+1.")
start_phase(N+1)
```

Every phase broadcast MUST include a re-anchoring reminder:

```
Phase <N> complete. Proceeding to Phase <N+1>.

REMINDER
  GOAL <sprint objective, copied verbatim from spec>
  ROLE <your role and file ownership, unchanged unless reassigned>
  FILES <your owned files, re-read before starting work>

Phase <N+1> tasks are now in the task list. Claim and begin.
```

Re-anchoring is especially critical at:

- Phase 2 to 3 (Design to Refactor): teammates shift from planning mode to coding mode
- Phase 6 to 7 (Retest to Debug): teammates shift from validation mode to fix mode
- Any phase following a `redirect` checkpoint signal

---

## Role Assignment

Each teammate receives a named role with a specific responsibility scope. Roles map to
agent color conventions:

- BLUE: implementation (owns source files, writes code)
- PINK: planning and documentation (owns docs, writes stubs, coordinates design)
- RED: adversarial testing and security review

In a 5-agent team, a common assignment pattern is:

```
lead          | orchestration, phase gates, task list
builder-api   | BLUE | owns: src/api/*.py
builder-data  | BLUE | owns: src/data/*.py
tester        | PINK | owns: tests/
hardener      | BLUE | owns: tests/ (after Phase 4, negotiated with tester)
```

The Lead assigns roles in Phase 0 and includes the full file ownership list in every
teammate spawn prompt. Roles do not change during a sprint unless the Lead explicitly
reassigns and broadcasts the change.

---

## Non-Overlapping File Ownership

File ownership is the primary collision-prevention mechanism. The rules:

1. Each file belongs to exactly one teammate. No exceptions.
2. Shared config or utility files that multiple teammates need to read but not write
   are marked `read_only_refs` in the build spec.
3. If a teammate discovers they need to modify a file outside their list, they STOP
   and message the Lead. They do not touch the file.
4. The Lead resolves ownership conflicts before allowing work to continue.
5. Gate files (files that block multiple teammates) are identified in Phase 0 and
   assigned to the teammate with the most dependency on them.

For maximum safety on builds with large overlapping file graphs, spawn teammates with
worktree isolation. Each teammate works in a separate git branch; the Lead merges at
phase gates. This provides git-level enforcement on top of the ownership protocol.

---

## Communication Protocol

All inter-agent communication routes through `SendMessage`. The patterns are:

**Lead to all teammates (broadcast):**

```
SendMessage(
  type: "broadcast",
  content: "Phase 2 complete. Proceeding to Phase 3. [REMINDER block]. Claim tasks."
)
```

**Teammate to Lead (status report):**

```
SendMessage(
  type: "message",
  recipient: "team-lead",
  content: "Phase 2 complete for API module. Test stubs at tests/test_api.py. No blockers."
)
```

**Teammate to Lead (blocker):**

```
SendMessage(
  type: "message",
  recipient: "team-lead",
  content: "BLOCKED: need to modify config/settings.py but it belongs to builder-data.
            Waiting for resolution before continuing Phase 3."
)
```

**Lead to teammate (shutdown):**

```
SendMessage(
  type: "shutdown_request",
  recipient: "builder-api",
  content: "Phase 9 complete. Work done. Shutting down team."
)
```

**Rules for teammates:**

- Report completion of every phase with: status, file manifest, any blockers found
- Do not proceed to the next phase until the Lead broadcasts advancement
- Stop immediately and message the Lead when blocked
- Do not fix bugs without Lead approval (to avoid bypassing phase gates)
- Do not touch files outside your ownership list without Lead authorization

---

## Teammate Spawn Prompt Template

Every teammate spawn prompt must include these fields. Structured prompts prevent scope
drift and give re-anchoring context at every checkpoint.

```
ROLE <teammate name> | <BLUE|PINK|RED> | <model> effort:<low|medium|high>
TEAM <team_name> | Sprint: <sprint_slug>
GOAL <one-sentence sprint objective from spec>
FILES <your owned files: the ONLY files you edit>
READ_ONLY <reference files to read but not modify>
TDD <test stub paths and expected Green-state verification commands>
PHASE <current phase number and name>
COORDINATE SendMessage to <lead name> for blockers and phase completions
```

Example for a 5-agent API build sprint:

```
ROLE builder-api | BLUE | sonnet effort:high
TEAM api-module-team | Sprint: api-module-v1
GOAL Build the new payments API module with validation and error handling
FILES src/api/payments.py, src/api/validators.py
READ_ONLY src/api/base.py, config/api_config.yaml
TDD tests/test_payments.py (must pass before done)
PHASE 3 (Refactor): implement against Phase 2 test stubs
COORDINATE SendMessage to team-lead for blockers and phase completions
```

---

## Example: 5-Agent Team Building a New API Module

This example walks through the first three phases of a sprint to build a payments API
module. Team: 1 Lead + 4 Teammates.

**Team composition:**

```
lead             | orchestration, phase gates
builder-api      | BLUE | owns: src/api/payments.py, src/api/validators.py
builder-models   | BLUE | owns: src/models/payment.py, src/models/transaction.py
tester           | PINK | owns: tests/test_payments.py, tests/test_transactions.py
hardener         | PINK | owns: tests/ (phases 5+)
```

**Phase 0 (Lead):**

```
Lead: TeamCreate("api-module-team")
Lead: TaskCreate(audit-api, audit-models, audit-tests)
Lead: Task(spawn "builder-api",   model=sonnet, effort=high, prompt="[template above]")
Lead: Task(spawn "builder-models", model=sonnet, effort=high, prompt="[template]")
Lead: Task(spawn "tester",         model=sonnet, effort=medium, prompt="[template]")
Lead: Task(spawn "hardener",       model=sonnet, effort=medium, prompt="[template]")
Lead: SendMessage(type=broadcast, content="Phase 0 complete. Claim audit tasks.")
```

**Phase 1 (Teammates audit in parallel):**

```
builder-api:    [reads existing API surface]
                SendMessage(lead, "Audit done. Found 3 legacy endpoints to preserve.
                             No conflicts. See audit-api.md")

builder-models: [reads model layer]
                SendMessage(lead, "Audit done. payment.py does not exist yet (greenfield).
                             transaction.py has 1 shared field with billing module.")

tester:         [reads test suite]
                SendMessage(lead, "Audit done. Test coverage at 41% overall.
                             No existing payments tests. Clean slate.")
```

**Lead gates Phase 1:**

```
Lead: [verifies all 3 audit tasks completed, no critical blockers]
Lead: TaskCreate(design-api, design-models, design-stubs)
Lead: SendMessage(type=broadcast,
        content="Phase 1 complete. Proceeding to Phase 2 (Design).
                 REMINDER: GOAL: Build payments API module.
                 FILES: unchanged. Claim design tasks.")
```

**Phase 2 (Design + test stubs):**

```
tester: [writes failing test stubs for all payment flows]
        [commits tests/test_payments.py with stubs in Red state]
        SendMessage(lead, "Design done. Stubs written and confirmed failing.
                    See tests/test_payments.py. 14 stubs total.")

builder-api:    [documents API contract, validates against stubs]
                SendMessage(lead, "Design done. API spec at docs/api-payments.md.
                            Aligns with tester stubs.")

builder-models: [documents model schema]
                SendMessage(lead, "Design done. Model schema at docs/models-payment.md.")
```

**Lead TDD gate check:**

```
Lead: [verifies test stubs exist and fail for all features]
Lead: [approves Phase 2 exit]
Lead: TaskCreate(impl-api, impl-models)
Lead: SendMessage(type=broadcast,
        content="Phase 2 complete. TDD gate passed. Proceeding to Phase 3 (Refactor).
                 REMINDER: implement against Phase 2 stubs. Make them pass (Green state).")
```

Phases 3 through 9 continue in the same pattern: teammates claim tasks, implement,
report back; Lead verifies exit criteria and gates the next phase.

---

## Claude Code Implementation

In Claude Code, the Lead uses:

- `TeamCreate(name)`: initialize the team and get a team ID
- `TaskCreate(name, blockedBy=[...])`: add tasks to the shared task list
- `Task(spawn teammate, model, prompt)`: spawn a persistent teammate agent
- `SendMessage(type, recipient, content)`: communicate with teammates
- `TaskList()`: inspect current task state
- `TeamDelete()`: shut down the team after Phase 9

Teammates use:

- `SendMessage(type="message", recipient="team-lead", content=...)`: report to Lead
- Standard file tools (Read, Edit, Write, Bash) within their owned files

Enable agent teams in Claude Code settings:

```json
{
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
}
```

---

## Codex Equivalent

In Codex (or any agentic framework without native TeamCreate), implement the same
pattern using:

- A top-level orchestrator agent that holds the phase state machine
- Sub-agents spawned via the `Task` tool with explicit file ownership in the system
  prompt
- A shared scratchpad file (e.g., `tmp/team-status.md`) where teammates append status
  lines and the orchestrator reads to gate phases
- Direct message passing via append-only log files when `SendMessage` is not available

The phase logic, file ownership rules, TDD gates, and re-anchoring reminders all apply
identically regardless of the underlying framework.

---

## Anti-Patterns

### File Collision Drift

Two agents editing the same file. Fix: confirm file ownership before every edit. When
in doubt, message the Lead before touching any file not on your list.

### Phase Skip Drift

A teammate advancing to Phase N+1 work before the Lead broadcasts advancement. Fix:
the Lead must broadcast explicitly. Teammates wait for the broadcast, not for their own
task to complete.

### Blind Commit Drift

Committing without running tests locally. Fix: run tests, confirm pass, then commit.

### Lead-as-Coder Drift

The Lead implementing features instead of orchestrating. Fix: if the Lead discovers
code that needs writing, spawn a teammate for it. The Lead stays in coordination mode.

### Silent Failure Drift

A teammate working past a blocker without reporting it. Fix: when blocked, stop
immediately and message the Lead. Do not attempt workarounds without authorization.

### Silent Fix Drift

A teammate fixing a bug discovered mid-phase without Lead approval. Fix: message the
Lead. Bugs get resolved in Phase 7 under Lead supervision. Ad-hoc fixes bypass the
phase gate and can introduce regressions.

---

## Quality Metrics

Track these per sprint to identify process health:

- **Regression rate:** bugs found in Phase 6+ that should have been caught in Phase 4
  or 5. Target: under 10%.
- **Blocker frequency:** how often teammates hit files outside their ownership list.
  High frequency signals the Phase 0 ownership map needs improvement.
- **Phase skip requests:** teammates asking to skip phases. Any request is a process
  smell.
- **Phase gate latency:** time between all tasks completing and Lead broadcasting
  advancement. High latency means the Lead is not checking task state promptly.

---

## Related Docs

- [hive-mind-3tier.md](hive-mind-3tier.md): Scale up to 3-15 agents across multiple
  workstreams, each with its own sub-lead
- [worker-swarm.md](worker-swarm.md): Simpler fire-and-forget pattern for well-defined
  parallel work
- [Decision Tree](../guides/decision-tree.md): decision guide for choosing between
  Patchwork, Worker Swarm, and Hive Mind variants
- [Orchestrator Prompt](../templates/orchestrator-prompt.md): prompt template for
  spawning and coordinating teammates

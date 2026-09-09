---
title: Codex Pattern Adapters
description: How the universal patterns map onto Codex primitives. Covers spawn mechanics, handoff formats, the run ledger, and role templates.
---

# Codex Pattern Adapters

Codex is one runtime surface for the same core patterns: Patchwork, Worker
Swarm, Research Swarm, Hive Mind, and Worktree Sprint as an isolation layer.
The patterns themselves do not change. What
changes is the coordination surface: instead of the Claude Code `Agent` tool,
team messaging, and background task controls, you use the primitives exposed by the current Codex client. Names and argument shapes
can vary; the examples below are orchestration pseudocode, not an SDK.
Delegation requires a direct request or applicable project or skill instruction.

Read `overview.md` first for the runtime summary and `setup-and-agents-md.md`
for the bootstrap flow. This document covers the pattern-specific adaptations
and handoff mechanics.

---

## Runtime Overview

Claude Code and Codex both support multi-agent work, but they expose it
differently.

**Claude Code model:**

- The main agent spawns sub-agents via the `Agent` (Task) tool.
- `TeamCreate` registers a named agent with a persistent identity.
- `SendMessage` routes messages between agents in the same session.
- `run_in_background=true` starts agents asynchronously without blocking.
- Sub-agents share the host environment (filesystem, shell, secrets).

**Codex model:**

- Every agent has its own task context. Local agents can share a filesystem;
  create worktrees explicitly when separate Git state is needed.
- `spawn_agent(role, task)` starts an agent and returns an agent or thread ID.
- `send_input(thread_id, message)` pushes a message to a running agent.
- `wait_agent(thread_id)` blocks until the agent produces output.
- `close_agent(thread_id)` tears down the agent and releases resources.
- There is no persistent TeamCreate equivalent. Agent identity lives in config
  files (`AGENTS.md` or per-role `.toml` configs) that are loaded at spawn time.
- Shared state must be written to files, committed, or passed explicitly through
  handoff messages.

**Key implications:**

- Agents cannot directly read each other's in-memory state. All coordination
  flows through the orchestrator via structured handoffs.
- Child agents should return distilled findings or bounded patches, not raw
  transcripts. The parent is responsible for integration.
- The runtime's thread budget means large topologies must run in waves.
- Applicable project instructions and custom agent configuration supply
  persistent guidance. Restate the exact task, files and acceptance conditions
  in the dispatch; verify the working directory and active instruction scope.

---

## AGENTS.md: Universal Configuration Entry Point

`AGENTS.md` at the repo root is the primary mechanism for injecting persistent
context into every Codex agent. Think of it as the bootstrap configuration that
travels with each spawn.

**Instruction and context loading:**

Local Codex clients discover applicable project instructions. Verify the client,
working directory and instruction chain; do not assume IDE users always need to
paste the root file manually. A child may receive inherited or forked context,
depending on the exposed spawn options. It does not automatically receive every
sibling's findings. Supply a self-contained assignment and pass needed evidence.

**What to put in AGENTS.md:**

A useful `AGENTS.md` covers:

- Project goal and architectural overview (2-3 sentences)
- Repo layout: which directories own what
- Coding conventions and style rules
- Secret / credential handling rules
- Branch and commit conventions
- Which files are off-limits or read-only
- Test commands to use for verification

Keep it under 400 lines. Long `AGENTS.md` files consume context budget that
agents need for actual work.

**Inline file ownership maps in task prompts:**

For Hive Mind runs, embed a file ownership map directly in each lead's task
prompt rather than relying solely on `AGENTS.md`. This prevents leads from
accidentally editing each other's files even if they misread the global config:

```json
{
  "file_ownership": {
    "owned": ["src/api/auth/**", "tests/api/auth/**"],
    "read_only": ["src/api/middleware/**", "config/"],
    "off_limits": ["src/api/billing/**", "src/admin/**"]
  }
}
```

Include this block in every `task_dispatch` and workstream decomposition
handoff. Explicit ownership in the task prompt is more reliable than global
declarations alone.

---

## Native configuration and wave planning

Current local releases enable subagents by default. A direct user request or
applicable project or skill instruction admits delegation. Configuration enables
the capability; it does not authorize an unrelated task.

```toml
# Selected native setting for .codex/config.toml in a trusted project.
[agents]
max_concurrent_threads_per_session = 4
```

The cap excludes the primary thread. Leave room within the child cap for a
verifier, or close the implementation wave before starting verification.
`max_threads` remains a legacy alias. Omit the cap to use the client's default.

Wave sizes, phase numbers, output paths and stall deadlines belong in the task
or run ledger. They are methodology conventions, not additional native TOML
settings. Nested leads are conditional on the runtime's available depth and
capacity. When nesting is unavailable, the parent dispatches workers directly.

See the [official subagent configuration](https://learn.chatgpt.com/docs/agent-configuration/subagents)
and [configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference),
checked September 9, 2026. Preserve existing model and permission choices when
adapting the [configuration template](../../templates/codex/codex-config.toml).

---

## Session Start Checklist

Run these checks before spawning any agents. Catching misconfigurations here
prevents wasted compute budget on agents that start with wrong context.

1. **Verify applicable instructions.** Confirm the working directory and
   current project context before dispatch. Restate child ownership and proof.

2. **Check thread budget.** Review the current child cap and active threads.
   Count how many agents your first wave needs. If the wave exceeds the thread
   limit, plan the stagger before spawning.

3. **Decompose tasks to fit within the compute window.** Estimate how many
   phases your run requires. Structure the decomposition so all phases complete
   within the runtime budget available to the session. If the run is too large,
   split it into checkpointed sessions with explicit hand-off artifacts.

4. **Set role via `.codex/agents/<role>.toml`.** Confirm the role config files
   exist for every role you will spawn (lead, worker, explorer, verifier). If
   a custom role cannot load, resolve the error before assigning it. Do not
   assume a particular fallback or broaden permissions.

5. **Choose recovery evidence.** Reuse the owning task ledger and durable
   source state. For a multi-phase run without an existing owner, the example
   files below provide a portable checkpoint. Avoid creating a second ledger.

---

## Role Definitions

Use the [standalone role templates](../../templates/codex/codex-agents/lead.toml)
for leads, workers, explorers and verifiers. Copy selected files into
`.codex/agents/`. Each has `name`, a short `description`, and
`developer_instructions`; optional `model_reasoning_effort` selects effort.
Omitting `model` retains the configured or inherited model selection.

Leads and workers inherit permissions. Explorer and verifier templates request
`read-only` and instruct the agent to return findings to the parent. Parent
runtime overrides and managed policy still apply; a role file is not a stronger
isolation boundary than the active runtime. Never assume tests are read-only:
commands that write fixtures, caches or reports need a suitable admitted harness.
The parent owns persistence of returned review reports.

Use one mutation owner per worktree and one owner for final integration. A lead
can perform its own bounded work when child delegation is unavailable. A role
name alone grants no merge, deployment or external-action authority.

---

## Patchwork

Patchwork is a single-session baseline: one agent, no spawning, no
orchestration overhead. Use it when the change is fewer than 10 mechanical
fixes that do not require parallel investigation.

**When Patchwork is right:**

- Rename a function or variable across a bounded file set.
- Fix a lint rule violation in under 5 files.
- Update a config value that appears in known locations.
- Apply a boilerplate change (add a field, update an import) to a short list
  of files.

**How it works in Codex:**

No `spawn_agent` calls. The root Codex session is the only agent. Read
`AGENTS.md`, understand the task, make the changes, run the test command,
report done. If you find yourself wanting to parallelize investigation or
split work between agents, the task has grown past Patchwork scope and should
be re-scoped as a Worker Swarm.

**Session flow:**

1. Confirm the task fits Patchwork scope (< 10 mechanical fixes, no
   architectural decisions).
2. Read relevant files.
3. Make all changes in sequence.
4. Run the test command.
5. Report result. No handoffs, no run ledger, no verifier spawn needed.

**No run ledger required.** For Patchwork runs, the ledger and event log are
unnecessary overhead. A single commit message summarizing what changed is
sufficient.

---

## Worker Swarm

Worker Swarm in Claude Code fans out sub-agents via the Task tool with
`run_in_background=true`. In Codex, the equivalent is spawning workers with
`spawn_agent` and collecting results with `wait_agent`.

**Flow:**

1. The lead (or orchestrator, for small runs) produces a task list. Each task
   has a unique `task_id`, a bounded file set, acceptance criteria, and a test
   command.
2. Spawn one worker per independent task. Tasks with no shared files can run
   concurrently (up to the thread limit).
3. Use the available wait primitive and collect each `task_complete` handoff.
4. If a worker fails, either retry with a revised task or escalate to the lead.
5. After all workers complete, spawn a verifier to confirm the aggregate result.

**Paste block format** (what you give each worker at spawn time):

```json
{
  "type":        "task_dispatch",
  "task_id":     "ws-auth-T1",
  "files":       ["src/api/auth/token.ts", "tests/api/auth/token.test.ts"],
  "goal":        "Implement JWT token refresh. Token must rotate on use.",
  "acceptance":  ["Token refresh endpoint returns 200 with new token",
                  "Used token is invalidated after refresh"],
  "test_command": "npm test -- --grep 'token refresh'"
}
```

Workers report back in this format:

```json
{
  "type":          "task_complete",
  "task_id":       "ws-auth-T1",
  "status":        "pass",
  "files_changed": ["src/api/auth/token.ts", "tests/api/auth/token.test.ts"],
  "test_output":   "2 passing (340ms)"
}
```

**Thread budget note:** A Worker Swarm can only run as many tasks in parallel
as the session thread budget allows. Queue excess tasks and spawn them as
threads close.

---

## Research Swarm

Research Swarm uses read-only explorers to scan the codebase before any
implementation work starts. The explorer template requests `read-only`; verify
the active permission policy and preserve read-only task scope.

**Flow:**

1. Start a bounded wave of explorers, each scoped to a discovery domain (e.g.,
   one per module, one per concern: auth, data layer, API surface).
2. Give each explorer a structured output requirement so results are mergeable.
3. Wait for all explorers to complete.
4. The orchestrator (or lead) reads all findings and builds the manifest: a list
   of files, their roles, dependency chains, and risk areas.
5. Feed the manifest into a Worker Swarm or Hive Mind for implementation.

**Explorer task format:**

```json
{
  "type":   "explore_request",
  "domain": "authentication layer",
  "scope":  ["src/api/auth/**", "src/middleware/**"],
  "questions": [
    "What token validation strategy is currently used?",
    "Which middleware functions touch session state?",
    "Are there any direct database calls in auth routes?"
  ],
  "output_format": {
    "files":        "list of relevant file paths",
    "findings":     "answers to each question with file+line references",
    "risks":        "patterns that could break under the proposed change",
    "unknowns":     "gaps that need human input before implementation"
  }
}
```

**Explorer output format:**

```json
{
  "type":     "explore_result",
  "domain":   "authentication layer",
  "files":    ["src/api/auth/middleware.ts", "src/api/auth/session.ts"],
  "findings": ["Token validation uses HS256 in middleware.ts:42",
               "Session state accessed in session.ts:17-38"],
  "risks":    ["HS256 secret is hardcoded in config/auth.js:5"],
  "unknowns": ["Unclear if token blacklist is checked on refresh"]
}
```

The orchestrator merges all explorer outputs into a single manifest and then
proceeds to Worker Swarm or Hive Mind decomposition.

### Wave batching

Codex fan-out should be planned as waves rather than as one maximum-width
spawn. A wave is a bounded set of independent child tasks launched from the
same manifest and collected before the next dependent phase begins.

Use manual `spawn_agent` calls when tasks need different roles, sandbox modes,
or reasoning effort. Use any bulk-dispatch helper your Codex surface provides
only when every row has the same safety envelope and file ownership is already
settled.

**Wave manifest format:**

```json
{
  "wave_id": "research-1",
  "budget": {
    "max_concurrent_children": 4,
    "reserved_for_parent": 1,
    "close_children_on_completion": true
  },
  "tasks": [
    {
      "role": "explorer",
      "task_id": "scan-auth",
      "scope": ["src/api/auth/**"],
      "output": "findings/auth.md"
    },
    {
      "role": "explorer",
      "task_id": "scan-data",
      "scope": ["src/db/**"],
      "output": "findings/data.md"
    }
  ]
}
```

**Mapping to Research Swarm waves:**

The Research Swarm model defines discovery waves followed by an implementation
wave. In Codex, the orchestrator launches only as many child agents as the
budget allows, waits for their concise outputs, closes completed threads, and
then launches the next batch if the manifest still has work.

```
spawn_agent(explorer, task_a)        # Wave 1 batch
spawn_agent(explorer, task_b)
wait_agent([task_a, task_b])         # collect bounded findings
close_agent(task_a)
close_agent(task_b)
build_manifest(results)             # orchestrator synthesizes
spawn_agent(worker, task_from_manifest)
```

---

## Hive Mind

Hive Mind in Claude Code uses `TeamCreate` to register durable named agents and
`SendMessage` for cross-agent communication. Codex has no persistent TeamCreate
equivalent. Durability is emulated through the run ledger (see below) and
explicit re-spawning with checkpoint context.

**2-Tier topology (3-8 agents, 1-3 workstreams):**

```
Orchestrator (root session, reasoning: high)
  |-- Lead A (durable thread, reasoning: high)
  |     |-- Worker A1 (ephemeral)
  |     |-- Worker A2 (ephemeral)
  |     |-- Verifier A (ephemeral, read-only)
  |-- Lead B (durable thread, reasoning: high)
        |-- Worker B1 (ephemeral)
        |-- Verifier B (ephemeral, read-only)
```

**3-Tier topology (6-15 agents, 3-6 workstreams):**

```
Orchestrator (root session, reasoning: high)
  |-- Lead A: API layer  -- Workers + Verifier
  |-- Lead B: Frontend   -- Workers + Verifier
  |-- Lead C: Tests      -- Workers + Verifier
  |-- Lead D: Infra      -- Workers + Verifier
```

When the session thread budget is tight, stagger larger 3-tier runs: close
completed Phase 1 leads before spawning the next wave.

**The parent owns the critical path.** It decomposes, integrates and performs
useful local work while independent lanes run. Leads own workstreams; workers
own bounded tasks. Verifiers supply evidence; the applicable owner decides
acceptance. The topology diagrams show roles over a run, not guaranteed
concurrent capacity or permission for nested spawning.

**Coordination via Codex primitives:**

```
spawn_agent(role: "lead", task: "<workstream decomposition JSON>")
  -> returns thread_id

send_input(thread_id, "<phase_authorized handoff JSON>")

wait_agent(thread_id)
  -> returns lead's phase_complete or blocked handoff

close_agent(thread_id)
  -> after final phase verified
```

Leads use the same primitives internally to manage their workers:

```
spawn_agent(role: "worker", task: "<task_dispatch JSON>")
wait_agent(worker_thread_id)
spawn_agent(role: "verifier", task: "<verify_request JSON>")
wait_agent(verifier_thread_id)
send_input(orchestrator_thread, "<phase_complete JSON>")
```

---

## Worktree Sprint

Treat Worktree Sprint as external git isolation layered underneath the Codex
orchestration surface.

**Flow:**

1. Create the worktrees before spawning any lead or worker that will write.
2. Pass each lead its assigned worktree path explicitly in the task payload.
3. Keep worktree ownership aligned with the same no-file-overlap rules used for
   non-worktree Codex runs.
4. Consolidate through the orchestrator after verifier approval, not by letting
   agents merge ad hoc.

**Why it matters more in Codex than in shared-session runtimes:**

- Sandboxes isolate agent context, but they do not remove merge risk.
- Worktrees make workstream boundaries visible at the git layer, not just in
  prompts and handoffs.
- Long-running multi-workstream Codex runs are easier to recover when branch
  and worktree ownership are explicit from the start.

---

## Handoff Contract Format

All coordination flows through the orchestrator. Leads do not message each
other directly. Every handoff is a typed JSON object, not prose. Prose handoffs
lose information across context boundaries and are ambiguous to parse.

### Handoff types

```
lead -> orchestrator:
  phase_complete    { type, workstream_id, phase, evidence, test_results }
  blocked           { type, workstream_id, reason, needs_from }
  child_task_result { type, workstream_id, task_id, status, artifacts }

orchestrator -> lead:
  phase_authorized  { type, workstream_id, next_phase, updated_context }
  unblock_resolved  { type, workstream_id, resolution, artifacts }
  scope_adjustment  { type, workstream_id, added_files, removed_files,
                      revised_acceptance }

lead -> worker:
  task_dispatch     { type, task_id, files, goal, acceptance, test_command }

worker -> lead:
  task_complete     { type, task_id, status, files_changed, test_output }

orchestrator -> verifier:
  verify_request    { type, workstream_id, phase, acceptance, test_command }

verifier -> orchestrator:
  verdict           { type, workstream_id, phase, pass, evidence, gaps }
```

### Constraint fields

Every handoff that assigns work should include a `constraints` block to prevent
scope creep:

```json
{
  "type":        "task_dispatch",
  "task_id":     "ws-db-T2",
  "files":       ["src/db/migrations/0012_add_refresh_tokens.sql"],
  "goal":        "Add refresh_tokens table with correct indexes.",
  "acceptance":  ["Migration runs without error", "Index on user_id exists"],
  "test_command": "npm run migrate:test",
  "constraints": {
    "read_only_outside_owned_files": true,
    "no_schema_changes_to_other_tables": true,
    "no_new_dependencies": true
  }
}
```

---

## The Run Ledger

Local Codex threads can be resumed through supported clients or SDKs. A portable
run ledger complements thread history with explicit work ownership, source
revisions and proof. Reuse an existing owning ledger when one is available.

**Location:** `.codex/runtime/` in the project root (or
`.ai/sprints/<slug>/codex-runtime/` for sprint-scoped runs).

### Files

```
run.json          Run metadata: goal, topology, start time, phase, status
workstreams.json  State per workstream: thread_id, phase, status, owned files
events.jsonl      Append-only log: every handoff, spawn, close, phase gate
checkpoints.json  Snapshot after each phase gate for recovery
```

### `run.json` structure

```json
{
  "run_id":       "run-2026-04-06-jwt-auth",
  "goal":         "Implement JWT auth with refresh tokens",
  "topology":     "2-tier",
  "started_at":   "2026-04-06T14:00:00Z",
  "current_phase": 1,
  "status":       "in_progress",
  "workstreams":  ["ws-auth", "ws-db"]
}
```

### `events.jsonl` entry format

```json
{ "ts": "2026-04-06T14:05:00Z", "event": "phase_complete",
  "workstream_id": "ws-auth", "phase": 1,
  "evidence": ["All auth tests pass"], "test_results": "3 passing" }
```

### Recovery procedure

If the orchestrator session dies mid-run:

1. Read `workstreams.json` for current state per workstream.
2. Read `events.jsonl` for the last recorded event per workstream.
3. Resume leads via `send_input` to their `thread_id` values if the threads are
   still alive.
4. If threads are gone: re-spawn leads with checkpoint context from
   `checkpoints.json` and skip phases already marked complete.

Update the chosen ledger at phase gates. Verify source and evidence before
resuming an effect; a recorded status alone does not prove that effect completed.

---

## Decomposition Framework

The orchestrator turns a solution design into a set of owned workstreams before
spawning any agents. This step is mandatory. Spawning agents without a
decomposition produces overlapping edits and conflicting context.

### Decomposition rules

1. Split by ownership, not by step. Each lead owns a vertical slice (feature,
   layer, or module), not a sequential phase. A lead that owns `src/api/auth/`
   handles design, implementation, and testing for that slice.
2. No file overlaps between leads. If two workstreams need the same file,
   merge them or designate one lead as owner and route the other's changes
   through a handoff.
3. Leads are durable. Workers are disposable. Leads persist across phases and
   accumulate workstream context. Workers are spawned for a single task.
4. Verifiers are mandatory before phase advancement. No lead self-certifies.
5. Child task creation stays within bounds. A lead may decompose its own work
   without orchestrator approval. It may not expand file ownership or skip phases.
6. The orchestrator synthesizes at phase gates. After all leads report
   completion, the orchestrator reviews outputs, resolves conflicts, updates the
   ledger, and authorizes the next phase.

### Decomposition template

Produce this JSON before spawning any agents:

```json
{
  "goal": "What the system should do when done",
  "workstreams": [
    {
      "id":           "ws-auth",
      "lead_role":    "lead",
      "description":  "Implement JWT auth layer",
      "owned_files":  ["src/api/auth/**", "tests/api/auth/**"],
      "read_access":  ["src/api/middleware/**", "config/"],
      "acceptance":   [
        "All auth endpoints return 401 without valid token",
        "Token refresh works"
      ],
      "test_command": "npm test -- --grep auth",
      "phase":        1,
      "blocked_by":   [],
      "risk_tier":    "medium"
    }
  ],
  "phases": [
    { "id": 1, "name": "Foundation",   "workstreams": ["ws-auth", "ws-db"] },
    { "id": 2, "name": "Integration",  "workstreams": ["ws-api", "ws-frontend"],
      "blocked_by": [1] }
  ]
}
```

### Scaling guide

| Solution size               | Topology  | Leads | Workers per lead | Phases |
|-----------------------------|-----------|-------|-----------------|--------|
| 1-3 files, single feature   | Patchwork | 0     | 0               | 1      |
| 4-10 files, 2-3 modules     | 2-tier    | 2-3   | 1-2             | 1-2    |
| 10-30 files, cross-cutting  | 2-tier    | 3-4   | 2-3             | 2-3    |
| 30+ files, multi-system     | 3-tier    | 4-6   | 2-4             | 3-5    |

---

## Prompt Templates

Paste these into the Codex session that will play each role. Replace
placeholder values with the actual decomposition or task data.

**Note on tool names:** The tool names `Glob`, `Grep`, `Read`, `Edit`, and
`Write` are Claude Code-specific. They do not exist in Codex agents. When
writing task prompts for Codex workers or explorers, use runtime-portable
formulations instead:

| Claude Code phrasing              | Codex-portable alternative                        |
|-----------------------------------|---------------------------------------------------|
| "Use Grep to find all usages of X" | "Search for all usages of X in the codebase"     |
| "Use Glob to find *.ts files"      | "Find all TypeScript files under src/"           |
| "Use Read to inspect the file"     | "Read the file and examine its contents"         |
| "Use Edit to update the function"  | "Update the function in the file"                |

The Codex agent will use whatever file operation primitives its sandbox
provides. Naming Claude Code tools explicitly in Codex prompts causes the
agent to report a tool-not-found error or silently ignore the instruction.

### Orchestrator template

```xml
<hive_mind_orchestrator>
You are a Hive Mind orchestrator. Your job is to decompose a solution design
into owned workstreams, spawn lead agents, gate phase transitions, and
synthesize the final result. Keep the critical path and useful local work.

<solution_design>
PASTE_SOLUTION_DESIGN_HERE
</solution_design>

<decomposition_rules>
1. Split by ownership (vertical slices), not by step (horizontal phases).
2. No file overlaps between leads.
3. Leads are durable. Workers are ephemeral.
4. Spawn a verifier before authorizing any phase transition.
5. Leads may create child tasks within their file and phase envelope only.
6. Synthesize at phase gates: review all lead outputs, resolve conflicts,
   update run.json and workstreams.json, authorize the next phase.
</decomposition_rules>

<execution_flow>
1. Read the solution design.
2. Produce the decomposition JSON (workstreams, phases, file ownership).
3. Write it to .codex/runtime/run.json and workstreams.json.
4. Spawn lead agents for Phase 1 workstreams.
5. Wait for all Phase 1 leads to report phase_complete.
6. Spawn verifiers for each Phase 1 workstream.
7. If all verifiers pass: log the phase gate, authorize Phase 2.
8. If any verifier fails: send feedback to the lead, wait for fix, re-verify.
9. Repeat until all phases complete.
10. Write final synthesis to events.jsonl and report to user.
</execution_flow>

<constraints>
- if thread budget is tight: stagger waves if needed.
- Use nested leads only when the live runtime permits them; otherwise flatten
  the wave under the parent. Workers do not expand delegation on their own.
- All file writes must be committed before reporting phase_complete.
- Never commit to the main branch. Use a feature branch.
- Append every phase gate event to events.jsonl.
</constraints>
</hive_mind_orchestrator>
```

### Lead template

```xml
<hive_mind_lead>
You are a workstream lead for: WORKSTREAM_DESCRIPTION

Owned files:  OWNED_FILES_LIST
Read access:  READ_ACCESS_LIST
Phase:        PHASE_NUMBER
Blocked by:   BLOCKED_BY_LIST (or "none")

Acceptance criteria:
ACCEPTANCE_CRITERIA_LIST

Test command: TEST_COMMAND

Your responsibilities:
1. Decompose your goal into 2-5 worker tasks (bounded, non-overlapping).
2. Spawn workers with task_dispatch handoffs.
3. Wait for each worker to return a task_complete handoff.
4. Spawn a verifier with a verify_request handoff.
5. If verifier passes: send phase_complete to the orchestrator.
6. If verifier fails: fix the issue, re-verify, then report.

Report to the orchestrator only via structured JSON handoffs. Do not
expand file ownership, edit files outside your owned set, or advance
phases without verifier confirmation.
</hive_mind_lead>
```

### Worker template

```xml
<hive_mind_worker>
You are an implementation worker.

Task:           TASK_DESCRIPTION
Files:          FILES_LIST
Acceptance:     ACCEPTANCE_CRITERIA
Test command:   TEST_COMMAND

Instructions:
1. Read all files in your file list.
2. Implement the change described in the task.
3. Run the test command.
4. Return a task_complete handoff with status, files_changed, and test_output.
5. Do not expand scope. Do not edit files outside your list.
</hive_mind_worker>
```

### Explorer template

```xml
<hive_mind_explorer>
You are a read-only explorer. Do not edit any files.

Domain:   DOMAIN_DESCRIPTION
Scope:    FILE_GLOBS_LIST
Questions:
QUESTIONS_LIST

Return a JSON object with these fields:
- files:    list of relevant file paths you examined
- findings: answers to each question, with file path and line number
- risks:    patterns that could break under the proposed change
- unknowns: gaps that require human input before implementation begins
</hive_mind_explorer>
```

### Verifier template

```xml
<hive_mind_verifier>
You are a read-only verifier. Do not edit any files.

Workstream:  WORKSTREAM_ID
Phase:       PHASE_NUMBER
Test command: TEST_COMMAND

Acceptance criteria:
ACCEPTANCE_CRITERIA_LIST

Instructions:
1. Run the test command.
2. Check whether the output satisfies each acceptance criterion.
3. Return a verdict JSON:
   { "pass": true|false, "evidence": [...], "gaps": [...] }

If pass is false, list exactly what failed and why in "gaps."
</hive_mind_verifier>
```

---

## Programmatic callers

The [Codex SDK](https://developers.openai.com/codex/sdk/) starts, continues and
resumes local Codex threads. Retain thread IDs and use the SDK's supported
continuation or resume methods. The [app server](https://learn.chatgpt.com/docs/app-server)
supplies client-facing history, approval and event interfaces.

A direct Responses API application is a different integration. Do not treat its
response IDs as native Codex agent-thread IDs or invent a top-level request
`phase` field for this methodology. Keep workflow phase and acceptance in the
application's own ledger and pass needed task context through documented API
inputs. Follow the selected API's current continuity and compaction contract;
this repository does not supply that integration or a compaction policy.

---

## When Not To Force This Runtime

**Filesystem ownership must be explicit.** Local children may share a checkout.
The sandbox is a permission boundary, not an automatic private filesystem
snapshot. Worktrees isolate Git state, not credentials or external authority.
Preserve dirty work and exact revisions before closing or removing any lane.

**Capacity and nesting vary.** Design to the limits exposed in the active
session. Run waves or flatten the topology when a child cannot spawn. Closing a
thread can release concurrency; it does not refund tokens already spent.

**Context needs a handoff.** Resume supported threads when appropriate; provide
self-contained task and evidence references when starting fresh ones. Do not
assume either universal full-history inheritance or universally blank children.

**The parent must benefit from delegation.** If it has no independent useful
work or cannot review the outputs, keep the task local. Preserve configured
model and effort defaults unless the user or applicable instructions select a
different role configuration.

---

## Relationship to Other Patterns

This document is a runtime adapter, not a new pattern. The canonical pattern
definitions and the decision matrix for choosing between them are in
`../../core/patterns/overview.md`.

The Hive Mind 9-phase workflow (Audit, Design, Refactor, Test, Harden, Retest,
Debug, Rerun, Ship) applies here. The phases in the decomposition template map
to subsets of that workflow. Not every run needs all nine phases.

- [../../core/patterns/patchwork.md](../../core/patterns/patchwork.md): single-agent baseline
- [../../core/patterns/worker-swarm.md](../../core/patterns/worker-swarm.md): lead-directed parallel agents
- [../../core/patterns/research-swarm.md](../../core/patterns/research-swarm.md): scan-driven discovery
- [../../core/patterns/overview.md](../../core/patterns/overview.md): decision matrix for all patterns

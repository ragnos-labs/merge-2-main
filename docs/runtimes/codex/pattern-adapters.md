---
title: Codex Pattern Adapters
description: How the universal patterns map onto Codex primitives. Covers spawn mechanics, handoff formats, the run ledger, and role templates.
---

# Codex Pattern Adapters

Codex is one runtime surface for the same four patterns (Patchwork, Worker
Swarm, Research Swarm, Hive Mind). The patterns themselves do not change. What
changes is the coordination surface: instead of the Claude Code `Agent` tool,
`TeamCreate`, `SendMessage`, and `run_in_background`, you use Codex-native
primitives: `spawn_agent`, `send_input`, `wait`, and `close_agent`.

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

- Every agent runs in an isolated sandbox with its own filesystem snapshot.
- `spawn_agent(role, task)` starts an agent and returns a `thread_id`.
- `send_input(thread_id, message)` pushes a message to a running agent.
- `wait(thread_id)` blocks until the agent produces output.
- `close_agent(thread_id)` tears down the agent and releases resources.
- There is no persistent TeamCreate equivalent. Agent identity lives in config
  files (`AGENTS.md` or per-role `.toml` configs) that are loaded at spawn time.
- Each agent starts from a clean sandbox; shared state must be written to files
  and committed or passed explicitly through handoff messages.

**Key implications:**

- Agents cannot directly read each other's in-memory state. All coordination
  flows through the orchestrator via structured handoffs.
- File writes inside a sandbox are local until the agent commits them. The
  orchestrator sees committed output only.
- The 6-thread default limit means large topologies must run in waves.
- `AGENTS.md` at the repo root is the universal configuration entry point.
  Every spawned agent reads it. Role-specific overrides go in per-role `.toml`
  files referenced from the project config.

---

## AGENTS.md: Universal Configuration Entry Point

`AGENTS.md` at the repo root is the primary mechanism for injecting persistent
context into every Codex agent. Think of it as the bootstrap configuration that
travels with each spawn.

**CLI vs IDE loading behavior:**

- **Codex CLI** auto-loads `AGENTS.md` at session start. Every spawned sub-agent
  receives its contents automatically. No manual injection needed.
- **Codex IDE** does NOT auto-load `AGENTS.md`. IDE users must manually paste
  the XML context block into the conversation before spawning agents. If you
  skip this step, sub-agents start with no project context.

**What sub-agents receive at spawn time:**

Sub-agents receive exactly two things: (a) the contents of `AGENTS.md` and
(b) the task prompt you pass to `spawn_agent`. They do NOT inherit the
orchestrator's conversation history, its reasoning state, or any
`send_input` messages sent to other agents. Every sub-agent starts blank
except for `AGENTS.md` and its own task prompt.

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

## Enabling Multi-Agent Mode

```toml
# ~/.codex/config.toml  (or  .codex/config.toml  per project)
[features]
multi_agent = true

[agents]
max_threads = <set to your runtime budget>
max_depth   = 1
job_max_runtime_seconds = <set to your runtime budget>
```

Or toggle it interactively: type `/experimental` inside a Codex session and
select "Multi-agents."

**Thread budget and compute window:**

Codex runtime limits evolve. All spawned agents and the orchestrator count
against the runtime budget. For large Hive Mind runs, structure your
decomposition so the full run completes within the real budget available to the
session:

- Limit each phase to a conservative number of concurrent leads, leaving
  headroom for the orchestrator and any verifier threads.
- Close completed threads promptly: lingering idle threads consume both the
  thread budget and the compute window.
- For runs that approach the runtime limit, write checkpoint context to
  `checkpoints.json` at each phase gate so the run can be resumed in a new
  session if needed.

If a run must span multiple sessions, treat the checkpoint file as the
hand-off artifact and re-spawn the orchestrator with it at the start of the
next session.

If the exact limits or configuration fields in this section differ from the
runtime you are using, prefer the official Codex docs and keep the methodology
rule: design to the real thread and compute budget you have, not the one you
wish you had.

---

## Session Start Checklist

Run these checks before spawning any agents. Catching misconfigurations here
prevents wasted compute budget on agents that start with wrong context.

1. **Verify `AGENTS.md` at repo root.** Confirm the file exists and contains
   current project context. If you are using the Codex IDE (not CLI), copy the
   full `AGENTS.md` content into an XML block and paste it into the session
   before proceeding.

2. **Check thread budget.** Review `max_threads` in `.codex/config.toml`.
   Count how many agents your first wave needs. If the wave exceeds the thread
   limit, plan the stagger before spawning.

3. **Decompose tasks to fit within the compute window.** Estimate how many
   phases your run requires. Structure the decomposition so all phases complete
   within the runtime budget available to the session. If the run is too large,
   split it into checkpointed sessions with explicit hand-off artifacts.

4. **Set role via `.codex/agents/<role>.toml`.** Confirm the role config files
   exist for every role you will spawn (lead, worker, explorer, verifier). If
   a role file is missing, the agent falls back to default settings, which may
   use wrong reasoning effort or sandbox mode for the task.

5. **Initialize the run ledger.** Create `.codex/runtime/run.json` and
   `workstreams.json` before spawning. An absent ledger means no recovery path
   if the orchestrator session is interrupted mid-run.

---

## Role Definitions

Four roles map onto the same responsibilities used in Claude Code patterns.
Define them in per-role config files and reference them from the project config.

```toml
# .codex/agents/lead.toml
model_reasoning_effort   = "high"
sandbox_mode             = "full"
developer_instructions   = """
You are a workstream lead. You own a defined set of files and a feature goal.
Decompose your goal into 2-5 worker tasks. Spawn workers for implementation.
Spawn a verifier before reporting phase completion. You may create child tasks
within your file ownership and phase. You may NOT edit files outside your
ownership set or advance to the next phase without verifier confirmation.
Report to the orchestrator via send_input when your phase is complete.
"""

# .codex/agents/worker.toml
model_reasoning_effort   = "medium"
sandbox_mode             = "full"
developer_instructions   = """
You are an implementation worker. You receive a bounded task with specific
files, acceptance criteria, and a test command. Implement the change. Run the
test command. Report success or failure. Do not expand scope.
"""

# .codex/agents/explorer.toml
model_reasoning_effort   = "low"
sandbox_mode             = "read-only"
developer_instructions   = """
You are a read-only explorer. Search, read, and analyze code. Return structured
findings: file paths, function signatures, dependency chains, risk areas.
Never edit files. Never run destructive commands.
"""

# .codex/agents/verifier.toml
model_reasoning_effort   = "medium"
sandbox_mode             = "read-only"
developer_instructions   = """
You are a verifier. Run the provided test command. Check outputs against
acceptance criteria. Return a structured verdict:
{ "pass": bool, "evidence": [...], "gaps": [...] }
Never edit files. If tests fail, report exactly what failed and why.
"""
```

---

## Adapting Patchwork for Codex

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

## Adapting Worker Swarm for Codex

Worker Swarm in Claude Code fans out sub-agents via the Task tool with
`run_in_background=true`. In Codex, the equivalent is spawning workers with
`spawn_agent` and collecting results with `wait`.

**Flow:**

1. The lead (or orchestrator, for small runs) produces a task list. Each task
   has a unique `task_id`, a bounded file set, acceptance criteria, and a test
   command.
2. Spawn one worker per independent task. Tasks with no shared files can run
   concurrently (up to the thread limit).
3. Call `wait` on each worker thread. Collect the `task_complete` handoff.
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

## Adapting Research Swarm for Codex

Research Swarm uses read-only explorers to scan the codebase before any
implementation work starts. In Codex, explorers run with `sandbox_mode =
"read-only"` so they cannot accidentally modify files.

**Flow:**

1. Spawn 2-8 explorers in parallel, each scoped to a discovery domain (e.g.,
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

### Wave batching with spawn_agents_on_csv

`spawn_agents_on_csv` is a Codex-native primitive for launching multiple agents
in one call using a CSV-formatted task list. It is the direct Codex equivalent
of fanning out a wave in the Research Swarm model.

**When to use it vs manual sequential spawning:**

- Use `spawn_agents_on_csv` when you have 3+ independent tasks ready at the
  same time and want to start all of them in a single orchestrator turn. This
  avoids the round-trip overhead of calling `spawn_agent` N times and waiting
  between each.
- Use manual `spawn_agent` + `wait` when tasks have heterogeneous configs
  (different roles, sandbox modes, or reasoning efforts) that cannot be
  expressed uniformly in a CSV row, or when you need to inspect each result
  before spawning the next.

**CSV format:**

```
role,task_json
explorer,{"type":"explore_request","domain":"auth layer","scope":["src/api/auth/**"]}
explorer,{"type":"explore_request","domain":"data layer","scope":["src/db/**"]}
explorer,{"type":"explore_request","domain":"API surface","scope":["src/api/routes/**"]}
```

**Mapping to Research Swarm waves:**

The Research Swarm model defines two waves: Wave 1 (parallel discovery) and
Wave 2 (implementation, gated on Wave 1 results). `spawn_agents_on_csv`
implements Wave 1 exactly: one CSV call launches all explorers in parallel,
and a single `wait_all` collects all results before the orchestrator builds
the manifest. Wave 2 (Worker Swarm) then starts from that manifest.

```
spawn_agents_on_csv(explorer_csv)   # Wave 1: all explorers start together
wait_all(wave_1_thread_ids)         # block until all Wave 1 results arrive
build_manifest(results)             # orchestrator synthesizes
spawn_agents_on_csv(worker_csv)     # Wave 2: workers start from manifest
```

---

## Adapting Hive Mind for Codex

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

**The orchestrator never implements.** It decomposes, dispatches, gates phase
transitions, and synthesizes. Leads own workstreams. Workers own tasks.
Verifiers own acceptance.

**Coordination via Codex primitives:**

```
spawn_agent(role: "lead", task: "<workstream decomposition JSON>")
  -> returns thread_id

send_input(thread_id, "<phase_authorized handoff JSON>")

wait(thread_id)
  -> returns lead's phase_complete or blocked handoff

close_agent(thread_id)
  -> after final phase verified
```

Leads use the same primitives internally to manage their workers:

```
spawn_agent(role: "worker", task: "<task_dispatch JSON>")
wait(worker_thread_id)
spawn_agent(role: "verifier", task: "<verify_request JSON>")
wait(verifier_thread_id)
send_input(orchestrator_thread, "<phase_complete JSON>")
```

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

Codex sandboxes are ephemeral. There is no built-in persistent agent state
across sessions. The run ledger is a set of flat files that serves as the
durability layer.

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

The run ledger is the only recovery path. Write to it after every phase gate,
not just at the end.

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
synthesize the final result. You do NOT implement code.

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
- max_depth = 1: leads spawn workers; workers do not spawn sub-workers.
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

## Responses API (Programmatic Callers)

If you drive Codex agents programmatically via the Responses API rather than
the CLI or IDE, three fields matter for multi-agent runs.

**`phase` field:**

Pass `phase` in the request body to indicate which phase of a Hive Mind run
the call belongs to. The Responses API does not enforce phase gates on its
own; you must track phase state in your run ledger and pass the correct `phase`
value so downstream agents know their context. Mismatch between the ledger
phase and the request `phase` is a common source of duplicate or out-of-order
work.

**`previous_response_id` for conversation continuity:**

Codex agents spawned via the Responses API are stateless by default. To
maintain conversation continuity within a durable lead agent, pass
`previous_response_id` set to the `id` from the prior response. This chains
the turns together so the agent retains its prior reasoning. Omitting this
field restarts the agent from a blank context, equivalent to re-spawning with
no checkpoint.

**Context compaction:**

Long-running leads accumulate large contexts. The Responses API does not
automatically compact. For leads that span many worker cycles, periodically
summarize the conversation state into a structured checkpoint (using the
`checkpoints.json` format), close the lead, and re-spawn with the checkpoint
as the opening context rather than the full prior conversation. This keeps
token costs predictable and avoids context-window truncation on extended runs.

---

## Limitations

**Sandboxes are ephemeral.** Each agent starts from a fresh filesystem snapshot.
Work must be committed to the repo before the agent closes. Uncommitted
in-memory state is lost when the sandbox exits.

**No persistent TeamCreate equivalent.** There is no built-in way to register a
named agent that persists across Codex sessions. Long-running leads must be
re-spawned with checkpoint context if the orchestrator session is interrupted.
The run ledger is the mitigation, not a full replacement.

**Thread limit bounds parallelism.** Large topologies must run in waves when
the runtime thread budget is small. Design your decomposition with the actual
thread budget in mind: close completed threads before spawning the next wave.

**max_depth = 1.** Workers cannot spawn sub-workers. If a task is too large
for a single worker, the lead must break it further before dispatching. There is
no 3-tier fan-out at the worker level.

**Context windows are independent.** Each spawned agent starts with a clean
context. It knows only what you give it at spawn time plus what is in
`AGENTS.md`. Leads accumulate context within a session but lose it if
re-spawned. Pass explicit checkpoint context when re-spawning after interruption.

**Commits are the synchronization mechanism.** Two workers editing the same
file in separate sandboxes will conflict at merge time. The no-file-overlap rule
exists for this reason. Enforce it in the decomposition step, not after the fact.

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

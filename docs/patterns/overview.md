---
title: "Multi-Agent Patterns: Overview"
description: "Decision guide for the four multi-agent execution patterns (Patchwork, Worker Swarm, Research Swarm, Hive Mind) plus the Worktree Sprint infrastructure layer. Covers when to use each, cost tradeoffs, and how patterns compose."
---

# Multi-Agent Patterns: Overview

This document describes the four execution patterns and one infrastructure layer available in this framework. Each pattern is a distinct workflow with its own coordination model, agent count range, and cost profile. Use this guide to select the right pattern for a given task before spawning any agents.

## Terminology

These five terms are reserved. Do not use them interchangeably or as synonyms.

```
+----------------+------------------------------------------------------+
| Term           | Means                                                |
+----------------+------------------------------------------------------+
| Patchwork      | Main agent only. No sub-agents.                      |
| Worker Swarm   | Lead-directed parallel agents. Lead writes every     |
|                | prompt. Agents execute and report back.              |
| Research Swarm | Scan or data-driven discovery. A manifest defines    |
|                | tasks in waves. Agents investigate autonomously.     |
| Hive Mind      | Formal team with shared task list and inter-agent    |
|                | messaging. 2-tier (flat) or 3-tier (hierarchical).  |
+----------------+------------------------------------------------------+
| Worktree Sprint| Infrastructure layer. Git-level isolation for any   |
|                | pattern running across parallel workstreams.         |
|                | Not a pattern itself.                                |
+----------------+------------------------------------------------------+
```

Generic term for any of the above: "multi-agent execution" or "parallel agents."

---

## Decision Tree

Start here to choose a pattern.

```
How much work is there?
  |
  +-- Fewer than 10 mechanical changes in known files?
  |   --> Patchwork
  |
  +-- Need to DISCOVER what is broken first (scan, audit, analyze)?
  |   --> Research Swarm
  |
  +-- Know what needs doing; need parallel hands to BUILD or FIX?
  |   --> Worker Swarm (4-12 agents, lead directs)
  |
  +-- Need agents to coordinate autonomously via messaging?
  |   +-- Single workstream, complex build --> Hive Mind (2-tier)
  |   +-- Three or more workstreams       --> Hive Mind (3-tier)
  |
  +-- Not sure? --> Worker Swarm (simplest multi-agent; easiest recovery)

Need git isolation across workstreams?
  --> Wrap any pattern above in a Worktree Sprint
```

---

## Decision Matrix

```
+----------------+--------+-----------+--------------+--------------------+
| Pattern        | Agents | Autonomy  | Coordination | Best Trigger       |
+----------------+--------+-----------+--------------+--------------------+
| Patchwork      | 1      | None      | None         | Small mechanical   |
|                |        |           |              | fixes              |
| Worker Swarm   | 4-12   | Low       | Lead collects| Directed batch;    |
|                |        |           | results      | parallel build     |
| Research Swarm | 4-16   | Medium    | Manifest +   | Scan results;      |
|                |        |           | wave gates   | quality sweeps     |
| Hive Mind 2T   | 3-8    | High      | Messaging +  | Autonomous single- |
|                |        |           | task list    | workstream build   |
| Hive Mind 3T   | 15-30+ | High      | 3-tier       | 3+ parallel work-  |
|                |        |           | messaging    | streams at scale   |
+----------------+--------+-----------+--------------+--------------------+
```

### Cost Comparison

Relative cost per session. Actual spend depends on model selection and task complexity.

```
+----------------+--------+-------------------+---------------+
| Pattern        | Agents | Relative Cost     | API Call Risk |
+----------------+--------+-------------------+---------------+
| Patchwork      | 1      | Lowest (baseline) | Low           |
| Worker Swarm   | 4-12   | Low to medium     | Medium        |
| Research Swarm | 4-16   | Medium            | Low           |
| Hive Mind 2T   | 3-8    | Medium to high    | High          |
| Hive Mind 3T   | 15-30+ | High              | Medium        |
+----------------+--------+-------------------+---------------+
```

API call risk refers to your LLM provider's rate limit exposure. In any multi-agent setup, consolidate provider API calls to the orchestrator or lead only. Agents that need external data should receive it in their task prompt rather than calling the API themselves.

---

## Pattern Summaries

### 1. Patchwork

Patchwork is the default for small, well-understood work. The main agent does everything directly: read, edit, commit. There are no sub-agents, no coordination overhead, and no inter-agent communication.

Use Patchwork when the scope is fewer than ten mechanical changes across known files and no research or discovery is required. Examples include fixing typos, renaming a variable across a handful of files, or toggling configuration values. If you need to figure out what is wrong before fixing it, you are in Research Swarm territory, not Patchwork.

There is no formal SOP for Patchwork because the pattern is just "do it." Apply the appropriate effort level to your model call: low for trivial edits, medium for changes that require judgment.

Full reference: [./patchwork.md](./patchwork.md)

---

### 2. Worker Swarm

Worker Swarm is the workhorse pattern for directed batch work. The lead agent stays in the driver's seat throughout: writing every agent's prompt, collecting results, and optionally spawning a second wave of execution agents. Agents receive self-contained prompts with all context they need. They do not know about each other and do not coordinate.

The canonical structure is two phases. Phase 1 is read-only reconnaissance: background agents scan, analyze, or research their assigned areas in parallel. The lead reviews findings before proceeding. Phase 2 is execution: agents implement, test, or document based on what Phase 1 surfaced. Non-overlapping file ownership is mandatory. No two agents should touch the same file.

Worker Swarm suits test-suite generation, documentation runs, parallel refactoring across independent modules, and any work where the shape of the task is known upfront but parallel hands would speed delivery. When you are not sure which multi-agent pattern to use, start here. It is the easiest to reason about and recover from if something goes wrong.

Full reference: [./worker-swarm.md](./worker-swarm.md)

---

### 3. Research Swarm

Research Swarm is the discovery pattern. Instead of the lead writing agent prompts, a manifest file defines the work. The manifest groups tasks into waves with explicit ordering and dependency gates. Agents are autonomous within their assigned task scope: they investigate their target, produce findings, and optionally apply fixes. The operator spawns each wave, monitors completions, and reviews output between waves rather than writing prompts in real time.

Wave ordering is the key safety mechanism. Simple mechanical tasks go in early waves; complex analysis tasks go in later waves after simpler context is established. Within a wave, file ownership must be non-overlapping. Across waves, a `blockedBy` dependency mechanism serializes access to shared files. After the swarm completes, re-run the original scan to verify findings are resolved.

Research Swarm is the right choice when the work is defined by data rather than by the lead's judgment: static analysis output, security scan results, quality audit findings, or any batch of issues where the investigation itself is the primary deliverable. Its natural follow-up is a Worker Swarm to implement whatever the research surfaces.

Full reference: [./research-swarm.md](./research-swarm.md)

---

### 4. Hive Mind

Hive Mind is the autonomous coordination pattern. It uses a formal team structure with a shared task list and inter-agent messaging. Teammates claim unblocked work from the task list, coordinate via messages, and gate phase transitions through the lead. Two variants exist based on scale.

**2-tier** (lead plus teammates): One workstream, 3-8 agents. The lead creates the team, populates the task list, spawns teammates, and gates phase transitions. Teammates can message each other and the lead. They cannot proceed to the next phase until the lead approves. Use 2-tier when a complex single-workstream build requires autonomous coordination within a single session.

**3-tier** (orchestrator, leads, bees): Multiple workstreams, 15-30 or more agents. An orchestrator owns phase gating and cross-workstream decisions. Each workstream has a dedicated lead who spawns and collects worker bees via the task tool. Bees are not team members: they cannot send messages, they only report to their parent lead. A per-workstream scratchpad (JSONL file) lets bees log findings that leads and the orchestrator can read. Use 3-tier when you have three or more independent workstreams each large enough to warrant a dedicated lead.

Both tiers follow a nine-phase workflow: Audit, Design, Refactor, Test, Harden Tests, Retest, Debug, Rerun, Ship. The lead gates every phase transition. No shortcuts.

Full reference: [./hive-mind.md](./hive-mind.md)

---

## Worker Swarm vs. Research Swarm: The Key Distinction

These two patterns are most often confused. The difference comes down to who defines the work and what the primary output is.

```
+---------------------+----------------------------+----------------------------+
| Dimension           | Worker Swarm               | Research Swarm             |
+---------------------+----------------------------+----------------------------+
| Purpose             | Build / fix / implement    | Discover / analyze / audit |
| Work definition     | Lead writes every prompt   | Manifest or scan data      |
| Agent autonomy      | Low: execute exactly what  | Medium: investigate and    |
|                     | the lead specified         | report within task scope   |
| Primary output      | Code changes               | Findings and reports       |
| Phase structure     | 2 phases (recon + execute) | N waves from manifest      |
| Lead role           | Writes prompts, collects   | Monitors between waves,    |
|                     | and synthesizes results    | does not write prompts     |
| Typical follow-up   | Ship                       | Worker Swarm               |
+---------------------+----------------------------+----------------------------+
```

Research Swarm discovers; Worker Swarm implements. They are designed to be used in sequence for large remediation or audit workflows.

---

## Hive Mind 2-tier vs. 3-tier

```
+---------------------+--------------------+-----------------------+
| Dimension           | 2-tier             | 3-tier                |
+---------------------+--------------------+-----------------------+
| Workstreams         | 1                  | 3+                    |
| Tier structure      | Lead + teammates   | Orch + leads + bees   |
| Bee layer           | No                 | Yes                   |
| Per-workstream      | No                 | Yes (JSONL scratchpad)|
| scratchpad          |                    |                       |
| Worktree isolation  | Optional           | Mandatory             |
| Typical agent count | 3-8                | 15-30+                |
+---------------------+--------------------+-----------------------+
```

Rule: three or more independent workstreams each needing a dedicated lead means 3-tier. One complex workstream with autonomous coordination means 2-tier.

---

## The Worktree Sprint Infrastructure Layer

Worktree Sprint is not a pattern. It is a git isolation layer that wraps any of the four patterns when the work spans multiple parallel workstreams that need independent branches.

Each workstream gets its own isolated git working directory (a worktree) branched off the sprint branch. Agents in one workstream cannot accidentally touch files in another. Phase-gate merges are sequential, which eliminates merge conflicts. After each merge, a sync step pulls the merged state back into active worktrees so later-phase agents see the full picture.

The lifecycle follows four operations: init (create branches, worktrees, and a manifest), merge (phase gate: merge workstreams into the sprint branch), sync (pull merged state back), and final (clean up worktrees and hold for review before merging to main).

Worktree Sprint is mandatory for Hive Mind 3-tier because the bee layer requires strict workstream isolation to prevent concurrent file collisions. For all other patterns it is optional but recommended any time you have two or more workstreams that touch overlapping areas of the codebase.

Full reference: [./worktree-sprint.md](./worktree-sprint.md)

---

## How Patterns Compose

Patterns are not mutually exclusive. The Worktree Sprint layer can wrap any pattern. Research Swarm and Worker Swarm are designed to chain together. The standard large-project flow is:

```
Research Swarm (discover what needs doing)
  |
  v
Worker Swarm or Hive Mind (implement findings)
  |
  v
[Wrapped in Worktree Sprint for git isolation if 2+ workstreams]
```

For the largest builds, the 3-tier Hive Mind orchestrator can spawn Worker Swarms as sub-patterns within individual workstreams when a lead needs to delegate a parallelizable subtask without adding those agents to the main team roster.

The guiding principle: choose the simplest pattern that fits the task. Patchwork before Worker Swarm. Worker Swarm before Hive Mind. Add Worktree Sprint only when git isolation is genuinely needed.

---

## Runtime Surfaces: Claude Code and Codex

All four patterns run on both Claude Code and Codex, though the coordination primitives differ for Hive Mind.

**Claude Code** uses built-in team management tools: `TeamCreate`, `TaskCreate`, `TaskList`, and `SendMessage` for Hive Mind. Patchwork, Worker Swarm, and Research Swarm use the `Task` tool to spawn background agents.

**Codex** (ChatGPT Pro with multi-agent enabled) uses native runtime tools: `spawn_agent`, `send_input`, `wait`, and `close_agent`. The pattern topology is identical to Claude Code; only the primitives change. Role configurations live in `.codex/agents/` and are ignored by Claude Code.

```
Claude Code primitive    Codex equivalent
-----------------------  ----------------------------
TeamCreate               Root session + spawn_agent
TaskCreate / TaskList    External run ledger (JSON)
SendMessage              send_input / wait
Task (spawn teammate)    spawn_agent(role: "lead")
Task (spawn bee)         spawn_agent(role: "worker")
```

Patchwork and Worker Swarm work identically on both surfaces. Research Swarm manifest execution is surface-agnostic (the manifest format is the same; the agent runner adapts). Hive Mind has a dedicated Codex adapter because the messaging and task-list primitives differ substantially.

Full Codex reference: [./hive-mind-codex.md](./hive-mind-codex.md)

---

## Model Selection Guidance

Match model tier to task complexity. Upgrading model tier is expensive and rarely necessary; adjusting effort level is almost always the right lever.

```
+-------------------+--------------------+---------+---------------------------+
| Role              | Recommended Tier   | Effort  | Use For                   |
+-------------------+--------------------+---------+---------------------------+
| Orchestrator      | Most capable tier  | Max     | Phase gating, arch review |
| Hive Mind lead    | Standard tier      | High    | Multi-hop coordination    |
| Standard agent    | Standard tier      | High    | Refactoring, deep analysis|
| Moderate tasks    | Standard tier      | Medium  | Multi-file impl, synthesis|
| Simple lookups    | Standard tier      | Low     | File scans, simple edits  |
| Pure mechanical   | Fast/cheap tier    | Default | Zero-ambiguity find/replace|
+-------------------+--------------------+---------+---------------------------+
```

Rule: drop effort level before switching to a cheaper model. A standard-tier agent at low effort outperforms a cheap-tier agent on any task with ambiguity.

Full model selection guidance: [../guides/model-selection.md](../guides/model-selection.md)

---

## Pre-Launch Checklist (Patterns 2-4)

Before spawning agents for any multi-agent run, verify:

- File ownership is non-overlapping: no two agents touch the same file.
- External provider API calls are consolidated to orchestrator or lead only.
- A sprint meta-log file is initialized to capture discoveries, escalations, and novel solutions.
- TDD contracts are defined for complex builds: tests specify "done" before implementation starts.
- Worktree isolation is set up if the run has two or more parallel workstreams.
- Model and effort level match task complexity (see table above).

---

## Further Reading

- [./patchwork.md](./patchwork.md): Patchwork pattern detail
- [./worker-swarm.md](./worker-swarm.md): Worker Swarm SOP and config templates
- [./research-swarm.md](./research-swarm.md): Research Swarm manifest format and wave design
- [./hive-mind.md](./hive-mind.md): Hive Mind SOP, 9-phase workflow, communication matrix
- [./hive-mind-codex.md](./hive-mind-codex.md): Hive Mind Codex runtime adapter
- [./worktree-sprint.md](./worktree-sprint.md): Worktree Sprint lifecycle and branch hierarchy
- [../guides/model-selection.md](../guides/model-selection.md): Model and effort selection matrix
- [../guides/sprint-planning.md](../guides/sprint-planning.md): Sprint artifacts and plan-to-code ratio
- [../guides/tdd-contracts.md](../guides/tdd-contracts.md): TDD contract template and enforcement by pattern

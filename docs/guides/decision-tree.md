---
title: Pattern Selection Decision Tree
description: Five questions to pick the right multi-agent pattern in under 60 seconds.
---

# Pattern Selection Decision Tree

Five questions. Under 60 seconds. Pick your pattern and start.

---

## The Decision Tree

```
Q1: How many files or units of work are changing?
|
+-- Fewer than 10, mechanical changes --> PATCHWORK (done)
|
+-- 10 or more --> continue to Q2
|
Q2: Are the changes independent of each other?
|
+-- Yes, they can run in parallel --> WORKER SWARM (done)
|
+-- No, or unclear --> continue to Q3
|
Q3: Is the primary goal discovery/research, or execution/building?
|
+-- Discovery (scan, audit, analyze, find what needs fixing) --> RESEARCH SWARM (done)
|
+-- Execution (I know what needs building) --> continue to Q4
|
Q4: How many independent workstreams does the work require?
|
+-- One workstream, complex autonomous build --> HIVE MIND 2-TIER (done)
|
+-- Two or more workstreams, each needing its own lead --> HIVE MIND 3-TIER (done)
|
Q5: Do parallel agents need file-level git isolation?
|
+-- Yes --> Add WORKTREE SPRINT layer to whichever pattern above you chose
|
+-- No --> Run the pattern directly
```

**Unsure after Q2?** Default to Worker Swarm. It is the simplest multi-agent pattern
and the easiest to recover from if you picked wrong.

---

## Numbered Questions (Linear Form)

If the flowchart is not your style, walk through these sequentially and stop
at the first match.

**1. Fewer than 10 mechanical changes?**
Yes: use Patchwork. Run them yourself, no sub-agents needed.

**2. Independent parallel work across 4 to 12 agents?**
Yes: use Worker Swarm. The lead writes every agent prompt.

**3. Need to discover what is broken or what exists before building?**
Yes: use Research Swarm. Agents scan and produce a findings manifest; a Worker
Swarm or Hive Mind implements from those findings.

**4. One complex workstream requiring autonomous coordination?**
Yes: use Hive Mind 2-tier. One lead, 3 to 8 teammates, no bee layer.

**5. Multiple independent workstreams, each needing its own lead?**
Yes: use Hive Mind 3-tier. An orchestrator coordinates 2 or more leads, each
running their own bee agents.

**+. Any pattern with parallel agents that must not conflict on files?**
Yes: wrap the chosen pattern in a Worktree Sprint for git-level isolation.

---

## Quick-Reference Table

```
+------------------+---------+----------+---------------------+------------------+
| Pattern          | Agents  | Cost     | Best For            | Not For          |
+------------------+---------+----------+---------------------+------------------+
| Patchwork        | 1       | 1x       | <10 mechanical      | Discovery,       |
|                  |         |          | edits, no sub-agent | complex builds   |
|                  |         |          | overhead needed     |                  |
+------------------+---------+----------+---------------------+------------------+
| Worker Swarm     | 4-12    | 2-4x     | Directed parallel   | Autonomous       |
|                  |         |          | build/fix, lead     | coordination,    |
|                  |         |          | writes all prompts  | discovery        |
+------------------+---------+----------+---------------------+------------------+
| Research Swarm   | 4-16    | 3-6x     | Audits, scans,      | Implementing     |
|                  |         |          | codebase discovery, | known changes    |
|                  |         |          | pre-build analysis  |                  |
+------------------+---------+----------+---------------------+------------------+
| Hive Mind 2-tier | 3-8     | 4-8x     | One complex         | Multiple         |
|                  |         |          | workstream needing  | independent      |
|                  |         |          | autonomous agents   | workstreams      |
+------------------+---------+----------+---------------------+------------------+
| Hive Mind 3-tier | 15-30+  | 8-12x    | 3+ parallel         | Single-stream    |
|                  |         |          | workstreams, each   | work, overkill   |
|                  |         |          | with dedicated lead | for small tasks  |
+------------------+---------+----------+---------------------+------------------+
| Worktree Sprint  | n/a     | +0       | Git isolation for   | Not a standalone |
| (layer)          | (layer) | (infra)  | any parallel        | pattern; wraps   |
|                  |         |          | pattern             | one of the above |
+------------------+---------+----------+---------------------+------------------+
```

Cost is relative to a single-agent Patchwork run. Worktree Sprint adds no agent
cost; it adds setup and merge overhead only.

---

## Hive Mind 2-Tier vs 3-Tier at a Glance

```
+------------------------+-------------------+-----------------------+
| Dimension              | 2-Tier            | 3-Tier                |
+------------------------+-------------------+-----------------------+
| Workstreams            | 1                 | 3 or more             |
| Structure              | Lead + teammates  | Orchestrator + leads  |
|                        |                   | + bee workers         |
| Bee layer              | No                | Yes                   |
| Typical agent count    | 3-8               | 15-30+                |
| Worktree isolation     | Optional          | Mandatory             |
| Per-workstream notes   | Shared scratchpad | One scratchpad each   |
+------------------------+-------------------+-----------------------+
```

Rule: if each workstream could be a self-contained project with its own lead,
use 3-tier. If it is one project with multiple agents collaborating, use 2-tier.

---

## Worker Swarm vs Research Swarm at a Glance

```
+---------------------+--------------------+------------------------+
| Dimension           | Worker Swarm       | Research Swarm         |
+---------------------+--------------------+------------------------+
| Primary goal        | Build, fix, ship   | Discover, audit, scan  |
| Who writes prompts  | Lead writes each   | Manifest or scan data  |
| Agent autonomy      | Low (execute only) | Medium (investigate)   |
| Primary output      | Code changes       | Findings, reports      |
| Typical follow-up   | Ship               | Worker Swarm           |
+---------------------+--------------------+------------------------+
```

Research Swarm discovers; Worker Swarm implements. They are complementary
and often run back-to-back.

---

## Common Mistakes

**Skipping to Hive Mind when Worker Swarm is enough.**
Hive Mind adds coordination overhead (team messaging, task lists, phase gates).
If a lead can write all agent prompts upfront and the work is parallelizable,
Worker Swarm ships faster at lower cost.

**Using Patchwork on 15 files.**
Patchwork is one agent doing everything sequentially. At 15 or more files,
the context window bloats and errors compound. Escalate to Worker Swarm.

**Using Research Swarm to implement.**
Research Swarm agents produce findings; they are not builders. Using them to
write production code mixes roles and produces unreliable output. Always
follow a Research Swarm with a Worker Swarm or Hive Mind for implementation.

**Running Hive Mind 3-tier on a single workstream.**
3-tier requires an orchestrator, leads, and bees. For one workstream, that
overhead is pure waste. Use 2-tier or Worker Swarm instead.

**Skipping Worktree Sprint when agents share a repo.**
Without git isolation, parallel agents on the same branch will clobber each
other's changes. If two or more agents are committing to the same repository
in parallel, add a Worktree Sprint layer.

**Choosing 3-tier because the task feels big.**
Tier is determined by workstream count, not task size or importance. A very
large single workstream is still 2-tier.

---

## Pattern Docs

- [Patchwork](../patterns/patchwork.md)
- [Worker Swarm](../patterns/worker-swarm.md)
- [Research Swarm](../patterns/research-swarm.md)
- [Hive Mind 2-Tier](../patterns/hive-mind-2tier.md)
- [Hive Mind 3-Tier](../patterns/hive-mind-3tier.md)
- [Worktree Sprint](../patterns/worktree-sprint.md)
- [Patterns Overview](../patterns/overview.md)

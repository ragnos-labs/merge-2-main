---
title: Worker Swarm
description: Lead-directed parallel execution with 4-12 worker agents. The lead writes every prompt, fans out independent tasks, and consolidates results.
---

# Worker Swarm

The Worker Swarm is the workhorse pattern for parallel execution. One lead agent (your active Claude Code or Codex session) orchestrates 4-12 worker agents across two phases: a dispatch phase that fans work out, and a consolidation phase that pulls it back in.

The defining characteristic: the lead writes every prompt. Workers execute and report. Workers never spawn sub-workers.

---

## When to Use It

Use this pattern when you have a batch of tasks that are:

- **Independent**: no task depends on another task's output
- **Non-overlapping**: each task touches different files
- **Bounded**: each task has a clear done state the lead can verify

Good fits:

- Fixing the test suite in 8 different modules in parallel
- Applying a standard refactor across 10 unrelated files
- Running the same analysis against a list of inputs
- Translating a set of config files from one format to another
- Generating boilerplate for a set of new endpoints
- Hunting for a class of bug (missing null checks, unused imports) across separate packages

Poor fits:

- Tasks where output of task A feeds task B (use sequential dispatch instead)
- Tasks that all write to a shared file (use a single agent instead)
- Tasks requiring coordination or negotiation (use Hive Mind instead)
- A single complex task that does not decompose cleanly (do not force it)

**Scale rule**: fewer than 4 independent tasks does not justify the overhead. More than 12 agents in a single turn will hit tool-call ceilings; split into waves.

---

## Architecture

```
Lead Agent (main Claude Code session)
    |
    +-- Dispatch Phase
    |     +-- Worker 1  (owns files: src/auth/*)
    |     +-- Worker 2  (owns files: src/billing/*)
    |     +-- Worker 3  (owns files: src/notifications/*)
    |     +-- Worker 4  (owns files: src/search/*)
    |     +-- ...up to ~8 per turn, background
    |
    +-- Consolidation Phase
          +-- Collect results from all workers
          +-- Validate each output
          +-- Resolve gaps or failures
          +-- Commit and report
```

The lead never goes idle during dispatch. While workers run in the background, the lead prepares the consolidation plan: what a passing result looks like for each worker, what to do if one fails.

---

## Two-Phase Execution

### Phase 1: Dispatch

The lead fans all workers out in as few turns as possible. Because the Agent tool has a practical ceiling of roughly 8 tool calls per assistant message, split large swarms across two consecutive turns.

For each worker, the lead writes a prompt that includes:

1. **Scope**: exactly which files or directories the worker owns
2. **Task**: what to do, stated precisely
3. **Output format**: what the worker must return (file paths changed, test results, structured summary)
4. **Done criteria**: how the worker knows it is finished

All workers run with `run_in_background: true` unless a later worker in the same turn depends on an earlier one (rare; usually means you should restructure).

Example dispatch for 8 workers fixing module test suites:

```
Worker 1: "Fix all failing tests in tests/auth/. Return: list of test files touched,
           count of tests fixed, any tests you could not fix and why."

Worker 2: "Fix all failing tests in tests/billing/. Return: same format as above."

Worker 3: "Fix all failing tests in tests/notifications/. Return: same format."

... (repeat for workers 4-8 with their respective module directories)
```

Each prompt is self-contained. Workers should not need to ask follow-up questions. If the task is ambiguous enough that a worker might ask, the lead has not written a good prompt.

### Phase 2: Consolidation

After all background workers complete, the lead:

1. Reads each worker's output
2. Validates the result against the done criteria
3. Handles any failures (see Failure Handling below)
4. Commits passing work
5. Produces a consolidated summary

Consolidation is sequential. The lead works through each worker result one at a time, does not parallelize this phase, and does not commit until it has read the actual output (not just the worker's self-report).

---

## File Ownership

This is the single most important constraint. Each worker owns a non-overlapping set of files. No two workers may touch the same file.

Before dispatching, the lead produces an explicit ownership map:

```
Worker 1: src/auth/**, tests/auth/**
Worker 2: src/billing/**, tests/billing/**
Worker 3: src/notifications/**, tests/notifications/**
Worker 4: src/search/**, tests/search/**
```

If a file needs changes that span two workers' domains, the lead handles that file directly in consolidation, not by giving two workers permission to touch it.

**Shared config files are a common trap.** If a `pyproject.toml`, `package.json`, or similar shared config needs an update, exclude it from all workers and handle it in consolidation after all workers finish.

The ownership rule prevents last-writer-wins corruption. When two agents write the same file concurrently, one silently overwrites the other. This is not detectable until you look for it.

---

## Model Selection for Workers

Use the cheapest model that can do the job reliably on the first attempt. A retry from a fast model plus a clean run from a slower model often costs more than just using the slower model from the start.

| Task type | Recommended model |
|:----------|:-----------------|
| Literal find-replace, known values only | Haiku or equivalent fast model |
| Mechanical config or env var changes | Haiku or equivalent fast model |
| Single-file bug fixes | Sonnet or equivalent mid-tier |
| Multi-file refactors | Sonnet or equivalent mid-tier |
| Synthesis, judgment, design decisions | Sonnet high-reasoning or Opus |
| Architecture review | Opus or equivalent frontier model |

The default for most worker tasks is the mid-tier model (Sonnet-class). Drop to a fast model only when the task is zero-ambiguity mechanical. Upgrade to a frontier model only when the worker must make design decisions.

Over-using fast models increases retry rate. Over-using frontier models inflates cost without improving outcomes for mechanical work. Calibrate per task, not per swarm.

---

## The Lead Writes Every Prompt

Workers do not write prompts for other workers. Workers do not spawn agents. Workers execute and report.

This constraint exists because:

- Prompt quality degrades when agents write prompts without the full context the lead has
- Sub-worker chains are hard to monitor and impossible to interrupt cleanly
- Failure attribution becomes unclear when the call chain is deep

If a worker's task is large enough that it seems to need its own sub-workers, it is a signal to decompose the task at the lead level. Split the single large worker prompt into two or three smaller worker prompts, and dispatch them in the next wave.

---

## Review Protocol

The lead validates every worker output before committing or integrating it.

**Do not trust the worker's self-report.** Workers will report success. Read the actual files.

Review checklist for each worker:

- [ ] Output matches the format requested in the prompt
- [ ] Files changed are within the worker's assigned scope (no scope bleed)
- [ ] Done criteria are actually met (tests pass, not just "I fixed the tests")
- [ ] No unintended side effects in adjacent files

For test-fix workers specifically: run the tests. A worker that reports "all tests fixed" but left the test suite in a broken state is a failure regardless of the narrative.

Two-stage review for non-trivial work:

1. **Spec compliance**: Did the worker do what was asked? Nothing more, nothing less?
2. **Quality**: Is the code correct, clean, and consistent with the surrounding codebase?

For mechanical transforms (stage 1 only is sufficient), skip quality review. For implementation work touching business logic, run both stages before committing.

---

## Failure Handling

Workers fail. The lead's job is to detect failures early and recover cleanly.

**Failure modes:**

| Mode | Symptom | Lead action |
|:-----|:--------|:------------|
| Incomplete output | Worker returned partial results or stopped early | Re-dispatch same worker with narrower scope |
| Wrong scope | Worker touched files outside its ownership map | Revert those files; re-dispatch with explicit exclusions |
| Blocked | Worker could not proceed (missing context, ambiguous spec) | Provide missing context; re-dispatch |
| Wrong model | Worker made bad judgment calls on a mechanical task (or vice versa) | Re-dispatch with corrected model selection |
| Spec mismatch | Worker did something different than asked | Re-dispatch with clearer prompt; do not send the same prompt again |

**Re-dispatch rules:**

- Fix the underlying cause before re-dispatching. The same prompt with the same model will produce the same result.
- If a worker fails twice on the same task, the lead handles the task directly rather than dispatching a third time.
- Never ignore a failure and integrate the partial output. Partial output causes downstream bugs that are harder to find than the original failure.

**Cascade failures:** If three or more workers fail on similar tasks, stop and re-examine the task definition. The problem is likely in the original decomposition or the shared prompt template, not the individual workers.

---

## Example: 8 Workers Fixing Module Test Suites

Scenario: a repository has 8 modules, each with a broken test suite. You want to fix all of them in parallel.

**Step 1: Build the ownership map**

```
Worker 1: tests/auth/
Worker 2: tests/billing/
Worker 3: tests/notifications/
Worker 4: tests/search/
Worker 5: tests/export/
Worker 6: tests/import/
Worker 7: tests/analytics/
Worker 8: tests/admin/
```

Verify: no shared files, no shared fixtures that would cause concurrent write conflicts.

**Step 2: Write the dispatch prompt template**

Each worker gets a prompt of the form:

```
Your scope: tests/<module>/

Task:
1. Run the existing test suite: `pytest tests/<module>/ -v 2>&1`
2. Read the failure output carefully.
3. For each failing test, identify the root cause.
4. Fix the code under src/<module>/ or the test itself (if the test is wrong).
5. Re-run until all tests in your scope pass.
6. Do NOT modify any file outside tests/<module>/ or src/<module>/.

Return when done:
- Count of tests that were failing at start
- Count of tests passing now
- List of files you changed (paths only)
- Any tests you could not fix, with one-line explanation for each
```

**Step 3: Dispatch all 8 workers in a single turn (background)**

Fire all 8 with `run_in_background: true`. The lead then prepares the consolidation checklist while they work.

**Step 4: Consolidate**

For each worker:
1. Read the returned summary.
2. Verify counts are plausible (a worker that "fixed 40 tests" by deleting them needs scrutiny).
3. Run a spot-check: `pytest tests/<module>/ --tb=short`.
4. If passing, add worker's changed files to the commit staging area.
5. If failing, re-dispatch that worker with a narrower scope or additional context.

**Step 5: Commit**

After all 8 workers pass review, commit all changes in a single commit with a message describing the scope: "fix: restore passing test suites across 8 modules".

---

## Claude Code Usage

In Claude Code, workers are spawned using the Agent tool (also called the Task tool in some contexts):

```
Agent(
  model: "claude-sonnet-4-6",
  run_in_background: true,
  prompt: "Your scope: tests/auth/  ..."
)
```

Key settings:

- `run_in_background: true` for all Phase 1 and most Phase 2 workers
- Set `model` explicitly per worker based on task type
- Do not use `run_in_background: false` unless a later agent in the same turn needs the result (almost never needed in a properly structured swarm)

**Tool call ceiling**: Claude Code has a hard ceiling of approximately 8 tool calls per assistant message. A swarm of 12 workers must be split into two turns of 6 each. The lead fires the first 6, waits, then fires the remaining 6 in the next turn.

**Reading results**: Workers write output to their context. The lead reads it with the Read tool (for files the worker was asked to produce) or by reading the agent's returned message directly. Always read; never assume.

---

## Codex Usage

In Codex, parallel agents run as separate sandbox instances. The lead session dispatches by opening multiple sandbox agents with distinct prompts and non-overlapping file scopes.

Codex-specific notes:

- Each sandbox agent has its own file system state. Changes in one sandbox do not affect others.
- After workers complete, the lead applies each worker's diff to the main workspace manually (review each diff before applying).
- Ownership is enforced by sandbox isolation rather than convention, which makes accidental file conflicts impossible but requires explicit merge steps.
- Use the `--scope` flag or equivalent prompt-level scope restriction to prevent workers from reading outside their module. This keeps context windows lean and reduces the chance of a worker "helping" with something outside its task.

---

## Common Mistakes

**Giving two workers the same file**

The second write silently overwrites the first. Always produce an explicit ownership map before dispatching. Check shared config files especially.

**Trusting the worker's self-report**

Workers report success. Read the actual output. Run the tests. The extra 30 seconds of verification prevents hours of debugging.

**Dispatching without a done criterion**

"Fix the auth module" is not a done criterion. "All tests in tests/auth/ pass with zero failures" is. Without a clear done criterion, workers over-deliver, under-deliver, or deliver the wrong thing.

**Sending the same failed prompt again**

If a worker fails, the problem is in the prompt, the model, the scope, or the context. Dispatching the identical prompt again will produce the same failure. Change something before re-dispatching.

**Letting workers negotiate with each other**

Workers do not communicate with each other. If task B needs output from task A, the lead collects A's output and passes the relevant parts into B's prompt explicitly. Workers that try to read each other's in-progress output will get stale or missing data.

**Over-parallelizing tiny tasks**

Spawning 8 agents to each change 2 lines of config is overhead-heavy. Batch very small tasks: have one worker handle all 8 config changes sequentially, or handle them directly in the lead session.

**Under-specifying the output format**

Asking for "a summary" produces wildly inconsistent results. Specify structure: "Return: a bullet list of file paths changed, each with a one-line description of the change." Consistent output format makes consolidation fast and reliable.

**Committing before validating all workers**

One bad worker can invalidate the entire batch. Validate all workers before staging any files for commit. If a worker is still failing during consolidation, hold the entire commit until it is resolved or explicitly deferred.

---

## Quick Reference

```
1. Decompose: identify independent tasks with non-overlapping files
2. Map ownership: explicit file list per worker, no overlaps
3. Select models: mid-tier default, fast for mechanical, frontier for judgment
4. Write prompts: scope + task + output format + done criteria
5. Dispatch: all workers background, max 8 per turn, split into waves if larger
6. Consolidate: read actual output, run verification, do not trust self-reports
7. Handle failures: diagnose root cause, fix prompt/model/scope, re-dispatch once
8. Commit: all workers passing, staged by file ownership, single descriptive commit
```

---

## Related Patterns

- [Patchwork](patchwork.md): fewer than 4 tasks, no sub-agents needed
- [Research Swarm](research-swarm.md): scan-driven discovery before execution, manifest-based waves
- [Hive Mind 2-Tier](hive-mind-2tier.md): agents that coordinate with each other, not just with a lead
- [Hive Mind 3-Tier](hive-mind-3tier.md): multi-workstream orchestration at scale

---
title: The Sprint Scribe
description: A background observer agent that monitors multi-agent sprints, produces structured logs, and surfaces health alerts. A supporting concept for Hive Mind sprints with 8 or more agents.
---

# The Sprint Scribe

The Sprint Scribe is a read-only background agent that watches a multi-agent sprint as
it runs and produces structured documentation: event logs, progress snapshots, health
alerts, and an end-of-sprint summary.

The Scribe does not execute sprint work. It observes and records.

---

## What the Scribe Is

The Scribe is a lightweight observer agent spawned alongside your sprint agents.
It operates on a poll cycle, typically every 5 minutes. It reads scratchpads,
git logs, and task status files. It writes entries to the sprint meta-log.

The Scribe has no write access to sprint working files. It only appends to the meta-log.

The Scribe is not a pattern. It is a supporting role that can be added to any Hive Mind
sprint to reduce the observability burden on the lead agent.

---

## When to Use It

Add a Scribe when:

- The sprint has 8 or more active agents
- Tracking progress manually across all workstreams would require frequent interruptions
  to the lead
- The sprint is expected to run for an extended period (multiple phases, high agent count)
- You want structured records for post-sprint review without asking agents to self-report

Skip the Scribe when:

- The sprint has fewer than 4 workstreams (the lead can track progress directly)
- The sprint is short and well-bounded (a single phase with a clear done state)
- Cost sensitivity requires minimizing active agents

The Scribe is most useful in 2-tier and 3-tier Hive Mind sprints. It adds limited value
to Worker Swarms because those are fire-and-forget: there is little ongoing state to
observe.

---

## What the Scribe Produces

### Real-Time Event Log

The Scribe appends entries to the sprint meta-log as agents complete tasks, hit blockers,
or produce notable outputs. Each entry is a JSON line with a timestamp, type, summary,
and confidence score.

Entry types:

- `innovation`: A good engineering decision worth capturing for future reference. Example:
  an agent batching API calls to avoid rate limits, or using lazy loading instead of
  eager initialization.
- `workaround`: An ad-hoc fix applied when something unexpected broke. Example: an
  environment variable override to bypass a broken dependency, or a manual retry loop
  around a flaky external call.
- `health_alert`: A signal that something may be wrong. See the Health Alerts section.

### Progress Dashboard

On each poll cycle, the Scribe notes which workstreams have produced commits or scratchpad
updates in the last interval and which have not. This produces a lightweight signal: active
workstreams show movement; stalled workstreams do not. The Scribe logs this as a
`progress_snapshot` entry.

The progress dashboard is not a substitute for the lead reviewing agent output. It is a
signal layer, not a control layer.

### Health Alerts

The Scribe emits a `health_alert` entry when it detects one of the following patterns:

- An agent has produced no commits and no scratchpad updates for two or more consecutive
  poll cycles (possible stall or hang)
- A commit message indicates a repeated retry of the same operation (possible loop)
- A scratchpad entry describes a problem that has not been followed by a resolution entry
  in the next cycle (possible unresolved blocker)
- A workstream's recent commits touch files outside its declared scope (possible scope
  drift)

Health alerts are signals, not diagnoses. The Scribe flags; the lead investigates.

### Sprint Summary

When the Scribe receives a shutdown request, it produces a brief end-of-sprint summary
as a final log entry. The summary includes:

- Count of innovation and workaround entries captured
- List of workstreams that showed stall signals (if any)
- Any health alerts that were never followed by resolution signals
- Total poll cycles completed

---

## How to Spawn a Scribe

Spawn the Scribe after the sprint is initialized and before the first phase
begins. The exact primitive depends on runtime, but the operating contract does
not change:

- One Scribe per sprint
- Read-only access to logs, scratchpads, and status artifacts
- Fast, inexpensive model tier
- Non-blocking execution so the lead or orchestrator keeps moving

Runtime-specific spawn mechanics live in:

- `../../runtimes/claude-code/pattern-adapters.md`
- `../../runtimes/codex/pattern-adapters.md`
- `../../runtimes/openclaw/pattern-adapters.md`

---

## The Scribe Prompt Template

Include the following in the Scribe's instructions. Replace `<SLUG>` with the sprint
identifier and `<SPEC_SUMMARY>` with a one-paragraph description of the sprint's scope.

---

You are the Sprint Scribe for sprint `<SLUG>`. Your job is to observe sprint execution
and record innovation and workaround moments in the meta-log. You do NOT execute sprint
work. You observe and log.

**Sprint context**: `<SPEC_SUMMARY>`

**Data sources** (poll every 5 minutes):

1. Scratchpads at `.ai/sprints/<SLUG>/scratchpad-*.jsonl`. Look for problem descriptions,
   solution approaches, retries, and environment issues.
2. Git log: `git log --all --oneline --since="5 minutes ago"`. Look for commit messages
   that mention workarounds, fixes, or optimizations.
3. Task status files for completed task updates.

**How to log an innovation entry**:

```
{"ts":"<ISO8601>","type":"innovation","agent":"scribe","summary":"<one sentence>",
 "detail":"<what and why>","pattern":"<label>","confidence":<0.0-1.0>}
```

**How to log a workaround entry**:

```
{"ts":"<ISO8601>","type":"workaround","agent":"scribe","summary":"<one sentence>",
 "problem":"<what broke>","detail":"<what was done>","temporary":true}
```

Append entries to `.ai/sprints/<SLUG>/meta-log.jsonl`.

**Dedup rule**: Track logged patterns in memory. Do not log the same pattern twice.
When in doubt, skip. Noise is worse than gaps.

**Confidence calibration**:

- 0.9 or above: obviously good practice, applies broadly
- 0.7 to 0.9: solid decision in context
- 0.5 to 0.7: interesting but situational
- Below 0.5: do not log

Flag uncertainty explicitly. If you cannot tell whether a commit represents an
innovation or just normal work, do not log it.

**At shutdown**: Produce a brief text summary of all captured entries, then approve
the shutdown.

---

## Confidence Calibration

The Scribe should never guess. When evidence is ambiguous, it skips the entry rather
than logging at low confidence. A meta-log with 4 high-confidence entries is more
useful than one with 20 marginal ones.

The confidence field is a first-person estimate, not a probability. It answers the
question: "How convinced am I that this is worth capturing?" Apply the scale above.

If the Scribe is unsure whether a commit belongs to a given workstream or whether
a retry loop is a workaround or normal behavior, it should log the uncertainty as a
note in the summary field rather than asserting a classification it cannot verify.

---

## Scribe vs. Meta-Log

These are not separate systems. The Scribe is the agent that produces the meta-log.
The meta-log is the output artifact.

If you run a sprint without a Scribe, the lead agent or individual worker agents are
responsible for appending meta-log entries. The format is the same either way. The
Scribe simply centralizes that responsibility in a dedicated observer rather than
distributing it across agents that are already busy building.

---

## Limitations

The Scribe can only observe what it can read:

- Files it has access to (scratchpads, meta-log, task status files)
- Git history (commits, messages, file change lists)

The Scribe cannot:

- Read other agents' context windows
- Observe agent reasoning that has not been written to a file
- Detect agent failures that produce no file output (a hung agent that writes nothing
  is invisible until the stall detector fires)
- Know whether a completed task meets quality criteria (it can see that work was done,
  not whether the work is correct)

For quality review, use the lead agent or a dedicated reviewer agent. The Scribe is
an observability aid, not a QA gate.

---

## Related Docs

- [Hive Mind 2-Tier](../patterns/hive-mind-2tier.md)
- [Hive Mind 3-Tier](../patterns/hive-mind-3tier.md)
- [Worker Swarm](../patterns/worker-swarm.md)
- [Pattern Selection Decision Tree](decision-tree.md)

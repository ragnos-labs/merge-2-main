---
title: Meta-Log Gates
description: A lightweight evidence model for long-running agent work.
---

## Meta-Log Gates

Long-running agent work needs evidence at the start, evidence while it is
moving, and evidence before it is declared done.

That is what meta-log gates are for.

## Why This Exists

Without an evidence trail, multi-agent work degrades into:

- "I think we already checked that"
- "someone fixed it in another thread"
- "the tests probably passed earlier"
- "we changed the plan but forgot to say so"

Meta-log gates are the minimum structure that keeps a sprint reviewable without
forcing everyone into heavy process.

## The Three Gates

### G1: Init

Before substantive work begins, record:

- the goal
- the chosen pattern
- the owned files or scope
- the initial risks or unknowns

If none of that is written down, the sprint has no reliable starting point.

### G2: In-Flight

At meaningful transitions, record:

- what changed
- what was verified
- what is blocked
- whether the plan or scope moved

This does not need to be verbose. It needs to be real.

### G3: Ship

Before the work is handed off, shipped, or merged, record:

- what was completed
- what proof exists
- what remains deferred
- the final artifact set or report location

The ship gate is the bridge between "work happened" and "someone else can
trust the result."

## What To Record

Good meta-log entries are short and structured.

Minimum fields:

- timestamp
- actor or role
- phase or gate
- summary
- evidence pointer

Evidence pointers can be:

- test output
- diff or commit references
- review notes
- generated artifacts
- links to relevant docs

## Scope Changes Must Be Visible

If the plan changes, the meta-log should say so.

That includes:

- added workstreams
- dropped requirements
- risk reclassification
- new blockers

Hidden scope change is one of the fastest ways agent work becomes
unreviewable.

## Keep It Lightweight

Meta-log gates are not a request for essay-writing.

If the entries are so heavy that no one wants to write them, the system will
rot. The right level is "enough for a new human to understand what happened."

## Where This Fits

Meta-log gates complement, but do not replace:

- sprint plans
- handoff contracts
- release gates
- retrospectives

Think of them as continuity infrastructure for the work between those bigger
artifacts.

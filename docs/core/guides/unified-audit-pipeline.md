---
title: Unified Audit Pipeline
description: A runtime-agnostic pattern for turning scattered checks into one reviewable audit pass.
---

## Unified Audit Pipeline

A good audit pipeline does not just run scanners. It produces a reviewable
finding set, a repair path, and a clear statement of what was actually checked.

## Why This Exists

Agent-heavy teams tend to accumulate half a dozen overlapping review motions:

- static checks
- security scans
- semantic code review
- docs alignment checks
- config or infrastructure validation
- optional runtime probes

When these stay disconnected, the same branch gets reviewed three times and no
one can say what the final verdict actually was.

The fix is not "more scanners." The fix is one audit contract that absorbs
multiple signals into one result.

## Core Shape

A unified audit pipeline has five layers:

1. **Scope**: decide whether you are auditing a repo, a directory, or a diff
2. **Tool scans**: run the mechanical checks that are cheap and repeatable
3. **Agent review**: evaluate correctness, security, docs, and config with
   fresh reviewers
4. **Consolidation**: deduplicate, sort by severity, and produce one finding set
5. **Repair loop**: fix accepted findings, then re-verify the affected surface

Not every repo needs every layer on every run. The contract stays the same.

## Minimum Finding Contract

Every finding should carry enough structure for another human or agent to act:

- severity
- category
- file or scope
- issue statement
- evidence
- recommended fix

A finding without evidence is a suggestion, not an audit result.

## Suggested Review Tiers

The exact implementation varies by repo, but a stable split usually looks like:

- **Security**: credential exposure, injection risk, auth mistakes, unsafe shell
  or process behavior
- **Code quality**: logic bugs, correctness gaps, brittle assumptions, dead code
- **Docs alignment**: stale examples, missing instructions, broken references
- **Config and infra**: unsafe defaults, drift, invalid assumptions, bad rollout
  mechanics
- **Runtime probing**: optional DAST or live checks when the target is running

Large scopes usually benefit from parallel reviewers. Small scopes usually do
better with one tighter pass.

## Repair Loop

An audit pipeline should not stop at "here are 47 findings."

Use a repair loop when:

- the findings are scoped enough to fix in the same session
- ownership is clear
- the branch is not already too noisy

Keep the repair contract simple:

1. fix accepted findings
2. re-run the checks that prove the fix
3. report what changed
4. call out anything intentionally deferred

## False Positive Discipline

All real audit systems eventually need suppression rules. Add them slowly.

Good suppression rules are:

- narrow in scope
- explicit about why the result is not actionable
- time-bounded or reviewable

Bad suppression rules hide categories of work because the findings are
annoying.

## Quick, Standard, and Deep Modes

A single audit pipeline can expose multiple operating modes:

- **Quick**: cheap baseline plus focused review on the changed scope
- **Standard**: the normal full branch or target pass
- **Deep**: the standard pass plus heavier runtime probes or broader coverage

The modes should change depth, not semantics. A quick pass still needs an
honest final report.

## Output Contract

A useful audit run ends with:

- what was audited
- what was skipped
- what was found
- what was fixed
- what still blocks merge or release

If the result is "clean," the report should still say which surfaces were
actually checked.

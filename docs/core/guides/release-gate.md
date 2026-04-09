---
title: Release Gate
description: A runtime-agnostic release checklist for moving from done coding to reviewable, auditable merge candidates.
---

# Release Gate

This guide is the public-safe shape behind the kind of `/ship` workflow many
teams eventually build for themselves.

The exact commands will vary by repo. The phase order should not.

## Why This Exists

Multi-agent coding does not fail only during implementation. It also fails in
the last mile:

- the wrong files get staged
- tests were never actually run
- a review happened, but no one fixed the findings
- a branch is pushed without an audit trail
- a PR exists, but there is no clear record of what was checked

A release gate is the discipline that turns "looks done" into "reviewable,
traceable, and safe to merge."

## The 6 Phases

### Phase 0: Prepare

Classify the diff before you do anything else.

- what changed
- how risky it is
- whether this is a full pass or a delta rerun
- whether the change is small enough for a lightweight path

Artifacts to record:

- changed files
- base branch or base commit
- risk classification
- rerun scope (`full`, `delta`, or `cached`)

### Phase 1: Preflight

Run the blocking baseline checks for the repo.

Typical categories:

- tests
- lints
- type checks
- docs validation
- instruction-file hygiene
- secret or policy checks

If the baseline fails, stop and fix it before continuing.

### Phase 2: Review

Review the actual diff, not the intention.

Minimum review surface:

- correctness
- security
- shell and process safety
- test realism
- scope creep
- file ownership violations

For small changes, a direct checklist review is often enough.

For larger changes, split review into parallel passes such as:

- code review
- docs review
- security review
- acceptance verification

## Phase 3: Commit

Commit only after accepted findings are fixed.

Rules:

- stage specific files only
- never bulk-stage blindly
- do not fold unrelated work into the release
- leave the worktree clean after commit

If multiple agents touched the branch, verify the final staged file list before
committing.

## Phase 4: Gate

Run the post-commit quality gate.

The implementation is repo-specific, but the output should collapse to one of
three states:

- `GO`: safe to publish
- `WARN`: publishable, but call out degradations
- `BLOCK`: fix and re-run the gate

The key is not which scanner you use. The key is that the gate produces a
clear, reviewable decision.

## Phase 5: Publish

Publish is where the branch becomes visible to other humans.

Typical actions:

- push the branch
- create or update the PR
- attach the review summary
- surface the exact commands, tests, or scans that were run

This phase should not merge automatically unless a human explicitly asked for
that behavior.

## Phase 6: Report

End with a short operator digest.

Include:

- branch name
- scope of review
- findings found and fixed
- commit hash
- gate result
- PR URL or reason no PR was opened

If you skipped any phase, say so explicitly.

## Lite Mode

Not every change deserves the full beast.

Use a lightweight path when the diff is small, bounded, and low-risk. A good
lite mode still keeps:

- blocking baseline checks
- semantic review
- explicit staging
- a clear final report

What usually gets trimmed:

- heavy post-commit scans
- doc-sync or indexing work
- non-blocking telemetry or digest tasks

## No-Implicit-Merge Rule

Shipping is not the same thing as merging.

Keep these decisions separate:

- "This branch has been checked"
- "This branch should be merged now"

That separation matters more, not less, when multiple agents are involved.

## What To Customize Per Repo

Customize the mechanics, not the shape:

- which tests count as the blocking baseline
- which scanners feed the gate
- how PR text is generated
- how branch state is cached
- which follow-up tasks run after publish

The public pattern is the contract. Your local tooling is an implementation.

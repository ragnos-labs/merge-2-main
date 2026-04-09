---
title: Ship Rerun Semantics
description: A guide for deciding when a release pipeline should run cached, delta, full, or lite paths.
---

## Ship Rerun Semantics

Not every second pass should rerun everything from scratch. Not every second
pass should trust cache either.

This guide defines a clean contract for rerunning a release pipeline without
losing confidence in the result.

## Why This Exists

Teams often rerun the same "ship" pipeline after:

- fixing findings from the last review
- updating a small number of files
- rebasing onto main
- repairing documentation or config drift

If every rerun is full, you burn time and compute. If every rerun is cached,
you miss real regressions.

## The Four Modes

### Cached

Use a cached result only when the commit and relevant inputs have not changed.

Good fit:

- identical commit
- identical effective flags
- unchanged release inputs

Do not use cache for fresh proof of mutable external state.

### Delta

Use a delta rerun when a small, bounded set of files changed after a prior
full pass.

Good fit:

- small fix pass after review
- docs-only or config-only follow-up
- narrow remediation on a known set of findings

Delta mode should shrink review scope, not pretend unchanged prerequisites were
never needed.

### Full

Use a full rerun when the branch meaningfully changed or when the prior state
is not trustworthy.

Good fit:

- broad diff changes
- rebase with conflict resolution
- cache miss or cache corruption
- changed review intent
- changed risk profile

When in doubt, pay for a full pass.

### Lite

Use lite mode for small, low-risk work that still deserves an explicit release
path.

Lite mode should keep:

- baseline validation
- semantic review
- explicit staging or commit checks
- a final report

Lite mode should trim weight, not honesty.

## What Should Never Be Trusted Blindly

Some surfaces should be treated as fresh-run by default:

- security baselines
- tests that depend on current branch state
- live environment checks
- any gate based on mutable external data

Cache the report if you want. Re-run the proof if the proof can change.

## Scope Decision Rules

Use these as defaults:

- `cached` if HEAD and effective inputs are identical
- `delta` if only a small, well-understood subset changed after a full pass
- `full` if the branch meaningfully changed or trust is degraded
- `lite` only when the work is small, bounded, and low-risk

The exact threshold is repo-specific. The contract is not.

## Report The Rerun Choice

A rerun is easier to trust when the final report states:

- which mode was used
- why that mode was chosen
- what was rechecked
- what was intentionally skipped

If the answer is "we trusted cache," say that explicitly.

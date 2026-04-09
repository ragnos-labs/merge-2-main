---
title: Verification Discipline
description: A reference for proving claims with fresh evidence instead of memory or guesswork.
---

## Verification Discipline

Run the proving command. Read the output. Then claim the result.

That is the core rule.

## Why This Exists

Agent work fails when confidence outruns evidence.

Common examples:

- "tests pass" based on an earlier run
- "the bug is fixed" because the code changed
- "the file updated" because the write succeeded
- "the service is healthy" because it started once

Verification discipline is the habit that stops those mistakes from getting
reported as facts.

## The Gate Sequence

For any claim of completion:

1. identify the command or read that proves the claim
2. run it fresh
3. read the output and exit status
4. verify that the evidence matches the claim
5. only then report the result

Skip any step and you are guessing.

## Common Failures

| Claim | Real evidence | Not enough |
| --- | --- | --- |
| Tests pass | fresh test output with zero failures | "should pass" |
| Build works | build output plus exit code 0 | "no obvious errors" |
| File changed | re-read file shows intended content | "write succeeded" |
| Bug fixed | reproducer or regression test now passes | "patched the code" |
| Service healthy | health check or endpoint response | "service started" |
| Agent finished | landed diff matches requested change | agent self-report |

## Red-Flag Language

Treat these phrases as a hard stop:

- should
- probably
- seems to
- likely
- I believe
- appears to

When that language shows up, the next step is verification, not narration.

## Where This Applies

Use verification discipline:

- before telling a user something is done
- before committing
- before opening or updating a PR
- before declaring a fix worked
- before trusting a delegated result

It does not need to slow down exploration. It does need to gate conclusions.

## Delegation Rule

Do not trust a subagent's success message by itself.

Verify the result by checking:

- the changed files
- the diff
- the requested proof surface

Delegation without verification is just distributed guessing.

---
title: How We Work At RAGnos
description: A public-safe operating manifesto for fast experiments, hard edges, and reviewable agent work.
---

## How We Work At RAGnos

This page is the public-safe version of our operating posture.

Call it a manifesto if you want. Call it a lab manual with worse sleep habits
if you prefer. The point is the same: we like moving fast, but we do not think
"fast" means "sloppy and impossible to audit later."

## What We Optimize For

We care about three things enough to keep repeating them:

- speed without magical thinking
- experimentation without amnesia
- weirdness without losing reviewability

The mad-scientist part is real. So is the paper trail.

## The Working Rules

### 1. Run the experiment, but instrument it

We like trying things that are new, messy, or slightly unreasonable.

That does not mean "YOLO and forget what happened." If a workflow matters, it
should leave enough evidence for another person to understand:

- what changed
- what ran
- what failed
- what we learned

If it is not reviewable, it is not done.

### 2. Source reality beats vibe reality

When a runtime, tool, or protocol changes every other week, opinions are cheap.
Primary sources matter.

We would rather have:

- one boring official link
- one accurate command
- one proof surface

than twenty confident sentences that age like milk.

### 3. Build guardrails around the chaos

Agent work gets weird quickly.

The answer is not to avoid ambitious workflows. The answer is to box them in
with:

- file ownership
- checkpoints
- release gates
- audit loops
- explicit handoffs

The experiment can be chaotic. The operating frame should not be.

### 4. Steal patterns, not trust

We study other repos constantly.

We borrow:

- structures
- workflows
- review moves
- interface ideas

We do not blindly inherit their assumptions, safety posture, or maintenance
quality. That is why the repo has a radar page instead of an endorsement hall
of fame.

### 5. Human judgment stays in the loop

We use agents aggressively. We do not outsource final judgment to them.

Humans still decide:

- whether a finding matters
- whether a release is acceptable
- whether a tradeoff is worth it
- whether a claim is strong enough to publish

If the humans disappear completely, all you have left is automated confidence.
That is not the same thing as confidence.

### 6. Personality is allowed at the edge

We do not think every engineering doc needs to sound like drywall.

Some repo surfaces can carry more voice, commentary, or character. But the
actual operating docs still need to be clear enough to survive a cold read at
2 a.m. during a real problem.

Style is welcome. Sass is not allowed to break the instructions.

### 7. Publish what helps, keep what should stay sharp

Some things belong in public:

- methodology
- templates
- source maps
- public-safe examples

Some things do not:

- internal glue
- private product leverage
- internal routing and automation detail
- anything that stops being useful the moment you remove the secret sauce

We are happy to share the lab notes that make the field better. We are not
obligated to open the whole basement.

## The Short Version

This is probably the shortest honest summary:

- move fast
- write it down
- verify it
- argue with it
- keep the strange parts useful

That is the job.

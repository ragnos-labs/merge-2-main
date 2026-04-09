---
title: How We Work At RAGnos
description: A public-safe operating manifesto for fast experiments, hard edges, and reviewable agent work.
---

## How We Work At RAGnos

This page is the public-safe version of our operating posture.

Call it a manifesto if you want. Call it a lab manual with worse sleep habits
if you prefer. The point is the same: we like moving fast, but we do not think
"fast" means "sloppy and impossible to audit later."

## Mission

Our mission is to make agentic engineering faster, safer, weirder, and more
legible for the people actually doing the work.

That means:

- publish methods that help real teams move
- keep governance, observability, and security in the loop
- make public material useful enough to raise the floor for everyone
- leave room for experimentation, discovery, and the occasional productive
  argument with reality

We are not trying to make the work less strange. We are trying to make the
strange parts usable.

## Commitment To The Community

We believe public uplift matters.

That shows up here as a few simple commitments:

- share methodology when it can help without leaking private leverage
- credit upstream ideas instead of pretending we invented the internet
- keep this repo welcoming to people across stacks, backgrounds, and levels of
  formality
- leave room for absurdist humor without turning the space hostile, exclusionary,
  or smug
- build a place where people can challenge assumptions, contribute patterns,
  and call out weak claims

Safe space, in practice, means a place where people can learn, disagree, and
show up as themselves without getting punished for not sounding like the loudest
guy in the room.

## What We Optimize For

We care about three things enough to keep repeating them:

- speed without magical thinking
- experimentation without amnesia
- weirdness without losing reviewability

The mad-scientist part is real. So is the paper trail.

## What The Hell Does RAGnos Mean

It is a nerdy mashup, not a pristine museum-grade etymology.

The `RAG` part is the obvious one: retrieval-augmented generation, the
engineering reality a lot of this work grew out of.

The `nos` part is more aspirational and more mischievous:

- a nod to `gnosis`, or knowing
- a sideways wink at `agnostic`, because we want the methods to be more stack-
  agnostic than our actual day-to-day preferences sometimes are
- a reminder that discovery matters, even when we are clearly dragging our own
  preferred tools into the lab with us

So the name points in a few directions at once:

- nerdy enough to admit where it came from
- ideological enough to care about discovery and knowledge
- aspirational enough to reach for tool and stack agnosticism

Do we have our own stack preferences and begrudging lock-ins? Obviously.

The aspiration still counts. The joke is that we know better than to pretend we
are fully above our own habits, metaphysics, or vendor gravity.

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

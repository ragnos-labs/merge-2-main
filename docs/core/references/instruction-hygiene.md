---
title: Instruction Hygiene
description: A reference for keeping root instruction files lean, stable, and reviewable.
---

## Instruction Hygiene

Root instruction files are bootloaders, not junk drawers.

If the root becomes bloated, stale, or contradictory, every downstream agent
inherits the mess.

## Why This Exists

Many repos now carry instruction surfaces such as:

- `AGENTS.md`
- `CLAUDE.md`
- runtime-specific config or role files
- local overrides for subdirectories

The temptation is to keep shoving more detail into the root. That usually makes
the instruction layer slower to read, harder to trust, and easier to break.

## Root File Contract

Keep the root instruction file:

- short
- stable
- portable
- high-signal

It should answer:

- what this repo is
- what the main rules are
- where deeper guidance lives

It should not try to inline the entire operating manual.

## Breadcrumb Contract

Use the root to point downward.

A good breadcrumb pattern is:

- one short rule
- one command or action when relevant
- one link to the deeper guide

That keeps the top layer readable while still making the detail discoverable.

## What Belongs In Child Docs

Move these downward early:

- runtime-specific behavior
- role-specific instructions
- workflow details
- long examples
- exception handling
- policy nuance

The deeper the detail, the less likely it belongs in the root.

## Keep The Tree Coherent

Instruction hygiene is not only about size. It is also about consistency.

Watch for:

- duplicate rules in multiple places
- stale links
- root files that contradict the deeper docs
- runtime-specific claims presented as universal truths

If two files disagree, the repo has an instruction bug.

## Update Rules

When editing instruction surfaces:

1. update the canonical child doc first if the detail lives there
2. keep the root wording compressed
3. verify that links still resolve
4. re-read the full root file after edits

Every extra line in a root instruction file should justify its existence.

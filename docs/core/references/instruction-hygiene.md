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

---

## Before and After

### Bad: AGENTS.md as a junk drawer

```markdown
# AGENTS.md

This repo has many agents. Here is everything you need to know.

## Background
[3 paragraphs of project history]

## Coding rules
- Use 2-space indent for JS, 4 for Python
- Run lint before commit
- Don't commit .env files
- Make sure to handle errors
- [29 more bullets]

## Testing
[4 paragraphs covering each test framework, fixture conventions,
flaky-test triage, mock policy, snapshot-test rules, integration vs.
unit boundaries...]

## How to write a PR description
[2 paragraphs of template]

## How we onboard
[a section that should be in CONTRIBUTING.md]

## Known issues
[a section that should be tracked in issues]

[continues for 500 lines]
```

The reader finishes uncertain about what is rule, what is context, and what
is folklore. Every agent inherits the same uncertainty.

### Good: AGENTS.md as a bootloader

```markdown
# AGENTS.md

Documentation-only repo. Multi-agent coordination methodology.

## Bootstrapping rules
1. Read the README first.
2. Use `just tool` before opening a PR.
3. One owner per file. See `docs/core/patterns/overview.md`.
4. Reject any spawn missing a model pin. See
   `docs/templates/universal/spawn-guard-hook.md`.

## Where deeper guidance lives
- Coding standards: `docs/core/guides/`
- Testing rules: `docs/core/guides/tdd-integration.md`
- Voice rules: `docs/core/references/instruction-hygiene.md` (this doc)
- Contributing: `CONTRIBUTING.md`

If a rule is not above and not in a linked doc, it is not a rule.
```

The reader finishes in under a minute knowing what the repo is, the four
hard rules, and where to look for everything else. The 500 lines of detail
still exist; they just live where they belong.

The pattern is the same at every level: the root is a bootloader, the
linked docs carry the weight.

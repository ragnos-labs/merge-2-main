---
title: Post-Sprint Completion Guide
description: The 4-step pipeline to consolidate, review, quality-gate, and ship after a multi-agent sprint finishes implementation.
---

# Post-Sprint Completion Guide

A multi-agent sprint is not done when the last agent commits. It is done when
the combined result is validated, reviewed, and merged. This guide is the
procedural checklist for everything that happens between "implementation
complete" and "PR merged."

Run this pipeline after every sprint, regardless of pattern (Worker Swarm,
Research Swarm, Hive Mind). Skip nothing. Each step exists because parallel
agents introduce specific failure modes that single-agent runs do not.

---

## Prerequisites: Sprint Completion Gate

Before starting the pipeline, verify all of the following:

```
[ ] All agent tasks are marked complete
[ ] Every agent has committed and pushed its branch
[ ] No unresolved merge conflicts remain on individual branches
[ ] No agent is still running (shut them all down)
[ ] You have a list of every branch involved in this sprint
```

If any item is unchecked, resolve it before proceeding.

---

## Step 1: Consolidation

Merge all workstream branches into a single integration branch.

### 1.1 Create an integration branch

```bash
git checkout main
git pull origin main
git checkout -b integrate/<sprint-slug>
```

### 1.2 Merge each workstream branch

Merge one branch at a time. Do not squash; preserve commit history for the
review step.

```bash
git merge --no-ff <workstream-branch-1>
git merge --no-ff <workstream-branch-2>
# repeat for each branch
```

### 1.3 Resolve conflicts

Conflicts here are normal. Parallel agents touching overlapping files will
produce them. Resolution rules:

- **Interface files** (shared types, config schemas, API contracts): take the
  union of both changes unless they directly contradict. If they contradict,
  the workstream that owns that interface wins.
- **Implementation files**: each agent owns its files. If agents drifted into
  each others territory, that is a file ownership violation (caught in Step 2).
- **Lock files** (package-lock.json, requirements.txt): regenerate from source
  rather than merging manually.

After resolving each conflict, run a quick smoke check before the next merge:

```bash
# language-dependent; use whatever confirms the project parses and starts
npm run build        # or: python -m py_compile src/
```

### 1.4 Verify the combined result compiles and passes a basic smoke test

```bash
# Run the cheapest test that confirms the integration is not broken
npm test -- --bail   # or: pytest -x -q
```

Exit criteria: the integration branch builds and the smoke test passes. If it
does not, stop here and debug before continuing. A broken integration baseline
makes every subsequent step unreliable.

---

## Step 2: Review

A final human-readable review pass across all changes. The goal is to catch
what automated tools miss: missing intent, misaligned ownership, and
incomplete work.

### 2.1 File ownership audit

Each agent should have touched only the files in its assigned scope. Generate
a per-file, per-branch diff to verify:

```bash
git log --name-only --no-merges integrate/<sprint-slug> ^main | sort | uniq -c | sort -rn
```

Files touched by more than one workstream are not automatically a problem, but
each one deserves a second look. Flag any file where both agents made
substantive (not just formatting) changes to the same lines.

### 2.2 Completeness check

Walk the original sprint task list and confirm each item has a corresponding
implementation:

```
[ ] Each planned feature or fix has code that addresses it
[ ] No task was logged as "complete" without a corresponding commit
[ ] Stub functions or placeholder classes have been filled in
```

### 2.3 Leftover markers

Search for markers that agents use when they defer work:

```bash
grep -rn "TODO\|FIXME\|HACK\|XXX\|PLACEHOLDER\|NOT IMPLEMENTED" --include="*.ts" --include="*.py" --include="*.js" .
```

Each hit needs a decision: fix it now, or log it as a deferred item (see the
Deferred Items section below). Do not ship with unmarked stubs.

### 2.4 Test coverage gaps

For each new module or function added during the sprint, confirm a test exists:

```bash
# Example for Python projects
pytest --co -q | grep "no tests ran"

# Example for TypeScript projects
npx jest --listTests
```

A gap is not always a blocker, but it must be a conscious choice. Either add
the test or log a deferred item explaining why coverage was intentionally
skipped.

---

## Step 3: Quality Gate

All checks must pass before creating the PR. This is a hard gate.

### 3.1 Full test suite

```bash
# Run the complete test suite, not just the smoke test
pytest -q             # Python
npm test              # Node
cargo test            # Rust
go test ./...         # Go
```

Exit criteria: zero failures. Skipped tests are acceptable only if they were
already skipped before the sprint.

### 3.2 Linter and formatter

```bash
# Run whatever the project uses
npx eslint . --max-warnings 0
ruff check .
golangci-lint run
```

Exit criteria: zero warnings that block merge.

### 3.3 Type checker

```bash
npx tsc --noEmit          # TypeScript
mypy src/                 # Python
```

Exit criteria: zero type errors.

### 3.4 Security scan

Run at minimum a secrets scan and a dependency vulnerability check:

```bash
# Secrets
git secrets --scan
# or: trufflehog filesystem .

# Dependency vulnerabilities
npm audit --audit-level=high
pip-audit
```

Exit criteria: no high or critical severity findings. Medium severity findings
must be acknowledged (comment explaining why they are acceptable to ship).

### 3.5 Handle gate failures

| Failure type          | Action                                                    |
|-----------------------|-----------------------------------------------------------|
| Test failures         | Fix forward. Identify which workstream introduced the     |
|                       | failure and apply a targeted fix. Commit and re-run.      |
| Lint/type errors      | Fix forward. These are mechanical; do not revert.         |
| Security: secrets     | Remove the secret immediately. Rotate the credential.     |
|                       | Do not ship until the secret is purged from history.      |
| Security: dependency  | Upgrade the dependency or add a suppression with a        |
|                       | comment. Confirm with the project owner before shipping.  |
| Broken integration    | If a workstream cannot be fixed quickly, revert it from   |
|                       | the integration branch and ship the rest. Log the         |
|                       | reverted workstream as a deferred item.                   |

**Fix forward vs. revert a workstream.** Revert a whole workstream only when
the failure is fundamental to that workstream's design (not a typo or missing
import) and a fix would take longer than the value delivered by shipping the
other workstreams now. In all other cases, fix forward.

To revert a specific workstream from the integration branch:

```bash
git revert -n $(git log --merges --first-parent --oneline integrate/<sprint-slug> ^main | grep <workstream-branch> | awk '{print $1}')
git commit -m "revert: remove <workstream> from integration pending rework"
```

---

## Step 4: Ship

### 4.1 Write the PR description

The PR description must cover every workstream. Use this structure:

```
## Summary

Brief statement of what the sprint delivered as a whole.

## Workstreams

### <Workstream 1 name>
- What it changed and why
- Key files modified

### <Workstream 2 name>
- What it changed and why
- Key files modified

## Testing

How the combined result was validated (which suite, what passed).

## Deferred Items

List any items intentionally skipped. Link to follow-up tickets if they exist.
```

### 4.2 Create the PR

```bash
git push origin integrate/<sprint-slug>
gh pr create \
  --title "<sprint-slug>: <one-line summary>" \
  --body-file /tmp/pr-body.md \
  --draft
```

Open as a draft first. Review the rendered description before marking it ready
for review.

### 4.3 Human approval

Tag at least one human reviewer. Do not merge without explicit approval. The
reviewer should confirm:

- The PR description accurately represents the changes
- No workstream was silently dropped without explanation
- Deferred items are logged somewhere actionable

### 4.4 Merge

After approval:

```bash
gh pr merge <pr-number> --squash   # or --merge, per your project convention
```

Delete the integration branch and all workstream branches after merge.

---

## Deferred Items

Items intentionally skipped during the sprint are not failures; they are
decisions. Capture each one so it does not silently disappear.

### What qualifies as deferred

- Test coverage gaps accepted during the sprint
- Workarounds added with intent to harden later
- Features scoped out mid-sprint due to complexity
- Known issues that are out of scope for this sprint

### How to log them

Create a deferred log entry for each item. At minimum, record:

```
[DEFERRED] <short description>
Context: why this was skipped during the sprint
Risk: what breaks or degrades if this is never addressed
Follow-up: where the ticket or tracking item lives
```

Append these to a sprint notes file, a project TODO doc, or directly into your
issue tracker as new tickets. The format does not matter; the requirement is
that they exist somewhere the team will actually look.

### Temporary workarounds

If an agent left a workaround tagged with a cleanup target (a comment like
`# TEMPORARY: replace with X after Y is merged`), escalate that to a follow-up
ticket immediately. Temporary workarounds that are not tracked become permanent.

---

## Retrospective

Capture lessons learned before context evaporates. This takes 15 minutes and
prevents the same problems from recurring next sprint.

### What to capture

Answer each question once, briefly:

1. **What worked?** Which agents, patterns, or file assignments went smoothly?
2. **What broke?** What caused the most rework during consolidation or review?
3. **What surprised us?** Anything the sprint plan did not anticipate?
4. **What would we change?** One concrete change to the agent setup or task
   breakdown for next time.

### Where to store it

Save the retrospective as a short markdown file alongside the sprint artifacts:

```
.ai/sprints/<sprint-slug>/retro.md
```

Or append a summary to your project's changelog. The goal is that someone
planning the next sprint can read it in under 5 minutes and adjust.

---

## Cleanup

After the PR merges, clean up sprint artifacts to keep the workspace tidy.

### Remove worktrees (if Worktree Sprint was used)

```bash
# List all worktrees
git worktree list

# Remove each sprint worktree
git worktree remove <path-to-worktree>

# Prune stale references
git worktree prune
```

Do not remove a worktree before confirming its branch is merged and you have
copied any gitignored content you want to keep (local configs, scratch files).

### Delete merged branches

```bash
# Local
git branch -d <workstream-branch-1>
git branch -d <workstream-branch-2>
git branch -d integrate/<sprint-slug>

# Remote
git push origin --delete <workstream-branch-1>
git push origin --delete integrate/<sprint-slug>
```

### Archive sprint artifacts

Move the sprint working directory to an archive location:

```bash
mv .ai/sprints/<sprint-slug> .ai/sprints/archive/<sprint-slug>
```

Keep the archive for at least one sprint cycle in case a deferred item needs
context from the original plan.

### Update tracking systems

- Mark all sprint tasks as complete in your issue tracker
- Close any planning documents that were scoped to this sprint
- Update the project README or changelog if the sprint changed user-facing
  behavior

---

## Full Checklist

Copy this checklist into your sprint notes and check off each item.

```
SPRINT COMPLETION GATE
[ ] All agent tasks complete
[ ] All agents committed and pushed
[ ] All agents shut down

STEP 1: CONSOLIDATION
[ ] Integration branch created from main
[ ] All workstream branches merged (no-ff)
[ ] Conflicts resolved
[ ] Smoke test passes on integration branch

STEP 2: REVIEW
[ ] File ownership audit complete (no unexpected overlaps)
[ ] All sprint tasks have corresponding implementations
[ ] TODO/FIXME sweep done (each hit is fix or logged deferred)
[ ] Test coverage gaps assessed (gaps are logged deferred or covered)

STEP 3: QUALITY GATE
[ ] Full test suite passes
[ ] Linter passes (zero blocking warnings)
[ ] Type checker passes
[ ] Security scan passes (no high/critical)

STEP 4: SHIP
[ ] PR description covers all workstreams
[ ] PR opened as draft, description reviewed
[ ] PR marked ready for review
[ ] Human approval received
[ ] PR merged

DEFERRED ITEMS
[ ] All skipped items logged with context and risk
[ ] Temporary workarounds escalated to follow-up tickets

RETROSPECTIVE
[ ] What worked, broke, surprised, and would change: all captured
[ ] Retro saved to .ai/sprints/<slug>/retro.md

CLEANUP
[ ] Worktrees removed (if applicable)
[ ] Merged branches deleted (local and remote)
[ ] Sprint artifacts archived
[ ] Issue tracker updated
```

---

## Related

- [Pattern Selection Decision Tree](decision-tree.md)
- [Worktree Sprint](../patterns/worktree-sprint.md)
- [Hive Mind 2-Tier](../patterns/hive-mind-2tier.md)
- [Hive Mind 3-Tier](../patterns/hive-mind-3tier.md)
- [Worker Swarm](../patterns/worker-swarm.md)

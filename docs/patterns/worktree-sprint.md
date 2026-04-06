---
title: Worktree Sprint
description: An infrastructure layer that uses git worktrees to give each workstream its own isolated working directory and branch, preventing file conflicts when multiple agents work in parallel on the same repository.
---

# Worktree Sprint

Worktree Sprint is not a coordination pattern. It is an isolation layer that sits
underneath any pattern (Worker Swarm, Hive Mind, or even a manual multi-agent run)
and solves one specific problem: multiple agents touching the same repository at the
same time destroy each other's work.

The solution is git worktrees. Each workstream gets its own directory on disk with
its own branch. Agents never share a working directory. Conflicts surface explicitly
at merge time instead of silently corrupting in-progress work.

---

## The Problem It Solves

When two agents run concurrently in the same git checkout, they race on every file
they touch. Agent A reads a file, Agent B edits and commits that same file, then
Agent A overwrites B's version. The result is lost work with no error message.

Worktree Sprint eliminates this by giving each agent its own isolated workspace.
Agents write freely within their own worktree. Integration happens once, deliberately,
at a defined merge gate.

---

## Git Worktrees: A Brief Primer

A git worktree is a secondary working directory linked to the same repository. One
repository can have multiple worktrees checked out simultaneously, each on a
different branch.

```bash
# Standard checkout (only one working directory)
/repo/          (branch: main)

# After adding two worktrees
/repo/          (branch: sprint/auth-refactor)
/repo/.worktrees/auth-refactor--api-routes/   (branch: sprint/auth-refactor--api-routes)
/repo/.worktrees/auth-refactor--middleware/   (branch: sprint/auth-refactor--middleware)
```

Each worktree shares the same `.git` database (history, objects, refs) but has its
own index, HEAD pointer, and working files. Changes in one worktree do not appear
in another until you explicitly merge.

Key commands:

```bash
git worktree add <path> <branch>    # create a new worktree on an existing branch
git worktree add <path> -b <branch> # create a new worktree and a new branch
git worktree list                   # show all worktrees
git worktree remove <path>          # remove a worktree (branch is preserved)
git worktree prune                  # remove stale refs for deleted worktrees
```

---

## Branch Architecture

Worktree Sprint uses a two-level branch hierarchy:

```
main
 |
 +-- sprint/<slug>                         (the sprint branch; receives all merges)
      |
      +-- sprint/<slug>--<workstream-a>    (workstream branch)
      +-- sprint/<slug>--<workstream-b>    (workstream branch)
      +-- sprint/<slug>--<workstream-c>    (workstream branch)
```

The double-dash separator (`--`) between slug and workstream ID is required because
git prohibits having both `sprint/auth-refactor` and `sprint/auth-refactor/api-routes`
as branch names (the slash creates a ref hierarchy conflict).

Example:

```
sprint/auth-refactor
sprint/auth-refactor--api-routes
sprint/auth-refactor--middleware
sprint/auth-refactor--tests
```

Each workstream branch maps to one worktree on disk:

```
.worktrees/
  auth-refactor--api-routes/
  auth-refactor--middleware/
  auth-refactor--tests/
```

---

## The Lifecycle

```
INIT  -->  WORK  -->  MERGE  -->  SYNC  -->  FINAL  -->  REVIEW
```

### Phase 1: INIT

Create the sprint branch from your base branch, then create one worktree per
workstream:

```bash
# Create sprint branch from main
git checkout main
git checkout -b sprint/auth-refactor

# Create workstream branches and worktrees
git worktree add .worktrees/auth-refactor--api-routes -b sprint/auth-refactor--api-routes
git worktree add .worktrees/auth-refactor--middleware  -b sprint/auth-refactor--middleware
git worktree add .worktrees/auth-refactor--tests       -b sprint/auth-refactor--tests
```

Record the worktrees in a manifest so you can drive the merge and cleanup phases
programmatically:

```json
{
  "sprint_branch": "sprint/auth-refactor",
  "base_branch": "main",
  "workstreams": [
    {
      "id": "api-routes",
      "branch": "sprint/auth-refactor--api-routes",
      "path": ".worktrees/auth-refactor--api-routes",
      "status": "active"
    },
    {
      "id": "middleware",
      "branch": "sprint/auth-refactor--middleware",
      "path": ".worktrees/auth-refactor--middleware",
      "status": "active"
    }
  ]
}
```

### Phase 2: WORK

Agents operate exclusively within their assigned worktree. The orchestrator (or
human operator) stays on the sprint branch in the main checkout.

- Each agent receives the absolute path to its worktree and its branch name.
- Agents commit to their own branch. They never touch the sprint branch directly.
- Independent workstreams run in parallel. Only dependencies serialize work.

### Phase 3: MERGE (Phase Gate)

Merge each workstream branch into the sprint branch sequentially:

```bash
git checkout sprint/auth-refactor

# Merge each workstream in turn
git merge sprint/auth-refactor--api-routes
git merge sprint/auth-refactor--middleware
git merge sprint/auth-refactor--tests
```

Sequential merging is intentional. Each merge surfaces conflicts one at a time
against a known, stable base. Parallel merges obscure which workstream introduced
a conflict.

If a merge conflicts: abort (`git merge --abort`), resolve the overlap (see
Conflict Resolution below), then rerun the merge.

### Phase 4: SYNC

Pull the merged sprint branch back into each worktree so agents have a unified
codebase for any follow-on work:

```bash
# In each worktree
git merge sprint/auth-refactor
```

Skip SYNC if the sprint is complete after the first MERGE pass.

### Phase 5: FINAL and REVIEW

Remove the worktrees and workstream branches. The sprint branch is the deliverable.

```bash
git worktree remove .worktrees/auth-refactor--api-routes
git worktree remove .worktrees/auth-refactor--middleware
git worktree remove .worktrees/auth-refactor--tests
git worktree prune

# Delete workstream branches (sprint branch is preserved)
git branch -d sprint/auth-refactor--api-routes
git branch -d sprint/auth-refactor--middleware
git branch -d sprint/auth-refactor--tests
```

The sprint branch now holds all the work. Open a pull request from it or merge it
to the target branch after human review.

---

## Conflict Resolution

Conflicts fall into four categories:

| When | What Happens | Who Resolves |
|------|-------------|--------------|
| Phase gate merge | merge aborts; reports which branch conflicted | Orchestrator or designated lead |
| Sync into worktree | only that worktree's merge aborts; others continue | Lead in their worktree |
| Final merge to main | merge exits with error; cleanup blocked | Orchestrator |
| Two sprint trees targeting main | second tree's final rebase surfaces it | Orchestrator after rebase |

**Prevention is better than resolution.** When planning workstreams, assign each
shared file to exactly one workstream. If two workstreams must both touch a shared
file (a config file, a types file, an index barrel), coordinate in one of these ways:

- One workstream owns the file and the other sends it a PR-style review comment
  before committing.
- The orchestrator handles the shared file in a separate commit on the sprint branch
  after all workstreams merge.
- The shared file changes are deferred to a follow-on cleanup workstream that runs
  after the parallel phase completes.

---

## Cleanup

After the sprint branch has been merged to its target:

```bash
# Remove all worktrees
git worktree remove <path> --force   # --force if worktree has untracked files
git worktree prune

# Delete sprint branch
git branch -d sprint/auth-refactor
git push origin --delete sprint/auth-refactor  # if pushed to remote
```

Safety checks to include in any automation:

- Never `rm -rf` a worktree path without first confirming it is inside your
  designated worktree base directory (resolve symlinks with `pwd -P`).
- Archive the manifest (rename to `manifest.done.json`) rather than deleting it.
  It is useful for post-sprint inspection.
- Only delete the sprint branch after confirming its commits are reachable from the
  target branch (`git branch --merged main` should include the sprint branch).

---

## Composing with Patterns

Worktree Sprint is an isolation layer, not a coordination pattern. You choose a
coordination pattern per workstream independently of the infrastructure layer.

**Worker Swarm in worktrees**

The most common combination. The orchestrator stays on the sprint branch. Each
lead agent runs in its own worktree. Bee agents share their lead's worktree (or
get their own if they will touch overlapping files within the workstream).

```
Orchestrator (sprint branch, main checkout)
  |
  +-- Lead A (worktree: auth-refactor--api-routes)
  |     +-- Bee A1 (same worktree, non-overlapping files)
  |
  +-- Lead B (worktree: auth-refactor--middleware)
        +-- Bee B1 (same worktree, non-overlapping files)
```

**Hive Mind in worktrees**

For very large sprints, a Hive Mind orchestrator can manage the sprint-level
coordination while each cell operates in an isolated worktree. The Hive Mind
task list replaces the manifest as the source of truth for workstream status.

**Patchwork in worktrees**

Rarely needed. If a single-agent workstream is short enough for Patchwork, it
probably does not need worktree isolation. Use Patchwork directly on the sprint
branch instead.

**Manual multi-agent without a coordination pattern**

You can use Worktree Sprint without any formal coordination pattern. Spawn agents
directly into their worktrees with task descriptions and let them work. The merge
phase provides the integration point regardless of how the agents were coordinated.

---

## Claude Code Usage

In Claude Code, pass the worktree path and branch to each agent via the Task tool:

```
Run in directory: /path/to/.worktrees/auth-refactor--api-routes
Branch: sprint/auth-refactor--api-routes
Task: [your workstream task description]
```

Some versions of the Agent tool support an `isolation: "worktree"` hint. When
available, it creates a worktree automatically and passes the path to the sub-agent.
When not available, set up worktrees manually with the INIT commands above and
reference the absolute paths in your spawn prompts.

Always give agents their absolute worktree path. Relative paths break when the
agent changes directories during its run.

---

## Codex Usage

In Codex, use the terminal session to set up worktrees before spawning agents.
Pass the worktree path explicitly in the task description:

```
Your working directory for this task is:
  /path/to/.worktrees/auth-refactor--api-routes

Your branch is:
  sprint/auth-refactor--api-routes

Do not commit to any other branch. Do not modify files outside your working directory.
```

The explicit boundary instruction matters. Codex agents working in long-horizon
loops can drift outside their assigned scope if the boundary is not stated clearly.

---

## When NOT to Use It

Worktree Sprint adds overhead: branch creation, worktree setup, a merge phase, and
a cleanup phase. This overhead is not justified in several cases:

| Scenario | Use Instead |
|----------|-------------|
| Single workstream (no parallelism) | Branch directly, no worktrees needed |
| Small task under 10 changes | Patchwork on your current branch |
| Workstreams touch non-overlapping files | Any pattern without worktrees is fine; file conflicts are impossible anyway |
| One-off investigation with no writes | No branch infrastructure needed |
| Short parallel run where agents can coordinate by reading commits | A single shared branch with sequential commits is simpler |

The decision point: will two or more agents write to the same repository
simultaneously? If yes, use Worktree Sprint. If no, skip it.

---

## Failure Modes

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Merge conflict at phase gate | merge aborts and reports the conflicting file | Resolve manually, rerun the merge |
| Worktree directory deleted manually | `git worktree list` shows it as prunable | Rerun `git worktree add` with the same path and branch (idempotent) |
| Agent commits to wrong branch | `git log` on sprint branch shows unexpected commits | Cherry-pick the commits to the correct branch, reset the wrong branch |
| Stale worktree refs after crash | `git worktree list` shows entries with no directory | `git worktree prune` clears them |
| Cleanup fails with "worktree is dirty" | `git worktree remove` exits nonzero | Inspect the worktree for uncommitted changes before using `--force` |

---

## Example: Three-Workstream Auth Refactor

**Setup**

```bash
git checkout main
git checkout -b sprint/auth-refactor
git worktree add .worktrees/auth-refactor--api-routes  -b sprint/auth-refactor--api-routes
git worktree add .worktrees/auth-refactor--middleware   -b sprint/auth-refactor--middleware
git worktree add .worktrees/auth-refactor--tests        -b sprint/auth-refactor--tests
```

**Assign workstreams**

- api-routes: update route handlers to use new auth middleware signature
- middleware: implement the new auth middleware
- tests: write integration tests covering the new flow

Note: middleware must land before api-routes can be fully validated. The merge
order at the phase gate handles this: merge middleware first, then api-routes.

**Merge**

```bash
git checkout sprint/auth-refactor
git merge sprint/auth-refactor--middleware  # middleware lands first
git merge sprint/auth-refactor--api-routes  # can now validate against actual middleware
git merge sprint/auth-refactor--tests
```

**Cleanup**

```bash
git worktree remove .worktrees/auth-refactor--api-routes
git worktree remove .worktrees/auth-refactor--middleware
git worktrees remove .worktrees/auth-refactor--tests
git worktree prune
git branch -d sprint/auth-refactor--api-routes sprint/auth-refactor--middleware sprint/auth-refactor--tests
```

The sprint branch `sprint/auth-refactor` is now ready for review or a pull request.

---

## Related

- [Worker Swarm](./worker-swarm.md): the coordination pattern most commonly composed with Worktree Sprint
- [Hive Mind 2-Tier](./hive-mind-2tier.md): single-workstream coordination with worktree isolation
- [Hive Mind 3-Tier](./hive-mind-3tier.md): multi-workstream coordination that benefits most from worktree isolation
- [Overview](./overview.md): decision matrix for choosing between all patterns

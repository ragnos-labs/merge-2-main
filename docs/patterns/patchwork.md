---
title: Patchwork
description: The simplest pattern. One agent, no sub-agents, no coordination overhead. Use it for mechanical fixes under 10 changes.
---

# Patchwork

Patchwork is the baseline pattern: a single agent completes all work directly using
its available tools. No sub-agents. No delegation. No coordination layer.

If the task is small and mechanical, use Patchwork. Everything else is overhead.

---

## When to Use It

Use Patchwork when all of the following are true:

- Fewer than 10 discrete changes
- You already know which files need to change (no discovery phase needed)
- Changes are mechanical: rename, replace, delete, reorder, reformat
- No shared state or interleaved writes across files
- A single agent can hold the full context of the work in one pass

Examples that fit:

- Rename a variable across 5 files
- Fix 8 lint errors flagged by a linter
- Update 3 config values after an API version bump
- Remove a deprecated import from 4 modules
- Reorder fields in a schema to match a new convention
- Swap a constant value referenced in 6 places

---

## How It Works

One agent. Direct tool use. No delegation.

```
Agent
  |
  +-- Read file A
  +-- Edit file A
  +-- Read file B
  +-- Edit file B
  +-- Commit changes
```

The agent reads the relevant files, makes the edits, and commits. There is no
manifest, no task list, no sub-agent spawning. The agent completes the work in
the current session using whatever tools are available (Read, Edit, Bash for git).

**TDD note**: If you are fixing a bug (not just reformatting), write the failing
test first. Mechanical refactors where existing tests already cover the behavior
can skip this. When in doubt, write the test.

---

## Claude Code Usage

In Claude Code, Patchwork is the default mode. The main agent uses the Read,
Edit, and Bash tools directly. No Task tool invocations needed.

Model guidance:

- Low effort: trivial edits with no ambiguity (literal find-and-replace, constant swaps)
- Medium effort: edits that require reading context to get right (rename with call-site analysis)
- High effort: edits that involve judgment (refactor that preserves observable behavior)

Match the effort level to the complexity of the judgment required, not to the
number of files touched.

---

## Codex Usage

In Codex, Patchwork is also the natural default. The agent works directly in the
terminal session. No `spawn_agent` calls needed.

Use the Codex IDE for paste-based context when the change spans many files and
you want the agent to see all relevant code at once before editing.

---

## When to Upgrade to Worker Swarm

Patchwork has outgrown its purpose when any of these signs appear:

| Sign | Upgrade to |
|------|-----------|
| 10 or more changes across unrelated files | Worker Swarm |
| You do not yet know what needs changing (need a discovery pass first) | Research Swarm |
| Changes in different files are logically independent and could run in parallel | Worker Swarm |
| The work requires judgment on some files but is mechanical on others | Worker Swarm |
| A single agent pass would be too long to review in one commit | Worker Swarm |

The clearest signal: if you find yourself mentally partitioning the work into
"this half" and "that half," spawn a Worker Swarm. Two agents on two non-overlapping
file sets finish faster and produce cleaner commits than one agent serializing
both halves.

---

## Example Scenarios

**Rename a function across 5 files**

The function `get_user_data` is being renamed to `fetch_user_profile`. It appears
in 5 files. Patchwork: read each file, make the edit, commit. No coordination needed.

**Fix lint errors after a rule change**

A linter run produces 7 errors across 4 files. All are the same violation type.
Patchwork: read each flagged file, apply the fix, commit. One agent, one pass.

**Update config values after a dependency upgrade**

A library upgrade changes 3 configuration key names. They appear in 2 config files
and 1 test fixture. Patchwork: update all 3 locations, verify the tests still pass,
commit.

**Remove a deprecated import**

A module was deprecated and removed. Its import appears in 6 files, none of which
use anything else from it. Patchwork: remove the import line from each file, commit.

---

## Limits

Patchwork does not scale. It is intentionally constrained:

- One agent means one context window. Large diffs degrade output quality.
- Sequential edits mean no parallelism. A 20-file rename takes longer than it needs to.
- No recovery layer. If the agent makes a mistake mid-run, there is no second agent to catch it.

For anything above 10 changes or involving files you have not yet identified, move
to a more capable pattern.

---

## Related Patterns

- [Worker Swarm](./worker-swarm.md): lead-directed parallel agents for batch work you know how to decompose
- [Research Swarm](./research-swarm.md): scan-driven discovery when you do not yet know what needs fixing
- [Overview](./overview.md): decision matrix for choosing between all patterns

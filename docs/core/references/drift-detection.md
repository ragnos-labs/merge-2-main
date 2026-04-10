---
title: Drift Detection
description: How to detect and correct the three types of agent drift in multi-agent sprints: scope drift, goal drift, and pattern drift.
---

Drift is what happens when an agent's behavior diverges from its assignment
during a sprint. It is not a sign of broken tooling or a bad model. It is a
predictable consequence of giving an agent a long-horizon task with only
upfront context. Drift accumulates gradually and is rarely obvious until
consolidation, when you discover that two agents modified the same file,
or that a workstream "completed" its task but produced the wrong thing.

This reference covers the three main types of drift, how to spot each one
early, how to correct it once it has occurred, and how to structure sprints
to reduce its frequency.

---

## Type 1: Scope Drift

Scope drift occurs when an agent expands beyond the files, modules, or
responsibilities defined in its workstream assignment.

### Why it happens

Agents are trained to be helpful and thorough. When an agent encounters
a related problem while completing its assigned task, it will often fix
it. From the agent's perspective this is good behavior. From the sprint's
perspective it is a file ownership violation that can corrupt another
workstream's work.

### Detection signals

**During the sprint:**
- An agent's commit touches files not listed in its scope definition
- An agent reports completing tasks not in its original task list
- An agent's progress updates reference modules it was not assigned

**At consolidation:**
- Merge conflicts in files assigned to a different workstream
- Duplicate implementations of the same function in two workstreams
- A workstream's "completed" task is missing because a different agent
  silently absorbed it

**In the diff:**
```bash
# Find all files touched by a specific branch
git log --name-only --no-merges <branch> ^main | sort -u

# Compare against the expected scope from the sprint plan
# Any file not in the expected list is a scope violation
```

### Correction actions

1. Identify the scope boundary violation: which file or module was touched
   outside assignment.
2. Determine whether the change is valid. If the agent fixed a real bug in
   another workstream's territory, the fix may be correct but needs to move
   to the right owner. Cherry-pick the commit to the correct branch, then
   revert it from the violating branch.
3. If the change is redundant with work the assigned workstream was already
   doing, discard the drifted version and let the owner's implementation
   stand.
4. Document the violation in the retrospective under "What Did Not Work."

### Prevention strategies

- List the exact file paths each workstream is allowed to touch. File-pattern
  rules work well: `src/payments/**`, `tests/payments/**`.
- Add an explicit "off-limits" list for high-contention files (shared
  types, config, database schemas). State: "If you need to change this
  file, stop and report a blocker; do not modify it yourself."
- Use the checkpoint protocol to review diffs mid-sprint rather than
  only at consolidation. Scope drift caught at checkpoint 1 takes 10
  minutes to fix. Scope drift caught at consolidation takes hours.

---

## Type 2: Goal Drift

Goal drift occurs when an agent loses sight of the acceptance criteria and
produces technically correct work that does not satisfy the sprint's intent.

### Why it happens

Agents optimize for what is measurable in the immediate context. As a task
grows longer, the acceptance criteria defined at the top of the prompt become
less salient than the immediate sub-problem the agent is solving. The agent
produces something that compiles, passes its own tests, and looks finished
but diverges from what the sprint actually needed.

Goal drift is more insidious than scope drift because the agent will often
report success with genuine confidence. There is no error, no conflict, no
obvious signal that something went wrong.

### Detection signals

**During the sprint:**
- An agent's status updates stop referencing the original acceptance criteria
- An agent reports "done" faster than the task complexity would suggest
- An agent asks no clarifying questions on a task that contains ambiguity

**At review:**
- The implementation passes its own tests but fails an integration test against
  adjacent workstreams
- The delivered interface is correct in shape but wrong in semantics (e.g., a
  function that parses the right format but applies the wrong transformation)
- The agent completed the literal instructions but missed the intent (e.g.,
  "add pagination" was implemented as client-side slicing instead of server-side
  query limits)

**Diagnostic question to ask:**
  "If I gave this implementation to a user with only the original acceptance
  criteria, would they say it is correct?"

### Correction actions

1. Return to the acceptance criteria from the sprint plan. Compare each
   criterion against the actual output, one by one.
2. Identify where the divergence started. Usually it is one ambiguous criterion
   the agent resolved in the wrong direction.
3. Feed the agent a correction prompt that restates the specific criterion it
   missed, provides an example of the correct behavior, and asks it to fix only
   that gap.
4. Do not ask the agent to "review everything." Agents given broad correction
   prompts will make additional unasked-for changes. Be surgical.

### Prevention strategies

- Write acceptance criteria as observable behaviors, not descriptions of
  implementation. "Returns a 429 status with a Retry-After header when the rate
  limit is exceeded" is better than "handles rate limiting correctly."
- Include at least one concrete input/output example per acceptance criterion.
  Examples anchor the agent more reliably than abstract descriptions.
- Restate the most important acceptance criteria at the end of the prompt, not
  only at the top. Agents weight recent context more heavily on long tasks.
- Use TDD contracts. A test that was written to match the acceptance criteria
  cannot lie about whether the implementation matches. See
  [TDD Contracts Template](tdd-contracts-template.md).

---

## Type 3: Pattern Drift

Pattern drift occurs when an agent changes its coordination approach mid-sprint:
switching from the assigned pattern, bypassing phase gates, or unilaterally
deciding to take on orchestrator responsibilities.

### Why it happens

Agents that encounter friction with the assigned pattern will sometimes try to
work around it. A worker agent that cannot get a response from the orchestrator
may start making coordination decisions itself. A research agent may start
writing implementation code when it believes the research phase is "obviously
done." An agent that was given only one task may start pulling in adjacent tasks
from the shared task list without being asked.

Pattern drift often looks like initiative. The agent is trying to help. But it
undermines the coordination guarantees that the pattern provides, and it makes
the sprint's state unpredictable for the orchestrator and for other agents.

### Detection signals

**During the sprint:**
- A worker agent sends messages to other agents directly instead of through the
  orchestrator
- A worker agent marks tasks complete that it was not assigned
- A research agent produces implementation artifacts (code, schema changes)
  without being promoted to an implementation role
- An agent advances to a new phase without an explicit gate signal from the
  orchestrator
- The orchestrator reports phase completion but some agents are still running
  tasks from the previous phase

**At consolidation:**
- Commits that belong to multiple phases intermixed on a single branch
- Work that was supposed to be gated behind a review appears in the initial
  commit wave
- Two agents produced parallel implementations of the same component because
  each thought the other was not handling it

### Correction actions

1. Stop the drifting agent. Do not let it continue accumulating work that may
   conflict with the correct flow.
2. Assess the state: what has already been committed, what is still in progress,
   what was supposed to happen next in the correct pattern.
3. If the agent produced valid work out of sequence, determine whether it can be
   merged into the correct phase retroactively, or whether it needs to be held
   until the correct gate is reached.
4. Restart the agent with an explicit prompt that restates its role, the current
   phase, and what it is and is not allowed to do without orchestrator approval.

### Prevention strategies

- Include a role definition at the top of every agent prompt. State explicitly:
  "You are a worker agent. You do not advance phases, message other agents, or
  take on tasks not assigned to you."
- Define phase gates as conditions, not time-based signals. "Phase 2 begins when
  the orchestrator sends you a message saying 'PHASE_2_START'." This makes it
  impossible for an agent to accidentally advance phases.
- For Hive Mind patterns, the orchestrator should be the only agent with write
  access to the task list. Workers report completion; the orchestrator updates
  the list.
- Keep worker task lists short. An agent with a three-task list is less likely
  to drift than one with a fifteen-task list. Decompose large workstreams further
  if pattern drift is recurring.

---

## Drift Summary Table

```
+----------------+-----------------------------+---------------------------+
| Type           | Primary signal              | Root cause                |
+----------------+-----------------------------+---------------------------+
| Scope drift    | Files outside assignment    | Agent fixes related       |
|                | touched at consolidation    | issues it encounters      |
+----------------+-----------------------------+---------------------------+
| Goal drift     | Implementation correct but  | Acceptance criteria not   |
|                | does not match intent       | salient late in the task  |
+----------------+-----------------------------+---------------------------+
| Pattern drift  | Agent takes coordination    | Agent works around        |
|                | actions not in its role     | friction in the pattern   |
+----------------+-----------------------------+---------------------------+
```

---

## Related

- [Retrospective Template](retrospective-template.md)
- [Positive Enforcement](positive-enforcement.md)
- [TDD Contracts Template](tdd-contracts-template.md)
- [Checkpoint Protocol](../guides/checkpoint-protocol.md)
- [Sprint Planning Guide](../guides/sprint-planning.md)
- [Orchestrator Prompt Template](../../templates/universal/orchestrator-prompt.md)

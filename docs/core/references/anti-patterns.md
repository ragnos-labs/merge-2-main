---
title: "Multi-Agent Anti-Patterns"
description: "Catalog of 13 universal anti-patterns that cause multi-agent runs to fail, stall, or produce unreliable output. Applies across all patterns: Patchwork, Worker Swarm, Research Swarm, Hive Mind, and Worktree Sprint."
---

# Multi-Agent Anti-Patterns

This catalog documents recurring mistakes that cause multi-agent runs to fail, stall, or
produce unreliable output. Each anti-pattern is marked with the patterns it most commonly
affects, but the underlying failure modes are universal.

Use this reference as a pre-launch checklist or a post-mortem guide when a run goes wrong.

---

## Anti-Pattern Index

```
+----+----------------------------+-----------------------------------------------+
| #  | Name                       | One-Line Summary                              |
+----+----------------------------+-----------------------------------------------+
|  1 | The Monolith Agent         | One agent doing everything alone              |
|  2 | File Collision             | Two agents editing the same file              |
|  3 | Context Stuffing           | Overloading a prompt with irrelevant detail   |
|  4 | Premature Escalation       | Wrong pattern for the task size               |
|  5 | Model Overkill             | Expensive model on mechanical work            |
|  6 | Silent Failure             | Agent fails without reporting back            |
|  7 | Scope Creep                | Agent expands beyond its assigned task        |
|  8 | Zombie Agents              | Forgotten background agents still running     |
|  9 | The Telephone Game         | Too many delegation layers distort intent     |
| 10 | Checkpoint Avoidance       | Skipping human review to move faster          |
| 11 | Freeform Everything        | No structured output; every agent differs     |
| 12 | The Everything Sprint      | Too much scope in one sprint                  |
| 13 | Merge Panic                | Waiting until the end to merge all branches   |
+----+----------------------------+-----------------------------------------------+
```

---

## 1. The Monolith Agent

**Patterns affected:** All (especially Worker Swarm, Hive Mind)

### What it looks like

One agent is given an enormous task: refactor a module, write all the tests, update all the
documentation, and verify the build. The agent works sequentially through the list, context
window fills up, and it either stalls, hallucinates later steps, or truncates output.

### Why it fails

A single agent processing many files in sequence accumulates error. Each step is built on
potentially incorrect prior output. There is no parallelism, no cross-check, and no clean
boundary at which a failure can be isolated. The context window is a finite resource; packing
it with unrelated tasks degrades performance on every task.

### What to do instead

Decompose the work first. Identify which tasks are independent and assign one agent per
non-overlapping unit of work. If one agent truly must do multiple steps, scope each step
tightly with a separate prompt and collect results before proceeding. Use Patchwork only when
the total scope is fewer than 10 mechanical changes. Anything larger belongs in a Worker Swarm
or Hive Mind.

---

## 2. File Collision

**Patterns affected:** Worker Swarm, Research Swarm, Hive Mind (all tiers)

### What it looks like

Two or more agents are assigned tasks that touch the same file. Both read the original, both
write their changes, and one silently overwrites the other. The result compiles (or does not),
but the second agent's changes are lost. Alternatively, both agents try to edit the file at
the same moment and produce a corrupted or conflicted state.

### Why it fails

Agents do not hold locks on files. Without explicit ownership rules, concurrent writes are a
race condition. The agent that commits last wins, and the loser's work vanishes without error.
This is one of the most common and hardest-to-detect failure modes because the symptom (a
file that looks fine) hides the cause (half the intended changes were discarded).

### What to do instead

Before spawning any agents, write out an explicit file ownership map. No two agents may be
assigned tasks that touch the same file in the same phase. For shared configuration or
generated files, designate one agent as the sole writer and route all other agents' outputs
through it. Use a Worktree Sprint to give each agent its own isolated branch whenever two or
more workstreams touch overlapping parts of the repository.

Reference: [../patterns/worktree-sprint.md](../patterns/worktree-sprint.md)

---

## 3. Context Stuffing

**Patterns affected:** All

### What it looks like

An agent's prompt includes the full contents of every related file, all prior conversation
history, architectural background notes, a coding style guide, and several examples "just in
case." The actual task instruction is buried in paragraph five. The agent spends most of its
token budget processing context it will never use and produces lower-quality output on the
specific task it was assigned.

### Why it fails

Every token in the prompt competes for the model's attention. Irrelevant context dilutes the
signal. Prompts that include far more context than is necessary for the task at hand produce
agents that are slower, more expensive, and less accurate. Reasoning quality peaks when the
prompt is focused.

### What to do instead

Give an agent only what it needs to complete its specific task: the files it will touch, the
acceptance criteria it must meet, and the output format it must produce. If background context
is genuinely required, summarize it in two to three sentences rather than quoting entire
documents. A focused 400-token prompt almost always outperforms a sprawling 4,000-token
prompt for the same task.

---

## 4. Premature Escalation

**Patterns affected:** Worker Swarm, Hive Mind

### What it looks like

A three-file refactor is run as a Hive Mind 3-tier operation. An orchestrator is spun up,
two leads are created, each spawns bee agents, a scratchpad is initialized per workstream,
and the nine-phase workflow is invoked. The actual code change takes 20 minutes; setup,
coordination, and teardown take two hours.

### Why it fails

More powerful patterns carry more coordination overhead. Hive Mind 3-tier is designed for
15-30 or more agents across 3 or more independent workstreams. Applying that scaffolding to
a small task introduces failure surfaces (agent miscommunication, phase-gate delays, orphaned
tasks) without any of the benefits. Cost scales with pattern complexity; so does recovery time
when something goes wrong.

### What to do instead

Use the pattern selection decision tree before spawning anything. Patchwork handles fewer than
10 mechanical changes. Worker Swarm handles directed parallel work where the lead can write
every prompt upfront. Hive Mind 2-tier handles one complex autonomous workstream. Hive Mind
3-tier is warranted only when three or more independent workstreams each need a dedicated lead.

Reference: [../guides/decision-tree.md](../guides/decision-tree.md)

---

## 5. Model Overkill

**Patterns affected:** All

### What it looks like

Every agent in a Worker Swarm, including the ones doing zero-ambiguity find-and-replace across
config files, is assigned the most capable (and most expensive) model tier at maximum effort.
The bill is 8 to 10 times larger than necessary. No improvement in output quality is visible
because the tasks did not require it.

### Why it fails

Model capability beyond what the task requires produces no benefit. Effort level is a
multiplier on cost and latency. Mechanical tasks (renaming identifiers, reformatting JSON,
updating version strings) have deterministic correct answers; a cheaper, faster model at low
effort produces identical output at a fraction of the cost. Applying maximum effort to low-
ambiguity work is pure waste.

### What to do instead

Match model tier and effort level to task complexity. Reserve the most capable tier and
maximum effort for orchestrators, security reviews, and architectural decisions. Use a standard
tier at high effort for multi-file implementation and synthesis. Use a standard tier at low
effort for simple lookups and scans. Use the cheapest tier only for completely mechanical,
zero-ambiguity tasks. Adjust effort level before switching model tier; a standard-tier model
at low effort almost always outperforms a cheap-tier model on any task that has even mild
ambiguity.

Reference: [../guides/model-selection.md](../guides/model-selection.md)

---

## 6. Silent Failure

**Patterns affected:** Worker Swarm, Research Swarm, Hive Mind (all tiers)

### What it looks like

An agent hits an error partway through its task: a file it was supposed to read does not
exist, a test it was supposed to run is broken, or a subtask is blocked by a missing
dependency. Instead of reporting the failure, the agent returns a partial result or a
cheerful "completed" message that omits the failed portion. The lead or orchestrator proceeds
under the assumption that the task succeeded.

### Why it fails

Silent failures propagate. Later agents build on incorrect or incomplete prior output. The
failure is often not discovered until integration, at which point it is expensive to trace
back to the root cause. Agents that swallow errors are more dangerous than agents that crash
loudly, because the crash is visible.

### What to do instead

Make failure reporting an explicit part of every agent's output contract. Require agents to
include a `status` field (success, partial, blocked, failed) and a `blockers` list in their
structured response. Treat any missing or ambiguous status as a failure. In Hive Mind, use the
messaging layer to surface blockers in real time rather than waiting for phase-gate review.
Design the response schema so that omitting a required field is itself a detectable failure.

---

## 7. Scope Creep

**Patterns affected:** All

### What it looks like

An agent assigned to "add input validation to the login form" also refactors the surrounding
authentication module, updates related tests it was not assigned to, renames several
variables throughout the file for clarity, and leaves a comment suggesting a larger
architectural change. The assigned task is done, but so are six unassigned tasks, some of
which conflict with work another agent is doing concurrently.

### Why it fails

Agents that expand their scope create uncoordinated changes. In a parallel run, scope
expansion is almost guaranteed to produce file collisions or logical conflicts with other
agents. Even in a single-agent run, unrequested changes complicate review and introduce
regression risk in areas that were not supposed to be touched.

### What to do instead

Scope boundaries must be explicit in the prompt, not implied. State what the agent should
NOT touch alongside what it should. Include a rule like: "Do not modify any file not listed
in your task. If you identify adjacent work that should be done, note it in your report under
'deferred observations' but do not implement it." Review agent output for changes outside the
assigned scope before accepting it.

---

## 8. Zombie Agents

**Patterns affected:** Worker Swarm, Hive Mind, Research Swarm

### What it looks like

A background agent is spawned to perform a long-running scan or analysis. The lead moves on
to other work. The agent finishes (or stalls indefinitely), but no one checks. Hours later,
the agent's output is stale or gone. In the worst case, the agent is still actively writing
to files that subsequent agents have already modified.

### Why it fails

Background agents are not self-managing. If the spawning agent does not actively collect
results, background processes become orphaned. Stale output fed into a later phase produces
incorrect downstream work. Agents that have been forgotten but are still running can corrupt
work that later agents have written, with no coordination signal to detect the conflict.

### What to do instead

For every background agent spawned, log it immediately: name, task, expected output location,
and expected completion signal. The lead must explicitly collect and validate every background
agent's output before proceeding to the next phase. In Hive Mind, the task list is the
authoritative record of in-flight work; no agent should be running without a corresponding
open task entry. Set a timeout expectation in the agent prompt so stalled agents can be
identified and terminated.

---

## 9. The Telephone Game

**Patterns affected:** Hive Mind (3-tier especially), Worker Swarm with nested delegation

### What it looks like

An orchestrator gives a high-level goal to a lead. The lead interprets it and gives a
lower-level version to a bee. The bee interprets that and produces output. By the time the
output returns to the orchestrator, the original goal has been subtly but materially changed
at each translation layer. The final deliverable is not wrong, but it is not what was asked
for either.

### Why it fails

Each delegation layer introduces interpretation variance. Natural language is ambiguous;
every summarization and re-framing adds drift. Three-tier Hive Mind has at minimum two
translation layers (orchestrator to lead, lead to bee). Without a mechanism to carry original
intent all the way through the delegation stack, the final output reflects the last agent's
interpretation, not the original specification.

### What to do instead

Pass acceptance criteria verbatim through every delegation layer. Do not paraphrase the
success condition; quote it. In Hive Mind 3-tier, the orchestrator should write acceptance
criteria as a checklist that each lead includes verbatim in bee prompts. Use structured output
schemas to lock the shape of the deliverable at every tier. Validate output against the
original criteria at each phase gate, not just at the final review.

---

## 10. Checkpoint Avoidance

**Patterns affected:** Hive Mind, Worker Swarm, Worktree Sprint

### What it looks like

A long-running run completes all implementation phases without any intermediate human review.
The first time a human sees the output is at the final merge. The output has fundamental
design issues or has gone significantly off-spec, but reverting requires undoing many hours of
agent work. The checkpoint steps were in the plan; they were skipped to move faster.

### Why it fails

Human review gates exist to catch drift before it compounds. Multi-agent runs can travel a
long distance in the wrong direction between checkpoints. The later a fundamental error is
caught, the more work must be discarded. Skipping checkpoints does not save time; it
concentrates all rework at the end of the run, when it is most expensive.

### What to do instead

Treat phase gates as non-negotiable. No agent run should span more than one phase without a
human review of that phase's output. In Hive Mind, the lead gates every phase transition and
should not proceed without explicit approval. In Worker Swarm, Phase 1 reconnaissance output
must be reviewed before Phase 2 execution begins. Checkpoint commits should be created at
each validated phase boundary so any rollback is surgical, not total.

Reference: [../guides/checkpoint-protocol.md](../guides/checkpoint-protocol.md)

---

## 11. Freeform Everything

**Patterns affected:** Worker Swarm, Research Swarm, Hive Mind

### What it looks like

A Research Swarm of 12 agents each produces findings in a different format: one writes a
Markdown summary, one writes a JSON object, one writes a bulleted list, one writes a
narrative paragraph. The lead must now parse 12 different structures to synthesize results.
This takes longer than the original scan and introduces interpretation errors.

### Why it fails

Unstructured, heterogeneous output cannot be aggregated programmatically. The lead (or the
orchestrator) becomes a manual data-cleaning step. Inconsistent output shapes make it
impossible to detect silent failures via schema validation. They also make it harder to spot
when one agent's findings contradict another's, because the discrepancy is buried in format
differences rather than visible as a value mismatch.

### What to do instead

Define a response schema for every agent role before spawning any agents. Include the schema
in every agent's prompt as a required output contract. The schema should be the minimum
necessary structure: a status field, a primary output field, and a blockers or notes field.
Validate every agent response against the schema before passing it downstream. Treat a
schema-invalid response the same as a failed response.

---

## 12. The Everything Sprint

**Patterns affected:** All, especially Hive Mind and Worktree Sprint

### What it looks like

A sprint is scoped to include a new feature, three bug fixes, a security audit, a
documentation refresh, a database migration, and a dependency upgrade. All workstreams are
run in parallel. Merge conflicts are constant. Agents assigned to the security audit surface
issues that require changes in the same files the feature agents are editing. The sprint ends
with several workstreams incomplete and an unstable integration branch.

### Why it fails

Scope and parallelism have a non-linear relationship with risk. Adding more independent
workstreams increases the probability of unexpected interactions between them. File contention
is harder to prevent when many things are changing at once. Phase gating becomes unreliable
when different workstreams are in different phases simultaneously. Recovery from a failed
everything sprint is proportionally harder because there is no clean rollback boundary.

### What to do instead

Scope each sprint to one coherent goal. If multiple independent goals need to be pursued in
parallel, run them as separate sprints on separate branches rather than as workstreams within
the same sprint. A sprint should have one primary deliverable that can be accepted or
rejected as a unit. Stretch goals are acceptable as a final phase only after the primary
deliverable has passed its phase gate.

---

## 13. Merge Panic

**Patterns affected:** Worktree Sprint, Worker Swarm, Hive Mind (3-tier)

### What it looks like

A Worktree Sprint runs four workstreams in parallel. Each workstream completes its work on
its own branch. No merges happen until all four branches are done. The team then attempts to
merge all four branches into the sprint branch simultaneously. The merge conflicts are
catastrophic: hundreds of conflicting hunks across dozens of files. Resolving them manually
takes longer than the original sprint.

### Why it fails

Merge conflicts accumulate non-linearly with branch divergence. A branch that diverges for
one phase has small, tractable conflicts. A branch that diverges for an entire sprint has
conflicts that are often logically unresolvable without understanding the intent of every
change on every branch. Waiting until everything is done before merging is the single most
reliable way to turn a successful sprint into a failed integration.

### What to do instead

Merge frequently and in sequence. In a Worktree Sprint, plan merge gates at each phase
boundary: after each phase, merge the workstreams that have completed that phase before
proceeding. Merge order should follow dependency: merge the workstream whose output others
depend on first, then sync the remaining active worktrees against the updated sprint branch
before they continue. No worktree should be allowed to diverge for more than one phase
without a merge or sync step.

Reference: [../patterns/worktree-sprint.md](../patterns/worktree-sprint.md)

---

## Summary Table

```
+----+----------------------------+---------------+------------------------------+
| #  | Name                       | Patterns      | Core Fix                     |
+----+----------------------------+---------------+------------------------------+
|  1 | The Monolith Agent         | All           | Decompose; one agent per     |
|    |                            |               | non-overlapping unit         |
+----+----------------------------+---------------+------------------------------+
|  2 | File Collision             | WS, RS, HM    | Explicit ownership map;      |
|    |                            |               | Worktree Sprint for overlap  |
+----+----------------------------+---------------+------------------------------+
|  3 | Context Stuffing           | All           | Focused prompts; summarize   |
|    |                            |               | background, don't quote it   |
+----+----------------------------+---------------+------------------------------+
|  4 | Premature Escalation       | WS, HM        | Use decision tree before     |
|    |                            |               | spawning anything            |
+----+----------------------------+---------------+------------------------------+
|  5 | Model Overkill             | All           | Match tier and effort to     |
|    |                            |               | task complexity              |
+----+----------------------------+---------------+------------------------------+
|  6 | Silent Failure             | WS, RS, HM    | Require status + blockers in |
|    |                            |               | every output schema          |
+----+----------------------------+---------------+------------------------------+
|  7 | Scope Creep                | All           | Explicit "do not touch"      |
|    |                            |               | boundaries in every prompt   |
+----+----------------------------+---------------+------------------------------+
|  8 | Zombie Agents              | WS, RS, HM    | Log every background agent;  |
|    |                            |               | collect before next phase    |
+----+----------------------------+---------------+------------------------------+
|  9 | The Telephone Game         | HM, nested WS | Pass acceptance criteria     |
|    |                            |               | verbatim through all tiers   |
+----+----------------------------+---------------+------------------------------+
| 10 | Checkpoint Avoidance       | HM, WS, WT    | Phase gates are mandatory;   |
|    |                            |               | no phase without review      |
+----+----------------------------+---------------+------------------------------+
| 11 | Freeform Everything        | WS, RS, HM    | Define response schema;      |
|    |                            |               | validate before aggregating  |
+----+----------------------------+---------------+------------------------------+
| 12 | The Everything Sprint      | All           | One sprint, one primary      |
|    |                            |               | deliverable                  |
+----+----------------------------+---------------+------------------------------+
| 13 | Merge Panic                | WT, WS, HM 3T | Merge each phase before      |
|    |                            |               | proceeding to the next       |
+----+----------------------------+---------------+------------------------------+
```

**Pattern key:** WS = Worker Swarm, RS = Research Swarm, HM = Hive Mind, WT = Worktree Sprint

---

## Further Reading

- [../patterns/overview.md](../patterns/overview.md): Pattern overview and decision matrix
- [../guides/decision-tree.md](../guides/decision-tree.md): Pattern selection in 5 questions
- [../guides/model-selection.md](../guides/model-selection.md): Model tier and effort guidance
- [../guides/checkpoint-protocol.md](../guides/checkpoint-protocol.md): Phase gate and review protocol
- [../patterns/worktree-sprint.md](../patterns/worktree-sprint.md): Worktree Sprint lifecycle
- [../patterns/worker-swarm.md](../patterns/worker-swarm.md): Worker Swarm file ownership rules
- [../patterns/hive-mind-3tier.md](../patterns/hive-mind-3tier.md): 3-tier structure and bee layer

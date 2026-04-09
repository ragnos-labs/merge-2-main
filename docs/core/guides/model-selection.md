---
title: Model Selection and Cost Optimization
description: Strategy for choosing model tiers and effort levels in multi-agent workflows, covering the sonnet-first philosophy, cost tradeoffs, token hygiene, and per-pattern defaults.
---

# Model Selection and Cost Optimization

Choosing the right model for each agent role is the single most controllable cost lever in a
multi-agent workflow. It is also the most commonly misused one. This guide covers the reasoning
system behind model selection: tiers, effort levels, escalation criteria, and per-pattern
defaults.

---

## The Standard-First Philosophy

Default to the standard tier. Only escalate when the task genuinely requires it.

This is not a cost-cutting heuristic. It reflects how these models actually perform in agentic
contexts. The standard tier is capable enough to handle the overwhelming majority of implementation,
analysis, and synthesis tasks. Reserving the most capable tier for architecture and security review
means it arrives fresh, focused, and not wasted on file scans.

The practical corollary: before escalating model tier, first try increasing the effort level of
your current model. Effort is cheaper than a tier upgrade and solves most of the same problems.

---

## Model Tiers

Three tiers cover all use cases. Exact model names vary by provider and evolve over time.
Use tier names in your prompts and documentation to stay provider-agnostic.

```
+----------------+-------------------+----------------------------+------------------+
| Tier           | Relative Cost     | Strengths                  | Escalate When    |
+----------------+-------------------+----------------------------+------------------+
| Most capable   | 3-5x standard     | Architecture, adversarial  | Security review, |
|                |                   | reasoning, ambiguous       | arch decisions,  |
|                |                   | multi-system design        | complex debug    |
+----------------+-------------------+----------------------------+------------------+
| Standard       | Baseline (1x)     | Implementation, synthesis, | Default for all  |
|                |                   | multi-file analysis,       | agents. Tune     |
|                |                   | agentic tool use           | effort first.    |
+----------------+-------------------+----------------------------+------------------+
| Fast/efficient | 0.2-0.3x standard | High-volume mechanical     | Literal renames, |
|                |                   | tasks, zero-ambiguity ops, | env toggles,     |
|                |                   | routing, classification    | batch classify   |
+----------------+-------------------+----------------------------+------------------+
```

Cost penalty relative to fast/efficient:

- Standard tier: roughly 3x input and output cost
- Most capable tier: roughly 15x input and output cost

A 10-agent swarm using all standard-tier agents costs about 3x more than an all-fast swarm. That
premium is almost always worth it: standard-tier agents produce higher first-pass quality, require
fewer retries, and need less lead intervention. The net cost including rework typically favors
standard-first.

---

## The Effort Thermostat

Standard-tier models expose a reasoning effort parameter. Think of it as a thermostat: it scales
how much internal reasoning the model applies before responding. Adjusting effort is almost always
the right first move before changing model tier.

```
+--------+---------------------------------------+------------------------------------+
| Level  | When to Use                           | Example Tasks                      |
+--------+---------------------------------------+------------------------------------+
| low    | Trivial lookups, no judgment required | File scan, config read, grep result|
|        |                                       | formatting, structural navigation  |
+--------+---------------------------------------+------------------------------------+
| medium | Moderate implementation, mild         | Multi-file change, simple synthesis|
|        | ambiguity, some judgment needed       | test generation for known patterns |
+--------+---------------------------------------+------------------------------------+
| high   | Default for most agentic work.        | Refactoring, deep analysis,        |
| (def.) | Ambiguous requirements, multi-hop     | cross-file dependency tracing,     |
|        | reasoning, complex tool use chains    | complex prompt-to-code translation |
+--------+---------------------------------------+------------------------------------+
| max    | Reserved for most-capable tier only.  | Architecture review, security      |
|        | Full reasoning capacity engaged.      | audit, adversarial threat modeling |
+--------+---------------------------------------+------------------------------------+
```

Standard tier at effort: low still outperforms fast/efficient on tasks with any ambiguity. The
3x cost premium buys confidence, not just speed. Drop effort before switching tiers; only drop
tiers when the task truly has zero ambiguity.

---

## When to Escalate to Most Capable

Escalation to the most capable tier is justified in four situations:

1. **Architecture decisions**: design choices that affect multiple systems, introduce new
   dependencies, or constrain future work in ways that are hard to reverse.

2. **Security review**: adversarial threat modeling, permission boundary analysis, authentication
   flow audits, and anything that requires reasoning about what an attacker would do.

3. **Complex multi-hop debugging**: bugs where the root cause crosses several abstraction layers,
   where the evidence is contradictory, or where every standard-tier attempt has failed to
   identify the issue.

4. **Ambiguous multi-system design**: decomposing a large feature that touches three or more
   independent subsystems where design choices in one constrain choices in others.

What does not justify escalation: recon, boilerplate, documentation, test generation for known
patterns, config changes, renaming, or anything with a clear and mechanical definition of done.
Using the most capable tier for those tasks costs 15x more with no quality benefit.

---

## When to Use Fast/Efficient

Fast/efficient tier agents earn their keep on a specific class of task. Outside that class they
are a false economy.

Use fast/efficient when ALL of the following are true:

- The task definition is completely unambiguous (no judgment required)
- The output format is fully specified in the prompt
- A wrong answer is immediately detectable without deeper analysis
- Retry cost is low (the fix is trivial if the agent makes an error)

Canonical fast/efficient tasks:

- Literal find-and-replace across files
- Renaming a single variable or constant codebase-wide
- Toggling an environment flag or config value
- Converting a list of items from one format to another (CSV to JSON, etc.)
- Counting occurrences or checking for the presence of a pattern
- High-volume batch classification where each item is evaluated independently (100+ items)
- Routing or dispatching: reading a selector and returning the next step

If you are unsure whether a task qualifies, use standard tier at effort: low. The cost difference
is small and the quality gap is meaningful.

---

## Token Hygiene

Model cost scales with token volume, not just tier. Keeping prompts and context windows lean is
the second most impactful cost lever after model selection.

**Prompts:**

- Specify the exact output format and maximum length in every agent prompt.
- Pass only the subset of prior findings relevant to the current agent, not the full prior phase
  output.
- Compress handoffs: what file, what change, what format to return.

**Context window:**

- Read only the section of a file you need, not the whole file.
- Do not re-read a file that has not changed since you last read it.
- Request concise structured output from sub-agents ("return a bullet list of X") rather than
  asking for narrative analysis.
- When multiple agents need the same data, fetch it once in the lead or orchestrator and pass
  the result in each agent's task prompt. Do not have each agent fetch independently.

**Spawning decisions:**

- Before spawning an agent, ask whether a single search or read call in the main agent accomplishes
  the same thing. A single targeted lookup is cheaper than a sub-agent with context overhead.
- Spawn for true parallelism only. If the speedup does not justify the overhead, do it inline.

---

## API Budget Management

Every LLM provider enforces rate limits. In large swarms, those limits constrain throughput more
than model quality. Managing the budget is an operational discipline, not an afterthought.

**Before a large multi-agent run:**

- Check your remaining rate quota. If it is low relative to the expected call volume, wait for a
  reset window rather than starting and hitting the ceiling mid-sprint.
- Count expected provider API calls across all agents. Multiply per-agent estimate by agent count.
  Compare against available quota.
- Reserve budget for end-of-sprint operations: PR creation, CI status checks, merge. These happen
  when the rest of the work is already done; running out of budget at that stage wastes all of it.

**During a run:**

- Consolidate provider API calls to the orchestrator or lead. Sub-agents receive results in their
  task prompt rather than calling the provider independently.
- Fetch all needed fields in a single call. Multiple calls for the same resource at different field
  sets is a common anti-pattern.
- Poll external status (CI, deploy checks) at reasonable intervals. Tight polling loops consume
  quota for no additional information.

**Anti-patterns to avoid:**

```
+--------------------------------------+-------------------------------------------+
| Anti-Pattern                         | Fix                                       |
+--------------------------------------+-------------------------------------------+
| Every agent calls the provider API   | Orchestrator fetches once, passes result  |
| independently for the same data      | in each agent's task description          |
+--------------------------------------+-------------------------------------------+
| Multiple calls for same resource     | Single call with all needed fields        |
| fetching different fields each time  | consolidated                              |
+--------------------------------------+-------------------------------------------+
| Polling status in a tight loop       | Fixed interval polling; stop at low quota |
+--------------------------------------+-------------------------------------------+
| Starting a large run with low quota  | Check quota first; wait for reset window  |
+--------------------------------------+-------------------------------------------+
| No quota reserved for end-of-sprint  | Reserve minimum budget for final ops      |
| operations                           | before the sprint starts                  |
+--------------------------------------+-------------------------------------------+
```

---

## Runtime Surface Notes

Model tiers remain universal, but the runtime surface changes the tool budget,
parallelism ceiling, and failure modes around those models.

Routing rule:

- Choose tier and effort here.
- Check the runtime-specific constraints in `docs/runtimes/` before finalizing
  the run plan.

Fast summary:

- Claude Code: strongest built-in coordination ergonomics.
- Codex: sandboxed agent threads and explicit `AGENTS.md` bootstrap.
- OpenClaw: Bedrock-only, best for ambient or daemon-style work rather than
  interactive coding sessions.

Detailed capability gaps and Bedrock-specific hazards live in:

- `../../runtimes/claude-code/primitives-and-limits.md`
- `../../runtimes/codex/primitives-and-limits.md`
- `../../runtimes/openclaw/bedrock-gotchas.md`

---

## Subscription vs. API Cost Tradeoffs

The unit economics of multi-agent work change substantially depending on how you are paying for
model access.

**API billing (pay-per-token):**

Model selection directly maps to spend. Every agent call, background recon scan, and retry costs
real money. The strategies in this guide apply in full: default to standard tier, use effort
levels aggressively, keep context lean, and escalate sparingly.

**Subscription plans (fixed monthly):**

Many providers offer subscription tiers that include agent-heavy workflows at a flat monthly rate.
On a subscription plan, marginal per-token cost is effectively zero within your usage envelope. The
constraint shifts from token cost to rate limits and context window capacity.

Under subscription, the selection logic changes:

- Escalate to most capable tier more freely for ambiguous tasks. The cost penalty disappears.
- Effort level is still a useful control because higher effort increases latency and context use,
  not direct cost.
- Rate limit management remains critical regardless of billing model.
- Token hygiene still matters for throughput and context window management, not spend.

The practical rule: on subscription plans, optimize for quality and throughput. On API billing,
optimize for quality per dollar and apply the full cost discipline in this guide.

---

## Model Selection Per Pattern

Each pattern has a default model profile shaped by its coordination demands and agent count.

### Patchwork

Single agent, any tier. Match the tier and effort to the task directly: low effort for mechanical
edits, high effort for anything requiring judgment. No swarm overhead to amortize.

### Worker Swarm

```
+-------------------+----------------+--------+
| Role              | Tier           | Effort |
+-------------------+----------------+--------+
| Lead agent        | Standard       | High   |
| Recon workers     | Standard       | Low    |
| Execution workers | Standard       | Medium |
| Pure mechanical   | Fast/efficient | Default|
| workers           |                |        |
+-------------------+----------------+--------+
```

The lead stays at high effort because it writes every prompt and synthesizes results. Workers
drop to low or medium because their scope is bounded and self-contained. Mechanical workers
(find-and-replace, env toggles) use the fast/efficient tier.

### Research Swarm

```
+-------------------+----------------+--------+
| Role              | Tier           | Effort |
+-------------------+----------------+--------+
| Wave lead (you)   | Standard       | High   |
| Scanner agents    | Fast/efficient | Default|
| Analysis agents   | Standard       | Medium |
| Synthesis agent   | Standard       | High   |
+-------------------+----------------+--------+
```

Scanners are fast/efficient because their job is pattern detection, not reasoning. Analysis
agents use standard at medium because they interpret findings. The synthesis agent compiles
the full picture and operates at high effort.

### Hive Mind (2-tier)

```
+-------------------+----------------+--------+
| Role              | Tier           | Effort |
+-------------------+----------------+--------+
| Lead              | Standard       | High   |
| Teammates         | Standard       | High   |
| Mechanical tasks  | Fast/efficient | Default|
+-------------------+----------------+--------+
```

Teammates coordinate autonomously and handle multi-hop reasoning, so standard at high effort
is the floor. Do not run Hive Mind teammates at low effort; they need headroom to reason about
coordination decisions.

### Hive Mind (3-tier)

```
+-------------------+----------------+--------+
| Role              | Tier           | Effort |
+-------------------+----------------+--------+
| Orchestrator      | Most capable   | Max    |
| Workstream leads  | Standard       | High   |
| Worker bees       | Standard       | Medium |
| Mechanical bees   | Fast/efficient | Default|
+-------------------+----------------+--------+
```

The orchestrator gates all phase transitions, makes cross-workstream decisions, and holds the
full picture. Most capable at max effort is justified here because there is one orchestrator
and its errors cascade to all 15-30 agents below it. Leads operate at standard/high. Bees
operate at standard/medium because their scope is bounded to a single workstream task.

---

## The Right Model for the Job: A Heuristic

The core heuristic is: match model capability to task ambiguity.

```
Ambiguity is HIGH when:
  - Requirements are underspecified
  - The correct approach requires multi-step reasoning
  - Failure modes are non-obvious
  - The task crosses multiple abstraction layers
  --> Use standard tier, high effort. Escalate to most capable if standard fails.

Ambiguity is MEDIUM when:
  - Requirements are clear but implementation has choices
  - The task is bounded to one area of the codebase
  - A reasonable first attempt will likely be close to correct
  --> Use standard tier, medium effort.

Ambiguity is LOW when:
  - The task is fully specified with no judgment required
  - The correct output is verifiable without analysis
  - Retry is cheap if the model errors
  --> Use standard tier, low effort. Use fast/efficient if truly mechanical.
```

When in doubt, go one level up in effort rather than one tier up in model. Effort is cheaper.
When effort is already at high and quality is still failing, then escalate the model tier.

---

## Quick Reference

```
DEFAULT SETUP:
  Most tasks           --> Standard tier, effort: high (default)
  File scans/lookups   --> Standard tier, effort: low
  Multi-file synthesis --> Standard tier, effort: medium
  Arch/security review --> Most capable tier, effort: max
  Mechanical only      --> Fast/efficient tier, effort: default

COST SIGNALS:
  Standard vs fast     --> ~3x cost premium; worth it for any ambiguity
  Most capable vs std  --> ~5x additional premium; reserved for arch + security

EFFORT BEFORE TIER:
  1. Try effort: low
  2. Try effort: medium
  3. Try effort: high
  4. Only then: escalate tier

PER-PATTERN DEFAULTS:
  Patchwork            --> Any tier, match effort to task
  Worker Swarm         --> Standard lead (high), standard workers (low-medium),
                          fast/efficient for pure mechanical
  Research Swarm       --> Fast/efficient scanners, standard analysis (medium),
                          standard synthesis (high)
  Hive Mind 2T         --> Standard throughout (high); fast/efficient for mechanical
  Hive Mind 3T         --> Most capable orchestrator (max), standard leads (high),
                          standard/fast bees (medium/default)
```

---

## Further Reading

- [../patterns/overview.md](../patterns/overview.md): Pattern decision matrix with per-role model
  guidance
- [../patterns/worker-swarm.md](../patterns/worker-swarm.md): Worker Swarm SOP with agent count
  and model assignment templates
- [../patterns/research-swarm.md](../patterns/research-swarm.md): Research Swarm wave design and
  scanner configuration
- [../patterns/hive-mind-2tier.md](../patterns/hive-mind-2tier.md): Hive Mind 2-tier team setup
  and phase workflow
- [../patterns/hive-mind-3tier.md](../patterns/hive-mind-3tier.md): Hive Mind 3-tier orchestrator,
  lead, and bee configuration

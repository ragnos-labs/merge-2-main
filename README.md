# merge-2-main by Mr. CLI

**A living field guide for multi-agent coding, review, and release discipline.**

Patterns, guides, references, and templates for orchestrating 2 to 30+ AI
agents on real software engineering tasks. This repo is documentation-only by
design: a public methodology layer, not a framework, SDK, or hosted service.

It is a clusterf*ck out there. Hope this helps.

## What This Repo Is

A source-backed methodology library for agentic software work. The goal is to
document the coordination patterns, review gates, audit hooks, and runtime
adapters that help teams move quickly without losing traceability.

You get:

- coordination patterns from single-agent work to large swarms
- a git-isolation layer for parallel workstreams
- cross-cutting guides for planning, tests, checkpoints, release gates, and
  artifacts
- references for anti-patterns, handoffs, sourcing, and schemas
- worked examples showing full end-to-end workflows
- ready-to-use templates for prompts, configs, and sprint artifacts

Works with [Claude Code](https://code.claude.com/docs/en), [OpenAI
Codex](https://openai.com/index/introducing-codex/), and
[OpenClaw](https://openclaw.im/docs/start/setup). The methodology stays
tool-agnostic; runtime specifics live under `docs/runtimes`.

Canonical docs live under `docs/core`, `docs/runtimes`, and `docs/templates`.

## What This Repo Is Not

This repo is not:

- plug-and-play production code
- a vendor truth machine
- a substitute for engineering judgment, code review, or runtime docs
- a "spawn 20 agents and pray" playbook

The patterns here are opinionated about process, reviewability, and scope
control. They are not a claim that one vendor, one model, or one topology wins
forever (spoiler, it does not)

## What It Optimizes For

Three buckets drive most of the choices in this repo:

- **Security**: audits, tests, scanner layering, safer release gates, and
  controls that catch hallucinated or unsafe changes before they land
- **Governance**: file ownership, handoff contracts, checkpoints, merge
  discipline, and scope control for parallel work
- **Observability**: traces, sprint artifacts, drift detection, and reviewable
  evidence showing what happened and why

The patterns are about controlled coordination, not just more coordination.

## How To Use This Repo

You do not need to read everything (but you probably should, but most of you
won't. I mean, I wouldn't). What would I do? Point my coding agent at the repo
and ask it "what's legit? what's bogus? what should we consider folding into
our ops?" Something like that.

Use this repo in one order:

1. Choose the pattern.
2. Choose the runtime.
3. Choose the template.
4. Review an example if you need the full flow.

If you want the shortest path:

- start with the [Decision Tree](docs/core/guides/decision-tree.md)
- choose a runtime in [docs/runtimes](docs/runtimes/README.md)
- grab the matching scaffold in [docs/templates](docs/templates/README.md)
- use a worked example from [docs/core/examples](docs/core/README.md) only
  when you want the whole flow end to end

## Push Back Early

None of this is gospel.

If a pattern feels overbuilt, under-specified, too expensive, or wrong for your
reality, push back. Open an issue, send a correction, or argue with the
assumptions. This repo is supposed to survive contact with real teams, not win
an abstract purity contest.

## Security And Due Diligence

This repo tries to be source-backed, corrigible, and explicit about where live
vendor behavior belongs. Claims can still go stale. Bad actors exist. Tooling
shifts. You should verify high-risk workflows, safety assumptions, and scanner
fit for your own environment before trusting them.

If you want a starting point for layered security checks, begin with [Security
Tooling Starting
Points](docs/core/references/security-tooling-starting-points.md). If you have
a stronger recommendation, open an issue and make the case.

## Quick Start: Pick Your Pattern

Answer these questions in order. Stop at the first "yes."

```text
1. Fewer than 10 mechanical changes?
   YES --> Patchwork (single agent, no coordination)

2. Are the changes independent (no shared state)?
   YES --> Worker Swarm (lead + 4-12 parallel workers)

3. Is this discovery/research, not execution?
   YES --> Research Swarm (wave-based parallel investigation)

4. Single workstream, needs ongoing coordination?
   YES --> Hive Mind 2-Tier (lead + 3-8 persistent teammates)

5. Multiple workstreams, 15+ agents?
   YES --> Hive Mind 3-Tier (orchestrator + leads + worker bees)
```

Need file isolation between workstreams? Add the **Worktree Sprint** layer on
top of any pattern.

## Core Methodology

Universal pattern docs:

| Pattern | Agents | Best For | Cost |
| ------- | ------ | -------- | ---- |
| [Patchwork](docs/core/patterns/patchwork.md) | 1 | Quick fixes, renames, config changes | Lowest |
| [Worker Swarm](docs/core/patterns/worker-swarm.md) | 4-12 | Independent parallel tasks | Low |
| [Research Swarm](docs/core/patterns/research-swarm.md) | 4-16 | Codebase audits, web research, landscape analysis | Low-Medium |
| [Hive Mind 2-Tier](docs/core/patterns/hive-mind-2tier.md) | 3-8 | Complex single-workstream features | Medium |
| [Hive Mind 3-Tier](docs/core/patterns/hive-mind-3tier.md) | 15-30 | Multi-workstream sprints | High |
| [Worktree Sprint](docs/core/patterns/worktree-sprint.md) | Any | Git isolation layer (composable with any pattern) | +Minimal |

Start with the [Pattern Overview](docs/core/patterns/overview.md) or the
[Decision Tree](docs/core/guides/decision-tree.md).

Want the folder-level map first?

- [Core Overview](docs/core/README.md)
- [Runtime Overview](docs/runtimes/README.md)
- [Template Overview](docs/templates/README.md)

## Runtime Surfaces

Pick the runtime after you pick the pattern:

- [Claude Code Runtime](docs/runtimes/claude-code/overview.md): interactive
  sessions, native background agents, team-style coordination
- [Codex Runtime](docs/runtimes/codex/overview.md): sandboxed agent threads,
  `AGENTS.md`, per-role configs, programmatic orchestration
- [OpenClaw Runtime](docs/runtimes/openclaw/overview.md): local-first
  background execution, scheduled workflows, and provider-routing caveats

## Core Guides

Cross-cutting practices that apply across all patterns:

- [Decision Tree](docs/core/guides/decision-tree.md): Select the right pattern
  in under 60 seconds
- [Unified Audit Pipeline](docs/core/guides/unified-audit-pipeline.md):
  Structured findings, repair loops, and tiered review passes
- [Model Selection](docs/core/guides/model-selection.md): Effort thermostat,
  cost optimization, tier assignment
- [Behavior Design](docs/core/guides/behavior-design.md): Character as an
  interface layer, not a substitute for process
- [Sprint Planning](docs/core/guides/sprint-planning.md): Plan artifacts, file
  ownership, dependency graphs
- [TDD Integration](docs/core/guides/tdd-integration.md): Red-Green-Refactor
  across multi-agent workflows
- [Checkpoint Protocol](docs/core/guides/checkpoint-protocol.md): When and how
  agents pause for human review
- [Trigger-Based Docs Sync](docs/core/guides/trigger-based-docs-sync.md):
  Working-set driven doc maintenance and downstream checks
- [Release Gate](docs/core/guides/release-gate.md): A public-safe `/ship`
  style checklist for review, commit, gate, and publish
- [Ship Rerun Semantics](docs/core/guides/ship-rerun-semantics.md): When to
  use cached, delta, full, or lite passes
- [Meta-Log Gates](docs/core/guides/meta-log-gates.md): Evidence checkpoints
  for long-running agent work
- [Sprint Artifacts](docs/core/guides/sprint-artifacts.md): Meta-logs, bug
  logs, and retrospective specs
- [Post-Sprint Completion](docs/core/guides/post-sprint-completion.md): The
  4-step ship pipeline
- [Scribe](docs/core/guides/scribe.md): Background observer agent for sprint
  monitoring

## Core References

- [Anti-Patterns](docs/core/references/anti-patterns.md): 13 mistakes to avoid
  across all patterns
- [Handoff Contracts](docs/core/references/handoff-contracts.md): Structured
  JSON agent-to-agent messages
- [Verification Discipline](docs/core/references/verification-discipline.md):
  Run it, read the output, then claim the result
- [Instruction Hygiene](docs/core/references/instruction-hygiene.md): Keep root
  instruction files lean and push detail downward
- [Research Manifest Schema](docs/core/references/research-manifest-schema.md):
  JSON schema for research tasks
- [TDD Contracts Template](docs/core/references/tdd-contracts-template.md):
  Copy-paste test contract format
- [Retrospective Template](docs/core/references/retrospective-template.md):
  Post-sprint review format
- [Drift Detection](docs/core/references/drift-detection.md): Scope, goal, and
  pattern drift signals
- [Positive Enforcement](docs/core/references/positive-enforcement.md): Prompt
  design principles
- [Ecosystem Radar](docs/core/references/ecosystem-radar.md): External repos
  and resource links that are on our radar, not under our control
- [Stack And Teams We Respect](docs/core/references/stack-and-teams-we-respect.md):
  Observability, telemetry, and LLM engineering projects that map directly to
  how we work
- [Security Tooling Starting
  Points](docs/core/references/security-tooling-starting-points.md): Layered
  scanner categories and official docs
- [Ecosystem Source Map](docs/core/references/ecosystem-source-map.md):
  Official runtime and protocol sources plus attribution rules

## Templates

Ready-to-use files for starting a sprint:

- [Build Spec](docs/templates/universal/build-spec.json): Sprint plan template
  (JSON)
- [Research Manifest](docs/templates/universal/research-manifest.json):
  Research swarm task list (JSON)
- [Orchestrator Prompt](docs/templates/universal/orchestrator-prompt.md): Hive
  Mind orchestrator instructions
- [Scribe Prompt](docs/templates/universal/scribe-prompt.md): Background
  observer instructions
- [Codex Config](docs/templates/codex/codex-config.toml): Multi-agent Codex
  setup
- [Codex Agents](docs/templates/codex/codex-agents/): Role configs (lead,
  worker, explorer, verifier)

## Worked Examples

End-to-end walkthroughs showing each pattern in action:

- [Security Audit](docs/core/examples/security-audit.md): 30-agent Research
  Swarm auditing a web app's security posture, then handing findings to a
  Worker Swarm for fixes
- [Feature Build](docs/core/examples/feature-build.md): 8-worker swarm
  building a notification system with email, SMS, and in-app channels
- [Full Sprint](docs/core/examples/full-sprint.md): 20-agent Hive Mind 3-Tier
  migrating a session-based auth system to JWT across 4 workstreams
- [Research Landscape](docs/core/examples/research-landscape.md): 10-agent
  internet research swarm evaluating vector database options

## Project Structure

```text
docs/
  core/
    patterns/     # Universal coordination patterns
    guides/       # Universal operating guidance
    references/   # Schemas, anti-patterns, contracts, and source maps
    examples/     # Worked examples with runtime assumptions
  runtimes/       # Claude Code, Codex, and OpenClaw surface docs
  templates/      # Universal templates plus runtime-specific configs
```

## Source-Backed Claims

Runtime details change fast. When this repo makes a claim about a live runtime
or protocol, prefer linking the official source rather than freezing brittle
product behavior into a universal guide.

Start here:

- [Ecosystem Source Map](docs/core/references/ecosystem-source-map.md)
- [Contributing](CONTRIBUTING.md)

## Philosophy

**Agents amplify plans.** A good plan with 10 agents produces 10x the output.
A bad plan with 10 agents produces 10x the mess. This framework front-loads
planning so agents execute with clarity.

**Non-overlapping file ownership.** The single most important rule. No two
agents should edit the same file. When they do, you get merge conflicts, lost
work, and wasted compute. Every pattern in this framework enforces this
constraint.

**Right model for the job.** Use the strongest model for decisions
(architecture, security review). Use the cheapest model for execution
(renames, boilerplate, scanning). The effort thermostat lets you tune
reasoning depth without switching models.

**Human checkpoints.** Agents drift. They make wrong assumptions, expand scope,
and accumulate errors. Checkpoints catch this before it compounds. The
framework defines when to pause based on task complexity, not arbitrary
schedules.

**Behavior is an interface layer.** Character can improve usability and
correction loops, but only when the process underneath stays reviewable. See
[Behavior Design](docs/core/guides/behavior-design.md).

**How we work at RAGnos.** Fast experiments are welcome. Unreviewable chaos is
not. If you want the public-safe mad-scientist version of our operating
posture, read [How We Work At
RAGnos](docs/core/guides/how-we-work-at-ragnos.md).

## Emerging Topics

Some lanes are intentionally stubbed because they matter, but they are not yet
ready to pretend they are finished.

- [AI Philosophy And Implications](docs/core/references/ai-philosophy-and-implications.md):
  placeholder for the bigger questions and operating consequences
- [Discovery Vs Invention](docs/core/references/discovery-vs-invention.md):
  placeholder for the scientific and philosophical debate around AI
- [Character Layer](docs/core/guides/character-layer.md): placeholder for the
  higher-level personality surface that sits on top of behavior design

Call it an orderly mess, or at least an intentional one.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. This is a
documentation-only repository: contributions are doc improvements, new
examples, and corrections.

## License

Apache 2.0. See [LICENSE](LICENSE).

---

Built by [RAGnos Labs](https://github.com/ragnos-labs/merge-2-main).

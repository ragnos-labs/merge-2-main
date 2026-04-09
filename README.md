# merge-2-main

**Multi-agent coordination framework for Claude Code, Codex, and OpenClaw.**

Patterns, guides, and templates for orchestrating 2 to 30+ AI agents on real software engineering tasks. Built from production experience running thousands of multi-agent sprints.

## What This Is

A complete framework for coordinating AI coding agents. Not a library. Not an SDK. Markdown docs that structure how you think about, plan, and execute multi-agent work.

You get:
- **4 coordination patterns** from single-agent to 30-agent sprints
- **1 infrastructure layer** for git-based isolation
- **8 cross-cutting guides** covering model selection, TDD, checkpoints, and more
- **7 reference docs** with anti-patterns, templates, and schemas
- **4 worked examples** showing full end-to-end workflows
- **Ready-to-use templates** for prompts, configs, and sprint artifacts

Works with [Claude Code](https://docs.anthropic.com/en/docs/claude-code), [OpenAI Codex CLI](https://github.com/openai/codex), and OpenClaw. The patterns are tool-agnostic; runtime specifics live in dedicated surface docs.

## Quick Start: Pick Your Pattern

Answer these questions in order. Stop at the first "yes."

```
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

Need file isolation between workstreams? Add the **Worktree Sprint** layer on top of any pattern.

## Core Methodology

Universal pattern docs:

| Pattern | Agents | Best For | Cost |
|---------|--------|----------|------|
| [Patchwork](docs/core/patterns/patchwork.md) | 1 | Quick fixes, renames, config changes | Lowest |
| [Worker Swarm](docs/core/patterns/worker-swarm.md) | 4-12 | Independent parallel tasks | Low |
| [Research Swarm](docs/core/patterns/research-swarm.md) | 4-16 | Codebase audits, web research, landscape analysis | Low-Medium |
| [Hive Mind 2-Tier](docs/core/patterns/hive-mind-2tier.md) | 3-8 | Complex single-workstream features | Medium |
| [Hive Mind 3-Tier](docs/core/patterns/hive-mind-3tier.md) | 15-30 | Multi-workstream sprints | High |
| [Worktree Sprint](docs/core/patterns/worktree-sprint.md) | Any | Git isolation layer (composable with any pattern) | +Minimal |

Start with the [Pattern Overview](docs/core/patterns/overview.md) or the [Decision Tree](docs/core/guides/decision-tree.md).

## Runtime Surfaces

Pick the runtime after you pick the pattern:

- [Claude Code Runtime](docs/runtimes/claude-code/overview.md): interactive sessions, native background agents, team-style coordination
- [Codex Runtime](docs/runtimes/codex/overview.md): sandboxed agent threads, `AGENTS.md`, per-role configs, programmatic orchestration
- [OpenClaw Runtime](docs/runtimes/openclaw/overview.md): announce-back sessions, daemon-style dispatch, Bedrock-only constraints

## Core Guides

Cross-cutting practices that apply across all patterns:

- [Decision Tree](docs/core/guides/decision-tree.md): Select the right pattern in under 60 seconds
- [Model Selection](docs/core/guides/model-selection.md): Effort thermostat, cost optimization, tier assignment
- [Sprint Planning](docs/core/guides/sprint-planning.md): Plan artifacts, file ownership, dependency graphs
- [TDD Integration](docs/core/guides/tdd-integration.md): Red-Green-Refactor across multi-agent workflows
- [Checkpoint Protocol](docs/core/guides/checkpoint-protocol.md): When and how agents pause for human review
- [Sprint Artifacts](docs/core/guides/sprint-artifacts.md): Meta-logs, bug logs, and retrospective specs
- [Post-Sprint Completion](docs/core/guides/post-sprint-completion.md): The 4-step ship pipeline
- [Scribe](docs/core/guides/scribe.md): Background observer agent for sprint monitoring

## Core References

- [Anti-Patterns](docs/core/references/anti-patterns.md): 13 mistakes to avoid across all patterns
- [Handoff Contracts](docs/core/references/handoff-contracts.md): Structured JSON agent-to-agent messages
- [Research Manifest Schema](docs/core/references/research-manifest-schema.md): JSON schema for research tasks
- [TDD Contracts Template](docs/core/references/tdd-contracts-template.md): Copy-paste test contract format
- [Retrospective Template](docs/core/references/retrospective-template.md): Post-sprint review format
- [Drift Detection](docs/core/references/drift-detection.md): Scope, goal, and pattern drift signals
- [Positive Enforcement](docs/core/references/positive-enforcement.md): Prompt design principles

## Templates

Ready-to-use files for starting a sprint:

- [Build Spec](docs/templates/universal/build-spec.json): Sprint plan template (JSON)
- [Research Manifest](docs/templates/universal/research-manifest.json): Research swarm task list (JSON)
- [Orchestrator Prompt](docs/templates/universal/orchestrator-prompt.md): Hive Mind orchestrator instructions
- [Scribe Prompt](docs/templates/universal/scribe-prompt.md): Background observer instructions
- [Codex Config](docs/templates/codex/codex-config.toml): Multi-agent Codex setup
- [Codex Agents](docs/templates/codex/codex-agents/): Role configs (lead, worker, explorer, verifier)

## Worked Examples

End-to-end walkthroughs showing each pattern in action:

- [Security Audit](docs/core/examples/security-audit.md): 30-agent Research Swarm auditing a web app's security posture, then handing findings to a Worker Swarm for fixes
- [Feature Build](docs/core/examples/feature-build.md): 8-worker swarm building a notification system with email, SMS, and in-app channels
- [Full Sprint](docs/core/examples/full-sprint.md): 20-agent Hive Mind 3-Tier migrating a session-based auth system to JWT across 4 workstreams
- [Research Landscape](docs/core/examples/research-landscape.md): 10-agent internet research swarm evaluating vector database options

## Project Structure

```
docs/
  core/
    patterns/     # Universal coordination patterns
    guides/       # Universal operating guidance
    references/   # Schemas, anti-patterns, and contracts
    examples/     # Worked examples with runtime assumptions
  runtimes/       # Claude Code, Codex, and OpenClaw surface docs
  templates/      # Universal templates plus runtime-specific configs
```

## Philosophy

**Agents amplify plans.** A good plan with 10 agents produces 10x the output. A bad plan with 10 agents produces 10x the mess. This framework front-loads planning so agents execute with clarity.

**Non-overlapping file ownership.** The single most important rule. No two agents should edit the same file. When they do, you get merge conflicts, lost work, and wasted compute. Every pattern in this framework enforces this constraint.

**Right model for the job.** Use the strongest model for decisions (architecture, security review). Use the cheapest model for execution (renames, boilerplate, scanning). The effort thermostat lets you tune reasoning depth without switching models.

**Human checkpoints.** Agents drift. They make wrong assumptions, expand scope, and accumulate errors. Checkpoints catch this before it compounds. The framework defines when to pause based on task complexity, not arbitrary schedules.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. This is a documentation-only repository: contributions are doc improvements, new examples, and corrections.

## License

Apache 2.0. See [LICENSE](LICENSE).

---

Built by [RAGnos Labs](https://github.com/ragnos-labs/merge-2-main).

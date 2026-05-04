---
title: Template Overview
description: Landing page for reusable sprint, prompt, and runtime template files.
---

# Template Overview

`docs/templates` contains reusable scaffolding for planning, orchestration, and
runtime setup.

Use the universal templates first. Add runtime-specific templates only when the
target runtime genuinely needs them.

Read in this order:

1. Start with a universal template.
2. Add Codex-specific config only if the chosen runtime needs it.
3. Return to the matching runtime docs when a template implies setup or limits.

## Universal Templates

- [Build Spec](./universal/build-spec.json): the per-sprint build plan format
- [Research Manifest](./universal/research-manifest.json): discovery-wave manifest for Research Swarms
- [Orchestrator Prompt](./universal/orchestrator-prompt.md): standing prompt for the top-tier coordinator
- [Scribe Prompt](./universal/scribe-prompt.md): standing prompt for the meta-log writer
- [Subagent Definition](./universal/subagent-definition.md): declared role default with model pin and tool surface
- [Spawn-Guard Hook](./universal/spawn-guard-hook.md): pre-spawn validation script; rejects unpinned or unjustified spawns
- [Meta-Log Entry Schema](./universal/meta-log-entry-schema.md): JSONL field set with self-heal extension and sample entries
- [Scratchpad Entries](./universal/scratchpad-entries.md): worked example of a workstream scratchpad JSONL

## Codex Templates

- [Codex Config](./codex/codex-config.toml)
- [Lead Agent](./codex/codex-agents/lead.toml)
- [Worker Agent](./codex/codex-agents/worker.toml)
- [Explorer Agent](./codex/codex-agents/explorer.toml)
- [Verifier Agent](./codex/codex-agents/verifier.toml)

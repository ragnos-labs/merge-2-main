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

- [Build Spec](./universal/build-spec.json)
- [Research Manifest](./universal/research-manifest.json)
- [Orchestrator Prompt](./universal/orchestrator-prompt.md)
- [Scribe Prompt](./universal/scribe-prompt.md)

## Codex Templates

- [Codex Config](./codex/codex-config.toml)
- [Lead Agent](./codex/codex-agents/lead.toml)
- [Worker Agent](./codex/codex-agents/worker.toml)
- [Explorer Agent](./codex/codex-agents/explorer.toml)
- [Verifier Agent](./codex/codex-agents/verifier.toml)

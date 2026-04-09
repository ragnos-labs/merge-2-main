---
title: Template Overview
description: Landing page for reusable sprint, prompt, and runtime template files.
---

# Template Overview

`docs/templates` contains reusable scaffolding for planning, orchestration, and
runtime setup.

Use the universal templates first. Add runtime-specific templates only when the
target runtime genuinely needs them.

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

## Compatibility Shims

Older top-level files under `docs/templates/` remain for link compatibility.
The canonical paths are:

- `docs/templates/universal/*` for portable templates
- `docs/templates/codex/*` for Codex-specific files

If both exist, prefer the canonical path.

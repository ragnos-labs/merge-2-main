---
title: OpenClaw Bedrock Gotchas
description: Bedrock-specific hazards and routing guidance for OpenClaw-based workflows.
---

# OpenClaw Bedrock Gotchas

If your OpenClaw deployment routes through Bedrock, treat that as a runtime
constraint, not an invisible implementation detail. Some failures show up as
degraded behavior rather than obvious hard errors.

Known hazard classes:

- Missing model ID prefixes or suffixes causing empty or misleading failures
- Web-search style workflows degrading without obvious errors
- Model variants that hang or mishandle structured tool use
- Context growth without the compaction ergonomics available elsewhere

Routing guidance:

- Do not treat Bedrock as a drop-in substitute for interactive sprint
  orchestration
- Prefer Claude Code or Codex for primary coding, debugging, and review loops
- Use OpenClaw when ambient execution is the decisive requirement

Verify the current provider-routing behavior in the official runtime docs before
relying on a repo-local assumption.

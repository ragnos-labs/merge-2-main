---
title: Codex Programmatic API
description: Notes for programmatic Codex orchestration, including response continuity and checkpoints.
---

# Codex Programmatic API

Use this page when the universal patterns are being driven through a programmatic
Codex surface instead of an interactive CLI or IDE session.

Focus areas:

- Response continuity across long-running leads
- Checkpointing and resumability
- Explicit phase tracking outside the model

Key rule:

- The methodology's phase gates and handoff contracts still live above the API.
  The API does not enforce them for you.

For the detailed field-level guidance, see the `Responses API` section in
`pattern-adapters.md`.

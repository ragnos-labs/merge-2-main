---
title: Ecosystem Source Map
description: Official docs and source-backed references for runtime-specific claims, plus attribution rules for upstream material.
---

# Ecosystem Source Map

This repo tries to separate durable methodology from fast-moving runtime facts.

Use this page for two things:

1. verify runtime or protocol claims against primary sources
2. attribute upstream ideas and materials responsibly

## Official Runtime Sources

### Codex

- [OpenAI: Introducing Codex](https://openai.com/index/introducing-codex/)
- What it supports in this repo:
  - parallel tasks in isolated environments
  - AGENTS.md-guided execution
  - traceable terminal logs and test evidence

### Claude Code

- [Claude Code hooks](https://code.claude.com/docs/en/hooks)
- What it supports in this repo:
  - policy and audit hooks around tool calls
  - hook-controlled blocking behavior
  - async hooks and post-tool feedback

### OpenClaw

- [OpenClaw setup docs](https://openclaw.im/docs/start/setup)
- What it supports in this repo:
  - workspace and config separation
  - local state and session surfaces
  - channel and runtime concepts

## Official Interoperability And Governance Sources

### Model Context Protocol

- [MCP specification](https://modelcontextprotocol.io/specification/2025-06-18)
- What it supports in this repo:
  - user consent and control
  - tool safety
  - logging and progress surfaces
  - explicit controls around LLM sampling

### Agent2Agent

- [Google Cloud donates A2A to Linux Foundation](https://developers.googleblog.com/google-cloud-donates-a2a-to-linux-foundation/)
- [A2A in Google's ADK docs](https://adk.dev/a2a/)
- What it supports in this repo:
  - neutral governance for agent interoperability
  - cross-vendor coordination
  - secure exchange of capabilities and context between agents

### A2UI

- [Introducing A2UI](https://developers.googleblog.com/introducing-a2ui-an-open-project-for-agent-driven-interfaces/)
- What it supports in this repo:
  - declarative UI instead of arbitrary generated code
  - portable, framework-agnostic surfaces
  - security-conscious UI generation for agent systems

## Acquisition And Market Signals

These are not methodology sources. They are market context for how open-source
projects, platforms, and developer ecosystems get positioned and monetized.

- [Microsoft to acquire GitHub for $7.5 billion](https://news.microsoft.com/source/2018/06/04/microsoft-to-acquire-github-for-7-5-billion/)
- [GitHub welcomes Semmle](https://github.blog/news-insights/company-news/github-welcomes-semmle/)
- [AP: Meta to acquire Moltbook](https://apnews.com/article/meta-moltbook-ai-agents-openclaw-31af42ccbb04001dd17a3fc7067d1de3)

Use these as signals that buyers often value:

- community position
- trust
- maintainers and operator know-how
- security or governance leverage
- strategic adjacency to a larger platform

Treat "repo acquisition" as shorthand. In practice, buyers often acquire the
team, brand, community position, and adjacent IP around a project, not just a
bare Git repository.

## Attribution Rules

When you borrow an idea from another repo, protocol, or doc set:

1. Prefer linking and summarizing over copying.
2. Put the primary source link near the claim.
3. If you copy any substantial material, preserve the original copyright and
   license notices exactly as required.
4. Make it obvious what is universal methodology, what is runtime-specific,
   and what is an upstream concept adapted here.

## License Notes

This repo is Apache 2.0 licensed.

That does not prevent you from linking to MIT, Apache 2.0, or other compatible
open-source projects. It does mean you should handle copied third-party
material carefully.

For permissive upstream material such as MIT:

- linking is straightforward
- summarizing in your own words is straightforward
- copying substantial text or code still requires preserving the upstream
  notice and license terms

For more guidance, see:

- [OSI MIT license page](https://opensource.org/license/mit)
- [ASF generative tooling guidance](https://www.apache.org/legal/generative-tooling.html)

This page is not legal advice. If you want to vendor third-party material into
the repo instead of linking to it, verify the exact license obligations first.

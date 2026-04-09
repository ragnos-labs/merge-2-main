---
title: Stack And Teams We Respect
description: Public-facing guide to the observability, telemetry, and LLM engineering projects we use, watch, and recommend as strong starting points.
---

## Stack And Teams We Respect

This page is a resource guide for the stack surfaces that most directly support
what `merge-2-main` is trying to do:

- make agent work more observable
- make debugging and review more evidence-based
- make LLM workflows less hand-wavey
- keep the stack as portable as practical, even when reality gets sticky

These are not the only good teams or projects in the ecosystem. They are the
ones that most directly show up in our actual ops, or that stay close enough
to the work that we keep them on the radar.

## Non-Affiliation Note

We are not affiliated with any repo, team, or company listed here. We just
like their work and use a lot of it.

Once you leave this repo, do your own diligence on safety, stability,
licensing, maintenance quality, and production fit.

If you are on one of these teams and want to talk partnerships, hit us up. We
will gladly take your money if the vibe is right.

## Why This Connects To `merge-2-main`

The methodology in this repo keeps circling back to three buckets:

- **Security**: what ran, what changed, what should not ship
- **Governance**: who owns what, which evidence counts, and how releases get
  gated
- **Observability**: traces, logs, metrics, evals, and artifacts that make the
  whole system reviewable

This stack matters because those buckets are not abstract values. They need
real infrastructure behind them.

## Core Stack Lanes

### LLM Observability And Evals

#### Langfuse

- Repo: [langfuse/langfuse](https://github.com/langfuse/langfuse)
- Why it matters: strong open-source surface for LLM observability, prompt
  management, datasets, and eval-adjacent workflows
- Why we respect the team: they have stayed close to the actual day-to-day
  operating needs of people building with models instead of pretending tracing
  alone solves the problem
- Fit with this repo: useful when you want prompt/version visibility,
  experiment traces, and a clearer paper trail around agent behavior

### Telemetry Standards And Collection

#### OpenTelemetry Specification

- Repo:
  [open-telemetry/opentelemetry-specification](https://github.com/open-telemetry/opentelemetry-specification)
- Why it matters: the vendor-neutral contract layer for telemetry concepts and
  semantics
- Why we respect the team: it is one of the main reasons "portable
  observability" is more than a slogan
- Fit with this repo: aligns with the stack-agnostic aspiration behind
  `merge-2-main`, even when everyone still ends up with preferences and some
  grudging lock-in

#### OpenTelemetry Collector

- Repo:
  [open-telemetry/opentelemetry-collector](https://github.com/open-telemetry/opentelemetry-collector)
- Why it matters: practical ingestion, processing, and export layer for moving
  telemetry through real systems
- Why we respect the team: it gives people a real way to build pipelines
  without hard-wiring themselves to one backend from day one
- Fit with this repo: a strong baseline for trace, log, and metric collection
  in agent-heavy systems

### Traces, Logs, Metrics, And Dashboards

#### Grafana

- Repo: [grafana/grafana](https://github.com/grafana/grafana)
- Why it matters: shared visual layer for metrics, logs, traces, dashboards,
  and operational visibility
- Why we respect the team: they have built a durable observability surface that
  works across many backends instead of forcing one closed worldview
- Fit with this repo: a good home for review surfaces, release visibility, and
  operational dashboards around agent workflows

#### Grafana Tempo

- Repo: [grafana/tempo](https://github.com/grafana/tempo)
- Why it matters: distributed tracing backend
- Why we respect the team: Tempo is one of the clearer open-source answers for
  making tracing practical at scale
- Fit with this repo: traces are one of the most useful ways to reconstruct
  what happened across agents, tools, and handoffs

#### Grafana Loki

- Repo: [grafana/loki](https://github.com/grafana/loki)
- Why it matters: log aggregation and querying
- Why we respect the team: Loki keeps logs in the same broader observability
  conversation instead of treating them as an isolated graveyard
- Fit with this repo: this is part of our actual observability surface today
  for execution logs, failure review, and debugging messy runs

#### Prometheus

- Repo: [prometheus/prometheus](https://github.com/prometheus/prometheus)
- Why it matters: foundational open-source metrics and alerting surface
- Why we respect the team: a lot of the modern observability world still builds
  on Prometheus assumptions, patterns, or direct integration
- Fit with this repo: metrics and alerting are part of the evidence chain, not
  just dashboard decoration

### Supporting Infrastructure

#### Redis

- Repo: [redis/redis](https://github.com/redis/redis)
- Why it matters: fast cache and coordination layer that shows up behind other
  services and in some workflow plumbing
- Why we respect the team: Redis remains one of the standard building blocks
  for "this system needs fast shared state" problems
- Fit with this repo: this is part of our actual ops, but more as supporting
  infrastructure than as a front-of-house methodology surface

## Adjacent Projects We Respect

These projects are relevant and respectable, but we should not pretend they are
currently central to our day-to-day stack if they are not.

### Grafana Alloy

- Repo: [grafana/alloy](https://github.com/grafana/alloy)
- Why it matters: programmable collection and routing layer that builds on
  OpenTelemetry Collector ideas
- Why we respect the team: it is one of the cleaner bridges between standards,
  collection, and the rest of the Grafana stack
- Current stance: adjacent and worth watching, but not a confirmed core part of
  our live ops right now

### Grafana Mimir

- Repo: [grafana/mimir](https://github.com/grafana/mimir)
- Why it matters: scalable metrics backend for Prometheus-style workloads
- Why we respect the team: it makes long-horizon and multi-tenant metrics less
  painful in real environments
- Current stance: relevant as the stack grows, but not something we should
  present as a current core dependency

## How To Read This Page

Use this page as:

- a stack map
- a rough split between "we use this now" and "we respect this enough to keep
  nearby"
- a starting point for your own observability architecture
- a list of teams worth watching if you care about agent operations,
  instrumentation, and reviewability

Do not use it as:

- a claim that this exact stack is mandatory
- a substitute for architecture decisions
- an endorsement that every linked repo is safe for every environment

## Contribution Rule

Good additions to this page should be:

- directly relevant to observability, governance, evals, release evidence, or
  stack portability
- official project or team repos, not random mirrors
- explainable in one short paragraph of real value

If the project is merely interesting, but not obviously tied to the operating
goals of this repo, it probably belongs in
[Ecosystem Radar](./ecosystem-radar.md) instead.

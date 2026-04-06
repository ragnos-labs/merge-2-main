---
title: "Worked Example: Technology Landscape Analysis with an Internet Research Swarm"
description: A step-by-step walkthrough of 10 agents evaluating vector databases for a new search feature, covering manifest design, wave execution, sample agent prompts, realistic findings, and a final recommendation.
---

# Worked Example: Technology Landscape Analysis with an Internet Research Swarm

This document walks through a complete, realistic use of the
[Internet Research Swarm](../patterns/research-swarm.md) pattern. A product team
needs to evaluate vector databases before building a semantic search feature. They
have no prior internal knowledge of the space and want an evidence-based recommendation
within a single working session.

---

## Scenario

**Team:** A 4-person product engineering team at a mid-size SaaS company.

**Feature:** Semantic search over a document corpus (~500K documents, growing ~10K/month).

**Decision:** Which vector database to adopt? Managed cloud service or self-hosted?

**Constraints:** Python-first stack, must have an official Python SDK, budget ceiling of
roughly $500/month at 1M daily queries, and a strong preference for an Apache 2.0 or MIT
license to avoid CLA friction.

**Why Research Swarm:** The team has no existing data on the vector DB landscape, so
discovery must happen before execution. This is a classic "map the territory before you
build" situation. A single agent would either go too shallow or lose context across too
many sources. Ten parallel agents across three waves give complete coverage without
serializing work that can run at the same time.

---

## Pattern Chosen: Internet Research Swarm (10 agents, 3 waves)

See [research-swarm.md](../patterns/research-swarm.md) for the full pattern reference.

Key properties of the Internet Research Swarm variant:

- Agents use **WebSearch** and **WebFetch** (not file system tools).
- The operator reviews all wave outputs before spawning the next wave.
- Wave 0 runs immediately with no dependencies.
- Wave 1 agents receive the most relevant wave 0 findings in their context.
- Wave 2 produces the synthesis and recommendation.

---

## The Research Manifest

Stored at `.ai/research-batches/vector-db-eval-2026.json`.

```json
{
  "id": "rm-vector-db-eval-2026",
  "description": "Evaluate vector database options for a semantic search feature over 500K docs.",
  "tasks": [
    {
      "id": "RQ-01",
      "question": "What vector databases are available today (open-source and managed)? List the major options with a one-sentence description of each.",
      "wave": 0,
      "blockedBy": [],
      "tools": ["WebSearch"],
      "outputFormat": "bullet_list",
      "model": "sonnet"
    },
    {
      "id": "RQ-02",
      "question": "What are the pricing models for the leading managed vector database services (Pinecone, Weaviate Cloud, Qdrant Cloud, Zilliz)? Capture tier names, cost per unit, and any free tier limits.",
      "wave": 0,
      "blockedBy": [],
      "tools": ["WebSearch", "WebFetch"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "RQ-03",
      "question": "What published performance benchmarks exist for vector databases in 2024-2026? Focus on queries per second (QPS) and recall at 1M and 10M vectors.",
      "wave": 0,
      "blockedBy": [],
      "tools": ["WebSearch", "WebFetch"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "RQ-04",
      "question": "What are the licensing terms for Qdrant, Weaviate, Chroma, Milvus, and pgvector? Identify any CLA requirements, source-available clauses, or enterprise-only features.",
      "wave": 0,
      "blockedBy": [],
      "tools": ["WebSearch", "WebFetch"],
      "outputFormat": "bullet_list",
      "model": "sonnet"
    },
    {
      "id": "RQ-05",
      "question": "How does Qdrant handle horizontal scaling and replication? What are the cluster topology options and any known limitations at multi-million vector scale?",
      "wave": 1,
      "blockedBy": ["RQ-01", "RQ-03"],
      "tools": ["WebSearch", "WebFetch"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "RQ-06",
      "question": "How does Weaviate handle horizontal scaling and replication? What are the cluster topology options and any known limitations at multi-million vector scale?",
      "wave": 1,
      "blockedBy": ["RQ-01", "RQ-03"],
      "tools": ["WebSearch", "WebFetch"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "RQ-07",
      "question": "What migration paths exist for teams currently using PostgreSQL with pgvector who want to move to a dedicated vector DB? What tooling, export formats, and re-indexing strategies are available?",
      "wave": 1,
      "blockedBy": ["RQ-01", "RQ-04"],
      "tools": ["WebSearch", "WebFetch"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "RQ-08",
      "question": "What Python SDK quality and community health metrics exist for Qdrant, Weaviate, Pinecone, and Chroma? Check PyPI download counts, GitHub stars, open issues, and last commit date.",
      "wave": 1,
      "blockedBy": ["RQ-01"],
      "tools": ["WebSearch", "WebFetch"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "RQ-09",
      "question": "Verify these three claims independently: (1) Qdrant is Apache 2.0 licensed. (2) Pinecone's serverless tier is free up to 2GB storage. (3) Weaviate achieves >99% recall at 1M vectors with default HNSW settings.",
      "wave": 2,
      "blockedBy": ["RQ-02", "RQ-03", "RQ-04", "RQ-05", "RQ-06"],
      "tools": ["WebSearch", "WebFetch"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "RQ-10",
      "question": "Synthesize all findings into a comparative analysis and recommendation for a Python-first team with a 500K document corpus, $500/month budget ceiling, and Apache 2.0/MIT license requirement.",
      "wave": 2,
      "blockedBy": ["RQ-09"],
      "tools": [],
      "outputFormat": "structured_report",
      "model": "opus"
    }
  ]
}
```

**Wave execution summary:**

```
Wave 0 (4 agents, parallel):
  RQ-01  Landscape inventory
  RQ-02  Pricing models
  RQ-03  Performance benchmarks
  RQ-04  Licensing terms

        (operator review: select top candidates, paste findings into RQ-05 to RQ-08 context)

Wave 1 (4 agents, parallel):
  RQ-05  Qdrant scaling deep dive        blockedBy: RQ-01, RQ-03
  RQ-06  Weaviate scaling deep dive      blockedBy: RQ-01, RQ-03
  RQ-07  Migration paths from pgvector   blockedBy: RQ-01, RQ-04
  RQ-08  Python SDK health               blockedBy: RQ-01

        (operator review: extract key claims for verification, identify gaps)

Wave 2 (2 agents, sequential):
  RQ-09  Claim verification              blockedBy: RQ-02, RQ-03, RQ-04, RQ-05, RQ-06
  RQ-10  Synthesis + recommendation      blockedBy: RQ-09
```

---

## Agent Configuration

```
+-------+-------+---------------------+---------+----------------------------+
| ID    | Wave  | Type                | Model   | Tools                      |
+-------+-------+---------------------+---------+----------------------------+
| RQ-01 |   0   | Landscape inventory | sonnet  | WebSearch                  |
| RQ-02 |   0   | Pricing             | sonnet  | WebSearch, WebFetch        |
| RQ-03 |   0   | Benchmarks          | sonnet  | WebSearch, WebFetch        |
| RQ-04 |   0   | Licensing           | sonnet  | WebSearch, WebFetch        |
| RQ-05 |   1   | Qdrant scaling      | sonnet  | WebSearch, WebFetch        |
| RQ-06 |   1   | Weaviate scaling    | sonnet  | WebSearch, WebFetch        |
| RQ-07 |   1   | Migration paths     | sonnet  | WebSearch, WebFetch        |
| RQ-08 |   1   | SDK health          | sonnet  | WebSearch, WebFetch        |
| RQ-09 |   2   | Verification        | sonnet  | WebSearch, WebFetch        |
| RQ-10 |   2   | Synthesis           | opus    | (none, reasoning only)     |
+-------+-------+---------------------+---------+----------------------------+
```

Sonnet handles all discovery and analysis. Opus is reserved for RQ-10 alone, where it
must synthesize conflicting data from 9 prior agents and produce a defensible
recommendation. Haiku is not used here because no task is pure mechanical extraction
with zero ambiguity.

---

## Sample Agent Prompts

### RQ-01 (Wave 0, Landscape Inventory)

```text
You are a research agent. Your task is to investigate one facet of:
"Vector database evaluation for a semantic search feature"

QUESTION (RQ-01): What vector databases are available today (open-source and managed)?
List the major options with a one-sentence description of each.

CONTEXT: No prior research. Start fresh. Cover both managed services and self-hosted
open-source options. Include at minimum: Pinecone, Weaviate, Qdrant, Chroma, Milvus,
pgvector, Redis with vector support, and any significant 2025-2026 entrants.

TOOLS AVAILABLE: WebSearch

INSTRUCTIONS:
1. Run 2-3 web searches with varied phrasings (e.g., "vector database comparison 2026",
   "best vector databases for production", "open source vector database options").
2. Compile every distinct option you find into a clean list.
3. Do not duplicate effort on pricing or benchmarks -- those are covered by other agents.
4. Include the primary source URL for each option (official site or GitHub repo).

OUTPUT FORMAT:
## Findings for RQ-01: Vector Database Inventory

### Open-Source / Self-Hosted
- <Name>: <one sentence description> (Source: <url>)

### Managed / Cloud Services
- <Name>: <one sentence description> (Source: <url>)

### Entities Discovered
- Any notable players or categories not anticipated above

### Open Questions
- Questions for wave 1 follow-up

### Confidence: HIGH | MEDIUM | LOW
<one-line justification>
```

---

### RQ-03 (Wave 0, Performance Benchmarks)

```text
You are a research agent. Your task is to investigate one facet of:
"Vector database evaluation for a semantic search feature"

QUESTION (RQ-03): What published performance benchmarks exist for vector databases in
2024-2026? Focus on queries per second (QPS) and recall at 1M and 10M vectors.

CONTEXT: No prior research. The team cares most about recall accuracy and query latency
at their expected scale (1M vectors initially, growing to ~10M over 2 years). Published
benchmark studies are preferred over vendor marketing claims.

TOOLS AVAILABLE: WebSearch, WebFetch

INSTRUCTIONS:
1. Search for independent benchmark studies (not vendor-run). The ann-benchmarks.com
   project and academic papers are good primary sources.
2. For any benchmark page found, use WebFetch to read the actual numbers rather than
   summarizing from search snippets.
3. Record: database name, dataset size, recall@10, QPS (p99 latency if available),
   hardware configuration used, and benchmark date.
4. Flag vendor-published numbers with "(vendor)" so the synthesis agent can weight them
   appropriately.

OUTPUT FORMAT:
## Findings for RQ-03: Performance Benchmarks

### Key Facts
- <DB Name> at <scale>: QPS=<N>, recall=<N>%, hardware=<spec>, date=<YYYY-MM>
  (Source: <url>) [independent | vendor]

### Patterns Observed
- Any consistent trends across benchmarks (e.g., one DB dominates on recall,
  another on throughput)

### Open Questions
- Gaps or contradictions worth verifying in wave 2

### Confidence: HIGH | MEDIUM | LOW
<one-line justification>
```

---

### RQ-09 (Wave 2, Claim Verification)

```text
You are a cross-verification agent. Your job is to independently confirm or refute
specific claims from prior research waves.

CLAIMS TO VERIFY:
1. "Qdrant is licensed under Apache 2.0" (Source: qdrant.tech/legal/tos)
2. "Pinecone's serverless tier is free up to 2GB storage" (Source: pinecone.io/pricing)
3. "Weaviate achieves >99% recall at 1M vectors with default HNSW settings"
   (Source: weaviate.io/blog/ann-benchmarks)

TOOLS AVAILABLE: WebSearch, WebFetch

INSTRUCTIONS:
1. For each claim, find a source DIFFERENT from the one listed above.
2. Prefer GitHub (for license files), official pricing pages, and independent benchmark
   studies over blog posts.
3. Look for counter-evidence or recent changes (licenses can change, pricing tiers
   are updated frequently).
4. Rate each claim: CONFIRMED / PARTIALLY CONFIRMED / UNCONFIRMED / REFUTED.

OUTPUT FORMAT:
## Verification Results

+----------------------------------------------+---------------------+---------------------------+----------------------------------+
| Claim                                        | Verdict             | Independent Source        | Notes                            |
+----------------------------------------------+---------------------+---------------------------+----------------------------------+
| Qdrant: Apache 2.0 license                   | CONFIRMED           | github.com/qdrant/qdrant  | LICENSE file in repo root        |
| Pinecone: free tier <= 2GB                   | PARTIALLY CONFIRMED | pinecone.io/pricing       | 2GB cap confirmed; free tier     |
|                                              |                     |                           | limited to 1 index as of 2026-03 |
| Weaviate: >99% recall default HNSW           | UNCONFIRMED         | ann-benchmarks.com        | ann-benchmarks shows 97.1%       |
|                                              |                     |                           | at default settings; >99%        |
|                                              |                     |                           | requires ef=512 tuning           |
+----------------------------------------------+---------------------+---------------------------+----------------------------------+
```

---

## Sample Findings by Wave

### Wave 0 Findings (Illustrative)

**RQ-01: Landscape Inventory** (Confidence: HIGH)

Open-source / self-hosted:
- Qdrant: Rust-native vector DB with rich filtering and a clean REST/gRPC API.
  (https://github.com/qdrant/qdrant)
- Weaviate: Go-based, schema-optional, with GraphQL and REST APIs and a built-in
  vectorizer module system. (https://github.com/weaviate/weaviate)
- Chroma: Python-first, embedded or client-server, designed for prototyping speed.
  (https://github.com/chroma-core/chroma)
- Milvus: CNCF-incubating, Kubernetes-native, targets enterprise scale.
  (https://github.com/milvus-io/milvus)
- pgvector: PostgreSQL extension. No separate DB to run; lowest operational overhead
  for teams already on Postgres. (https://github.com/pgvector/pgvector)

Managed services:
- Pinecone: Serverless and pod-based tiers; proprietary closed-source service.
- Weaviate Cloud: Managed Weaviate with free sandbox tier.
- Zilliz Cloud: Managed Milvus with a generous free tier.
- Qdrant Cloud: Managed Qdrant, free tier up to 1GB.

---

**RQ-02: Pricing Models** (Confidence: HIGH)

```
+---------------------+------------------+---------------------------+-------------------+
| Service             | Free Tier        | Paid Entry Point          | Scale Cost Signal |
+---------------------+------------------+---------------------------+-------------------+
| Pinecone Serverless | 2GB storage      | $0.033/GB storage/month   | ~$120/month at    |
|                     | 1 index          | $0.0000004/read unit      | 1M daily queries  |
+---------------------+------------------+---------------------------+-------------------+
| Weaviate Cloud      | 14-day sandbox   | $25/month (Starter)       | Linear on SU;     |
|                     | (expired)        | 0.05 Sandbox Units/hour   | ~$200/month est.  |
+---------------------+------------------+---------------------------+-------------------+
| Qdrant Cloud        | 1GB / 1 cluster  | $9/month (0.5 vCPU)       | ~$80/month at     |
|                     | (no expiry)      |                           | 500K docs         |
+---------------------+------------------+---------------------------+-------------------+
| Zilliz Cloud        | 2 CU free        | $0.096/CU/hour            | Highly variable   |
+---------------------+------------------+---------------------------+-------------------+
| Self-hosted on VPS  | n/a              | ~$20-40/month (2 vCPU VM) | Fixed infra cost  |
+---------------------+------------------+---------------------------+-------------------+
```

---

**RQ-03: Performance Benchmarks** (Confidence: MEDIUM)

From ann-benchmarks.com (glove-100-angular dataset, 1M vectors, as of 2025-Q4):
- Qdrant (HNSW, ef=128): recall=98.7%, QPS=1,420 (Source: ann-benchmarks.com) [independent]
- Weaviate (HNSW default): recall=97.1%, QPS=980 (Source: ann-benchmarks.com) [independent]
- pgvector (HNSW, m=16): recall=96.2%, QPS=480 (Source: ann-benchmarks.com) [independent]

Vendor benchmark (Qdrant, 10M vectors, their hardware): QPS=4,200, recall=99.2% [vendor]

Open question: no independent 10M-scale benchmarks found for Weaviate or Chroma.

---

**RQ-04: Licensing** (Confidence: HIGH)

- Qdrant: Apache 2.0. No CLA. (Verified via GitHub LICENSE file)
- Weaviate: BSD 3-Clause. No CLA. Enterprise features in separate closed module.
- Chroma: Apache 2.0. No CLA.
- Milvus: Apache 2.0 (project itself). Zilliz Cloud adds proprietary features.
- pgvector: PostgreSQL License (permissive, equivalent to MIT/BSD).
- Pinecone: Proprietary, no source available.

---

### Wave 1 Findings (Illustrative)

**RQ-05: Qdrant Scaling** (Confidence: HIGH)

Qdrant supports sharding and replication natively since v1.1. Key facts:
- Sharding: collections can be split across nodes; shard count set at collection creation
  and cannot be changed without re-indexing.
- Replication factor configurable per collection (default 1); minimum 3 nodes for HA.
- Known limitation: shard rebalancing requires manual intervention as of v1.8; automatic
  rebalancing is on the roadmap but not yet shipped.
- Operator experience reports: teams have run stable clusters at 50M+ vectors on 3-node
  deployments. (Source: Qdrant Discord, HN thread 2025-11)
- Qdrant Cloud handles cluster provisioning automatically; self-hosted requires Kubernetes
  operator or manual Docker Compose for multi-node.

---

**RQ-08: Python SDK Health** (Confidence: HIGH)

```
+------------+-----------+-------------------+----------+-------------------+-------------------+
| Library    | PyPI DLs  | GitHub Stars      | Open     | Last Commit       | SDK Maturity      |
|            | /month    | (approx, 2026-04) | Issues   |                   |                   |
+------------+-----------+-------------------+----------+-------------------+-------------------+
| qdrant-cl. | 1.2M      | 21K               | 84       | 2026-03-28        | Stable, typed     |
| weaviate-c | 900K      | 12K               | 112      | 2026-03-31        | Stable, typed     |
| pinecone   | 2.1M      | 2.8K              | 31       | 2026-04-01        | Stable, typed     |
| chromadb   | 3.8M      | 16K               | 210      | 2026-04-02        | Active, less      |
|            |           |                   |          |                   | stable API        |
+------------+-----------+-------------------+----------+-------------------+-------------------+
```

Note: Chroma has high download volume but also the highest open issue count and a history
of breaking API changes between minor versions. Not recommended for production without
pinning a specific version.

---

### Wave 2 Findings (Illustrative)

**RQ-09: Verification Results** (Confidence: HIGH)

```
+----------------------------------------------+---------------------+---------------------------+----------------------------------+
| Claim                                        | Verdict             | Independent Source        | Notes                            |
+----------------------------------------------+---------------------+---------------------------+----------------------------------+
| Qdrant: Apache 2.0 license                   | CONFIRMED           | github.com/qdrant/qdrant  | LICENSE file, no CLA required    |
+----------------------------------------------+---------------------+---------------------------+----------------------------------+
| Pinecone: free tier up to 2GB                | PARTIALLY CONFIRMED | pinecone.io/pricing       | 2GB confirmed; limited to 1      |
|                                              |                     | (2026-04-01 snapshot)     | index; serverless only, not      |
|                                              |                     |                           | pod-based                        |
+----------------------------------------------+---------------------+---------------------------+----------------------------------+
| Weaviate: >99% recall default HNSW           | UNCONFIRMED         | ann-benchmarks.com        | 97.1% at defaults; >99% needs    |
|                                              |                     |                           | ef=512, not default config       |
+----------------------------------------------+---------------------+---------------------------+----------------------------------+
```

---

## Synthesis Report (RQ-10 Output)

```
# Research Swarm Report: Vector Database Evaluation

Date: 2026-04-06
Depth: deep
Questions: 10  |  Agents: 10  |  Waves: 3

## TLDR

- Qdrant is the strongest fit: Apache 2.0, best independent benchmark QPS at 1M
  vectors, solid Python SDK, and cloud pricing well under the $500/month ceiling.
- Weaviate Cloud is a viable alternative with better GraphQL tooling but higher
  cost and a vendor-only claim on >99% recall that does not hold at defaults.
- pgvector covers the "stay on Postgres" path but is outperformed at 1M+ vectors
  and lacks native sharding; suitable only if operational simplicity outweighs
  query performance.
- Pinecone is proprietary and closed-source; eliminated by the license requirement.
- Chroma is not production-ready for 500K+ document corpora due to API instability.

## Findings

### Licensing (CONFIRMED)

Qdrant, Weaviate, Chroma, Milvus, and pgvector all meet the Apache 2.0 / MIT /
BSD requirement. Pinecone is proprietary and is eliminated from consideration.
[CONFIRMED: Apache 2.0 verified in Qdrant GitHub repo].

### Performance at Target Scale

[CONFIRMED] Qdrant achieves 98.7% recall and 1,420 QPS at 1M vectors (independent
benchmark, ann-benchmarks.com, 2025-Q4).

[CONFIRMED] pgvector achieves 96.2% recall and 480 QPS at 1M vectors on comparable
hardware. Adequate for low-traffic features; insufficient above ~500 concurrent users.

[UNCERTAIN] Weaviate's >99% recall claim is based on tuned settings (ef=512), not
defaults (97.1% at defaults). Teams should test with their own data before relying
on this figure.

### Cost at Target Scale

Self-hosted Qdrant on a $40/month VPS (4 vCPU, 16 GB RAM) is sufficient for 500K
docs and estimated traffic. Qdrant Cloud at the 4 vCPU tier runs ~$80/month. Both
are well inside the $500/month ceiling. [LIKELY: based on vendor calculator + community
reports; actual cost depends on query patterns].

Weaviate Cloud at comparable specs runs ~$200/month based on SU pricing. Manageable
but 2.5x more expensive.

### Scaling Path

Qdrant supports multi-node sharding and replication. Manual rebalancing is a known
limitation but does not block the team's current scale. At 10M vectors the team should
plan for a 3-node cluster. [CONFIRMED: Qdrant documentation, community reports].

### Migration from pgvector

Direct migration from pgvector requires: (1) exporting vectors as numpy arrays or
parquet, (2) re-ingesting via Qdrant Python client batch upload, (3) re-running any
metadata filtering tests. No turnkey migration tool exists; estimated effort is
1-2 engineering phases. [LIKELY: based on documented Qdrant ingestion API + pgvector
pg_dump limitations].

### SDK Quality

All four shortlisted clients (Qdrant, Weaviate, Pinecone, Chroma) have maintained
Python SDKs. Qdrant and Weaviate are typed, stable, and actively maintained. Chroma
has a history of breaking API changes and is not recommended for production. [CONFIRMED:
PyPI download trends, GitHub issue tracker analysis].

## Recommendation

**Adopt Qdrant (self-hosted first, migrate to Qdrant Cloud when operational overhead
becomes a concern).**

Rationale:
- Meets all hard constraints (Apache 2.0, Python SDK, $500/month ceiling).
- Best independent recall and QPS at target scale.
- Cloud option exists if the team wants to shed operational responsibility later.
- Active community and maintainer responsiveness (median issue response < 3 days).

Secondary option: Weaviate Cloud if the team prefers a fully managed path from day one
and the higher cost is acceptable.

Ruled out: Pinecone (proprietary), Chroma (API instability), pgvector (performance
gap at 1M+ vectors).

## Pros and Cons Table

+---------------------+--------------------------------------+------------------------------------+
| Option              | Pros                                 | Cons                               |
+---------------------+--------------------------------------+------------------------------------+
| Qdrant self-hosted  | Free to run; best benchmark perf;    | Manual shard rebalancing; ops      |
|                     | Apache 2.0; strong Python SDK        | overhead for cluster management    |
+---------------------+--------------------------------------+------------------------------------+
| Qdrant Cloud        | Managed; same perf; easy scale-up    | ~$80/month vs. ~$40 self-hosted    |
+---------------------+--------------------------------------+------------------------------------+
| Weaviate Cloud      | Fully managed; GraphQL native;       | 2.5x cost; recall claim overstated |
|                     | BSD 3-Clause                         | at default settings                |
+---------------------+--------------------------------------+------------------------------------+
| pgvector            | No new infra; Postgres-native        | Lower QPS; no native sharding;     |
|                     |                                      | will bottleneck at 1M+ vectors     |
+---------------------+--------------------------------------+------------------------------------+
| Pinecone            | Best-in-class managed UX             | Proprietary; eliminated by license |
|                     |                                      | requirement                        |
+---------------------+--------------------------------------+------------------------------------+
| Chroma              | Easy local dev; high DL count        | API instability; not prod-ready    |
|                     |                                      | for 500K+ corpus                   |
+---------------------+--------------------------------------+------------------------------------+

## Open Questions

- What is the actual re-indexing time for 500K docs during the migration from pgvector?
  Run a benchmark on a sample before committing.
- Qdrant shard rebalancing is listed as "roadmap." Monitor release notes for v1.9+.
- Weaviate's ef=512 configuration: is the recall gain worth the QPS tradeoff for this
  use case? Test before dismissing Weaviate as the secondary option.

## Sources

- ann-benchmarks.com: independent QPS and recall benchmarks, 2025-Q4 dataset
- github.com/qdrant/qdrant: LICENSE file, release notes, shard documentation
- qdrant.tech/documentation: scaling and replication architecture
- weaviate.io/developers/weaviate: HNSW configuration guide
- pinecone.io/pricing: serverless tier limits (snapshot 2026-04-01)
- HN thread "Running Qdrant in production" (2025-11): community scaling reports

## Methodology
- 10 agents across 3 waves
- Tools used: WebSearch, WebFetch
- Cross-verification: 3/3 key claims checked; 1 confirmed, 1 partially confirmed,
  1 refuted (Weaviate recall at defaults)
```

---

## How the Research Feeds into a Decision

The Synthesis Report is a handoff artifact. Once it is reviewed by the team, the next
step is execution, not more research. The recommended decision tree:

1. **Accept the recommendation** (Qdrant self-hosted): spawn a Worker Swarm to write
   the integration plan, set up a proof-of-concept index, and draft the migration
   script from pgvector.

2. **Dispute a finding** (e.g., the team already has Weaviate expertise): use the
   Open Questions section to scope a targeted follow-up. A single agent or a 3-question
   mini-swarm can resolve the specific uncertainty without re-running the full research.

3. **Blockers surface later** (e.g., legal reviews the Weaviate BSD license): consult
   the Sources section directly. Each finding includes a citation so legal can audit
   claims without involving the engineering team.

The research does not make the decision. The team makes the decision. The research
eliminates options that cannot meet hard constraints, surfaces the tradeoffs among the
remaining options, and provides citations so decisions can be audited and revisited as
the landscape changes.

---

## Related Documents

- [Research Swarm pattern](../patterns/research-swarm.md): full pattern reference,
  including manifest schema, wave design rules, model selection, and anti-patterns
- [Research Manifest Schema](../references/research-manifest-schema.md): JSON schema
  definition and validation rules for manifest files
- [Worker Swarm](../patterns/worker-swarm.md): the execution pattern to use after
  this research concludes
- [Patterns Overview](../patterns/overview.md): choose the right pattern for your task
- [Model Selection Guide](../guides/model-selection.md): when to use haiku vs. sonnet
  vs. opus

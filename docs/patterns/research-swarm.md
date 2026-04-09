---
title: Research Swarm
description: Wave-based multi-agent pattern for parallel discovery across codebases or the internet, with manifest-driven execution and structured synthesis.
---

# Research Swarm

The Research Swarm pattern fans out multiple agents to investigate different facets of a
question in parallel, then merges their findings into a single synthesis artifact. It is the
right pattern when you need to discover information you do not already have, rather than
execute work you have already planned.

Two variants share the same structure:

- **Codebase Research Swarm**: agents use Grep, Glob, and Read to scan a codebase in parallel.
- **Internet Research Swarm**: agents use WebSearch and WebFetch to gather external data.

The manifest, wave model, synthesis contract, and agent prompt structure are identical
across both variants. The only difference is the tool set assigned to each agent.

---

## When to Use It

Use the Research Swarm when:

- You need to map a landscape before deciding what to build or change.
- A codebase is large enough that a single agent cannot hold all relevant context.
- You are doing competitive or technology landscape analysis.
- You need an audit scan across a system (security, dependency, pattern usage).
- You have a complex question with multiple independent sub-questions that can be
  researched in parallel.

Do not use it for:

- Tasks where the work is already defined. Use Worker Swarm instead.
- Simple questions a single agent can answer in one pass.
- Tasks that require sequential reasoning where each step depends on the last.

The Research Swarm is a discovery pattern. Once it produces a Synthesis Report, a
Worker Swarm or a single agent takes the findings and acts on them.

---

## Core Concepts

### The Manifest

Every Research Swarm starts with a manifest: a JSON or YAML file that lists all research
questions, assigns each to a wave, and declares dependencies between questions.

The manifest is the contract between the operator and the agents. Writing it forces you to
decompose the research question before spawning any agents. This prevents the two most
common failure modes: overlapping searches that produce duplicate results, and missed
facets that leave gaps in the final report.

Store manifests at `.ai/research-batches/<topic-slug>.json` or a similar location your
team uses for scratch artifacts.

**Manifest schema:**

```json
{
  "meta": {
    "topic": "string: the research subject",
    "created": "YYYY-MM-DD",
    "depth": "shallow | standard | deep",
    "total_questions": 8,
    "output": "report | structured-data | comparison"
  },
  "questions": [
    {
      "id": "RQ-01",
      "question": "What is the current state of X?",
      "model_tier": "sonnet",
      "wave": 1,
      "sources": ["websearch", "webfetch"],
      "depth": "broad | focused | exhaustive",
      "blockedBy": [],
      "context": "Optional background the agent needs."
    }
  ]
}
```

Key fields:

- `id`: Use `RQ-NN` prefix (Research Question). IDs are referenced in `blockedBy`.
- `wave`: Integer. All questions in the same wave run in parallel. Lower waves run first.
- `blockedBy`: Array of question IDs that must complete before this question starts.
  An empty array means the question runs in wave 1 with no prerequisites.
- `model_tier`: `haiku` for mechanical extraction, `sonnet` for analysis, `opus` for
  complex multi-source synthesis.
- `sources`: Allowed tool categories for this question.
- `depth`: `broad` (wave 1 discovery), `focused` (wave 2 deep dives),
  `exhaustive` (wave 3 verification).
- `context`: Background the agent needs, including relevant findings from earlier waves.
  Populate this field after prior waves complete.

### Wave Execution

Waves enforce a dependency order while maximizing parallelism within each wave.

```
Wave 1: RQ-01, RQ-02, RQ-03 (all run in parallel, no dependencies)
           |         |        |
           v         v        v
Wave 2: RQ-04 (blocked by RQ-01, RQ-02), RQ-05 (blocked by RQ-03)
           |                              |
           v                              v
Wave 3: RQ-06 (blocked by RQ-04, RQ-05) -> RQ-07 (blocked by RQ-06)
```

The operator reviews all results from a wave before spawning the next. This review step
is not optional: wave 2 agent prompts must include relevant findings from wave 1, and the
operator decides which threads from wave 1 are worth pursuing in wave 2.

**Three-wave default:**

- Wave 1 (Broad Discovery): 4-6 agents map the landscape, identify key entities and players.
- Wave 2 (Deep Dives): 3-5 agents go deep on the most important wave 1 findings.
- Wave 3 (Verification and Synthesis): 2-3 agents cross-check key claims; one agent
  produces the final Synthesis Report.

Adapt based on depth setting: shallow (4 questions, 2 waves), standard (6-8 questions,
3 waves), deep (8-12 questions, 3-4 waves).

### Synthesis

The operator (or a dedicated synthesis agent) merges all wave outputs into one
Synthesis Report. Intermediate agent outputs are disposable once merged.

Merge rules:

1. **Deduplicate**: same fact from multiple agents becomes one entry with multiple
   citations (higher confidence).
2. **Resolve conflicts**: prefer primary sources over secondary, more recent over older,
   more specific over general. Flag unresolved conflicts explicitly.
3. **Confidence scoring**:
   - CONFIRMED: 2 or more independent sources agree.
   - LIKELY: 1 strong primary source.
   - UNCERTAIN: 1 weak source or conflicting data across agents.
   - UNVERIFIED: no independent confirmation found.
4. **Cross-verification gate**: key claims must be confirmed by at least 2 independent
   agents or sources before inclusion in the final report.

---

## Codebase Research Swarm

Agents use file system tools to scan a codebase in parallel. This variant is suited for:

- Auditing a large codebase for patterns (security, deprecated APIs, test coverage gaps).
- Mapping where a concept or abstraction is used across many files.
- Gathering context before a large refactor.
- Understanding an unfamiliar codebase.

**Tool assignments for codebase agents:**

```
+------------+--------------------------------------------------+
| Tool       | Best For                                         |
+------------+--------------------------------------------------+
| Glob       | Finding files by name pattern or extension       |
| Grep       | Searching for patterns, symbols, or text         |
| Read       | Reading specific files once located              |
| Bash (git) | Log, blame, diff for history and ownership       |
+------------+--------------------------------------------------+
```

**Codebase agent prompt template:**

```text
You are a codebase research agent. Your task is to investigate one aspect of this
repository.

QUESTION (RQ-NN): <question text>

SCOPE: <directory or file pattern to focus on>

CONTEXT: <background from prior waves, if any>

TOOLS AVAILABLE:
- Claude Code: Glob, Grep, Read (dedicated file tools)
- Codex: standard file operations (read_file, search_files, list_directory or equivalent native tools)
- OpenClaw: plugin tools registered via `api.registerTool()` - use whatever file tools are registered

Note: Tool names are runtime-specific. Use the file search and read capabilities native to your runtime.

INSTRUCTIONS:
1. Locate relevant files using the file search tool for your runtime
2. Find occurrences of key patterns or symbols using the search tool for your runtime
3. Examine specific files in detail using the file read tool for your runtime
4. Compile findings as structured bullets with file paths and line references

OUTPUT FORMAT:
## Findings for RQ-NN: <question>

### Key Facts
- Fact 1 (File: path/to/file.ts, line 42)
- Fact 2 (File: path/to/other.ts)

### Patterns Observed
- Pattern: description, locations

### Anomalies or Risks
- Any unexpected findings

### Open Questions
- Questions that surfaced for wave 2 follow-up

### Confidence: HIGH | MEDIUM | LOW
<one-line justification>
```

**Wave design for codebase scans:**

In a codebase swarm, wave 1 agents typically scan broad areas (directories, file types,
top-level patterns) while wave 2 agents drill into specific files or call sites identified
in wave 1. Wave 3 agents verify or cross-reference findings before synthesis.

Assign non-overlapping scopes per agent to prevent duplicate coverage. If two agents both
need to read the same core file, treat it as shared context and include its content in
the operator's review step rather than assigning it to both.

---

## Internet Research Swarm

Agents use web tools to gather external data. This variant is suited for:

- Technology landscape analysis.
- Competitive research.
- Evaluating a vendor, library, or API before adoption.
- Gathering facts to inform a design decision.

**Tool assignments for internet agents:**

```
+------------+--------------------------------------------------+
| Tool       | Best For                                         |
+------------+--------------------------------------------------+
| WebSearch  | Current events, recent releases, broad landscape |
| WebFetch   | Specific URLs, documentation pages, API specs    |
+------------+--------------------------------------------------+
```

**Wave 1 discovery agent prompt template:**

```text
You are a research agent. Your task is to investigate one facet of: "<TOPIC>"

QUESTION (RQ-NN): <question text>

CONTEXT: <any background the operator provides>

TOOLS AVAILABLE: WebSearch, WebFetch

INSTRUCTIONS:
1. Run 2-3 web searches with varied query phrasings
2. For promising leads, fetch the source page directly with WebFetch
3. Focus on primary sources: official docs, announcements, benchmarks
4. Compile findings as structured bullets with source URLs

OUTPUT FORMAT:
## Findings for RQ-NN: <question>

### Key Facts
- Fact 1 (Source: <url>)
- Fact 2 (Source: <url>)

### Entities Discovered
- Entity Name: brief description, relevance to topic

### Open Questions
- Questions that surfaced for wave 2 follow-up

### Confidence: HIGH | MEDIUM | LOW
<one-line justification>
```

**Wave 2 deep dive agent prompt template:**

```text
You are a research agent doing a deep dive. Topic: "<TOPIC>"

QUESTION (RQ-NN): <question text>

PRIOR FINDINGS (from Wave 1):
<operator pastes relevant wave 1 bullets here>

TOOLS AVAILABLE: WebSearch, WebFetch

INSTRUCTIONS:
1. Build on the prior findings; do not re-research what is already known
2. Read primary sources directly using WebFetch
3. Resolve any contradictions surfaced in prior findings
4. Focus on depth and citation quality over breadth

OUTPUT FORMAT:
## Deep Dive: RQ-NN - <question>

### Analysis
<2-4 paragraphs of structured analysis with inline citations>

### Key Takeaways
- Takeaway 1
- Takeaway 2

### Sources
- [Title](url) - what it contributed

### Confidence: HIGH | MEDIUM | LOW
```

**Wave 3 verification agent prompt template:**

```text
You are a cross-verification agent. Your job is to independently confirm or refute claims.

CLAIMS TO VERIFY:
1. "<claim A>" (Source: <original source>)
2. "<claim B>" (Source: <original source>)
3. "<claim C>" (Source: <original source>)

TOOLS AVAILABLE: WebSearch, WebFetch

INSTRUCTIONS:
1. For each claim, search for independent corroboration (a different source than original)
2. Look for counter-evidence or nuance that prior agents missed
3. Rate each claim: CONFIRMED / PARTIALLY CONFIRMED / UNCONFIRMED / REFUTED

OUTPUT FORMAT:
## Verification Results

+-------------------+-----------------------+--------------------------+------------------+
| Claim             | Verdict               | Independent Source       | Notes            |
+-------------------+-----------------------+--------------------------+------------------+
| <claim A excerpt> | CONFIRMED             | <url>                    | <notes>          |
| <claim B excerpt> | PARTIALLY CONFIRMED   | <url>                    | <nuance>         |
| <claim C excerpt> | UNCONFIRMED           | (none found)             | <notes>          |
+-------------------+-----------------------+--------------------------+------------------+
```

---

## Model Selection

Match model tier to task type. Most research agents should use Sonnet. Haiku is
appropriate only for mechanical extraction with no reasoning required. Opus is reserved
for final synthesis when merging many conflicting sources on a complex topic.

```
+---------------------+----------------+----------------------------------------------+
| Role                | Model Tier     | When to Use                                  |
+---------------------+----------------+----------------------------------------------+
| URL extraction      | haiku          | Fetching structured data from known pages    |
| Broad discovery     | sonnet         | Wave 1 landscape mapping                     |
| Deep analysis       | sonnet         | Wave 2 technical or focused research         |
| Claim verification  | sonnet         | Wave 3 cross-checking                        |
| Complex synthesis   | opus           | Merging 10+ conflicting sources (rare)       |
| Operator (lead)     | session model  | Driving execution, reviewing, merging        |
+---------------------+----------------+----------------------------------------------+
```

Default to Sonnet for 80% or more of agents. Use Haiku only when the task is pure
extraction with zero ambiguity. Reach for Opus only when synthesis involves genuinely
complex, conflicting, multi-source inputs.

---

## Synthesis Report Format

The Synthesis Report is the only deliverable. All intermediate agent outputs are
disposable once merged into this document.

```markdown
# Research Swarm Report: <TOPIC>

**Date**: YYYY-MM-DD
**Depth**: shallow | standard | deep
**Questions**: N | **Agents**: N | **Waves**: N

## TLDR
- 3-5 bullet executive summary

## Findings

### <Section per major theme>
<Structured prose with inline citations and confidence tags>

[CONFIRMED] Claim text here. [Source A](url), [Source B](url).
[LIKELY] Claim text here. [Source](url).
[UNCERTAIN] Conflicting data: Source A says X, Source B says Y.

## Entities Discovered
- Entity: description, relevance

## Open Questions
- Unanswered questions worth follow-up research

## Sources
- [Title](url) - brief note on what it contributed

## Methodology
- N agents across N waves
- Tools used: <list>
- Cross-verification: N/N key claims confirmed
```

---

## Worked Example: Technology Landscape Analysis

**Scenario**: A team wants to evaluate the current landscape of AI video generation tools
before deciding whether to integrate one into their product.

**Step 1: Decompose into a manifest**

```json
{
  "meta": {
    "topic": "AI Video Generation Landscape 2026",
    "created": "2026-04-06",
    "depth": "standard",
    "total_questions": 7,
    "output": "report"
  },
  "questions": [
    {
      "id": "RQ-01",
      "question": "What are the major AI video generation platforms available today?",
      "model_tier": "sonnet",
      "wave": 1,
      "sources": ["websearch"],
      "depth": "broad",
      "blockedBy": [],
      "context": "Include both open-source and commercial. Cover text-to-video,
                  image-to-video, and video-to-video."
    },
    {
      "id": "RQ-02",
      "question": "What are the key technical approaches used in current AI video generation?",
      "model_tier": "sonnet",
      "wave": 1,
      "sources": ["websearch", "webfetch"],
      "depth": "broad",
      "blockedBy": []
    },
    {
      "id": "RQ-03",
      "question": "What is the pricing model for the top commercial AI video platforms?",
      "model_tier": "sonnet",
      "wave": 1,
      "sources": ["websearch", "webfetch"],
      "depth": "broad",
      "blockedBy": []
    },
    {
      "id": "RQ-04",
      "question": "How do the top 3 platforms compare on output quality, speed, and API access?",
      "model_tier": "sonnet",
      "wave": 2,
      "sources": ["webfetch", "websearch"],
      "depth": "focused",
      "blockedBy": ["RQ-01", "RQ-03"],
      "context": "Use wave 1 findings to identify which platforms are worth comparing."
    },
    {
      "id": "RQ-05",
      "question": "What are the most capable open-source video generation models and their limits?",
      "model_tier": "sonnet",
      "wave": 2,
      "sources": ["websearch", "webfetch"],
      "depth": "focused",
      "blockedBy": ["RQ-01"]
    },
    {
      "id": "RQ-06",
      "question": "Verify key claims about pricing, quality benchmarks, and API availability.",
      "model_tier": "sonnet",
      "wave": 3,
      "sources": ["websearch", "webfetch"],
      "depth": "exhaustive",
      "blockedBy": ["RQ-04", "RQ-05"]
    },
    {
      "id": "RQ-07",
      "question": "Synthesize findings into a landscape report with a build-vs-buy recommendation.",
      "model_tier": "sonnet",
      "wave": 3,
      "sources": [],
      "depth": "exhaustive",
      "blockedBy": ["RQ-06"],
      "context": "Use case: short-form video content for SMB clients. Budget-sensitive.
                  Quality matters more than speed."
    }
  ]
}
```

**Step 2: Execute waves**

Wave 1: Spawn RQ-01, RQ-02, RQ-03 as 3 parallel agents (all have empty `blockedBy`).

Operator reviews wave 1 results. Selects threads for wave 2. Pastes relevant wave 1
findings into the `context` field for RQ-04 and RQ-05.

Wave 2: Spawn RQ-04 and RQ-05 in parallel. RQ-04 is blocked by RQ-01 and RQ-03
(now complete). RQ-05 is blocked by RQ-01 (now complete).

Operator reviews wave 2. Extracts 5-8 key claims for RQ-06 to verify.

Wave 3: Spawn RQ-06 (verification). After RQ-06 completes, spawn RQ-07 (synthesis).
RQ-07 is blocked by RQ-06.

**Step 3: Output**

RQ-07 produces the Synthesis Report. The operator reviews it, resolves any remaining
flags, and saves the final document.

**Agent and model summary for this example:**

```
+-------+--------+------------------+--------+---------------------------+
| ID    | Wave   | Question Type    | Model  | blockedBy                 |
+-------+--------+------------------+--------+---------------------------+
| RQ-01 | 1      | Landscape        | sonnet | (none)                    |
| RQ-02 | 1      | Technical        | sonnet | (none)                    |
| RQ-03 | 1      | Pricing          | sonnet | (none)                    |
| RQ-04 | 2      | Comparison       | sonnet | RQ-01, RQ-03              |
| RQ-05 | 2      | Open-source dive | sonnet | RQ-01                     |
| RQ-06 | 3      | Verification     | sonnet | RQ-04, RQ-05              |
| RQ-07 | 3      | Synthesis        | sonnet | RQ-06                     |
+-------+--------+------------------+--------+---------------------------+
```

10 agents would be appropriate for a deeper version of this same question: split each
wave 1 question across 2 agents assigned to different source types, then run the same
wave 2 and wave 3 structure. The manifest scales linearly.

---

## Claude Code Usage

In Claude Code, the operator is the main session. Research agents are background Task
workers spawned with the `Task(...)` tool.

Each wave is a batch of parallel `Task(...)` calls. The operator awaits all tasks in a
wave before reviewing results and spawning the next wave.

The operator's prompt for each agent should include:

1. The question text from the manifest.
2. The `context` field content (especially wave 1 findings for wave 2 agents).
3. The allowed tools for this question.
4. The required output format (structured bullets, confidence tag, source citations).

After all waves complete, the operator either writes the Synthesis Report directly or
spawns a final synthesis agent with all wave outputs as context.

---

## Codex Usage

Codex does not have native background sub-agent spawning within a single session.

The Codex adaptation treats each wave as a bounded retrieval and synthesis cycle within
the main session:

1. Create the manifest exactly as described above.
2. Execute wave 1 through parallel tool calls (web searches, file reads) rather than
   spawning independent agents.
3. Review wave 1 results before proceeding to wave 2.
4. Repeat for each wave, respecting `blockedBy` ordering.
5. If true parallel fan-out is required, open multiple Codex sessions (one per agent)
   and have the operator session collect results.

The manifest, wave structure, cross-verification gate, and Synthesis Report format are
the same regardless of platform. Codex operators run the same process with sequential
tool calls substituting for parallel agent spawning.

> **Codex: wave gating is manual.** Codex has no native `blockedBy` enforcement. Run all
> Wave 1 agents (or tool calls), review their outputs, then initiate Wave 2. The manifest
> serves as your checklist: mark each question complete before advancing.

---

## OpenClaw Usage

In OpenClaw, `sessions_spawn` can run Wave 1 agents in parallel (up to 8 concurrent).
Each agent is a session assigned to one manifest question. Wave advancement still requires
operator review before spawning the next wave.

OpenClaw uses an announce-back model: each agent posts its synthesis file path to the
orchestrator channel on completion. The operator collects these paths, reviews all wave
outputs, then triggers the next wave.

---

## Anti-Patterns

**No manifest, no structure.** Ad hoc "go research X" produces overlapping searches and
missed facets. Always decompose into a manifest first, even a minimal one with 3-4
questions and 2 waves.

**All agents use the same query.** Agents run identical searches and return duplicate
results. Assign different facets, query phrasings, or source types per agent so each
brings genuinely new data.

**No cross-verification.** Single-source claims get treated as fact. Always run a
verification step for key claims before they enter the Synthesis Report.

**Skipping the operator review between waves.** Wave 2 agents that run without wave 1
context re-discover what wave 1 already found. The review step is mandatory.

**Returning unstructured output.** Agents return pages of prose with no structure. The
operator cannot merge unstructured output efficiently. Require the output format in every
agent prompt.

**No synthesis step.** Wave results sit as separate files with no merge. The Synthesis
Report is the only deliverable; everything else is intermediate.

**Wrong model for the task.** A stronger model for simple URL extraction wastes budget;
a weaker model for complex synthesis loses quality. Match model tier to task type.

**Overlapping file scope in codebase scans.** Two agents both scan the same directory
and return duplicate findings. Assign non-overlapping scopes explicitly in each agent's
prompt.

---

## Related Documents

- [Patterns Overview](overview.md)
- [Worker Swarm](worker-swarm.md): for executing defined work in parallel
- [Patchwork](patchwork.md): for small, mechanical, single-agent fix batches
- [Hive Mind 2-Tier](hive-mind-2tier.md): for coordinated campaigns requiring persistent state
- [Hive Mind 3-Tier](hive-mind-3tier.md): for large multi-workstream campaigns

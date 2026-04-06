---
title: Retrospective Template
description: Copy-paste template for post-sprint retrospectives. Capture what worked, what did not, and what to change before context evaporates.
---

A retrospective is a short structured review you run after every sprint, before
you move on to the next one. Its only job is to prevent the same problems from
recurring. The whole exercise should take 15 to 20 minutes. If it takes longer,
the scope is too wide.

Run a retro after every sprint, regardless of outcome. Good sprints produce
useful templates. Failed sprints produce warnings.

---

## Template

Save this file at `.ai/sprints/<sprint-slug>/retro.md` and fill it in.

```
---
sprint: <sprint slug, e.g. feat-auth-v2>
date: <YYYY-MM-DD>
pattern: <Patchwork | Worker Swarm | Research Swarm | Hive Mind>
tier: <2-tier | 3-tier | n/a>
agent_count: <number of agents spawned>
facilitator: <who ran the retro>
---

## Sprint Summary

One or two sentences: what was the sprint trying to accomplish, and did it?

## Metrics

| Metric             | Value        |
|--------------------|--------------|
| Tasks planned      |              |
| Tasks completed    |              |
| Tasks deferred     |              |
| Success rate       | <completed / planned * 100>% |
| Blockers hit       |              |
| Merge conflicts    |              |
| Rework cycles      |              |

## What Worked

- <item>
- <item>

## What Did Not Work

- <item>
- <item>

## What Surprised Us

Anything the sprint plan did not anticipate: unexpected complexity, agent
misbehavior, external dependencies, scope changes.

- <item>

## What to Change

Concrete changes for the next sprint using this pattern. One sentence per item.
Each item should be actionable, not aspirational.

- <item>

## Action Items

| Action                   | Owner      | Deadline gate     |
|--------------------------|------------|-------------------|
| <what needs to happen>   | <who>      | <phase or sprint> |
```

---

## Filled-in Example: API Integration Sprint

```
---
sprint: feat-stripe-checkout
date: 2025-11-14
pattern: Worker Swarm
tier: n/a
agent_count: 4
facilitator: Hunter
---

## Sprint Summary

Added Stripe checkout to the storefront. All four workstreams completed.
Webhook handling required two rework cycles due to a schema mismatch between
W2 and W3.

## Metrics

| Metric             | Value |
|--------------------|-------|
| Tasks planned      | 12    |
| Tasks completed    | 11    |
| Tasks deferred     | 1     |
| Success rate       | 92%   |
| Blockers hit       | 1     |
| Merge conflicts    | 3     |
| Rework cycles      | 2     |

## What Worked

- File ownership boundaries were clean. W1 and W4 had zero overlaps.
- The shared types file (types/stripe.ts) prevented three separate
  mismatches that would have surfaced as runtime errors.
- W3 wrote failing tests before any implementation, which caught the
  webhook schema issue at G1 instead of at integration.

## What Did Not Work

- W2 and W3 both modified the webhook event schema without coordinating.
  Each agent followed its own local spec instead of the shared one.
- The sprint plan did not specify which workstream owned the shared schema.
  Both agents assumed they did.

## What Surprised Us

- The Stripe test mode SDK behavior differs from production on refund events.
  This was not documented anywhere in the sprint plan and cost one full
  rework cycle to diagnose.

## What to Change

- For any sprint with a shared data schema, name one workstream as schema
  owner in the plan. All other workstreams read from it; only the owner writes.
- Add a "known SDK gotchas" section to the sprint plan for third-party
  integrations.

## Action Items

| Action                               | Owner   | Deadline gate          |
|--------------------------------------|---------|------------------------|
| Add schema ownership field to sprint | Hunter  | Next sprint plan       |
| Log Stripe SDK test-mode quirks doc  | Hunter  | Before next Stripe work|
| Ship deferred refund edge case (W4)  | Agent   | Sprint feat-stripe-v2  |
```

---

## Tips

**Run it while memory is fresh.** The best time is within an hour of the sprint
closing. Waiting a day means losing the details that matter most.

**Separate what happened from what to do about it.** Fill in "What Worked" and
"What Did Not Work" as observations first. Then write "What to Change" as
prescriptions. Mixing them produces vague entries that help no one.

**Keep "What to Change" concrete.** "Better communication" is not actionable.
"Name a schema owner in every sprint plan" is. If you cannot describe the change
in one sentence with a clear before/after, break it down further.

**Deferred tasks are not failures.** Log them accurately in the metrics. A sprint
that deferred 2 out of 12 tasks and understood why is healthier than one that
claimed 12 out of 12 and buried two incomplete items.

**Review the previous retro before the next sprint.** Before writing a new sprint
plan, open the last retro and check whether the action items were applied. If
they were not, carry them forward or explicitly drop them with a reason.

**Short retros beat skipped retros.** If you only have five minutes, fill in the
metrics and one bullet under "What to Change." That is still useful.

---

## Related

- [Post-Sprint Completion Guide](../guides/post-sprint-completion.md)
- [Sprint Planning Guide](../guides/sprint-planning.md)
- [Sprint Artifacts Reference](../guides/sprint-artifacts.md)
- [Drift Detection](drift-detection.md)

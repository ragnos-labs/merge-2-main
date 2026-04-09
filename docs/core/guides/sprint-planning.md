---
title: Sprint Planning for Multi-Agent Builds
description: How to design a multi-agent sprint before writing any code. Covers workstream definition, file ownership, dependency graphs, shared file strategy, the build spec format, and the design approval gate.
---

# Sprint Planning for Multi-Agent Builds

Multi-agent execution amplifies the quality of the plan it runs on. A clear plan with
non-overlapping file ownership and explicit dependencies produces clean, parallel output.
A vague plan produces collisions, rework, and agents that quietly diverge from the goal.

This guide covers how to plan a sprint before spawning a single agent.

---

## Why Planning Matters More With Agents

A solo developer who discovers a bad plan mid-implementation can pivot cheaply. They hold
the entire context in their head, notice the contradiction, and adjust.

Agents cannot do this. Each agent has a local view of the work. If the plan assigns two
agents the same file, both edit it and one silently overwrites the other. If a dependency
is not explicit, agents working in parallel race against a shared interface that is still
changing. If acceptance criteria are missing, agents optimize for the wrong signal.

The cost of a bad plan is not linear: it multiplies by the number of agents running it.
A 6-agent sprint with a weak plan can produce more rework than 6 sequential developers.

The rule is simple: a good plan makes agent work faster; a bad plan makes it catastrophically
slower. Spend the time before spawning.

---

## The Plan Artifact

A sprint plan is a structured document (or set of documents) stored alongside the code. It
answers four questions:

1. What are the workstreams?
2. Which files does each workstream own?
3. What are the dependencies between workstreams?
4. What does "done" look like for each workstream?

For small sprints (2-3 agents, known codebase), this can be a single YAML or JSON file.
For larger sprints (4+ workstreams, greenfield code), split into a build spec file plus a
short architecture decision record.

Store plan artifacts in a dedicated sprint directory:

```
.ai/sprints/<slug>/
  build-spec.yaml       # workstreams, owners, dependencies, acceptance criteria
  architecture.md       # numbered decisions (endpoints, auth, dispatch)
  tdd-contracts.md      # test signatures and edge cases per workstream
```

---

## Plan-to-Code Ratio

For non-trivial work, target 20-30% of total effort on planning. That means: if you expect
implementation to take 10 units of effort, spend 2-3 units on the plan.

A practical ceiling: the spec should not be longer than 2x the expected implementation.
If your plan document is growing longer than the code it describes, compress it. Agents
read plans; bloated plans dilute the signal.

Signs the plan is too thin:

- Workstream descriptions use vague language ("handle the data layer")
- No file list per workstream
- Acceptance criteria say "works correctly" without a testable condition
- Dependencies are not listed (the assumption is "everything is independent")

Signs the plan is too thick:

- The plan re-documents existing code as prose
- Every file in the repo is listed, including untouched ones
- Acceptance criteria describe implementation steps rather than outcomes

---

## Defining Workstreams

A workstream is one logical unit of work that can be assigned to a single agent or a small
team of agents. It has a clear boundary, a defined output, and can be described in a
single sentence.

Good workstream definitions:

- "Add the webhook receiver: parse incoming events, validate signatures, write to the queue"
- "Build the email delivery adapter: implement send, retry, and bounce handling"
- "Write integration tests for the auth module: cover token refresh, expiry, and revocation"

Bad workstream definitions:

- "Backend work"
- "Handle all the API stuff"
- "Finish the feature"

Each workstream should:

- Map to one set of non-overlapping files
- Have one owner (an agent or a lead with bees)
- Have acceptance criteria that can be verified without human judgment
- Be completable without waiting on another workstream, OR have an explicit dependency declared

The number of workstreams sets the ceiling on parallelism. If 3 workstreams have no
dependencies between them, all 3 can run simultaneously. If workstream C depends on a
shared interface that workstreams A and B are both changing, C cannot start until A and B
are done.

---

## File Ownership Mapping

Every file that will be created or modified during the sprint must have exactly one owner:
one workstream that is allowed to write to it.

Non-overlapping file ownership is the single most important constraint in a multi-agent
sprint. When two agents edit the same file, one will overwrite the other. This is not
always visible: if both agents work on different functions in the same file, the second
commit silently discards the first.

The ownership map is a flat list. Before spawning agents, verify that no file appears
twice.

```yaml
file_ownership:
  workstream_a:
    - src/api/webhooks.ts
    - src/api/webhooks.test.ts
    - src/api/types/webhook.ts
  workstream_b:
    - src/delivery/email.ts
    - src/delivery/email.test.ts
    - src/delivery/retry.ts
  workstream_c:
    - src/auth/token.ts
    - src/auth/token.test.ts
    - src/auth/refresh.ts
```

If you cannot assign a file to exactly one workstream, that is a design signal. Either the
workstream boundary is wrong, or the file needs to be split.

Files that no workstream will touch do not need to appear in the map.

---

## Dependency Graph

The dependency graph answers: which workstreams must complete before others can start?

Express dependencies explicitly in the build spec using a `blocked_by` field. Workstreams
with no `blocked_by` entries can start immediately and run in parallel.

```yaml
workstreams:
  - id: ws-a
    name: Webhook Receiver
    blocked_by: []          # starts immediately

  - id: ws-b
    name: Email Delivery
    blocked_by: []          # starts immediately

  - id: ws-c
    name: Integration Tests
    blocked_by: [ws-a, ws-b]  # waits for both
```

Draw the graph before finalizing the plan. If you find that every workstream depends on
every other, the boundaries are wrong: the work is not actually parallel. Redesign the
interfaces so workstreams can proceed independently.

Common dependency patterns:

- Interface-first: one workstream defines a shared interface (types, API contract) and all
  others depend on it. This workstream should be small and fast.
- Sequential pipeline: workstream A produces data that B transforms that C delivers.
  Consider whether B and C can be developed against a stub output from A.
- Independent verticals: each workstream owns a full slice (model + service + test). No
  cross-workstream dependencies. This is the fastest topology.

---

## Shared Files Strategy

Some files need to be read by multiple workstreams but should only be written by one.
Configuration files, shared type definitions, and API contracts are common examples.

Three strategies:

**1. Designate one owner, others read-only.**
Assign the shared file to one workstream. All other workstreams are told they may read
but not modify it. If they discover the file needs a change, they report back rather than
editing directly.

```yaml
shared_files:
  - path: src/types/events.ts
    owner: ws-a
    read_only_for: [ws-b, ws-c]
    note: "ws-b and ws-c may read; changes go through ws-a"
```

**2. Scaffold shared files before spawning agents.**
Write the shared interface, config schema, or type definitions before the sprint starts.
Agents treat these files as stable contracts. This is the preferred approach for well-defined
interfaces.

**3. Serialize access via dependency.**
If the shared file will be modified by one workstream and that modification is a hard
dependency for others, make the dependency explicit: the other workstreams list the
owning workstream in their `blocked_by`.

Avoid patterns where multiple workstreams modify a shared file concurrently. Even with
careful coordination, this produces merge conflicts and silent overwrites.

---

## The Build Spec

The build spec is a YAML or JSON file that formalizes the plan. It is the document you
hand to the orchestrator or lead agent before spawning workers.

Minimum required fields:

```yaml
sprint:
  slug: add-webhook-delivery        # short, kebab-case identifier
  description: >
    Add webhook receipt, email delivery, and integration test coverage
    for the event pipeline.
  pattern: worker-swarm             # patchwork | worker-swarm | research-swarm | hive-mind

workstreams:
  - id: ws-a
    name: Webhook Receiver
    description: Parse incoming events, validate HMAC signatures, write to queue
    owner: agent-a
    blocked_by: []
    critical_files:
      - src/api/webhooks.ts
      - src/api/webhooks.test.ts
      - src/api/types/webhook.ts
    acceptance_criteria:
      - POST /webhooks returns 200 for valid signature, 401 for invalid
      - Malformed payloads return 400 with error message
      - All unit tests pass

  - id: ws-b
    name: Email Delivery Adapter
    description: Implement send, retry with exponential backoff, and bounce handling
    owner: agent-b
    blocked_by: []
    critical_files:
      - src/delivery/email.ts
      - src/delivery/email.test.ts
      - src/delivery/retry.ts
    acceptance_criteria:
      - send() returns delivery ID on success
      - retry() backs off with jitter, max 3 attempts
      - bounce events update recipient status in store

  - id: ws-c
    name: Integration Tests
    description: End-to-end tests covering webhook receipt through email delivery
    owner: agent-c
    blocked_by: [ws-a, ws-b]
    critical_files:
      - tests/integration/webhook-delivery.test.ts
    acceptance_criteria:
      - Happy path: event received, email delivered, delivery ID returned
      - Failure path: invalid signature rejected before queue write
      - Retry path: transient failure recovers within 3 attempts

shared_files:
  - path: src/types/events.ts
    owner: ws-a
    read_only_for: [ws-b, ws-c]

architecture_decisions:
  - id: AD-1
    decision: "Queue is an in-process array in test, Redis list in production"
  - id: AD-2
    decision: "HMAC validation uses SHA-256, secret from environment variable WEBHOOK_SECRET"
```

The build spec is the contract between the planner and the agents. Agents should not need
to make decisions about file ownership, dependency ordering, or acceptance criteria: all of
that is in the spec.

---

## Design Approval Gate

For any sprint involving 3 or more workstreams, get explicit human sign-off on the plan
before spawning agents.

The gate is not a formality. It catches:

- Workstream boundaries that will produce merge conflicts
- Missing dependencies (workstream C assumes an interface that workstream A has not
  defined yet)
- Acceptance criteria that are untestable or wrong
- Shared files that two workstreams will both need to write

Present the plan in summary form: workstream names, file lists, dependency graph, and
acceptance criteria. The reviewer does not need to read every line. They need to answer:
"Does this decomposition make sense? Are the boundaries clean?"

Do not spawn agents until you have a clear approval signal. Spawning before approval and
then discovering a bad boundary wastes the entire agent session.

For smaller sprints (1-2 workstreams, familiar codebase), the gate can be lightweight: a
quick confirmation that the file ownership map has no overlaps and the acceptance criteria
are testable.

---

## Iterating on the Plan Mid-Sprint

Agents will sometimes discover that the plan is wrong. An interface you assumed was stable
is still changing. A file you assigned to workstream A turns out to be deeply coupled to
workstream B's work. An acceptance criterion is untestable in the current environment.

When this happens, the correct response is to stop and replan, not to have agents work
around the problem.

Signs the plan needs revision:

- An agent reports it cannot complete its workstream without modifying a file owned by
  another workstream
- Two workstreams are blocked on the same shared resource
- Acceptance criteria cannot be verified with the available tools or test infrastructure
- The dependency graph has a cycle (workstream A needs B, B needs C, C needs A)

The revision process:

1. Stop the affected workstreams before they produce conflicting output.
2. Identify the root cause: wrong boundary, missing dependency, or wrong acceptance criteria.
3. Update the build spec.
4. Get approval on the revised plan (same gate as the original).
5. Respawn with the corrected spec.

Agents that have already committed valid work do not need to be re-run. Only the workstreams
affected by the plan change need to restart.

Do not patch around a bad plan by adding coordination instructions mid-sprint ("agent A,
please check with agent B before editing that file"). This produces implicit dependencies
that are invisible to future sprints and hard to debug.

---

## Example: Planning a 4-Workstream Feature Build

Scenario: add a user notification system. Users can subscribe to events, receive email and
in-app notifications, and manage their preferences.

### Step 1: Identify workstreams

Break the feature into independent verticals:

- WS-A: Subscription management (subscribe/unsubscribe, preference storage)
- WS-B: Email notification delivery
- WS-C: In-app notification delivery
- WS-D: Integration tests

### Step 2: Identify the shared interface

WS-B and WS-C both need to know what a "notification event" looks like. WS-A produces
subscription records that WS-B and WS-C consume.

Decision: WS-A owns the event type definitions. WS-B and WS-C treat them as read-only.
Scaffold the type file before spawning agents so all workstreams work against a stable
contract.

### Step 3: Draw the dependency graph

```
WS-A (subscriptions)    ----\
                              +----> WS-D (integration tests)
WS-B (email)    --------\   /
                          ---
WS-C (in-app)   --------/
```

WS-A, WS-B, and WS-C have no dependencies between them and can run in parallel. WS-D
depends on all three.

### Step 4: Write the build spec

```yaml
sprint:
  slug: user-notifications
  description: Add subscription management, email delivery, and in-app notifications
  pattern: worker-swarm

workstreams:
  - id: ws-a
    name: Subscription Management
    blocked_by: []
    critical_files:
      - src/subscriptions/store.ts
      - src/subscriptions/store.test.ts
      - src/types/notification-event.ts   # shared type, owned here
    acceptance_criteria:
      - subscribe() returns subscription ID
      - unsubscribe() removes record and returns 204
      - preferences() returns current settings for user

  - id: ws-b
    name: Email Notifications
    blocked_by: []
    critical_files:
      - src/notifications/email.ts
      - src/notifications/email.test.ts
    acceptance_criteria:
      - send() accepts NotificationEvent, returns delivery ID
      - Unsubscribed users are silently skipped
      - Failed sends are logged with event ID

  - id: ws-c
    name: In-App Notifications
    blocked_by: []
    critical_files:
      - src/notifications/inapp.ts
      - src/notifications/inapp.test.ts
    acceptance_criteria:
      - push() stores notification in user feed
      - Feed returns notifications in reverse-chronological order
      - Read receipts update unread count

  - id: ws-d
    name: Integration Tests
    blocked_by: [ws-a, ws-b, ws-c]
    critical_files:
      - tests/integration/notifications.test.ts
    acceptance_criteria:
      - Subscribe, trigger event, verify email and in-app both fire
      - Unsubscribe, trigger event, verify no delivery
      - Preference "email_only" routes to email, skips in-app

shared_files:
  - path: src/types/notification-event.ts
    owner: ws-a
    read_only_for: [ws-b, ws-c, ws-d]
```

### Step 5: Get design approval

Present the workstream list, file map, and dependency graph to the reviewer. Confirm:

- No file appears under two workstream `critical_files` lists
- WS-D's dependency on all three is intentional (integration tests need final implementations)
- The shared type file is scaffolded before agents spawn

### Step 6: Spawn agents

With approval, spawn WS-A, WS-B, and WS-C in parallel. When all three complete and pass
their acceptance criteria, spawn WS-D.

---

## Related Docs

- [../patterns/overview.md](../patterns/overview.md): Pattern selection guide
- [../patterns/worker-swarm.md](../patterns/worker-swarm.md): Worker Swarm pattern
- [../patterns/hive-mind-3tier.md](../patterns/hive-mind-3tier.md): 3-tier Hive Mind for large sprints
- [../patterns/worktree-sprint.md](../patterns/worktree-sprint.md): Git isolation for parallel workstreams

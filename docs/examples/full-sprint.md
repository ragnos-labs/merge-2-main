---
title: "Full Sprint Example: JWT Auth Migration (3-Tier Hive Mind, 20 Agents)"
description: A complete worked example of a 3-tier Hive Mind sprint with Worktree isolation. Traces a full-stack JWT auth migration across 4 workstreams and 20 agents from audit through merge.
---

# Full Sprint Example: JWT Auth Migration

This document walks through a complete 3-tier Hive Mind sprint from setup to
merged PR. The scenario is real-world complex: migrating a full-stack application
from session-based authentication to JWT tokens. The sprint touches the backend
middleware, API route authorization, the frontend auth flow, and the database
schema, all in parallel.

Use this as a reference for how the pieces fit together. Every decision made here
(why a dependency was sequenced, what the checkpoint said, how the merge was
ordered) follows from the patterns described in the canonical docs. Links to those
docs appear throughout.

---

## Scenario

**Codebase:** A full-stack web application (Node.js backend, React frontend,
PostgreSQL database) currently using server-side sessions stored in a `user_sessions`
table. Cookies carry a session ID. All route authorization checks happen against
the session store.

**Migration goal:** Replace session-based auth with JWTs. Access tokens are
short-lived (15 minutes), refresh tokens are long-lived (7 days) and stored in
an HTTP-only cookie. A JWT blacklist table tracks revoked refresh tokens. All
route authorization switches from session lookups to JWT claim validation.

**Scope:** The migration touches 4 distinct subsystems, each with its own internal
complexity. A flat approach would require one agent to hold all of this in
context simultaneously, which degrades output quality. The correct pattern is
[Hive Mind 3-Tier](../patterns/hive-mind-3tier.md) with
[Worktree Sprint](../patterns/worktree-sprint.md) isolation.

**Why this warrants 3-tier Hive Mind:**

- 4 parallel workstreams, each with 3-5 internal tasks
- Hard cross-workstream dependency (frontend token format must match backend)
- Database migration must complete before middleware session tests can run
- 20 agents total, above the Worker Swarm ceiling of roughly 12
- Two irreversible actions (DB migration, final merge) require human checkpoints

---

## Pattern Choice

**Pattern:** Hive Mind 3-Tier
**Isolation layer:** Worktree Sprint (4 workstream branches)
**Complexity tier:** T3 (two checkpoints required, per the
[Checkpoint Protocol](../guides/checkpoint-protocol.md))

The combination of 3-tier Hive Mind and Worktree Sprint is the standard setup
for any sprint where:

1. Multiple agents will write to the same repository simultaneously
2. The work is large enough to require a Lead per workstream
3. File conflicts would be silently destructive if agents shared a checkout

Each workstream Lead operates in an isolated git worktree on its own branch.
The Orchestrator works on the sprint integration branch. Merges happen at
explicit phase gates, not continuously.

---

## Workstreams

Four workstreams cover the migration end-to-end:

```
+------+-----------------------------+------------------------------------------+
| ID   | Name                        | Scope                                    |
+------+-----------------------------+------------------------------------------+
| WS1  | Backend Auth Middleware     | JWT validation, token generation, token  |
|      |                             | refresh endpoint, middleware chain wiring|
+------+-----------------------------+------------------------------------------+
| WS2  | API Route Authorization     | Role-based access decorators, permission |
|      |                             | checks on all protected routes, replace  |
|      |                             | session lookups with JWT claim reads     |
+------+-----------------------------+------------------------------------------+
| WS3  | Frontend Auth Flow          | Login/logout UI, token storage strategy, |
|      |                             | axios/fetch refresh interceptor, token  |
|      |                             | expiry handling                          |
+------+-----------------------------+------------------------------------------+
| WS4  | Database Migration          | Drop user_sessions table, create JWT     |
|      |                             | blacklist table, write and validate      |
|      |                             | migration scripts                        |
+------+-----------------------------+------------------------------------------+
```

---

## Agent Roster

**Total: 1 Orchestrator + 4 Leads + 15 Worker Bees = 20 agents**

```
Orchestrator (T1, max effort)
  |
  +-- Lead-WS1: Backend Auth Middleware (T2, high effort)
  |     Bee-1A: audit existing middleware chain and session validation code
  |     Bee-1B: implement JWT validation middleware (verify, decode, error)
  |     Bee-1C: implement token generation and refresh endpoint
  |     Bee-1D: wire new middleware into app startup chain, remove old hooks
  |
  +-- Lead-WS2: API Route Authorization (T2, high effort)
  |     Bee-2A: audit all protected routes, catalog existing session checks
  |     Bee-2B: implement role-based permission decorator
  |     Bee-2C: replace session checks on batch 1 routes (admin, users)
  |     Bee-2D: replace session checks on batch 2 routes (content, settings)
  |
  +-- Lead-WS3: Frontend Auth Flow (T2, high effort)
  |     Bee-3A: audit current login/logout flow and token storage code
  |     Bee-3B: implement token storage and retrieval utilities
  |     Bee-3C: implement refresh interceptor for API client
  |     Bee-3D: update login/logout components and route guards
  |
  +-- Lead-WS4: Database Migration (T2, high effort)
        Bee-4A: audit user_sessions table usage across all queries
        Bee-4B: write migration script: drop sessions, create blacklist table
        Bee-4C: update ORM models and query helpers to remove sessions table
```

**Model assignment:**

```
+-------------+-------+--------+-------------------------------------------+
| Role        | Tier  | Effort | Rationale                                 |
+-------------+-------+--------+-------------------------------------------+
| Orchestrator| Best  | Max    | Cross-workstream decisions, phase gates   |
| 4 Leads     | Strong| High   | Multi-hop coordination within workstream  |
| Audit Bees  | Fast  | Low    | Read-only file scans, no ambiguity        |
| Impl Bees   | Fast  | Medium | Narrow task, well-specified by Lead       |
| Migration   | Fast  | Medium | High-stakes narrow task; medium warranted |
+-------------+-------+--------+-------------------------------------------+
```

Never assign the strongest model to Bees. The cost differential can exceed 15x
with no benefit: the Lead already resolved the ambiguity before spawning.

---

## Worktree Setup

Before spawning any Leads, the Orchestrator sets up the sprint branch structure:

```bash
# Start from main
git checkout main
git pull origin main

# Create the sprint integration branch
git checkout -b sprint/jwt-auth-migration

# Create one worktree per workstream
git worktree add .worktrees/jwt-auth--ws1-middleware   -b sprint/jwt-auth--ws1-middleware
git worktree add .worktrees/jwt-auth--ws2-routes       -b sprint/jwt-auth--ws2-routes
git worktree add .worktrees/jwt-auth--ws3-frontend     -b sprint/jwt-auth--ws3-frontend
git worktree add .worktrees/jwt-auth--ws4-database     -b sprint/jwt-auth--ws4-database
```

**Resulting layout:**

```
repo/                                          (Orchestrator: sprint/jwt-auth-migration)
.worktrees/
  jwt-auth--ws1-middleware/                   (Lead-WS1: sprint/jwt-auth--ws1-middleware)
  jwt-auth--ws2-routes/                       (Lead-WS2: sprint/jwt-auth--ws2-routes)
  jwt-auth--ws3-frontend/                     (Lead-WS3: sprint/jwt-auth--ws3-frontend)
  jwt-auth--ws4-database/                     (Lead-WS4: sprint/jwt-auth--ws4-database)
```

The Orchestrator also initializes the sprint state file and scratchpads:

```
.ai/sprints/jwt-auth-migration/
  sprint-state.md
  scratchpad-ws1.jsonl
  scratchpad-ws2.jsonl
  scratchpad-ws3.jsonl
  scratchpad-ws4.jsonl
  meta-log.jsonl
```

For full reference on the worktree lifecycle (INIT, WORK, MERGE, SYNC, FINAL),
see [Worktree Sprint](../patterns/worktree-sprint.md).

---

## Dependency Map

Before any Leads are spawned, the Orchestrator maps cross-workstream dependencies
and writes them into `sprint-state.md`. This is the most important pre-work the
Orchestrator does.

```
WS4 (database) must complete before WS1 (middleware) can run live tests
  because: JWT blacklist table must exist for token revocation tests to pass.

WS1 (middleware) must finalize the JWT payload shape before WS3 (frontend) implements
  because: the frontend refresh interceptor must know the exact token format
  (claims structure, expiry field name, token type) to parse responses correctly.

WS2 (routes) depends on WS1 (middleware) for the final middleware signature
  because: route decorators call into the middleware; the function signature
  must be stable before route-level integration tests can pass.

WS3 (frontend) and WS2 (routes) have no dependency on each other.
WS4 (database) and WS3 (frontend) have no dependency on each other.
```

**Dependency graph:**

```
WS4 --[DB ready]--> WS1 --[token format]--> WS3
                    WS1 --[middleware sig]--> WS2
```

**Sequencing decision recorded in sprint-state.md:**

```
- WS4 starts immediately (no blockers, pure DB work)
- WS1 starts immediately (can complete most work; live tests wait on WS4)
- WS2 starts audit immediately; implementation waits for WS1 middleware signature
- WS3 starts audit immediately; implementation waits for WS1 token format decision
- Orchestrator will broadcast WS1 token format after Design phase gate
```

This is the correct approach when a workstream has one blocked task but several
unblocked tasks: spawn the Lead early, instruct it to start the unblocked tasks,
and gate the blocked task explicitly.

---

## Phase Walkthrough

### Phase 0: Orchestrator Setup

The Orchestrator (before spawning any Leads) does exactly three things:

1. Writes the sprint manifest and dependency map to `sprint-state.md`
2. Initializes all scratchpad and meta-log files
3. Sets up worktrees with the `git worktree add` commands above

No code changes in Phase 0. This phase is complete when the file structure
exists and the dependency map is recorded.

---

### Phase 1: Audit and Discovery

The Orchestrator spawns all 4 Leads simultaneously. No dependencies exist at
audit time; all workstreams can scan in parallel.

Each Lead spawn prompt includes:
- The workstream scope and file ownership list
- "Phase 1: Audit only. Read-only. No code changes."
- The scratchpad path for their workstream
- The sprint state file path (read-only for Leads)
- The absolute path to their worktree directory
- Exit criteria: a structured audit report (findings, file list, risks)

**What each Lead does in Phase 1:**

Lead-WS1 spawns Bee-1A to scan the existing middleware chain and all files that
reference session validation. Bee-1A returns a file map and a list of the
session validation call sites.

Lead-WS2 spawns Bee-2A to catalog all protected routes. Bee-2A reads every
route handler and returns a table: route, HTTP method, current session check,
required role.

Lead-WS3 spawns Bee-3A to read the current login/logout components, the auth
context provider, and the API client configuration. Bee-3A returns a summary
of where session tokens are currently stored and read.

Lead-WS4 spawns Bee-4A to query the schema and grep all usages of
`user_sessions` across the codebase. Bee-4A returns a count of query sites and
identifies any cascade dependencies.

**Orchestrator receives 4 audit reports and records key findings in sprint-state.md.**

Notable audit finding: Bee-2A discovers 3 routes in the admin batch that check
session data directly rather than going through the middleware. Lead-WS2 flags
this to the Orchestrator. The Orchestrator records it as a known complexity
in the sprint state file (WS2 has more work than initially estimated, but within
scope; no replanning needed).

---

### Phase 2: Design and Test Contracts

This is the most critical phase for a migration sprint. The Orchestrator uses
the audit findings to finalize the design decisions that other workstreams
depend on.

**The Orchestrator makes two binding decisions and broadcasts them:**

Decision 1 - JWT payload shape (unblocks WS3 implementation):

```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "role": "admin | editor | viewer",
  "iat": 1700000000,
  "exp": 1700000900,
  "jti": "unique-token-id"
}
```

Refresh token is delivered in a `Set-Cookie` header (HTTP-only, Secure, SameSite=Strict).
Access token is returned in the response body and stored in memory (not localStorage).

Decision 2 - Middleware function signature (unblocks WS2 implementation):

```
verifyJWT(req, res, next)           // standard Express middleware
requireRole(role: string)           // returns middleware; wraps verifyJWT
extractUser(req)                    // returns { id, email, role } from req.user
```

The Orchestrator writes both decisions to `sprint-state.md` and broadcasts
them to all 4 Leads before they spawn any implementation Bees.

**Test contracts defined in Phase 2:**

Each Lead writes failing test stubs that define the exit criteria for their
workstream. The gate from Phase 2 to Phase 3 is blocked until all stubs are
committed to their respective workstream branches.

WS1 test stubs cover: JWT validation rejects expired tokens, validates
signature, extracts correct claims; refresh endpoint issues a new access token
given a valid refresh cookie; blacklist check blocks revoked tokens.

WS2 test stubs cover: `requireRole("admin")` blocks a request with `role: editor`;
all 14 previously cataloged protected routes return 401 on missing token.

WS3 test stubs cover: refresh interceptor fires when a 401 is received; after
refresh, the original request retries with the new token; logout clears the
token from memory and calls the revoke endpoint.

WS4 test stubs cover: migration script runs idempotently; `user_sessions` table
is absent after migration; `jwt_blacklist` table has the correct schema.

---

### Phase 3: Implementation Wave 1

Leads spawn their first wave of implementation Bees. Independent Bees within a
workstream run in parallel. Each Bee prompt includes the relevant test stubs and
the instruction: "you are not done until all assigned stubs pass."

**WS4 runs first (no dependencies on other workstreams).**

Lead-WS4 spawns Bee-4B (migration script) and Bee-4C (ORM updates) in parallel.
Bee-4B writes the migration and runs it against a test database. Bee-4C updates
all ORM models and query helpers to remove references to `user_sessions`.

When WS4 is complete and its stubs pass, Lead-WS4 commits to the WS4 branch and
reports to the Orchestrator: "WS4 Wave 1 complete. Migration runs clean.
Blacklist table verified."

The Orchestrator records WS4 completion in `sprint-state.md` and signals
Lead-WS1: "WS4 complete. You may now run live tests against the blacklist table."

**WS1 and WS2 run in parallel (WS1 no longer blocked; WS2 uses finalized signature).**

Lead-WS1 spawns Bee-1B (JWT validation middleware) and Bee-1C (token generation
and refresh endpoint) in parallel. Bee-1D (app startup wiring) is queued for
Wave 2 after B and C complete.

Lead-WS2 spawns Bee-2B (permission decorator) while simultaneously spawning
Bee-2C and Bee-2D for route batches. The decorator must be committed before
route Bees can import it; Lead-WS2 manages this intra-workstream sequencing
without involving the Orchestrator.

**WS3 audit Bees are done; implementation Bees are now unblocked by the token format decision.**

Lead-WS3 spawns Bee-3B (token storage utilities) and Bee-3C (refresh
interceptor) in parallel. Bee-3D (UI components) is queued for after Bee-3B
and Bee-3C complete (the components depend on the utilities).

**Scratchpad usage during Wave 1:**

Bee-1B appends a lock entry when it begins editing `src/middleware/auth.js`:

```json
{"bee_id": "bee-1b", "ts": "2026-01-15T10:30:00Z", "type": "lock", "payload": "editing src/middleware/auth.js:1-120"}
```

Bee-1C reads the scratchpad before starting, sees Bee-1B's lock, and begins
on `src/routes/auth.js` instead. Bee-1C appends a finding entry when it
realizes the refresh endpoint needs to call into the blacklist check:

```json
{"bee_id": "bee-1c", "ts": "2026-01-15T10:45:00Z", "type": "finding", "payload": "refresh endpoint must call blacklist.check() before issuing new token; blacklist module not yet imported in routes/auth.js"}
```

Bee-1B reads this finding when it completes its lock and adds the import
before committing. The scratchpad prevented a coordination gap that would have
caused a test failure.

---

### Phase 4: Integration and Synthesis (Midpoint)

Leads collect Wave 1 results, run their workstream tests, and report to the
Orchestrator. This is the trigger point for Checkpoint 1.

WS4: all stubs passing. Migration verified. Complete.

WS1: JWT validation and token generation stubs passing. App startup wiring
(Bee-1D) queued for Wave 2. Blacklist integration test passing.

WS2: Permission decorator stubs passing. Route batch 1 (admin, users) stubs
passing. Route batch 2 (content, settings) has 2 failing stubs due to the 3
direct-session-check routes found during audit. These are the more complex
cases and Bee-2C could not resolve them cleanly in Wave 1. Lead-WS2 will spawn
a targeted Bee for those in Wave 2.

WS3: Token storage utilities passing. Refresh interceptor passing. UI component
stubs not yet run (Bee-3D queued for Wave 2).

The Orchestrator consolidates these 4 reports and fires Checkpoint 1.

---

### Checkpoint 1: T3 Midpoint Gate

**What the T3 checkpoint looks like at the Design phase gate (and here at Wave 1
midpoint) is the most important thing to get right. This is the Orchestrator's
primary surface to the human reviewer.**

```
CHECKPOINT T3 (1/2) -- jwt-auth-migration -- Wave 1 complete, Wave 2 pending
=================================================
DONE        All 4 workstreams completed Wave 1. WS4 (DB migration) fully
            complete and verified. WS1 (middleware) core JWT logic done;
            startup wiring queued for Wave 2. WS2 (routes) 12 of 14 routes
            converted; 2 remaining are direct-session-check edge cases.
            WS3 (frontend) token utilities and interceptor done; UI components
            queued for Wave 2.

GOAL        Migrate the full application from session-based authentication to
            JWT access/refresh tokens. Replace user_sessions table with JWT
            blacklist table. Update all protected routes and the frontend auth
            flow to use JWT claims.

DEFERRED    Bee-2C could not cleanly resolve 3 routes with direct session
            checks. A targeted Bee with the audit table (route, check location,
            required change) will handle them in Wave 2. No behavioral change
            is deferred; this is implementation scope only.

RISK        WS2: 3 admin routes bypass the middleware and read session data
            directly. Pattern is older and inconsistent with the rest of the
            codebase. Targeted Wave 2 Bee will handle, but reviewer should
            be aware these routes carry higher regression risk. Recommend
            adding 2 E2E assertions to cover them.
            WS1: refresh endpoint currently has no rate limiting. Out of scope
            for this sprint; backlogged.

FILES       src/middleware/auth.js, src/routes/auth.js, src/middleware/require-role.js
            src/routes/admin.js, src/routes/users.js (batch 1)
            src/utils/tokenStorage.js, src/api/interceptors/refresh.js
            migrations/001_drop_sessions_create_blacklist.sql
            models/JwtBlacklist.js (see diff for full file list)

TEST_STATUS 38 stubs written, 31 passing, 7 failing (5 WS2 batch-2 routes,
            2 WS3 UI components), 0 skipped

NEXT        Wave 2: targeted Bee on the 2 failing WS2 route batches. WS1
            startup wiring (Bee-1D). WS3 UI components (Bee-3D). No
            irreversible actions in Wave 2.

BLOCKERS    Reviewer should confirm: are the 3 admin direct-session routes
            acceptable to carry as Wave 2 targeted work, or must they block
            Wave 2 from starting?
-------------------------------------------------
SIGNAL?     proceed | redirect <instructions> | abort
=================================================
```

The reviewer responds: `proceed` (with a note to add 2 E2E assertions for the
admin routes, which Lead-WS2 logs as a Wave 2 task).

---

### Phase 5 and 6: Implementation Wave 2

With the human checkpoint complete, Leads spawn their Wave 2 Bees.

Lead-WS2 spawns a targeted Bee for the 3 direct-session-check routes. The Bee
receives the exact audit table from Bee-2A's Wave 1 output, the middleware
signature from the sprint state file, and the instruction to add 2 E2E
assertions after converting each route. All 5 remaining stubs pass.

Lead-WS1 spawns Bee-1D for app startup wiring. Bee-1D removes the old session
middleware from `app.js`, registers the new JWT middleware in the correct order,
and verifies startup by running the app in test mode. Stubs pass.

Lead-WS3 spawns Bee-3D for UI components. Bee-3D updates the Login component,
LogoutButton, and the auth route guard to call the new token storage utilities.
Stubs pass.

At this point all 38 stubs pass across all workstreams.

---

### Phase 7: Validation

Each Lead runs their workstream's full test suite (not just the sprint stubs)
and reports to the Orchestrator.

WS1: 47 tests pass. One pre-existing test for the legacy session format was
already skipped in the original suite and remains skipped.

WS2: 63 tests pass, including the 2 new E2E assertions added for the admin
routes. The 3 previously direct-session-check routes are green.

WS3: 29 tests pass. The refresh interceptor integration test runs against a
mock JWT server; all token expiry and retry scenarios pass.

WS4: 12 tests pass. Migration is idempotent (run twice, same result). Rollback
script verified.

**Integration test:** The Orchestrator runs the cross-workstream integration test
suite on the sprint integration branch (after a phase-gate merge of all 4
workstream branches). This suite covers: login flow end-to-end, token refresh
under expiry, role-based route access, logout and blacklist check. All 8
integration tests pass.

---

### Checkpoint 2: Pre-Merge Gate

The Orchestrator fires the second and final T3 checkpoint before the merge wave.

```
CHECKPOINT T3 (2/2) -- jwt-auth-migration -- Pre-merge
=================================================
DONE        All 4 workstreams complete. 149 total tests passing across all
            workstreams (47 + 63 + 29 + 12 = 151; 2 pre-existing skips).
            8 integration tests pass on the sprint branch. Migration verified
            idempotent. Refresh interceptor E2E verified.

GOAL        Migrate the full application from session-based authentication to
            JWT access/refresh tokens. Replace user_sessions table with JWT
            blacklist table. Update all protected routes and the frontend auth
            flow to use JWT claims.

DEFERRED    Refresh endpoint rate limiting: backlogged (not a correctness
            blocker; separate concern).
            Legacy session format test: pre-existing skip, not introduced by
            this sprint.

RISK        none

FILES       31 files changed across 4 workstreams. See PR diff for full list.
            Key files: src/middleware/auth.js, src/routes/** (14 route files),
            src/utils/tokenStorage.js, src/api/interceptors/refresh.js,
            migrations/001_drop_sessions_create_blacklist.sql

TEST_STATUS 151 passing, 0 failing, 2 skipped (pre-existing)

NEXT        Merge wave: WS4 branch first (DB schema, no downstream in merge),
            then WS1 (middleware), then WS2 (routes, depends on WS1 in tests),
            then WS3 (frontend, independent of others). Open PR from sprint
            branch against main (irreversible once pushed).

BLOCKERS    none
-------------------------------------------------
SIGNAL?     proceed | redirect <instructions> | abort
=================================================
```

The reviewer responds: `proceed`.

---

## The Merge Sequence

The Orchestrator runs the merge sequence on the sprint integration branch.
Order follows the dependency graph: workstreams that others depended on go first.

```bash
git checkout sprint/jwt-auth-migration

# WS4 first: no other workstream depends on WS4 at merge time
git merge sprint/jwt-auth--ws4-database
# Result: clean merge; migration files and ORM changes land

# WS1 second: routes (WS2) and frontend (WS3) depend on the middleware signature
git merge sprint/jwt-auth--ws1-middleware
# Result: clean merge; middleware module lands

# WS2 third: depends on WS1 being present to run integration assertions
git merge sprint/jwt-auth--ws2-routes
# Result: minor conflict on app.js (WS1 and WS2 both added require() calls)
# Orchestrator resolves: keep both imports, reorder alphabetically
# git add src/app.js && git merge --continue

# WS3 fourth: independent of WS2; no conflict expected
git merge sprint/jwt-auth--ws3-frontend
# Result: clean merge
```

One merge conflict surfaced (as expected with 4 workstreams touching `app.js`).
The conflict was minor and resolved by the Orchestrator in under 2 minutes.
Worktree isolation meant this was the only conflict in the entire sprint: without
isolation, the same race would have silently overwritten one of the imports
during parallel execution.

After the merge, the Orchestrator runs the full integration suite one final time
on the sprint branch. All 8 integration tests pass.

---

## Cleanup

```bash
# Remove worktrees
git worktree remove .worktrees/jwt-auth--ws1-middleware
git worktree remove .worktrees/jwt-auth--ws2-routes
git worktree remove .worktrees/jwt-auth--ws3-frontend
git worktree remove .worktrees/jwt-auth--ws4-database
git worktree prune

# Delete workstream branches (sprint branch preserved until PR merges)
git branch -d sprint/jwt-auth--ws1-middleware
git branch -d sprint/jwt-auth--ws2-routes
git branch -d sprint/jwt-auth--ws3-frontend
git branch -d sprint/jwt-auth--ws4-database

# Archive sprint manifest (do not delete; useful for post-sprint inspection)
mv .ai/sprints/jwt-auth-migration/manifest.json \
   .ai/sprints/jwt-auth-migration/manifest.done.json
```

The sprint branch `sprint/jwt-auth-migration` is now the deliverable. Open a
pull request from it against `main`. Agents are shut down after the PR is open.
Do not merge without explicit human instruction.

---

## Final Metrics

```
+----------------------------+----------+
| Metric                     | Value    |
+----------------------------+----------+
| Total agents               | 20       |
| Orchestrator               | 1        |
| Workstream Leads           | 4        |
| Worker Bees                | 15       |
+----------------------------+----------+
| Workstreams                | 4        |
| Worktrees created          | 4        |
| Workstream branches        | 4        |
+----------------------------+----------+
| Human checkpoints fired    | 2        |
| Checkpoint 1 signal        | proceed  |
| Checkpoint 2 signal        | proceed  |
+----------------------------+----------+
| Test stubs written         | 38       |
| Tests passing at merge     | 151      |
| Tests failing at merge     | 0        |
| Pre-existing skips         | 2        |
| Integration tests          | 8        |
+----------------------------+----------+
| Files changed              | 31       |
| Merge conflicts            | 1        |
| Conflict resolution        | Manual   |
+----------------------------+----------+
| Deferred items             | 2        |
| (rate limiting, legacy     |          |
|  session test skip)        |          |
+----------------------------+----------+
| Wave 1 Bee failures        | 0        |
| Wave 1 incomplete tasks    | 7        |
| (all resolved in Wave 2)   |          |
+----------------------------+----------+
```

---

## Key Lessons from This Sprint

**The dependency map is the Orchestrator's most important output.** Recording
it before spawning any Leads prevented the WS3 team from building the refresh
interceptor against the wrong token format. Two hours of implementation work
would have been thrown away.

**Spawn Leads early even on blocked workstreams.** WS2 and WS3 were both
partially blocked on WS1's decisions. Spawning them immediately for audit
work meant they arrived at the implementation phase with full context and
a complete task list. There was no idle time.

**Scratchpad collision avoidance works.** Bee-1B and Bee-1C both needed
`src/middleware/auth.js` in Wave 1. The scratchpad lock entry resolved the
conflict without any Lead intervention. Without it, one Bee would have
silently overwritten the other's work.

**Worktree isolation shrinks merge conflicts.** Fourteen weeks of session-based
auth code across 31 files, all changed in parallel, produced exactly one merge
conflict. That conflict was two require() statements in `app.js`. Worktree
isolation is not overhead; it is what makes large parallel sprints reliable.

**Two checkpoints are the minimum for T3.** The midpoint checkpoint caught the
3 direct-session-check admin routes before Wave 2 started. Without that
surface, the reviewer would not have known about the higher regression risk on
those routes until the PR landed.

---

## Related Docs

- [Hive Mind 3-Tier](../patterns/hive-mind-3tier.md): the coordination pattern used here
- [Worktree Sprint](../patterns/worktree-sprint.md): the isolation layer used here
- [Checkpoint Protocol](../guides/checkpoint-protocol.md): checkpoint format and trigger rules
- [Overview](../patterns/overview.md): decision matrix for choosing between patterns
- [Model Selection](../guides/model-selection.md): how to assign models across tiers

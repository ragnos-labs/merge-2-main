---
title: "Worked Example: Security Audit with a Research Swarm"
description: A 30-agent security audit of a mid-sized web application using the codebase Research Swarm pattern feeding into a Worker Swarm for remediation.
---

# Worked Example: Security Audit with a Research Swarm

This example walks through a complete security audit of a mid-sized web application. A
Research Swarm (codebase variant) conducts discovery across three waves, produces a
ranked findings report, then hands off to a Worker Swarm that remediates the highest-
severity issues in parallel.

The full run uses roughly 30 agents: 10 research agents across 3 waves, a synthesis
agent, and 6 fix agents. The operator (your active session) drives every wave transition
and writes every agent prompt.

**Execution note:** This is a runtime-neutral example. The pattern and
sequencing are the point here; the exact spawn, tool, and handoff mechanics
depend on the runtime you choose. Use the matching adapter in
[Runtime Overview](../../runtimes/README.md) before copying the execution flow.

---

## Scenario

**Application:** A SaaS task management product. Node.js/Express API, Python data
processing service, React frontend, PostgreSQL database. Roughly 80,000 lines of code
across 400 files.

**Trigger:** Pre-launch security review. The team has no prior audit baseline.

**Goal:** Identify and fix all CRITICAL and HIGH findings before the production launch.
Defer MEDIUM and LOW issues to a tracked backlog.

**Pattern selected:** Codebase Research Swarm (discovery) feeding a Worker Swarm (fixes).

Why Research Swarm first? The team does not know where the vulnerabilities are. They
need discovery before they can plan remediation. A Worker Swarm alone would require
knowing what to fix. The Research Swarm surfaces that knowledge.

See [Research Swarm](../patterns/research-swarm.md) and
[Worker Swarm](../patterns/worker-swarm.md) for full pattern documentation.

---

## Research Manifest

The operator authors the manifest before spawning any agents. Writing the manifest forces
decomposition of the audit into non-overlapping scopes.

```json
{
  "id": "rm-security-audit-webapp-001",
  "description": "Security audit of Node.js/Python/React/PostgreSQL web application pre-launch.",
  "tasks": [
    {
      "id": "T1",
      "question": "What npm and pip dependencies are outdated or have known CVEs? Scan package.json, package-lock.json, requirements.txt, and Pipfile.lock.",
      "wave": 0,
      "blockedBy": [],
      "tools": ["file_discovery", "file_reading"],
      "outputFormat": "structured_report",
      "model": "haiku"
    },
    {
      "id": "T2",
      "question": "Are any secrets, API keys, tokens, or credentials hardcoded in source files, config files, or environment defaults? Scan all .js, .ts, .py, .env, .yaml, and .json files.",
      "wave": 0,
      "blockedBy": [],
      "tools": ["file_discovery", "repo_search", "file_reading"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T3",
      "question": "Audit authentication and session management: JWT handling, session expiry, password hashing, account lockout, and token storage. Focus on src/auth/, src/middleware/, and any session config.",
      "wave": 0,
      "blockedBy": [],
      "tools": ["file_discovery", "repo_search", "file_reading"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T4",
      "question": "Check for the OWASP Top 10 at a surface level: missing security headers, open CORS policy, missing CSRF protection, unprotected admin routes, and error messages leaking stack traces.",
      "wave": 0,
      "blockedBy": [],
      "tools": ["file_discovery", "repo_search", "file_reading"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T5",
      "question": "Identify all SQL query construction sites in the Node.js and Python services. Flag any string interpolation or concatenation used to build queries. Focus on findings from T1 context about database access patterns.",
      "wave": 1,
      "blockedBy": ["T1", "T4"],
      "tools": ["file_discovery", "repo_search", "file_reading"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T6",
      "question": "Audit all API endpoints for missing authorization checks. For each route, verify that ownership and role checks exist before data access. Focus on routes surfaced as risky in T3 and T4.",
      "wave": 1,
      "blockedBy": ["T3", "T4"],
      "tools": ["file_discovery", "repo_search", "file_reading"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T7",
      "question": "Review data exposure: what user data fields are returned in API responses? Are passwords, tokens, internal IDs, or PII included in responses where they should not be? Check serializers, response builders, and GraphQL/REST schema.",
      "wave": 1,
      "blockedBy": ["T3", "T4"],
      "tools": ["file_discovery", "repo_search", "file_reading"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T8",
      "question": "Cross-cutting synthesis: given the injection findings from T5, map each vulnerable call site to the endpoint that invokes it. Produce a complete attack surface list: endpoint -> vulnerable function -> raw input source.",
      "wave": 2,
      "blockedBy": ["T5", "T6"],
      "tools": ["file_discovery", "repo_search", "file_reading"],
      "outputFormat": "structured_report",
      "model": "sonnet"
    },
    {
      "id": "T9",
      "question": "Rank all findings from T1 through T7 by severity using CVSS criteria. Assign CRITICAL, HIGH, MEDIUM, or LOW to each. Group by category. Flag any finding that is exploitable without authentication.",
      "wave": 2,
      "blockedBy": ["T5", "T6", "T7"],
      "tools": [],
      "outputFormat": "structured_report",
      "model": "opus"
    },
    {
      "id": "T10",
      "question": "Produce the final Security Audit Report. Include an executive summary, ranked findings table, per-finding remediation notes, and a fix prioritization recommendation for the Worker Swarm handoff.",
      "wave": 2,
      "blockedBy": ["T8", "T9"],
      "tools": [],
      "outputFormat": "structured_report",
      "model": "opus"
    }
  ]
}
```

**Wave summary:**

```
Wave 0 (parallel): T1, T2, T3, T4
  |
Wave 1 (parallel): T5 (blocked by T1, T4), T6 (blocked by T3, T4), T7 (blocked by T3, T4)
  |
Wave 2 (partially parallel): T8 (blocked by T5, T6), T9 (blocked by T5, T6, T7)
  |                                                              |
  +---------------------------+----------------------------------+
                              |
                            T10 (blocked by T8, T9)
```

---

## Agent Configuration by Wave

```
+-----+-------+--------------------------------------------------+--------+----------+
| ID  | Wave  | Role                                             | Model  | Parallel |
+-----+-------+--------------------------------------------------+--------+----------+
| T1  | 0     | Dependency CVE scan                              | haiku  | yes      |
| T2  | 0     | Secrets scan                                     | sonnet | yes      |
| T3  | 0     | Auth and session audit                           | sonnet | yes      |
| T4  | 0     | OWASP surface check                              | sonnet | yes      |
| T5  | 1     | SQL injection point analysis                     | sonnet | yes      |
| T6  | 1     | API authorization gap analysis                   | sonnet | yes      |
| T7  | 1     | Data exposure review                             | sonnet | yes      |
| T8  | 2     | Injection-to-endpoint attack surface mapping     | sonnet | yes      |
| T9  | 2     | Severity ranking                                 | opus   | yes      |
| T10 | 2     | Final report synthesis                           | opus   | no       |
+-----+-------+--------------------------------------------------+--------+----------+
```

T1 uses haiku because it is a pure file read and pattern match with no reasoning
required. T9 and T10 use opus because they must reason across all prior findings and
make judgment calls on severity. All other agents use sonnet.

---

## Wave 0 Execution

The operator fires T1, T2, T3, and T4 as four parallel background agents.

**Sample agent prompt for T2 (secrets scan):**

```
You are a codebase security agent. Your task is to scan for hardcoded secrets.

QUESTION (T2): Are any secrets, API keys, tokens, or credentials hardcoded in source
files, config files, or environment defaults?

SCOPE: All .js, .ts, .py, .env, .yaml, .json files in the repository.

CAPABILITIES AVAILABLE: file discovery, repository search, file reading

INSTRUCTIONS:
1. Find all files matching the extensions above.
2. Search for patterns: "api_key", "secret", "password", "token",
   "private_key", "AWS_", "STRIPE_", base64-looking strings > 20 chars, hex strings
   > 32 chars.
3. For each match, inspect the surrounding context (10 lines) to determine if it is
   a real credential vs. an example or environment variable reference.
4. Flag only real or likely-real credentials. Skip "process.env.SECRET" and similar
   indirection patterns unless the fallback value is hardcoded.

OUTPUT FORMAT:
## Findings for T2: Secrets Scan

### Confirmed Hardcoded Secrets
- Secret type, file path, line number, partial value (first 4 chars only)

### Suspicious Patterns (unconfirmed)
- Pattern, file path, line number, reason for suspicion

### Clean Areas
- List directories or file types scanned with no findings

### Confidence: HIGH | MEDIUM | LOW
<justification>
```

---

## Wave 0 Sample Findings

The operator reviews all four wave-0 results before proceeding.

**T1 (Dependency scan) key findings:**
- `jsonwebtoken@8.5.1` has a known algorithm confusion CVE (CVE-2022-23529). CRITICAL.
- `Pillow==9.1.0` (Python service) has a heap buffer overflow CVE. HIGH.
- 14 additional packages have MEDIUM or LOW advisories (outdated but no active exploit).

**T2 (Secrets scan) key findings:**
- `config/development.js` line 18: hardcoded Stripe test key (`sk_test_...`). The same
  key appears in `scripts/seed-db.js` line 6. HIGH (test key, but same secret pattern
  used in other envs; confirms a habit of inline secrets).
- `services/email/client.py` line 44: SendGrid API key hardcoded as a string fallback.
  HIGH.
- `.env.example` contains a real private key that was never rotated to a placeholder.
  CRITICAL.

**T3 (Auth audit) key findings:**
- JWTs signed with `HS256` using a key sourced from `process.env.JWT_SECRET`, but
  `process.env.JWT_SECRET` has a hardcoded fallback `"dev-secret"` in
  `src/middleware/auth.js` line 12. CRITICAL (any attacker who knows the fallback can
  forge tokens).
- Password reset tokens never expire. HIGH.
- No account lockout after repeated failed logins. MEDIUM.
- Session cookies set without `HttpOnly` or `Secure` flags in the staging config. HIGH.

**T4 (OWASP surface check) key findings:**
- CORS is set to `origin: "*"` with `credentials: true` in `src/app.js` line 34.
  CRITICAL. This combination allows any website to make credentialed cross-origin
  requests.
- No `helmet` or equivalent security headers middleware. MEDIUM.
- `/api/admin/users` and `/api/admin/billing` return `404` for unauthenticated requests
  but `403` for authenticated non-admins. The asymmetry confirms the routes exist and
  narrows an attacker's enumeration target. LOW (information disclosure, not
  exploitable directly).
- Stack traces included in error responses in production config. MEDIUM.

---

## Wave 1 Execution

The operator reviews wave-0 output, extracts key context, and populates the `context`
field for T5, T6, and T7. All three fire in parallel.

Key context fed into T5: the dependency scan found no ORM enforcement; direct `pg`
client queries are used throughout. Wave-0 OWASP check noted no input sanitization
middleware. This makes SQL injection likely present.

**T5 (Injection analysis) key findings:**
- `src/tasks/repository.js`: 4 query sites use template literal string interpolation
  with unvalidated user input (task name search, filter by assignee, sort parameter).
  CRITICAL.
- `services/reports/query_builder.py`: `ORDER BY` clause constructed via f-string with
  the raw `sort_field` request parameter. CRITICAL.
- `src/admin/search.js`: wildcard LIKE query with raw input. HIGH.

**T6 (Authorization gaps) key findings:**
- `GET /api/tasks/:taskId` fetches the task by ID without checking whether the requesting
  user owns it or is a member of the task's workspace. Any authenticated user can read
  any task by guessing IDs. CRITICAL (broken object level authorization).
- `PUT /api/workspaces/:workspaceId/members` checks that the caller is authenticated but
  not that they are an admin of the target workspace. Any member can add members to any
  workspace. HIGH.
- `GET /api/users/:userId/billing` has no ownership check. Any user can read any other
  user's billing details. CRITICAL.

**T7 (Data exposure) key findings:**
- `src/users/serializer.js`: the default user serializer includes `passwordHash`,
  `resetToken`, and `stripeCustomerId` in API responses. CRITICAL.
- The tasks list endpoint returns full user objects for each assignee including the
  fields above. CRITICAL (same root cause as serializer, but a higher-traffic route).
- Internal database row IDs (sequential integers) are exposed as public IDs in all
  routes. MEDIUM (enables enumeration attacks).

---

## Wave 2 Execution

The operator reviews wave-1 output. T8 and T9 fire in parallel. T10 fires after both
complete.

**T8 (Attack surface mapping) excerpt:**

```
Endpoint: GET /api/tasks?search=<input>&sort=<input>
  -> src/tasks/repository.js:findBySearch()     [SQL injection via search param]
  -> src/tasks/repository.js:findWithSort()     [SQL injection via sort param]
  Auth required: yes (JWT)
  Auth exploitable: no (must be logged in), but any authenticated user
  Combined risk: HIGH - any account can exfiltrate or corrupt task data

Endpoint: GET /api/reports/export?sort_field=<input>
  -> services/reports/query_builder.py:build_order_clause()  [SQL injection via sort_field]
  Auth required: yes
  Combined risk: CRITICAL - ORDER BY injection can lead to boolean-based blind SQLi
```

**T9 (Severity ranking) summary:**

```
CRITICAL (6 findings):
  C1 - CORS wildcard + credentials (T4)
  C2 - JWT secret fallback "dev-secret" (T3)
  C3 - Real private key in .env.example (T2)
  C4 - SQL injection in tasks search/sort (T5)
  C5 - Broken object level authorization on /api/tasks/:taskId (T6)
  C6 - Password hash and reset token in user serializer output (T7)

HIGH (5 findings):
  H1 - jsonwebtoken CVE-2022-23529 (T1)
  H2 - Hardcoded Stripe and SendGrid keys (T2)
  H3 - Session cookies without HttpOnly/Secure flags (T3)
  H4 - SQL injection in reports ORDER BY (T5)
  H5 - Workspace member escalation (no admin check) (T6)

MEDIUM (4 findings):
  M1 - Password reset tokens never expire (T3)
  M2 - No account lockout (T3)
  M3 - Missing security headers (T4)
  M4 - Sequential integer IDs exposed publicly (T7)

LOW (2 findings):
  L1 - Stack traces in error responses (T4)
  L2 - Admin route enumeration via 403 vs 404 asymmetry (T4)
```

---

## Synthesis Report

T10 produces the final Security Audit Report. The operator saves it as
`.ai/security-audit-report.md`.

**Executive summary (from T10):**

The application has 6 CRITICAL vulnerabilities, any one of which is launch-blocking. The
most severe combination is C2 + C5: an attacker who discovers the hardcoded JWT secret
can forge any user token, then use the missing BOLA check to read or modify any resource
in the system. The CORS misconfiguration (C1) allows a malicious website to trigger
credentialed API calls from a victim's browser without the victim's knowledge.

Remediation of all 6 CRITICAL findings is required before launch. The 5 HIGH findings
should be resolved in the same sprint. MEDIUM and LOW findings are suitable for a
follow-up backlog.

**Ranked findings table (excerpt):**

```
+------+-------+--------------------------------------------------+-------------------------------+
| ID   | Sev   | Finding                                          | Affected File(s)              |
+------+-------+--------------------------------------------------+-------------------------------+
| C1   | CRIT  | CORS wildcard with credentials                   | src/app.js:34                 |
| C2   | CRIT  | JWT secret hardcoded fallback                    | src/middleware/auth.js:12     |
| C3   | CRIT  | Real private key in .env.example                 | .env.example                  |
| C4   | CRIT  | SQL injection (tasks search + sort)              | src/tasks/repository.js       |
| C5   | CRIT  | Missing BOLA check on /api/tasks/:taskId         | src/tasks/routes.js           |
| C6   | CRIT  | Password hash + token in user serializer         | src/users/serializer.js       |
| H1   | HIGH  | jsonwebtoken CVE-2022-23529                      | package.json                  |
| H2   | HIGH  | Hardcoded Stripe/SendGrid keys                   | config/development.js, ...    |
| H3   | HIGH  | Session cookies missing HttpOnly/Secure          | src/app.js (session config)   |
| H4   | HIGH  | SQL injection in reports ORDER BY                | services/reports/query_...py  |
| H5   | HIGH  | Workspace member escalation                      | src/workspaces/routes.js      |
+------+-------+--------------------------------------------------+-------------------------------+
```

---

## Handoff to Worker Swarm

The operator reviews the synthesis report and plans the Worker Swarm. Six fix agents
cover the 11 CRITICAL and HIGH findings, grouped by category to keep file scope clean.

**Ownership map:**

```
Worker A: Authentication fixes
  - Remove "dev-secret" JWT fallback (C2), enforce env-required key
  - Rotate .env.example to placeholder only (C3)
  - Add HttpOnly + Secure flags to session cookies (H3)
  Files: src/middleware/auth.js, .env.example, src/app.js (session block only)

Worker B: CORS fix
  - Replace CORS wildcard with an allowlist (C1)
  Files: src/app.js (CORS block only)
  Note: .app.js is split between Worker A (session) and Worker B (CORS) by line range.
        Worker A must not touch the CORS lines; Worker B must not touch the session lines.
        Operator will do a final diff review to confirm no overlap.

Worker C: SQL injection fixes (Node.js)
  - Convert all 4 string-interpolated queries in tasks/repository.js to parameterized
    queries (C4)
  - Fix wildcard LIKE query in admin/search.js (H class, reported under T5)
  Files: src/tasks/repository.js, src/admin/search.js

Worker D: SQL injection fix (Python)
  - Replace f-string ORDER BY construction with a safe allowlist approach (H4)
  Files: services/reports/query_builder.py

Worker E: Authorization fixes
  - Add ownership check on GET /api/tasks/:taskId (C5)
  - Add admin check on PUT /api/workspaces/:workspaceId/members (H5)
  - Add ownership check on GET /api/users/:userId/billing
  Files: src/tasks/routes.js, src/workspaces/routes.js, src/users/routes.js

Worker F: Serializer + dependency fixes
  - Remove passwordHash, resetToken, stripeCustomerId from default user serializer (C6)
  - Upgrade jsonwebtoken to patched version (H1)
  - Move Stripe and SendGrid keys to environment variables, remove hardcoded fallbacks (H2)
  Files: src/users/serializer.js, package.json, config/development.js,
         services/email/client.py
```

**Sample Worker C prompt:**

```
You are a security fix agent. Your task is to eliminate SQL injection vulnerabilities.

SCOPE (your files only):
- src/tasks/repository.js
- src/admin/search.js

DO NOT touch any file outside this list.

TASK:
1. Read src/tasks/repository.js. Find all 4 query sites using template literal
   string interpolation. Convert each to a parameterized query using the pg client's
   placeholder syntax ($1, $2, ...). Do not change query logic, only the construction.
2. Read src/admin/search.js. Find the LIKE query using raw user input. Replace with
   a parameterized query. Escape the wildcard character if user input is inserted
   into the LIKE pattern.
3. For each change, add a one-line comment: "// fixed: parameterized query (security)"

DONE CRITERIA:
- Zero template literals remain in any query string in these two files.
- All query parameters are passed as the second argument to the pg client call.
- Existing tests still pass (run: npm test -- --testPathPattern=tasks).

RETURN:
- List of files changed
- Count of injection sites fixed
- Any sites you could not fix and why
- Test pass/fail result
```

All six workers fire in parallel using the runtime's asynchronous worker-dispatch
mechanism.

---

## Results

**After Worker Swarm consolidation:**

```
+----------+---------+------------------------------------------+----------+
| Worker   | Status  | Findings Fixed                           | Notes    |
+----------+---------+------------------------------------------+----------+
| A (auth) | PASS    | C2, C3, H3                               |          |
| B (CORS) | PASS    | C1                                       |          |
| C (SQLi) | PASS    | C4 (4 sites), admin LIKE query           |          |
| D (SQLi) | PASS    | H4                                       |          |
| E (authz)| PASS    | C5, H5, billing ownership check          |          |
| F (misc) | PARTIAL | C6 (serializer), H1 (jwt upgrade)        | See note |
+----------+---------+------------------------------------------+----------+
```

Worker F note: the Stripe key removal (H2) was deferred. The keys are referenced in
three config locations and one shell script outside the declared scope. Worker F flagged
the out-of-scope references and stopped rather than touching undeclared files. The
operator handled the remaining config locations directly in consolidation.

**Final metrics:**

```
CRITICAL findings:     6 identified / 6 fixed
HIGH findings:         5 identified / 4 fixed / 1 deferred (H2 partial)
MEDIUM findings:       4 identified / 0 fixed (backlog)
LOW findings:          2 identified / 0 fixed (backlog)

H2 deferred action:    Operator ticket created to rotate all keys and audit remaining
                       config locations. Treated as HIGH in the pre-launch checklist.

Total agents:          10 research + 1 synthesis + 6 fix = 17 agents
Total findings:        17 identified
Fixed this sprint:     15 (all CRITICAL, 4 of 5 HIGH)
```

---

## Lessons Learned

**Wave 0 scope separation works.** Assigning non-overlapping scopes to the four wave-0
agents prevented duplicate findings and made the synthesis step fast. T2 (secrets) and
T3 (auth) both touched `src/middleware/auth.js` for different reasons, but the operator
resolved the overlap in the wave review rather than letting the agents collide.

**Feed context explicitly between waves.** Wave-1 agents that received the wave-0 summary
in their `context` field produced tighter, more actionable findings. T5 already knew to
look for raw `pg` client queries because T4 had established that no ORM was in use. This
saved T5 from re-discovering the infrastructure context.

**Opus for synthesis is worth it.** T9 and T10 used opus. The severity ranking was
internally consistent and the executive summary identified the C2+C5 combination as the
highest-risk chain, which a simpler model would likely have listed as two independent
findings. For 2 agents out of 10, the cost delta is small; the quality gain on the
deliverable that drives all downstream decisions is significant.

**Worker scope must be explicit to the line.** The `src/app.js` split between Worker A
and Worker B required explicit instruction ("do not touch the CORS lines"). Without
that, one worker would have overwritten the other's changes. In practice, splitting a
single file across two workers is a smell: prefer reorganizing the task so each worker
owns a complete file. The operator noted this for future runs.

**Partial completions are honest completions.** Worker F stopping at its scope boundary
rather than touching undeclared config files was the correct behavior. The partial result
was auditable. A worker that silently modifies out-of-scope files is harder to trust and
harder to review.

**Research Swarm first, Worker Swarm second.** This sequence holds whenever you do not
know the shape of the work. Skipping the research phase and going straight to a fix swarm
would have required the operator to manually audit 80,000 lines to write worker prompts.
The research phase produced a ranked, structured handoff document in one operator review
cycle, and the fix swarm could execute against it immediately.

---

## Related Documents

- [Research Swarm pattern](../patterns/research-swarm.md): full documentation including
  manifest schema, wave execution model, and synthesis format
- [Worker Swarm pattern](../patterns/worker-swarm.md): lead-directed execution, file
  ownership rules, and failure handling
- [Research Manifest Schema](../references/research-manifest-schema.md): JSON schema
  reference with field definitions and validation rules
- [Model Selection guide](../guides/model-selection.md): when to use haiku, sonnet, and
  opus per task type

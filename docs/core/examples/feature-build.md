---
title: "Example: Building a Notification System with a Worker Swarm"
description: A worked example of using the Worker Swarm pattern to build a multi-channel notification system (email, SMS, in-app) across 8 parallel workers.
---

# Example: Building a Notification System with a Worker Swarm

This walkthrough shows a Worker Swarm building a complete notification system from
scratch inside an existing web application. Eight workers run in parallel, each owning
a distinct module. The lead dispatches, monitors, and consolidates.

Use this as a reference for how to decompose a feature, write dispatch prompts, and
handle integration during consolidation.

**Execution note:** This is a runtime-neutral example. The pattern and
sequencing are the point here; the exact spawn, tool, and handoff mechanics
depend on the runtime you choose. Use the matching adapter in
[Runtime Overview](../../runtimes/README.md) before copying the execution flow.

---

## Scenario

The app is a Node.js/Express API with a PostgreSQL database. It has users, teams, and
events, but no notification system. The feature request:

> Add a notification system supporting email, SMS, and in-app channels. Users can set
> per-channel preferences. Notifications are queued and dispatched asynchronously.
> All channels need test coverage. The feature ships with API documentation.

The lead reviews the codebase and identifies 8 independent modules. No module depends
on another's output at implementation time; the interfaces are agreed upfront. This is a
textbook Worker Swarm setup.

---

## Pattern Selection

The lead checks the decision tree. The task has 8 independent modules with non-overlapping
files, clear done criteria per module, and no negotiation required between workers. The
score: Worker Swarm, 8 workers.

See [Worker Swarm](../patterns/worker-swarm.md) for the full pattern reference.

---

## Upfront Interface Agreement

Before dispatching, the lead defines the shared interfaces that all workers must conform
to. This is the key enabler of parallelism: workers build against agreed contracts, not
against each other's in-progress output.

The lead writes a brief interface spec and includes the relevant excerpt in each worker's
prompt.

```
Notification shape (TypeScript):
  interface Notification {
    id: string;
    userId: string;
    channel: 'email' | 'sms' | 'in_app';
    subject: string;
    body: string;
    status: 'pending' | 'sent' | 'failed';
    createdAt: Date;
    sentAt: Date | null;
  }

Queue job shape:
  interface NotificationJob {
    notificationId: string;
    channel: 'email' | 'sms' | 'in_app';
    retryCount: number;
  }

Dispatcher contract:
  Each channel adapter exports: send(notification: Notification): Promise<void>
  Throws on failure. Dispatcher catches and updates status to 'failed'.

Preferences shape:
  interface NotificationPreferences {
    userId: string;
    emailEnabled: boolean;
    smsEnabled: boolean;
    inAppEnabled: boolean;
    phoneNumber: string | null;
    email: string;
  }
```

---

## File Ownership Map

The lead produces the ownership map before dispatching a single worker. No worker sees
this map directly; the lead uses it to prevent overlap when writing prompts.

```
Worker 1 (data model):
  src/notifications/models/notification.ts
  src/notifications/models/notification-preferences.ts
  migrations/NNNN_create_notifications.sql
  migrations/NNNN_create_notification_preferences.sql

Worker 2 (email channel):
  src/notifications/channels/email.ts
  src/notifications/channels/email.config.ts

Worker 3 (SMS channel):
  src/notifications/channels/sms.ts
  src/notifications/channels/sms.config.ts

Worker 4 (in-app channel):
  src/notifications/channels/in-app.ts
  src/websocket/notification-socket.ts

Worker 5 (preferences API):
  src/notifications/routes/preferences.ts
  src/notifications/controllers/preferences.controller.ts

Worker 6 (queue and dispatcher):
  src/notifications/queue/dispatcher.ts
  src/notifications/queue/worker.ts
  src/notifications/queue/retry.ts

Worker 7 (test suite):
  tests/notifications/ (all files under this directory)

Worker 8 (API documentation):
  docs/api/notifications.md
  docs/api/notification-preferences.md

Owned by lead (consolidation only):
  src/notifications/index.ts    (barrel export, assembled after all workers finish)
  src/app.ts                    (route registration)
  package.json                  (any new dependencies)
```

Shared files are excluded from all workers. The lead handles them after all workers
complete. This prevents last-writer-wins corruption.

---

## The Lead's Dispatch Prompts

The lead writes all 8 prompts before firing any workers. Below are three representative
examples showing the level of specificity required.

### Prompt: Worker 1 (Data Model)

```
You are Worker 1 of 8 building a notification system. Your scope is strictly:
  src/notifications/models/notification.ts
  src/notifications/models/notification-preferences.ts
  migrations/NNNN_create_notifications.sql
  migrations/NNNN_create_notification_preferences.sql

Do NOT touch any file outside this list.

Task:
Create the Notification and NotificationPreferences TypeScript models and the
corresponding database migration files for PostgreSQL.

Interfaces to implement (copy exactly, do not rename fields):

  interface Notification {
    id: string;           -- UUID primary key
    userId: string;       -- FK to users.id
    channel: 'email' | 'sms' | 'in_app';
    subject: string;
    body: string;
    status: 'pending' | 'sent' | 'failed';
    createdAt: Date;
    sentAt: Date | null;
  }

  interface NotificationPreferences {
    userId: string;       -- FK to users.id, unique
    emailEnabled: boolean;
    smsEnabled: boolean;
    inAppEnabled: boolean;
    phoneNumber: string | null;
    email: string;
  }

Migration requirements:
- Use sequential migration naming: check the migrations/ directory for the current
  highest number and increment by 1 for each migration file.
- Add indexes: notifications(userId, status), notifications(createdAt).
- Default emailEnabled=true, smsEnabled=false, inAppEnabled=true in preferences.
- Both tables need created_at and updated_at columns with DEFAULT NOW().

Return when done:
- List of files created (paths only)
- SQL snippet for the notifications table CREATE TABLE (for quick review)
- Any assumptions you made about the existing schema
```

---

### Prompt: Worker 3 (SMS Channel)

```
You are Worker 3 of 8 building a notification system. Your scope is strictly:
  src/notifications/channels/sms.ts
  src/notifications/channels/sms.config.ts

Do NOT touch any file outside this list.

Task:
Implement the SMS channel adapter using a Twilio-compatible REST API.

Required interface (this is the contract the dispatcher expects):
  export async function send(notification: Notification): Promise<void>
  -- Throws on failure. Do not catch and swallow errors.

The Notification type:
  interface Notification {
    id: string;
    userId: string;
    channel: 'email' | 'sms' | 'in_app';
    subject: string;
    body: string;
    status: 'pending' | 'sent' | 'failed';
    createdAt: Date;
    sentAt: Date | null;
  }

The SMS body should be: notification.subject + "\n\n" + notification.body, truncated
to 1600 characters (Twilio max for concatenated SMS).

The adapter must read recipient phone number from the NotificationPreferences record
for the userId. Import the Preferences model from:
  src/notifications/models/notification-preferences.ts

Config (sms.config.ts) must read from environment variables:
  TWILIO_ACCOUNT_SID
  TWILIO_AUTH_TOKEN
  TWILIO_FROM_NUMBER

Do not hard-code credentials. Throw a clear error on startup if any env var is missing.

Add the twilio package to package.json if it is not already present. Check first.

Return when done:
- Files created/modified (paths only)
- The function signature of the exported send function (one line)
- Whether you needed to modify package.json and what you added
```

---

### Prompt: Worker 7 (Test Suite)

```
You are Worker 7 of 8 building a notification system. Your scope is strictly:
  tests/notifications/ (all files; create the directory if it does not exist)

Do NOT touch any file outside this directory.

Task:
Write a test suite covering all four notification system modules: email channel, SMS
channel, in-app channel, and the dispatcher/queue. Use Jest (already configured in
the project).

Files you will be testing (read them to understand the interface before writing tests):
  src/notifications/channels/email.ts
  src/notifications/channels/sms.ts
  src/notifications/channels/in-app.ts
  src/notifications/queue/dispatcher.ts

Mock all external dependencies (SMTP server, Twilio API, WebSocket connections).
Do not make real network calls in tests.

Required coverage per module:
  Email channel:
  - send() with valid notification sends correct SMTP payload
  - send() throws if SMTP config is missing
  - send() throws on SMTP connection error (mock the failure)

  SMS channel:
  - send() with valid notification sends correct Twilio payload
  - send() truncates body at 1600 characters
  - send() throws if Twilio credentials are missing
  - send() throws on Twilio API error (mock the failure)

  In-app channel:
  - send() emits correct WebSocket event to the right userId room
  - send() throws if WebSocket server is not initialized

  Dispatcher:
  - Processes a pending notification and calls the correct channel adapter
  - Updates notification status to 'sent' on success
  - Updates notification status to 'failed' and does not rethrow on channel error
  - Respects user preferences (skips channel if disabled in preferences)
  - Retries failed notifications up to 3 times before marking as failed

Create one test file per module:
  tests/notifications/email.test.ts
  tests/notifications/sms.test.ts
  tests/notifications/in-app.test.ts
  tests/notifications/dispatcher.test.ts

Return when done:
- List of test files created
- Total count of test cases written
- Any channel implementation issues you discovered while writing tests (these are
  findings for the lead to review, not for you to fix -- your scope is tests/ only)
```

---

## Worker Results

After all 8 workers complete, the lead reviews each output.

```
Worker 1 (data model):
  Delivered: 4 files. Migrations numbered correctly. Added indexes as specified.
  One assumption flagged: used SERIAL for migration sequence numbers (matches
  existing migration files in the project).

Worker 2 (email channel):
  Delivered: email.ts and email.config.ts. Used nodemailer. Updated package.json.
  Lead note: package.json is in the lead's scope, not Worker 2's. Worker touched a
  shared file. Lead will review the diff and apply the dependency manually.

Worker 3 (SMS channel):
  Delivered: sms.ts and sms.config.ts. Used twilio SDK.
  Also attempted to update package.json. Same issue as Worker 2.
  Lead will reconcile both package.json additions in consolidation.

Worker 4 (in-app channel):
  Delivered: in-app.ts and notification-socket.ts. Used socket.io rooms.
  Clean scope compliance. No shared file touches.

Worker 5 (preferences API):
  Delivered: preferences.ts route and preferences.controller.ts.
  GET and PATCH endpoints. Input validation with zod.
  One finding flagged: zod not yet in package.json. Lead to add in consolidation.

Worker 6 (dispatcher):
  Delivered: dispatcher.ts, worker.ts, retry.ts. Used BullMQ for queue.
  Flagged: BullMQ requires Redis. Added REDIS_URL env var requirement. Lead to
  confirm Redis is available in the deployment environment before merging.

Worker 7 (test suite):
  Delivered: 4 test files, 22 test cases total.
  Findings for lead: SMS channel does not truncate body -- Worker 3's implementation
  is missing the 1600-char truncation. Dispatcher does not check user preferences
  before dispatching (Worker 6 omission).

Worker 8 (API docs):
  Delivered: notifications.md and notification-preferences.md.
  Formatted as OpenAPI-style markdown with request/response examples.
  Clean scope compliance.
```

---

## Consolidation

The lead works through the results sequentially. This phase is not parallelized.

### Package.json Reconciliation

Workers 2, 3, 5, and 6 each needed new packages. Because package.json is in the lead's
scope, the lead collects all required additions and applies them in a single edit:

```
nodemailer, @types/nodemailer   (Worker 2)
twilio                          (Worker 3)
zod                             (Worker 5)
bullmq                          (Worker 6)
```

The lead runs `npm install` once after applying all additions.

### Fixing Worker 3 (SMS Truncation)

Worker 7's test suite identified that the SMS channel does not truncate the message body.
This is a Worker 3 defect. The lead reads `src/notifications/channels/sms.ts` directly,
applies the truncation fix (3 lines), and re-runs the SMS tests to confirm they pass.

No re-dispatch needed. The fix is small enough for the lead to handle directly.

### Fixing Worker 6 (Preferences Check)

Worker 7 also found that the dispatcher does not check user preferences before
dispatching. The lead reads `src/notifications/queue/dispatcher.ts`, locates the
`processJob` function, and adds the preferences lookup before the channel adapter call.
Re-runs the dispatcher tests. All 5 dispatcher cases pass.

### Wiring the Barrel Export and Route Registration

The lead assembles `src/notifications/index.ts` (the barrel export re-exporting all
channel adapters, the dispatcher, and the models) and updates `src/app.ts` to register
the preferences routes under `/api/v1/notifications/preferences`.

### Redis Dependency Review

Worker 6 flagged that BullMQ requires Redis. The lead checks the deployment config and
confirms Redis is already in the stack (used by the session store). The REDIS_URL env
var is already set. No blocker. Lead adds a note to the PR description.

### Final Verification

```
npm test -- --testPathPattern=tests/notifications/   -- 22 tests pass
npm run lint                                          -- clean
npm run build                                         -- clean
```

All 8 modules pass review. All test cases pass. No scope bleed from any worker except
the package.json touches (handled in consolidation).

---

## Final Result

The lead opens a PR with all 8 modules integrated. The PR description summarizes each
module and calls out the two integration fixes applied during consolidation.

```
PR: feat: add notification system (email, SMS, in-app channels)

Modules included:
- Notification and preferences data models + migrations (Worker 1)
- Email channel adapter via nodemailer (Worker 2)
- SMS channel adapter via Twilio REST API (Worker 3)
- In-app channel via socket.io rooms (Worker 4)
- User notification preferences API (Worker 5)
- Async queue and dispatcher via BullMQ (Worker 6)
- Full test suite, 22 cases (Worker 7)
- API documentation (Worker 8)

Integration fixes applied in consolidation:
- SMS body truncation at 1600 characters (missed by Worker 3, caught by Worker 7)
- Dispatcher now checks user preferences before routing to channel adapters
  (missed by Worker 6, caught by Worker 7)

Note: BullMQ uses the existing Redis instance (REDIS_URL). No new infrastructure
required.

Files changed: 21 source files, 4 test files, 2 migration files, 2 API docs.
```

---

## What Made This Work

**Upfront interface agreement.** Workers built against shared contracts, not against each
other's in-progress output. Without agreed interfaces, workers would have made
incompatible assumptions about the Notification shape or the send() signature.

**Strict file ownership.** Workers 2 and 3 touched package.json (the lead's scope). The
lead caught this in consolidation and reconciled cleanly. If two workers had both
modified package.json, one would have silently overwritten the other's additions.

**Worker 7 as integration test.** Assigning a dedicated test worker meant integration
defects surfaced during consolidation rather than in production. Workers 3 and 6 had
real omissions; the test worker found both.

**Lead handles small fixes directly.** When Worker 7 surfaced the SMS truncation and
preferences check issues, the lead applied both fixes in consolidation rather than
re-dispatching to the original workers. For 3-line fixes, re-dispatch is overhead; the
lead is faster.

---

## Related

- [Worker Swarm pattern](../patterns/worker-swarm.md): full reference including failure
  handling, model selection, and common mistakes
- [Decision tree](../guides/decision-tree.md): how to choose between Worker Swarm,
  Research Swarm, and Hive Mind
- [TDD integration](../guides/tdd-integration.md): how to structure test workers in
  parallel with implementation workers

---
title: General Purpose Email Triage Automation Blueprint
doc_type: prompt
schema_version: "0.7.0"
last_updated: 2026-05-16
created: 2026-05-16
backlog_id: null
clickup_task_id: null
clickup_route: null
related_backlog_ids: []
auto_sop: false
origin_organization: Ragnos
origin_author: Hunter Lee Canning
origin_website: https://ragnos.io
source_repository: https://github.com/ragnos-labs/merge-2-main
canonical_path: blueprints/email-triage-automation-blueprint.md
---

## Email Triage Automation Blueprint Contract

**Purpose**: Email Triage Automation Blueprint gives an agent-ready prompt pattern for setting up a repeatable inbox triage flow across one or more email accounts, with safe labeling, newsletter synthesis, calendar dedupe, and durable memory output.

### Provenance

- **Organization**: Ragnos
- **Author**: Hunter Lee Canning
- **Website Source**: https://ragnos.io
- **Date Created**: 2026-05-16
- **Canonical Repo Path**: `blueprints/email-triage-automation-blueprint.md`

### Entity Registry

- **Email Triage Automation Blueprint** [Document]: Reusable prompt document for configuring a morning or periodic inbox triage agent.
- **Email Account** [System]: Email source inspected through available tools, APIs, connectors, or local CLI wrappers.
- **Calendar Account** [System]: Calendar target inspected before event creation or update.
- **Automation Memory** [Document]: Durable run memory used by later automations or human operators.
- **Newsletter Roundup** [Document]: Synthesized summary of non-thread-critical newsletter and news mail.
- **High-Priority Sender Lane** [Process]: Configurable sender group that receives deeper inspection and safer handling.
- **DEPENDS_ON**: Email Triage Automation Blueprint -> Email Account (reads messages and labels)
- **DEPENDS_ON**: Email Triage Automation Blueprint -> Calendar Account (dedupes and writes events when allowed)
- **PRODUCES**: Email Triage Automation Blueprint -> Automation Memory (records run state and blockers)

### Blueprint Fit

Use this blueprint when a person wants an agent to run an inbox pass, classify mail into operational lanes, summarize newsletter or news updates, detect high-priority scheduling threads, safely create or update calendar events, and write a compact memory handoff for downstream automations.

### Email Account Role

The Email Account is the inspected inbox source. The agent reads messages, labels, existing drafts, and source links through whatever email surface the receiving environment provides.

### Calendar Account Role

The Calendar Account is the scheduling target. The agent inspects existing events before writing anything and updates matching events instead of creating duplicates.

### Output Roles

The Newsletter Roundup is the synthesized news section. The Automation Memory is the durable handoff that records run status, open threads, blockers, and downstream state.

### Priority Lane Role

The High-Priority Sender Lane is the configured sender category that receives deeper inspection, safer first-pass handling, and explicit report coverage.

This blueprint is not an executable automation definition. It is a shareable prompt pattern that should be copied, filled in, and adapted to the receiving person's tools and accounts.

### Fill-In Fields

- `[PERSON_NAME]`: Person the agent is operating for.
- `[PRIMARY_INBOX]`: Primary work, business, or professional inbox.
- `[SECONDARY_INBOXES]`: Optional personal, side-project, or alternate inboxes.
- `[READ_ONLY_SUMMARY_INBOXES]`: Optional inboxes that should only be summarized.
- `[OPERATING_GUIDE_PATH]`: Local operating guide or manifesto, if one exists.
- `[AUTOMATION_MEMORY_PATH]`: Durable memory file for this automation.
- `[PREFERRED_EMAIL_CALENDAR_TOOL]`: Preferred email/calendar CLI, API, MCP, connector, or app surface.
- `[PRIMARY_LABELS]`: Label taxonomy for the primary inbox.
- `[SECONDARY_LABELS]`: Label taxonomy for secondary inboxes.
- `[HIGH_PRIORITY_SENDERS]`: Domains, senders, systems, or sender categories that require deeper inspection.
- `[TARGET_CALENDAR]`: Calendar where events may be created or updated.
- `[LOCAL_TIMEZONE]`: Person's default timezone.

## Email Triage Automation Blueprint Procedures

**Purpose**: Email Triage Automation Blueprint procedures provide the copy-ready prompt that another agent can use after the fill-in fields are replaced.

### Agent Prompt

```text
Operate as [PERSON_NAME] for the inbox triage pass across these inboxes:

- Primary inbox: [PRIMARY_INBOX]
- Secondary inboxes: [SECONDARY_INBOXES]
- Read-only summary inboxes: [READ_ONLY_SUMMARY_INBOXES]

Before doing inbox work, read this local operating guide if it exists:

[OPERATING_GUIDE_PATH]

Then read prior automation memory from:

[AUTOMATION_MEMORY_PATH]

Use the local email and calendar tools available in this environment. If there is a preferred tool, use it first:

[PREFERRED_EMAIL_CALENDAR_TOOL]

This automation owns triage state only. Do not send mail. Do not draft replies unless explicitly instructed. Do not archive, delete, or mark messages read unless the user has explicitly allowed that behavior.

Triage each inspected inbox into:

- Action
- Waiting
- FYI
- No-reply

Respect the live label taxonomy for each account. For the primary inbox, use:

[PRIMARY_LABELS]

For secondary inboxes, use:

[SECONDARY_LABELS]

Treat read-only summary inboxes as summary-only unless their label taxonomy and mutation rules are explicitly available. If an inbox is inaccessible, report it as blocked.

Apply safe label changes only when confidence is high and the change matches the established triage workflow. When uncertain, report the intended triage instead of mutating anything.

Build one cited handoff item containing these sections:

1. Important inbound email by lane
2. Top high-priority mail block
3. Newsletter Roundup
4. Urgent threads still lacking drafts or responses
5. Links to existing drafts that need attention
6. Stale waiting threads
7. Concise triage state for downstream automations
8. Calendar events created or updated
9. Dedupe decisions
10. Blockers or inaccessible sources

Newsletter Roundup rules:

Create a separate cited Newsletter Roundup across all inspected inboxes for newsletter, news, and non-thread-critical update mail. Do not list newsletters one by one. Instead, synthesize related coverage across different emails.

Use these subsections:

- Industry and Product Updates
- Upcoming Events
- Catch-All

Lead with Industry and Product Updates. Each bullet should summarize the key development and explicitly say when multiple newsletters covered the same event, launch, research item, company move, funding story, regulation, or product update.

For Upcoming Events, classify each item as:

- local
- out of range
- remote
- unclear

Every roundup item must include clickable email citations to every underlying source email or thread.

High-priority lane rules:

Treat inbound threads from these senders, domains, systems, or sender categories as high priority:

[HIGH_PRIORITY_SENDERS]

Examples of high-priority sender categories:

- active client or customer domains
- legal, accounting, finance, or compliance senders
- recruiting, hiring, booking, or scheduling systems
- executive, investor, partner, or vendor contacts
- support escalations or incident-notification systems
- project-critical notification addresses

Do not archive high-priority threads on first pass.

When confidence is high and the thread is active, apply Action immediately. Apply a secondary label such as Client, Money, VIP, Project, Legal, Hiring, or Support only when clearly appropriate and available in the account taxonomy.

Calendar extraction rules:

For high-priority scheduling threads, inspect whether the message contains an appointment, deadline, due date, callback, meeting, interview, booking, submission requirement, reminder, or event invitation.

If it does, extract:

- event name
- event type
- date
- time
- timezone
- location or remote link
- source sender or domain
- source email thread link
- submission, preparation, agenda, or follow-up details

Before creating a calendar event, inspect nearby relevant inbox threads and existing calendar events in a reasonable surrounding window. Dedupe by event name, person or organization, project or topic, date, time, and type.

If a matching event already exists, update it instead of creating a new one. If the same event appears in multiple emails, treat the emails as one event record. Prefer the richest or most recent details.

If no matching event exists, create a calendar event on [TARGET_CALENDAR].

Use the event name as the base title. Prefix it with a type marker only when explicit, for example:

- [Meeting]
- [Deadline]
- [Interview]
- [Submission]
- [In Person]
- [Remote]
- [Callback]

If only a date is available, create an all-day event. If a start time exists but no end time is provided, use a reasonable default duration and note that assumption in both the calendar description and the report.

If the event type is unclear, do not guess. Say so in the report and use a neutral event title.

Email link rules:

For clickable email citations, prefer tool-returned fields such as:

- gmailThreadUrl
- gmailDraftUrl
- gmailUrl
- display_url
- webUrl
- permalink

If the account uses Gmail and thread fields are missing, build links manually:

Thread:
https://mail.google.com/mail/?authuser=<account>#all/<threadId>

Draft:
https://mail.google.com/mail/?authuser=<account>#drafts?compose=<draftId>

Never use /mail/u/<email>/ paths.

Memory update rules:

At the end, update automation memory with:

- open threads
- triage state
- stale threads
- high-priority threads
- calendar actions
- dedupe decisions
- newsletter-roundup highlights
- follow-up candidates
- targeted human questions
- blockers

Final step, always execute even if earlier steps failed:

Write at minimum these lines to [AUTOMATION_MEMORY_PATH] before exit:

last_run: <ISO 8601 UTC timestamp>
status: <ok | partial | error>
notes: <one short sentence about what ran, what did not run, and why if applicable>

This final memory write must happen before exit unconditionally. If nothing else can be written, write those lines. Preserve any richer existing memory format on successful runs, but memory must never be older than this run.
```

## Email Triage Automation Blueprint Reference

**Purpose**: Email Triage Automation Blueprint reference records the adaptation rules that keep the prompt reusable outside its original environment.

### Adaptation Notes

The high-priority lane should match the receiving person's work and life. Common configurations include active clients, sales leads, recruiting processes, legal notices, invoices, customer escalations, internal leadership messages, event bookings, and time-sensitive operations alerts.

The invariant is not the category itself. The invariant is that high-priority senders deserve deeper inspection, no first-pass archive, optional calendar action, dedupe against existing events, and explicit reporting.

### Sharing Guidance

When sharing this blueprint externally, link to the repository copy rather than pasting an edited local variant. Keep account names, private domains, personal senders, and local filesystem paths out of the shared version.

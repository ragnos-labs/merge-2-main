---
title: Spawn-Guard Hooks Reference
description: The full operational picture for pre-spawn validation: rule taxonomy, escalation thresholds, telemetry, allowlists, and recovery patterns. Companion to the spawn-guard-hook template.
---

# Spawn-Guard Hooks Reference

A spawn-guard hook intercepts every agent-spawn call and decides allow or
reject before the call runs. The minimum viable script is in
[../../templates/universal/spawn-guard-hook.md](../../templates/universal/spawn-guard-hook.md).
This page covers what changes once you have run it for any meaningful sprint
length: rule design, telemetry, allowlist patterns, recovery, and the
relationship to the meta-log.

---

## Why a guard exists

The model selection guide's universal advice ("default to standard, escalate
sparingly") drifts the moment one prompt forgets to specify a tier. A guard
turns the advice into operational truth: a missing pin or unjustified
escalation fails closed. The lead sees the rejection, fixes the prompt,
re-runs.

In a single session you can self-discipline. Across a 30-agent run, the
guard is what makes the cost discipline survive contact with reality.

---

## Rule taxonomy

A guard enforces some subset of these rules. Pick the smallest set that
matches your operational risk profile; adding rules is cheap, removing them
later is harder because the team builds habits around them.

### Pin rules

| Rule | Purpose | Severity |
|------|---------|----------|
| Spawn must pin `model:` directly OR reference a pinned subagent role | Prevents silent escalation when the runtime fills in a default | Hard reject |
| Pinned subagent role must exist in the role registry | Catches typos that would silently fall back to a runtime default | Hard reject |
| Tool surface must match the role definition | Prevents read-only roles from getting Edit/Write | Hard reject |

### Escalation rules

| Rule | Purpose | Severity |
|------|---------|----------|
| Most-capable tier requires `[JUSTIFIED: <reason>]` in prompt | Forces a deliberate escalation decision | Hard reject without override |
| Most-capable tier rejected without `ALLOW_MOST_CAPABLE_SPAWN=1` env flag | Provides escape hatch for legitimate exceptions | Hard reject |
| Per-sprint escalation count exceeds budget | Catches drift toward overuse | Soft warning, then reject |

### Output-shape rules

| Rule | Purpose | Severity |
|------|---------|----------|
| Spawn prompt under N tokens | Prevents pathological prompts that bloat cost | Soft warning |
| Required output_contract present for roles that have one | Keeps return shape predictable | Hard reject |
| Sprint slug present in spawn payload | Required for meta-log routing | Hard reject |

The minimum useful set is the three pin rules plus the two escalation rules.
Everything else is a function of how mature your team's spawn discipline is.

---

## Escalation thresholds

A guard that only ever blocks is annoying; one that warns first and blocks
on repeat is useful. Apply the same shape as the meta-log self-heal
thresholds:

```
+-----------------------------------+----------------------+
| Signal                            | Action               |
+-----------------------------------+----------------------+
| Same lead rejected 3+ times for   | Allowlist or coach;  |
| the same rule in one sprint       | the rule may be off  |
+-----------------------------------+----------------------+
| Rule rejects > 25% of spawns      | Rule is over-tight;  |
| over a rolling window             | revise               |
+-----------------------------------+----------------------+
| New rejection reason appears 1x   | Log only             |
+-----------------------------------+----------------------+
```

Run the guard's stats in retrospectives, not mid-sprint. Adjusting the rules
mid-sprint to unblock work is how guards quietly stop guarding.

---

## Telemetry: log every decision

Allow decisions are not free of information. Every spawn-guard call should
emit a meta-log entry, regardless of outcome:

```json
{
  "ts": "2026-04-18T15:02:10Z",
  "actor": "spawn-guard",
  "phase": "G2",
  "event_type": "decision",
  "summary": "ALLOW spawn of explore-standard from lead-a",
  "evidence": "spawn-guard.log:213",
  "meta": {
    "decision": "allow",
    "rule_set": ["pin", "escalation"],
    "model": "standard",
    "subagent_type": "explore-standard"
  }
}
```

Reject entries get a `self_heal_candidate: true` flag plus a `remediation`:

```json
{
  "ts": "2026-04-18T15:02:10Z",
  "actor": "spawn-guard",
  "phase": "G2",
  "event_type": "failure",
  "summary": "REJECT most-capable spawn from lead-d: no [JUSTIFIED:] token",
  "self_heal_candidate": true,
  "remediation": "add justification token, drop to standard tier, or set ALLOW_MOST_CAPABLE_SPAWN=1 with a reason in the meta-log",
  "meta": {
    "decision": "reject",
    "rule": "escalation.justified_token",
    "model": "most-capable",
    "subagent_type": null
  }
}
```

This ties the guard into the broader self-heal pipeline: a rule that fires
3+ times in a sprint becomes a candidate for either coaching the lead or
relaxing the rule.

---

## Allowlists

Some sprints legitimately escalate more often than others (security audits,
architecture work, multi-system design reviews). A blanket
`ALLOW_MOST_CAPABLE_SPAWN=1` for those sprints is a sledgehammer; a per-sprint
allowlist is the right scalpel.

Allowlist file:

```yaml
# .ai/sprints/<slug>/spawn-guard-allowlist.yaml
sprint: auth-refactor-security-review
allowlist:
  - rule: escalation.justified_token
    reason: "security-review sprint; arch-review spawns at most-capable tier are expected"
    expires: 2026-04-25T00:00:00Z
    max_spawns: 8
```

The guard reads this file, increments a counter per allowed spawn, and
rejects when `max_spawns` is exceeded or the expiration passes. Allowlists
are scoped to one sprint; they do not cross over to the next run.

---

## Recovery patterns

When the guard rejects a spawn the lead expected to succeed, four recovery
patterns cover almost every case:

1. **Add the justification token.** The simplest fix. The lead amends the
   prompt with `[JUSTIFIED: arch decision crossing 3 services]` and re-runs.
2. **Drop to standard tier.** If the justification is thin, the right move
   is usually "actually we don't need most-capable here."
3. **Switch to a pinned role.** If the spawn is a kind the team does often,
   define a subagent role for it and reference by name.
4. **Add to the sprint allowlist.** For genuine exceptions specific to this
   sprint. Requires writing the reason; the reason is the audit trail.

The guard never auto-relaxes; recovery is always a deliberate edit.

---

## Failure modes the guard cannot prevent

Be honest about the limits. A spawn-guard hook prevents:

- Forgotten model pins
- Unjustified escalations
- Tool-surface mismatches at spawn time

It does not prevent:

- Bad prompts that pass the schema check but produce wrong output
- Token bloat from long input context (the guard sees only the spawn payload,
  not what the agent reads later)
- Coordination failures across multiple correctly-spawned agents
- An agent that hits a real bug in the model API

Use the guard for the failure modes it actually addresses. Use the broader
discipline (model selection guide, sprint planning, meta-log) for the rest.

---

## Implementation checklist

When adding a guard to a new repo or runtime:

- [ ] Identify the runtime's pre-tool-use hook surface
- [ ] Implement the three pin rules first; add escalation rules second
- [ ] Wire meta-log emission for both allow and reject decisions
- [ ] Test the guard with a deliberately-bad spawn (missing pin); confirm reject
- [ ] Test the guard with a most-capable spawn lacking justification; confirm reject
- [ ] Test the env-flag override; confirm allow when flag is set
- [ ] Run a small sprint with the guard active; review the rejection log
- [ ] Adjust rules based on what the rejection log surfaces, not on prediction

---

## Related

- [../../templates/universal/spawn-guard-hook.md](../../templates/universal/spawn-guard-hook.md):
  the minimum-viable shell script that this page extends
- [../../templates/universal/subagent-definition.md](../../templates/universal/subagent-definition.md):
  the named-role surface that pin rules check against
- [../guides/model-selection.md](../guides/model-selection.md): the universal
  philosophy and the enforcement section that motivates the guard
- [../guides/meta-log-gates.md](../guides/meta-log-gates.md): the self-heal
  thresholds that the guard's telemetry feeds into

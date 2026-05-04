---
title: Spawn-Guard Hook Template
description: A pre-spawn validation script that rejects agent spawns missing required fields, blocks unjustified escalations to the most-capable tier, and allows controlled override via an environment flag. Maps to the "pre-spawn guardrail" enforcement surface in the model selection guide.
---

# Spawn-Guard Hook Template

A spawn-guard hook is a pre-tool-use script that inspects every agent-spawn call
before it runs. The runtime invokes the hook with the call's payload on stdin; the
hook exits 0 to allow, non-zero to reject. The runtime surfaces the rejection
message back to the lead.

The guard turns the model selection guide's universal advice ("default to standard,
escalate sparingly") into operational truth: a missing model pin, a most-capable
spawn without justification, or a forbidden tool surface all fail closed. The lead
sees the rejection inline and fixes the prompt.

---

## What the guard checks

A practical guard enforces three rules:

1. **Model pin or named role.** Every spawn must either pin `model:` directly or
   reference a named subagent role (which has a pin in its definition). Spawns that
   omit both are rejected.
2. **Justified escalation.** A spawn pinned to the most-capable tier must include a
   justification token (e.g., `[JUSTIFIED: <reason>]`) in the prompt. Without it,
   reject. An environment flag (e.g., `ALLOW_MOST_CAPABLE_SPAWN=1`) overrides the
   check for legitimate exceptions; the flag is logged.
3. **Tool surface coherent with role.** A read-only role with `Edit` or `Write` in
   its tool list is a configuration error. Reject and report.

The third rule is optional but cheap to add and catches a common drift.

---

## Reference implementation (shell)

```bash
#!/usr/bin/env bash
# spawn-guard-hook.sh
# Reads the spawn call payload from stdin as JSON and decides whether to allow it.
# Exit 0: allow. Exit non-zero: reject with the message on stderr.

set -euo pipefail

payload=$(cat)

# Extract fields. The exact JSON path depends on the runtime; adjust to taste.
model=$(echo "$payload" | jq -r '.params.model // empty')
subagent_type=$(echo "$payload" | jq -r '.params.subagent_type // empty')
prompt=$(echo "$payload" | jq -r '.params.prompt // empty')

# Roles that carry a baked-in tier pin.
PINNED_ROLES="explore-standard mechanical-fast implement-standard"

# Rule 1: model pin or named pinned role.
if [[ -z "$model" ]]; then
  if ! grep -qw "$subagent_type" <<<"$PINNED_ROLES"; then
    echo "spawn-guard: missing model: pin and subagent_type ($subagent_type) is not a pinned role" >&2
    exit 2
  fi
fi

# Rule 2: most-capable tier needs justification.
if [[ "$model" == "most-capable" || "$model" == "opus" ]]; then
  if [[ "${ALLOW_MOST_CAPABLE_SPAWN:-}" != "1" ]] && ! grep -q '\[JUSTIFIED:' <<<"$prompt"; then
    echo "spawn-guard: most-capable spawn requires [JUSTIFIED: <reason>] token or ALLOW_MOST_CAPABLE_SPAWN=1" >&2
    exit 3
  fi
fi

exit 0
```

Wire this into your runtime's pre-tool-use hook list. The exact wiring varies; see
the runtime adapter under `docs/runtimes/`.

---

## Field-tested behaviors

A guard that has run for any meaningful sprint length will accumulate three
behaviors worth keeping:

- **Log every decision.** Allows are not free of information. A meta-log entry
  per spawn (`actor: spawn-guard`, `decision: allow|reject`, `reason: <code>`) gives
  you a record of how often the guard fires and on which prompts.
- **Allowlist by sprint.** Some sprints legitimately escalate more often (security
  audits, architecture work). Carry a per-sprint allowlist that softens rule 2
  rather than relying on the global env flag.
- **Surface rejection reasons in the meta-log too.** Every reject is a signal: the
  lead's mental model of role pinning is not yet automatic. After a few rejects on
  the same rule, consider whether the role definitions need adjusting.

---

## Anti-patterns

- **Failing open on parse errors.** If the hook cannot parse the payload, reject by
  default. A guard that silently allows malformed spawns is worse than no guard.
- **Treating the env flag as a permanent escape hatch.** It exists for the rare
  legitimate exception. If you find yourself exporting it for every run, the rules
  need to be reconsidered, not bypassed.
- **No reason in the rejection message.** The lead must be able to fix the prompt
  from the message alone. "Spawn rejected" is useless; "missing model: pin" is
  actionable.

---

## Related

- `docs/core/guides/model-selection.md`: the universal philosophy and the
  enforcement section that motivates this hook
- `docs/templates/universal/subagent-definition.md`: the named-role surface that
  works with this guard

---
title: Test Contract Template
description: A YAML schema for the per-task TDD contract that travels with a spec from planner to implementer. Designed to be parseable so a CI step can verify gate compliance without reading prose.
---

# Test Contract Template

A test contract is the precise, structured part of a task spec that says what
must be true before the task can be marked done. It exists so the implementer
and the reviewer share the same definition of correctness, and so a script can
verify the gate without human judgment.

This template is the YAML schema. The accompanying behavior (Red-Green-Refactor,
the three gates G1/G2/G3, the role separation between test author and
implementer) lives in [../../core/guides/tdd-integration.md](../../core/guides/tdd-integration.md).

---

## Schema

```yaml
test_contract:
  task: <one-line task description>          # required
  interface:                                  # required: what is being tested
    - name: <function-or-endpoint-name>
      signature: <type signature or HTTP shape>
  behaviors:                                  # required: at least one
    - id: <stable-id>
      description: <one-sentence behavior>
      kind: happy_path | error_path | boundary | integration
      test_file: <path/to/test/file.ext>
      test_name: <test function or it() name>
  fixtures:                                   # optional: pre-staged data
    - path: <path/to/fixture>
      purpose: <one line>
  gates:                                      # required: pass criteria
    g1_stubs_exist:
      command: <shell command that exits 0 when stubs are present>
    g2_stubs_fail_for_right_reason:
      command: <command that runs the tests and confirms expected failure>
    g3_all_pass:
      command: <command that runs the full suite>
  out_of_scope:                               # optional but recommended
    - <one-line item the implementer should NOT change>
```

The schema is intentionally minimal. Anything not in the contract is either
out of scope or covered by a separate contract.

---

## Worked example

```yaml
test_contract:
  task: Implement parse_config for the new YAML schema
  interface:
    - name: parse_config
      signature: "(path: str) -> Config"
  behaviors:
    - id: B1
      description: Returns a populated Config when file is valid YAML
      kind: happy_path
      test_file: tests/test_config.py
      test_name: test_parse_config_valid_returns_config
    - id: B2
      description: Raises ConfigError with descriptive message when file is missing
      kind: error_path
      test_file: tests/test_config.py
      test_name: test_parse_config_missing_raises
    - id: B3
      description: Raises ConfigError when required fields are absent
      kind: error_path
      test_file: tests/test_config.py
      test_name: test_parse_config_missing_field_raises
    - id: B4
      description: Empty file does not crash; returns empty Config
      kind: boundary
      test_file: tests/test_config.py
      test_name: test_parse_config_empty_file
    - id: B5
      description: Config object is accepted by initialize_app without error
      kind: integration
      test_file: tests/test_config.py
      test_name: test_parse_config_integrates_with_init
  fixtures:
    - path: tests/fixtures/config-valid.yaml
      purpose: Reference valid config used by B1 and B5
    - path: tests/fixtures/config-missing-field.yaml
      purpose: Triggers ConfigError in B3
  gates:
    g1_stubs_exist:
      command: "test -f tests/test_config.py && grep -q 'def test_parse_config_' tests/test_config.py"
    g2_stubs_fail_for_right_reason:
      command: "pytest tests/test_config.py -x 2>&1 | grep -E 'NotImplementedError|AssertionError'"
    g3_all_pass:
      command: "pytest -x"
  out_of_scope:
    - Do not modify initialize_app
    - Do not change the existing YAML schema definition
```

The implementer reads exactly five behaviors, three gate commands, and two
out-of-scope items. There is nothing to interpret.

---

## CI snippet

A short shell loop turns the contract into an automated gate. This example
parses the YAML with `yq` and runs each gate command:

```bash
#!/usr/bin/env bash
# verify-test-contract.sh
# Usage: verify-test-contract.sh <path-to-contract.yaml> <gate>
# Exit 0 if the gate passes, non-zero otherwise.

set -euo pipefail

contract="${1:?contract path required}"
gate="${2:?gate name required}"

cmd=$(yq ".test_contract.gates.${gate}.command" "$contract")
if [[ -z "$cmd" || "$cmd" == "null" ]]; then
  echo "verify-test-contract: no command for gate $gate in $contract" >&2
  exit 2
fi

echo "verify-test-contract: running $gate"
echo "  cmd: $cmd"
bash -c "$cmd"
```

Wire this into your CI as three sequential steps (one per gate). G1 runs
before implementation begins; G2 runs after the test author commits; G3 runs
after the implementer commits. A failure at any gate blocks the next phase.

---

## Why YAML and not prose

A prose contract ("returns a Config object on success") is a wish. A YAML
contract with a gate command is a verifiable claim. The template forces the
test author to commit to a check that a script can run, which forces them to
think through the assertion before the implementation starts.

This is the same shift the broader spec-driven development community has
made: structured contracts that are machine-readable beat narrative
descriptions every time, especially in agentic workflows where agents read
the spec before implementing.

---

## Anti-patterns

- **Behavior list with no gate commands.** A behavior that cannot be turned
  into a runnable check is not in the contract; it is a comment.
- **One huge behavior covering "all the stuff".** Behaviors are the unit of
  test definition. If your behavior block is two paragraphs, split it.
- **Out_of_scope as decoration.** The list should name files, functions, or
  modules the implementer is not allowed to touch. "Don't be evil" is not an
  out_of_scope item.
- **Gate commands that always exit 0.** Common in fresh contracts copied from
  templates. Verify the G2 command actually fails on unimplemented code; if it
  passes immediately, the gate is broken.

---

## Related

- [../../core/guides/tdd-integration.md](../../core/guides/tdd-integration.md):
  the workflow this template plugs into
- [../../core/references/tdd-contracts-template.md](../../core/references/tdd-contracts-template.md):
  prose-form contract reference (use this YAML schema for new contracts going
  forward)

---
title: TDD Integration for Multi-Agent Workflows
description: How to apply Test-Driven Development discipline when agents are writing and reviewing code across Worker Swarm and Hive Mind patterns.
---

# TDD Integration for Multi-Agent Workflows

## Why TDD Matters More With Agents

When an engineer writes bad code it breaks visibly: tests fail, the build breaks, something explodes
at runtime. When an agent writes bad code it often looks fine. It compiles. It returns something. It
passes a casual read. The failure is silent and deferred.

Multi-agent systems amplify this. Agent A writes a module. Agent B integrates it. Agent C ships it.
If no test existed to fail, nobody saw the breakage. By the time it surfaces in production, the
causal chain is buried.

Tests are the only reliable signal that an agent's output is correct. Without them, you are
accepting plausible-looking code as a substitute for verified behavior. These are not the same
thing.

---

## The Iron Law

**No production code without a failing test first.**

This is not a best practice. It is the required workflow for all non-trivial development. Mechanical
refactors (renames, formatting, import reordering) are exempt. Everything else requires a failing
test first.

---

## Red-Green-Refactor in Multi-Agent Context

The classic TDD cycle maps onto agent workflows with one important addition: the RED phase is
always assigned before any implementation work begins.

### RED Phase: Write a Failing Test

1. Write one minimal failing test.
2. Run it. Verify it fails for the right reason (not an import error, not a syntax error).
3. If it passes immediately, the test is wrong.

In a multi-agent workflow, the RED phase is the responsibility of whoever owns the specification.
The failing test is the handoff artifact. An implementer who receives a task with no failing test
should refuse the task and request one. If you cannot write the test, you do not understand the
requirement.

### GREEN Phase: Write the Simplest Passing Code

1. Write the simplest code that makes the test pass.
2. No optimization, no cleanup, no "while I'm here."
3. Run all tests. Verify everything is green.

Simplest means simplest. Hardcoded return values count if they make the test pass. The next RED
phase will force generalization.

### REFACTOR Phase: Clean Up Under Green

1. Clean up both test and production code.
2. Run tests after every change. Stay green the entire time.
3. If tests go red, revert and try again.

No behavioral changes during REFACTOR. If new behavior is needed, go back to RED.

---

## TDD Contracts

A TDD contract is a spec section that defines exactly what tests must pass before a task is
considered done. Every non-trivial task spec should carry one.

A minimal TDD contract includes:

- The public interface being tested (function signatures, API endpoints, class methods)
- The behaviors to cover (happy path, error path, boundary values)
- Any integration checkpoints (component wires together correctly with its dependencies)
- The gate criteria that must be met before the task is closed

Example contract section in a task spec:

```
## TDD Contract

Interface: `parse_config(path: str) -> Config`

Behaviors:
- Returns a populated Config object when the file is valid YAML
- Raises ConfigError with a descriptive message when the file is missing
- Raises ConfigError when required fields are absent
- Handles empty files without crashing

Integration: Config object is accepted by `initialize_app(config: Config)` without error

Gate: All behaviors above have passing tests. `pytest -x` exits 0.
```

The agent receiving this task writes tests for each listed behavior before touching production code.

---

## The Three Gates

TDD compliance in a multi-agent workflow is enforced through three checkpoints. Gates are sequential
and non-negotiable.

### G1: Test Stubs Exist

The test file exists. It imports the module under test. It contains at least one test function per
listed behavior. The tests may not run correctly yet, but the structure is in place.

G1 is the minimum to begin implementation. An agent that starts writing production code before G1
is in violation.

### G2: Tests Fail for the Right Reason

Each test runs and fails. Not with an import error or a typo. The test reaches the assertion and
fails because the production code does not yet implement the behavior.

G2 is the proof that the test is meaningful. A test that cannot fail is not a test.

### G3: Tests Pass

All tests in the contract pass. The full test suite passes. No warnings, no skips.

G3 is the gate to mark a task complete. Implementation work that has not reached G3 is not done,
regardless of how complete the code looks.

---

## Assigning TDD Roles: Separation of Concerns

The most effective pattern in multi-agent workflows is to separate test authorship from
implementation authorship.

**Test author:** Writes the failing tests based on the spec. Does not write production code.
Responsible for gates G1 and G2. Owns the TDD contract.

**Implementer:** Receives the failing tests. Writes production code to pass them. Does not modify
tests except to fix incorrect assertions (with lead approval). Responsible for gate G3.

The separation enforces three properties: tests cannot be retrofitted to match implementation;
the implementer cannot rationalize away a test they did not write; test quality becomes a distinct
signal. When one agent does both roles, the temptation to confirm existing code is strong. The
separation removes it structurally.

---

## TDD in Worker Swarm

In the [Worker Swarm pattern](../patterns/worker-swarm.md), the lead agent coordinates multiple
workers on parallel tasks. TDD maps onto this structure as follows:

**Lead responsibilities:**
- Write the TDD contract for each task before assigning it
- Specify which behaviors each worker is responsible for testing
- Enforce gate G2 (tests must fail for the right reason) before releasing implementation work
- Review gate G3 before accepting completed work

**Worker responsibilities:**
- Write failing tests matching the contract before writing any production code
- Confirm G1 and G2 before beginning implementation
- Confirm G3 before marking the task done
- Report any contract ambiguity to the lead rather than resolving it unilaterally

The lead does not accept a task completion that lacks a failing test in the commit history. If a
worker skips the RED phase, the lead returns the task.

Workers on independent tasks run their RED-GREEN-REFACTOR cycles in parallel. Integration tests that
verify cross-task wiring are the lead's responsibility or go to a dedicated integration worker.

---

## TDD in Hive Mind

In [2-tier](../patterns/hive-mind-2tier.md) and [3-tier](../patterns/hive-mind-3tier.md) Hive Mind
deployments, there is enough specialization to dedicate a teammate to the test function entirely.

**Test specialist role:**

- Owns the test suite for the entire workstream
- Writes TDD contracts during the planning phase (before implementation begins)
- Writes failing tests and passes them to implementation agents
- Reviews all tests before they are merged
- Maintains integration tests as new modules are added
- Flags violations when implementation agents modify tests without authorization

**Implementation agents:**

- Receive failing tests as their primary work artifact
- Write the minimal production code to reach G3
- Do not modify tests (flag inconsistencies to the test specialist instead)

Implementation agents cannot start until the test specialist has delivered at least G2 on their
assigned scope. In 3-tier deployments, the test specialist acts as the quality gate between the
strategic tier and the implementation tier.

---

## Mechanical Refactors: When to Skip TDD

Not every code change requires a new failing test first. The exemption is narrow.

**Exempt:**
- Renaming a variable, function, or file with no behavior change
- Reformatting code (whitespace, line length, import ordering)
- Updating configuration values with no logic change
- Adding or updating comments and documentation strings

**Not exempt (TDD required):**
- Any new function or method
- Any change to existing logic, even "trivial" ones
- Any bug fix (a bug without a reproducing test is a guess, not a fix)
- Any change to error handling
- Any refactor that changes observable behavior

When in doubt, write the test. The cost of an unnecessary test is small. The cost of a missed
regression is large.

---

## Bug Fix Discipline

Bug fixes are the most common TDD violation in multi-agent workflows. An agent identifies a bug,
writes a fix, marks it done. No test exists. The bug returns in the next release.

The correct sequence:

1. Write a failing test that reproduces the bug on current code.
2. Verify it fails for the right reason (reproduces the bug, not an unrelated error).
3. Write the fix. Verify the test passes.
4. Run the full suite to confirm nothing else broke.

A fix without a reproducing test is a hope, not a fix. The failing test is shared evidence that
the agent reporting the bug and the agent fixing it are solving the same problem.

---

## Rationalization Table

Agents generate excuses for skipping TDD. The following table covers the most common ones.

```
+-----------------------------------+---------------------------------------------------+
| Rationalization                   | Reality                                           |
+-----------------------------------+---------------------------------------------------+
| "Too simple to test"              | Simple code gets complex. Tests document behavior |
|                                   | and catch regressions. Write the test.            |
+-----------------------------------+---------------------------------------------------+
| "I'll test after"                 | You won't. And if you do, you'll write tests that |
|                                   | pass by definition. RED first.                    |
+-----------------------------------+---------------------------------------------------+
| "Tests after achieve the same     | They don't. Tests-after verify implementation,    |
| goals"                            | not behavior. Edge cases and brittle tests follow.|
+-----------------------------------+---------------------------------------------------+
| "Already manually tested"         | Manual testing is not repeatable, not in CI, not  |
|                                   | documentation. Write the test.                    |
+-----------------------------------+---------------------------------------------------+
| "Need to explore first"           | Exploration IS the test. Write a test that        |
|                                   | describes what you want, then make it work.       |
+-----------------------------------+---------------------------------------------------+
| "Test is hard to write"           | Correct signal: the design is unclear. Fix the    |
|                                   | design, then write the test.                      |
+-----------------------------------+---------------------------------------------------+
| "TDD will slow me down"           | TDD costs 20 minutes upfront. Debugging without   |
|                                   | tests costs 20 hours later.                       |
+-----------------------------------+---------------------------------------------------+
| "Existing code has no tests"      | Add tests for the code you're changing. Legacy    |
|                                   | debt does not justify new debt.                   |
+-----------------------------------+---------------------------------------------------+
| "This is a one-off script"        | One-off scripts become permanent infrastructure.  |
|                                   | Write the test.                                   |
+-----------------------------------+---------------------------------------------------+
```

---

## Anti-Patterns

These are structural mistakes that occur even when agents follow the Red-Green-Refactor cycle.

### Testing After Implementation

An agent writes production code, then writes tests to match it. The tests pass on first run. Tests
written after implementation verify what the code does, not what it should do. Edge cases not
considered during implementation are not tested.

Fix: The commit history must show the test file change before the production code change.

### Mocking Everything

An agent mocks every dependency. The test passes. In production, real dependencies behave
differently. The test proved nothing.

Fix: Use mocks only for true external dependencies (network, filesystem, third-party APIs). For
internal dependencies, use real implementations or lightweight fakes. Signs mocking has gone too
far: mock setup is longer than the test itself; the test passes but the integration fails.

### Testing Implementation Details

An agent tests internal mechanics rather than observable behavior. When the function is refactored,
tests break even though behavior is unchanged.

Fix: Test through the public interface. Assert on outputs and observable side effects. If renaming
an internal method breaks tests, those tests are testing structure, not behavior.

### Incomplete Mock Shape

A mock returns `{"status": "ok"}` when the real API returns a response with dozens of fields. Tests
pass because the code only uses `status`. Later someone adds a field access. The unit test still
passes. The integration fails.

Fix: Capture a real API response. Use it as the mock fixture. When the real API changes, update
the fixture.

### Integration Tests as Afterthought

All unit tests mock all dependencies. No test exercises actual component wiring. "Works in tests,
fails in production" becomes a recurring theme.

Fix: Unit tests and integration tests, not unit tests or integration tests. Write integration tests
for critical paths during the RED phase alongside unit tests.

---

## Verification Checklist

Run through this list before declaring any implementation task complete.

- [ ] Every new function or method has at least one test
- [ ] Each test was observed to fail before production code was written
- [ ] Production code is minimal with no speculative features
- [ ] Full test suite passes with no warnings or skips
- [ ] Tests use real code paths (mocks reserved for external dependencies only)
- [ ] Edge cases are covered: empty input, null values, boundary values, error paths
- [ ] Test names describe behavior ("returns empty list when input is empty"), not implementation
- [ ] Bug fixes have a reproducing test committed before the fix

---

## Related Docs

- [Worker Swarm pattern](../patterns/worker-swarm.md)
- [Hive Mind 2-tier pattern](../patterns/hive-mind-2tier.md)
- [Hive Mind 3-tier pattern](../patterns/hive-mind-3tier.md)
- [Pattern overview](../patterns/overview.md)

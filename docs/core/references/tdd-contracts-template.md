---
title: TDD Contracts Template
description: Copy-paste template for TDD contracts in multi-agent sprints. Defines what tests must exist and pass for a workstream to be complete.
---

A TDD contract is a named specification that defines which tests must exist and
pass before a workstream is considered done. Contracts are written BEFORE code
starts. They give every agent a shared definition of "done" and prevent
premature sign-off.

Use contracts on any sprint with two or more workstreams, or any single
workstream where correctness is non-trivial.

---

## Template

Paste this block into your sprint plan under a `## TDD Contracts` heading.
Fill in one `### W<n> Contracts` section per workstream.

```
## TDD Contracts

Contracts are defined before code begins. Each agent must write failing test
stubs that match these contracts before implementing anything.

### W1 Contracts (<workstream name>)

Module: <module or file being tested>
Test file: <relative path to test file>

| Test name              | Given                        | Expected behavior                     |
|------------------------|------------------------------|---------------------------------------|
| test_<feature>_happy   | <valid input / precondition> | <what the function returns or does>   |
| test_<feature>_invalid | <bad input>                  | <error raised or rejection returned>  |
| test_<feature>_edge    | <boundary value>             | <behavior at the edge>                |

Gates:
  G1 (stub): test file exists, all cases listed, all fail (no implementation)
  G2 (impl): all cases pass, no skips, no mocks of core logic
  G3 (ship): coverage >= <N>%, no regressions in dependent modules

### W2 Contracts (<workstream name>)

Module: <module or file being tested>
Test file: <relative path to test file>

| Test name | Given | Expected behavior |
|-----------|-------|-------------------|
| ...       | ...   | ...               |

Gates:
  G1 (stub): ...
  G2 (impl): ...
  G3 (ship): ...
```

---

## Filled-in Example: Auth Module

```
## TDD Contracts

### W1 Contracts (auth)

Module: src/auth/session.ts
Test file: tests/auth/session.test.ts

| Test name                    | Given                               | Expected behavior                          |
|------------------------------|-------------------------------------|--------------------------------------------|
| test_create_session_happy    | valid user id, 24h TTL              | returns signed JWT, sets expiry correctly  |
| test_create_session_no_user  | user id is null                     | throws InvalidUserError                    |
| test_verify_session_valid    | unexpired JWT from create_session   | returns decoded payload with user id       |
| test_verify_session_expired  | JWT with past expiry                | throws TokenExpiredError                   |
| test_verify_session_tampered | JWT with modified payload           | throws InvalidSignatureError               |
| test_revoke_session          | valid session id in store           | removes session, verify returns revoked    |

Gates:
  G1 (stub): tests/auth/session.test.ts exists, all 6 cases present, all fail
  G2 (impl): all 6 pass, no skips, real JWT lib used (no mock of sign/verify)
  G3 (ship): branch coverage >= 90%, integration test against live auth store passes
```

---

## Tips

**Write contracts before writing prompts.** If you cannot fill in the "Given"
and "Expected behavior" columns, the feature is not well-enough understood to
start. Clarify the spec first.

**One contract per logical module.** Do not bundle unrelated modules into one
contract block. Keep them easy to scan and assign.

**G1 gates are mechanical.** An agent can satisfy G1 in minutes: create the
file, write the test names, leave the bodies as `raise NotImplementedError` or
`expect(true).toBe(false)`. The value is the shared vocabulary, not the code.

**G3 coverage thresholds are negotiable.** Set them based on risk. A payment
module might require 95%. A CLI formatter might be fine at 70%. Write the
number down so there is no argument at ship time.

**Contracts are immutable after G1.** If requirements change, update the
contract explicitly and note the reason. Silent mutations defeat the purpose.

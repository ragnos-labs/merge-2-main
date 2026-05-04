---
title: Behavior Design
description: A guide for treating agent character and tone as an interface layer on top of solid process.
---

## Behavior Design

Agents are execution engines and interfaces. Behavior design shapes the
interface layer: how an agent explains decisions, handles correction,
escalates uncertainty, and signals confidence and limits.

The rule that ties this guide together: **personality is an interface layer,
not a substitute for process.** Charm without evidence becomes noise quickly.
A strong character layer only helps when the operating layer underneath
(plans, ownership, tests, review) is real.

---

## Five Design Principles

1. **Style serves clarity.** Tone choices that make the change harder to
   review are wrong choices.
2. **Confidence matches evidence.** "Probably" and "should" are not stronger
   words than "verified" and "ran." Calibrate language to what was actually
   checked.
3. **Correction is easy.** A well-designed agent voice makes it cheap for an
   operator to disagree, redirect, or back out.
4. **Escalation language is explicit.** "Blocker," "uncertain," "stop":
   reserved words that mean what they say.
5. **Disagreement is not drama.** When the agent pushes back on an operator
   instruction, it states the reason and stops. No theater.

---

## What Good Behavior Design Does

A useful agent voice makes it easier to:

- understand what changed
- spot uncertainty
- challenge bad assumptions
- recover from mistakes
- maintain momentum without pretending everything is fine

The best behavior design reduces friction in the correction loop.

---

## Anti-Patterns

| Anti-pattern | Why it fails | Correct behavior |
|--------------|--------------|------------------|
| Confident prose hiding uncertainty | Operator cannot tell what was verified vs. inferred | State what was checked and what was assumed |
| Every answer as theater | Tone overhead drowns the actual change | Plain output for plain changes |
| Anthropomorphism over accountability | Reader feels rapport, misses the diff | Personality at the edges, evidence at the center |
| Personality that makes review harder | Post-hoc audit slows down | Cut the flourish; keep the substance |
| Sycophantic acknowledgement | "You are right" in place of action | Agree if true, push back if not, then act |

If the personality layer makes post-hoc review harder, it is too strong.

---

## Stack Order

The stack only works in this order:

1. clear task model
2. ownership and scope boundaries
3. tests and verification
4. review and release gates
5. behavior layer

Reversing it (compelling voice over rigorous process) produces work that
feels good in the moment and fails in review.

---

## Related

- `docs/core/references/positive-enforcement.md`: prompt-design principles
  that complement behavior design
- `docs/core/references/verification-discipline.md`: the evidence layer that
  behavior design sits on top of

---
name: firefly-retro
description: Use when the user names firefly retro to review an actual failure or repeated rework on a delivered change — record what happened as contemporary facts first, locate the cause at one layer (product code, environment or review instructions), and return improvement proposals for approval, the activation of a rule being a separate approval. Not for a delivery that went smoothly with no repeated rework, and not for an incident whose cause already has an agreed conclusion and is covered by an existing rule.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "26"
---

# firefly Retro

A retro starts from a failure that already happened, or from repeated rework — never from a wish to codify practice. It records the event's contemporary facts, locates the cause at one layer, chooses the smallest intervention that removes that cause, and tests the choice on subsequent comparable work. The retro approves improvement proposals; activating a rule is a separate approval, and once a rule is in force its version and rollback basis stay on record. The shared rules — mandate, carriers, recording, verdicts — are in `${CLAUDE_HOME:-$HOME/.claude}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere. The form of the retro record and the attribution of disputed causes are in `references/retro-record.md`; the form of a rule candidate and its `## Retro rules` rows in `references/rule-candidate.md`; the shadow-score and the held-out assessment in `references/shadow-assessment.md`.

## When to use

- **Named.** The user names `firefly retro` after a failure or repeated rework on a delivered change: an acceptance that turned out wrong, a repair that came back more than once. The mandate record must cover this skill's writes — the change's `retro.md` and the `## Retro rules` rows this skill produces.
- **Entry condition.** An actual failure or repeated rework has happened. The retro works from that event's contemporary input, decision, tool result and actual consequence, taken from the change's records — not from a general wish to produce rules.

## When not to use

- **A delivery that went smoothly, with no repeated rework.** Routine success need not create a standing rule; no retro record is written for it.
- **An incident whose cause already has an agreed conclusion and is covered by an existing rule.** The existing conclusion is cited, not reopened.

## Mandate

**Fixed end.**

- The retro record written to the change's `retro.md`, and the improvement proposals — each rule candidate with its five fields — returned to the requester for approval. Activation of a rule is a separate approval (`references/rule-candidate.md`); the retro's end is the return of the proposals.

**Permitted effects.**

- Write `openspec/changes/<id>/retro.md` for the named change: the contemporary facts of the event separated from the later inferences, scoped and redacted, with the layer decision and the shadow records (`references/retro-record.md`).
- Append to `## Retro rules` in `.superpowers/sdd/progress.md` the rows of the candidates this skill produced — and only those: their five fields, their version, and after the separate activation approval the rollback basis. The section is appended by hand — the recorder has no subcommand for it — and never rewritten.
- Read the named change's records; for recurring incidents with disputed causes, read only within the evidence scope the responsible owner defines.

**Not granted.**

- Activating a rule. The retro approves improvement proposals; activation is a separate approval recorded under `## Retro rules`.
- Implementing a fix. A product-code fix with its regression, an environment fix, a fixture change: each is a delivery commissioned separately through the change's own path. This skill writes no product code and changes no environment.
- Writing the lesson into every skill. The counterfactual question comes first: would the proposed change have prevented the observed failure (`references/retro-record.md`)?
- Using an entire transcript as a learning asset. Only scoped, redacted facts related to the change enter the retro record.
- Requiring a standing rule from a routine delivery.

## Inputs

- The named change and its records: the observation record, the stored review returns, the progress record — the source of the event's contemporary input, decision, tool result and actual consequence.
- The three comparators of a rule candidate: the existing rule with its base revision, the smallest mechanical check that addresses the same failure, and the candidate.
- The case sets: the same normal and failing inputs the shadow-score runs on, and the held-out cases that take no part in tuning the rules (`references/shadow-assessment.md`).
- For recurring incidents with disputed causes: the evidence scope the responsible owner defines, and non-authors to test the two explanations (`references/retro-record.md`).
- The mandate record: the `## Mandate` section of the change's `proposal.md`.

## Procedure

### 1. Take the entry and its limits

1. Read the mandate record. It must cover this skill's writes: `retro.md` and the `## Retro rules` rows this skill produces. When it does not, give the conclusion in the reply only, write nothing, and `ESCALATE` to the requester.
2. Confirm the entry condition. A delivery that went smoothly, or an incident with an agreed conclusion covered by an existing rule, closes under `## When not to use` and writes nothing.

### 2. Record the facts before the inferences

1. From the change's records, write the event's contemporary facts first: the input, the decision, the tool result and the actual consequence. The later inferences follow in a part of their own, each marked as inference, so a reader can tell which is which. The form is in `references/retro-record.md`.
2. Extract only the material related to this change, redacted: credentials, report contents and raw sensitive output never enter the record. An entire transcript is not a learning asset.
3. Written by this skill, to `openspec/changes/<id>/retro.md`, as the facts are established — before any proposal is chosen.

### 3. Locate the cause at one layer

1. The same wrong acceptance — an export accepted as delivered while its file could not be read — has three possible layers, and the facts decide which one the cause sits at:

   | What the facts show | The intervention |
   |---|---|
   | The product published `ready` before the file existed | Product code, plus a regression for the same failure — a delivery commissioned separately |
   | The test fixture always returned a readable file | The environment or the fixture |
   | The evidence was adequate to tell the two apart, and the reviewer repeatedly treated status 200 as a successful download | Only then is changing the review instructions considered |

2. Ask the counterfactual before widening any change: **would the observed failure still have passed if this change had been in place last time?** A change that would not have prevented it is not adopted for it. The lesson is not written into every skill.

### 4. Choose the smallest intervention that removes the cause

1. Among the interventions that pass the counterfactual, choose the smallest one that removes the cause.
2. The choice is tested on the next comparable work of the same kind; a retro does not declare its own choice proven.

### 5. State the candidate's five fields

1. A rule candidate is stated with five fields, none omitted:

   - **Scope** — which rule text or gate it amends, and which checks it applies to.
   - **Base revision** — the version of the rule text the shadow-score ran against.
   - **Expected misses prevented** — the class of error it is expected to stop, with the incident that motivates it.
   - **Possible false blocks** — what correct work it could block that the existing rule does not.
   - **Withdrawal condition** — the observed state under which the rule is withdrawn, stated before activation.

2. The form of the candidate's record and of its `## Retro rules` rows is in `references/rule-candidate.md`.

### 6. Shadow-score the three comparators

1. On the same normal and failing inputs, run the existing rule, the smallest mechanical check and the candidate in shadow: record only what each would have ruled on each case, with the reason. A shadow record changes no verdict in force, and no live gate is altered by it (`references/shadow-assessment.md`).
2. The shadow records, with the case sets they ran on, are written to the change's `retro.md` by this skill.

### 7. Assess on the held-out cases

1. The cases that took no part in tuning the rules go to an independent review that likewise took no part in tuning them. It compares the three comparators on **misses** (failures let through), **false blocks** (correct work blocked), **interruptions** (times a person had to be pulled in) and **cost** (`references/shadow-assessment.md`).
2. Prefer the cheaper equivalent when the results are the same; reject a candidate whose benefit no one can review.
3. A candidate that introduces a new false block on a required scenario in the held-out cases, without a risk acceptance the requester or the requirement owner recorded, is rejected: it is not activated. A rule already active meets its withdrawal condition.

### 8. Approve the proposals; activation is a separate approval

1. The proposals return to the requester. A candidate the requester approves is recorded under `## Retro rules` in `.superpowers/sdd/progress.md` — written by this skill, appended by hand: the candidate id, the five fields, the shadow and held-out results, and its version, from v1.
2. Activation is a separate approval; the retro records the proposal and stops. Once separately approved and in force, the version and the rollback basis stay in `## Retro rules`; withdrawal appends a row citing the withdrawal condition as observed, and edits no earlier row (`references/rule-candidate.md`).

### 9. Disputed causes in recurring incidents

1. When the same symptom recurs across independent incidents and the cause is still disputed, the responsible owner scopes the readable evidence first: what may be read, of which events, by whom. Until the scope is defined, nothing is read beyond the change's own records.
2. Non-authors test the two explanations against the same facts, separately: one reads the events as a judgment error, the other as a tooling defect; each returns what its explanation predicts and where it fails.
3. The synthesis keeps the contrary evidence, not only the consensus: whatever one explanation cannot account for stays in the record with it (`references/retro-record.md`).

### 10. Route the unwired bad-file fixture

1. A fixture that always returns a readable file and is wired into no gate is a gate-mounting matter, not a rule change: the fixture is fixed, and the check is routed to `firefly-guard`'s gate-mounting entry under that skill's write authority. The review instructions are not updated for it.

## Outputs

| What | Carrier | Written |
|---|---|---|
| The retro record: contemporary facts separated from later inferences, scoped and redacted; the layer decision with the counterfactual; the shadow records with their case sets | `openspec/changes/<id>/retro.md` | By this skill, as the facts are established and as each shadow run completes; the record moves with the archive (contract, Carriers) |
| Approved rule candidates: the candidate id, the five fields, the shadow and held-out results, the version, and after the separate activation approval the rollback basis | `.superpowers/sdd/progress.md`, section `## Retro rules` | By this skill, appended by hand, never rewritten; the rows of the candidates it produced only |
| Improvement proposals for product code, environment or fixtures | The return to the requester, for separate commissioning | With the retro record |
| The held-out assessment: misses, false blocks, interruptions and cost, side by side | The change's `retro.md` | By this skill, from the independent review's return |

## Handoffs

- **To `firefly-guard`.** An unwired bad-file fixture: the fixture is fixed and the check is mounted through firefly-guard's gate-mounting entry, under that skill's write authority. No review instruction changes for it.
- **To the requester.** The improvement proposals, for approval; the activation of a rule, as a separate approval.
- **To the delivery path.** A product-code fix with its regression, an environment fix: commissioned separately, through the change's own path — proposal, tasks, implementation, review.
- The `retro.md` moves with the archive when `firefly-archive` is commissioned (contract, Carriers).

## Stop and escalate

Stop and `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- **The mandate record does not cover this skill's writes.** The conclusion goes in the reply, nothing is written. Owner: the requester.
- **Recurring incidents with a disputed cause, and the responsible owner has not defined the readable evidence scope.** The two explanations cannot be tested. Owner: the responsible owner.
- **No non-author is available** to test either explanation, or to assess the held-out cases. Owner: the requester.

An `ESCALATE` is a return path, not a verdict.

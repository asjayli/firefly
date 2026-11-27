---
name: firefly-bounds
description: Agrees the quality constraints of a change before implementation, written beside the scenarios they constrain, and runs the affected checks of a constraint axis when a review dispatches them. Use when a scenario of a change under proposal touches a measurable service objective, a compatibility promise, a data boundary or a load, when the user names firefly bounds, when firefly-review dispatches the affected checks of the budget axis or of another registered constraint axis, or when a measurement has become a product promise and needs its constraint. Not for a change that touches none of these — a pure documentation change, for example.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "05"
---

# firefly Bounds

A quality constraint is agreed before implementation and judged method first, number second. This skill writes each constraint beside the scenario it constrains, in the spec package of the change, and runs the affected checks of a constraint axis when a review dispatches them. The shared rules — mandate, carriers, recording, verdicts — are in `<skill-root>/references/handoff-contract.md`; they are referenced here and restated nowhere. The form of a constraint entry and the worked examples are in `references/constraint-entry.md`.

## When to use

- **Under firefly-propose.** A scenario of the change under proposal touches a measurable service objective, a compatibility promise, a data boundary or a load. The controller dispatches this skill so the constraints are agreed before implementation. The writes are limited to the permitted effects of the proposal mandate: the spec package, `design.md`, minutes, `probes/`, `doubt.md`.
- **Named.** The user names `firefly bounds` to define, revise or hand over the constraints of a change. The mandate record must cover the writes the work takes.
- **From firefly-review.** The review dispatches this skill for the affected checks of a conditional axis: the budget axis, or the axis of another registered constraint. Only those checks run, and their results return to that review.
- **From firefly-perf.** A measurement became a product promise: its baseline, tolerance and owner arrive here to be turned into a constraint. The handover carries no write authority (contract, Mandate record): writing the constraint entry needs a mandate whose permitted effects cover the spec package — a proposal dispatch already covers it; otherwise give the constraint in the reply and `ESCALATE` to the requester.

## When not to use

- The change touches no measurable service objective, compatibility promise, data boundary or load — a pure documentation change, for example. There is no constraint to extract and no check of a constraint axis to run.

## Mandate

**Fixed end.**

- Under a proposal dispatch: the constraint entries beside the affected scenarios, agreed before implementation, returned to the proposal. A returned conclusion goes back to the scenario it concerns and brings no new write authority.
- From firefly-perf: the constraint entry agreed and returned, under a mandate whose permitted effects cover the spec package; without one, the constraint is given in the reply and the missing authority is escalated.
- Named by the user: the terminal condition of the mandate record in force.
- From a review dispatch: the results of the affected checks returned to that review, with the interpretation the adjudication order gives. The independent reviewer issues the verdict; this skill never returns one of its own.

**Permitted effects.**

- Read the repository: the project's service objectives, compatibility promises, data boundaries, tests and main specs.
- Under a proposal dispatch: write constraint entries into `openspec/changes/<id>/specs/**/spec.md` beside the affected scenarios, and record the measurement that grounds a baseline, with its workload and variation, under `openspec/changes/<id>/probes/<name>/`.
- Under a review dispatch: one write — the observation row of each affected check through `firefly record observe`, with its evidence under `openspec/changes/<id>/evidence/<snapshot12>/`. Under this dispatch the skill is the verifier its scenario map row names.
- Under a named entry: what the mandate record permits, nothing more.

**Not granted.**

- Redefining a criterion, a measurement method or a baseline at review time so that a candidate passes. Applicability is revised when facts change, through a separate standard revision — never inside the review that judges the candidate.
- Relaxing a standing reference value, or resetting a baseline to clear a regression. The standing reference values are the project owner's, kept in the main specs.
- Deciding which measured change is acceptable, approving an exception or its scope, or consenting to the handover of a constraint to firefly-guard. These are the requirement owner's decisions; this skill prepares and presents them.
- Issuing the review's verdict. The adjudication order is returned as interpretation.
- Writing `openspec/specs/**/spec.md` at all — that is the project owner's write through the spec sync of firefly-docs. Mounting a check into the project's CI — that is firefly-guard's write, under its own authority.
- Under a review dispatch: changing the candidate, its spec or its constraints; editing a recorded observation row; hand-writing a ledger row.

## Inputs

- The mandate record: which entry this is and what its permitted effects cover.
- Under a proposal dispatch: the change `openspec/changes/<id>`, the scenarios the dispatch names, and the minutes those scenarios cite.
- The project's own records: service objectives, compatibility promises, data boundaries and existing tests; the main specs `openspec/specs/**/spec.md`, where the project owner keeps the standing reference values a change's spec references.
- Under a review dispatch: the affected checks of the axis, and the rows of `## Scenario map` in `openspec/changes/<id>/tasks.md` that name them — the check with its command or step, the expected outcome, the verifier — together with the spec version and the candidate snapshot the observations are made on.
- From firefly-perf: a baseline, a tolerance and an owner for a measurement that became a product promise.
- On resumption: the constraint entries in the spec package with the spec package version, the measurements under `probes/`, and the observation rows already written.

## Procedure

### 1. Take the entry and its limits

1. **Proposal dispatch.** Work only within the permitted effects of the proposal mandate. The conclusion returns to the scenarios the dispatch named.
2. **Named entry.** Read the mandate record first. When it does not cover the writes the work takes, give the conclusion in the reply only, write nothing, and `ESCALATE` to the requester.
3. **Review dispatch.** Only the affected checks of the axis. Change nothing: not the spec, not the constraints, not the candidate. The observation row and its evidence are the only write. The results return to the review; no write authority comes with them.
4. **Handover from firefly-perf.** The handover itself grants no write. When the mandate in force covers the spec package (a proposal dispatch does), write the constraint entry beside the scenario; otherwise apply the named-entry rule: conclusion in the reply only, and `ESCALATE` to the requester.

### 2. Extract the affected constraints before implementation

1. Read the project's existing service objectives, compatibility promises, data boundaries and existing tests, and take the constraints the dispatched scenarios affect. The project's own records are the source; nothing is derived from preference.
2. A number without a defensible basis is not written as a budget. Where the project states no target, measure the original version first under a specified workload, record the workload and the variation, and let the requirement owner decide which changes are unacceptable.
3. Constraints are agreed before implementation. A standard changed while a candidate is under judgment is not a revision; it is the overreach this skill exists to prevent.

### 3. Write the constraint beside its scenario

1. The carrier is `openspec/changes/<id>/specs/**/spec.md`, beside the affected scenario — not a generic checklist elsewhere. The entry is in the spec package: writing or editing it changes the spec package version.
2. Each entry records six things: the applicable scenario, the owner, the criterion, the measurement method, the baseline source and the consequence of failure (contract, Carriers). The template and the worked examples are in `references/constraint-entry.md`.
3. A hard constraint has no tolerance. The owner's success record does not substitute for another account's denial record: the check observes the denial itself.
4. A load constraint is comparable only under the conditions it states: input size, concurrency, environment and sampling method. Two numbers measured under different conditions are not compared directly.
5. The baseline source names where the baseline comes from: the project's tests, a service objective, a standing reference value in the main specs, or the measurement recorded under `probes/<name>/` with its workload and variation. Never a bare number.

### 4. Revise applicability through a standard revision, never at review time

1. Applicability is revised when facts change. The revision is a separate decision, submitted on its own: it states the affected consumers, the cost of relaxing and its approver.
2. The original results are preserved, never rewritten. The baseline and the candidate are re-measured under the new method.
3. A one-off exception carries its scope and its expiry, recorded in the entry it excepts. It is not the default standard of the next work.

### 5. Standing budgets and reference values

1. A budget that holds across changes has a stable reference value kept by the project owner in the main specs `openspec/specs/<capability>/spec.md`; the change's spec references it. It is not relaxed by rolling from the previous result.
2. This skill writes the reference and never the main specs: keeping the value there is the project owner's write through firefly-docs and needs its own authorization. When the project keeps no reference value yet, the constraint entry says so, and the request goes to the project owner through the controller.
3. When no target exists but the measurement is stable, the requirement owner may approve a non-regression limit: no worse than the accepted baseline plus the recorded measurement tolerance.
4. A result too noisy to distinguish is not written as a constraint; it is observed only.
5. The review rejects a candidate that crosses the shared reference even when the changes before it each passed. Resetting the baseline does not remove the regression.

### 6. Run the affected checks of a review axis

1. Run only the checks the dispatch names, under the measurement method the constraint entry and the scenario map row record. A check whose result needs a measurement interpreted is observed by the verifier its row names; under this dispatch, you are that verifier.
2. Write each observation row as it is produced, before the next step:

   `"<skill-root>/scripts/firefly.sh" record observe --change <id> --candidate <tree-sha> --spec <version> --scenario <S-xxx> --check <name> --result <pass|fail|unverified|not-applicable> --observer verifier:firefly-bounds [--evidence <path>] [--rule <text>] --note "<conditions observed under; the expected outcome the scenario map row named when observed; the check that row named>"`

   - `pass` and `fail` need `--evidence` naming an existing path, put under `openspec/changes/<id>/evidence/<snapshot12>/`.
   - `not-applicable` needs `--rule` naming the rule that applies and the reason.
   - `--note` is never omitted: it carries the conditions observed under, the expected outcome the scenario map row named when the observation was made, and the check that row named. The recorder writes them into the `Conditions` column (contract, Recording).
   - Before the check, capture the inputs with `firefly snapshot worktree` and `firefly snapshot --spec <id>`. Pass those exact values; later changes leave the observation historical. A rejected call writes nothing.
3. The implementer's own run documents a deviation; it never replaces this row.

### 7. Return the interpretation: the adjudication order

For each check, return to the review: the scenario, the check, the measurement method used, the result (`pass`, `fail` or `unverified`) and the evidence pointer. Where the situation matches the order below, return the value it points to as interpretation. The independent reviewer issues the verdict:

1. **Method before number.** A result is compared only after the checks were made under the agreed method. A result made under another criterion or method has lapsed (contract, Lapse); it is not compared, and the agreed method is rerun on the current candidate.
2. **Over the limit** is a violated constraint: the situation points to `REVISE`.
3. **Invalid result** — a smaller sample, a removed assertion or a check that did not run. A check that can run only after the candidate changes points to `REVISE`. A check that can be rerun on the current candidate points to `RECHECK`: restore the measurement; no repair round is consumed. Evidence that cannot be obtained under the existing authority or tools points to `INSUFFICIENT_EVIDENCE`, which escalates directly. None of the three passes.
4. **Workload no longer representative.** The finding goes back with the results. The standard revision is a separate decision (step 4); no standard is changed inside the review.

### 8. Hand a stable constraint to firefly-guard

With the requirement owner's consent, a constraint whose measurement method is stable and whose failures have an owner goes to firefly-guard to mount as a regression check. Mounting writes the project's CI: it takes write authority, which firefly-guard holds under its own mandate. This skill mounts nothing.

## Outputs

| What | Carrier | Written |
|---|---|---|
| The constraint entries beside the affected scenarios | `openspec/changes/<id>/specs/**/spec.md` | Under a proposal dispatch, as agreed; every edit changes the spec package version |
| The measurement that grounds a baseline, with workload and variation | `openspec/changes/<id>/probes/<name>/` | Under a proposal dispatch, before the entry cites it |
| The observation row of an affected check | `openspec/changes/<id>/verification.md`, through `firefly record observe` | Under a review dispatch, as it is produced |
| The evidence of an observation | `openspec/changes/<id>/evidence/<snapshot12>/` | Under a review dispatch, before the row that cites it |
| The results returned to the review, with the interpretation | The return to the review | Under a review dispatch; the verdict is the independent reviewer's |
| The standing reference values | `openspec/specs/<capability>/spec.md` | Never written by this skill: the project owner keeps them there through firefly-docs; this skill writes the reference to them |

## Handoffs

- **From firefly-propose.** The controller dispatches the scenarios whose behavior touches a measurable service objective, a compatibility promise, a data boundary or a load. A returned conclusion goes back to the scenario it concerns and brings no new write authority.
- **From firefly-review.** Only the affected checks of a conditional axis. Their results return to that review; no write authority comes with them.
- **From firefly-perf.** A baseline, a tolerance and an owner for a measurement that became a product promise.
- **To firefly-review.** Per check: the scenario, the check, the measurement method used, the result, the evidence pointer — and the value the adjudication order points to. The independent reviewer issues the verdict.
- **To firefly-guard.** A constraint whose measurement method is stable and whose failures have an owner, with the requirement owner's consent. Guard mounts it as a regression check under its own write authority.
- **To the project owner, through firefly-docs.** A budget that should hold across changes has its stable reference value kept in the main specs. This skill references it and does not write it; keeping it there needs its own authorization.

## Stop and escalate

Stop and `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- The mandate record does not cover the writes the named entry takes. The conclusion goes in the reply, nothing is written. Owner: the requester.
- The requirement owner has not decided which measured changes are acceptable, and the constraint cannot be agreed without that decision. Bring the measurement, its workload and its variation. Owner: the requirement owner.
- The original version cannot be measured under the existing authority or environment, and no defensible basis for the constraint exists without it. Owner: the requester.
- Or, without stopping: a measurement of a review-axis check cannot be obtained. Record the row `unverified` with the reason and return it; the review adjudicates `INSUFFICIENT_EVIDENCE` from it.

Noise is not a stop: a result too noisy to distinguish is observed only, and nothing is written as a constraint. An `ESCALATE` is a return path, not a verdict.

---
name: firefly-doubt
description: Runs one independent investigation in a fresh context against a consequential untested assumption that no existing check can settle, and records the smallest counterexample with its outcome and where it goes. Use when firefly-propose hands over a consequential assumption that is still unproven, or when the user explicitly commissions independent dissent, once the author has stated the result that would change the decision. Not used when no result that would change the decision can be stated (a dispute of preference, not a falsifiable claim), or when the decision is low-cost and an error is easy to withdraw.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "09"
---

# firefly Doubt

This skill is one independent investigation in a fresh context: dispatched by `firefly-propose` for an assumption its step 5 cannot settle, or named by the user. It returns a counterexample, or none. Dissent does not replace final judgment: the verdict on a candidate belongs to `firefly-review`. The shared rules are in `${CODEX_HOME:-$HOME/.codex}/firefly/references/handoff-contract.md`: they are referenced here and restated nowhere.

## When to use

- **A consequential assumption, still unproven.** A decision whose consequences are costly rests on an assumption, no existing check can settle it, and the author has stated the result that would change the decision. `firefly-propose` hands such an assumption over at its step 5; a spec does not fail only because no dissent report exists.
- **Named.** The user explicitly commissions independent dissent. The recorded mandate must cover the writes this skill makes (`## Mandate`); when it does not, see "Stop and escalate".
- **A close-out.** The requirement owner has decided an entry that stood `undecided`; one closing entry is appended under this skill (`### Close an entry the owner decided`).
- **Only when no existing check can answer.** An adequate existing assertion that could distinguish the outcomes settles the question before dissent begins: it is run first, and this skill is entered only when it cannot settle the claim.

## When not to use

- **No result that would change the decision can be stated.** What is at issue is a preference, not a falsifiable claim. Return it to whoever raised it; investigate nothing, record nothing.
- **The decision is low-cost.** An error is easy to withdraw, and deciding is cheaper than investigating the doubt.

## Mandate

**Fixed end.** The investigation's entry is on record in the counterexample record, with its outcome and where it goes, and the conclusion has returned to the decision it concerns: a counterexample, or none. The closing entry has the same fixed end. The mandate also ends by `ESCALATE` (see "Stop and escalate") and by an explicit stop of the user.

**Permitted effects.**

- Append one entry per investigation to the counterexample record: `openspec/changes/<id>/doubt.md`, append-only; for work that has no change, the `## Counterexamples` section of the progress record `.superpowers/sdd/progress.md`. The section has no recorder row; this skill appends its entries there by hand, and no other table row is hand-written (contract, Recording).
- Append the closing entry after the requirement owner's decision, to the same carrier.
- Run the permitted verification means the dispatch names, on the material the dispatch names.
- Under `firefly-propose`, the writes are limited to the proposal mandate's permitted effects (the spec package, `design.md`, the minutes, `probes/`, `doubt.md`), and the conclusion returns to the scenario it concerns and brings no new write authority — of those carriers this skill writes only the counterexample record.

**Not granted.**

- A verdict on a candidate, or anything that stands in for final judgment: `firefly-review` keeps it.
- Writing a scenario, revising a promise, or filling in the scope of an open blocker: the spec author does that, through `firefly-propose`. A promise changes only on the requirement owner's decision.
- Observation rows in the verification record: the designated verifier writes them, through the controller.
- Editing product code, the candidate, or the task package.
- A decision record: it takes a mandate that permits it, and it is written through `firefly-docs`.
- Asking a fresh dissenting context again in place of the owner's decision.

## Inputs

- **The claim.** A short stable identifier, the decision it supports, the assumption that decision rests on, and the stated result that would change the decision. The spec author states that result before the dispatch; the claim does not enter without it.
- **What the investigation examines — and what it does not.** The candidate snapshot, when one exists; the required scenarios; the constraints recorded beside the spec; the permitted verification means. The author's case for why the claim should pass is not part of the input: no self-assessment travels with the dispatch.
- **The stage binding.** Spec stage: the spec package version, what `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --spec <id>` prints. Implementation stage: that version and the candidate snapshot, what `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot` prints. The two stages bind separately; a record names the one it was judged against.
- **The mandate in force**, when this skill is named directly: the newest row of `## Mandate` of the change, or of `## Mandates` when the work has no change (contract, Mandate record).
- **The counterexample record**, for the count of entries the claim already has.

## Procedure

### 1. Gate the claim

1. The claim states the result that would change the decision, and an input under the permitted verification means could produce it. It does not: what is at issue is a preference, not a falsifiable claim. Return the claim to whoever raised it; investigate nothing, record nothing.
2. An existing assertion that can distinguish the outcomes and has not run goes back with the claim, named: run it first. Dissent begins only when no existing check can answer the claim.
3. Read the entries the claim already has in the counterexample record. One entry is one independent investigation. One follow-up is allowed per claim, only when new evidence has appeared that distinguishes the two competing explanations of the claim; without it, return the recorded outcome and investigate nothing. A third investigation is not commissioned. An investigation that never returned wrote no entry and counts as nothing: a dispatch that replaces an interrupted one is that same investigation, not a new one.

### 2. Fix the fresh context

The investigation runs in a context that wrote none of what it examines: not the claim, not the spec package, not the candidate. When this skill is entered in a context that produced any of those, dispatch one investigating agent that produced none of them; the investigation is that dispatch, and its return is the investigation's return. When this skill is itself the dispatched fresh context, it runs the investigation.

### 3. Run the investigation

Seek the smallest counterexample that changes the outcome:

- One input, two predictions, stated separately: what the candidate design predicts for that input, and what the business promise predicts for the same input.
- Run the input when a permitted verification means can execute it, and take the actual result as it comes.
- When only reasoning is possible, name the missing observation: the one that would distinguish the two predictions and cannot be made now.

**The export case.** The claim: deduplicating by query conditions makes retries safe. Two requests arrive with identical query conditions; one is a retry after its response was lost, the other is the same user's deliberate new export the next day. The candidate design predicts one merged job for both inputs; the business promise permits merging only the retry. The input pair is the counterexample. It runs on the candidate and both merge: the counterexample stands. This single counterexample warrants sending the design back; ten favorable opinions do not offset it. The remedy is one of two — distinguish submission intent explicitly in the design, or the requirement owner revises the promise — and the two inputs are verified again either way.

### 4. Record the entry

Append one entry per investigation, as the investigation completes and before the conclusion is returned. The fields:

| Field | Content |
|---|---|
| Claim | The claim's identifier |
| Changing result | The result that would change the decision |
| Judged against | The spec package version; the candidate snapshot, when one exists. For work that has no change, the material it examined instead |
| Counterexample | The smallest one, or `none found` |
| Predictions | The candidate design's and the business promise's, on the same input |
| Result | The actual result of the run, or the missing observation |
| Outcome | `holds`, `refuted` or `undecided` |
| Where it goes | The disposition of `### Take the outcome` |

- The versions are printed by the runtime; nobody derives them by hand (contract, Recording).
- The entry binds what it examined. A report made after implementation on a later candidate does not prove an earlier decision: the earlier entry stands as it was, and a later finding is a new entry under the count rule of step 1.
- No entry is rewritten; the record is append-only.
- A doubt that produced no counterexample is recorded `refuted` when observations dismissed it — the runs it made, or a recorded scenario that already distinguishes the inputs, attached as the contrary observation — and `undecided` when a missing observation kept it open.

### 5. Take the outcome

**`holds` — a counterexample stands.** One counterexample suffices to send the work back; ten favorable opinions do not offset it.

- Planning has not started: the counterexample is an open blocker of the spec. Return it to the spec author through `firefly-propose`; the scope it affects gets no task.
- Planning has started: return it to the controller. When the counterexample ran on the candidate, the designated verifier records the affected scenario as `fail` through `firefly record observe` (contract, Recording), with evidence under `openspec/changes/<id>/evidence/<snapshot12>/`; when it was only reasoned, the designated verifier records the check of that scenario as `unverified`. Either way the change returns to `firefly-propose`: the spec author writes the counterexample's input and expected result into a scenario, the planner gives its check a mapping in `## Scenario map` (the task package version changes; the ready decision is taken again), and only then does `firefly-implement` repair.

**`refuted` — dismissed, with the contrary observation.** Record only. A trade-off with lasting force goes to the controller, through `firefly-docs`, into a decision record, which needs a mandate that permits it.

**`undecided`.** A consequential promise still undecided is `ESCALATE`d (see "Stop and escalate"); asking another fresh context is not a substitute for the decision. One that is not consequential is recorded and returned as it stands.

### Close an entry the owner decided

When the requirement owner has decided an entry that stood `undecided`, and the decision is in the minutes — the controller records a user decision in the minutes under every mandate — append one closing entry to the same claim: `closed by the owner`, citing the owner's verbatim words in the minutes, and noting the accepted risk or the revised promise. A revised promise goes to the spec author. The undecided entry is not rewritten; the closing entry is the one that follows it, and the claim is undecided no longer.

## Outputs

| Fact | Carrier | Written |
|---|---|---|
| Counterexample entry | `openspec/changes/<id>/doubt.md` (append-only); for work that has no change, the `## Counterexamples` section of `.superpowers/sdd/progress.md` | One per investigation, as the investigation completes, before the conclusion is returned |
| Closing entry | The same carrier | After the requirement owner's decision is in the minutes |
| The conclusion | The return to the dispatcher, or to the requester when this skill was named directly | A counterexample, or none; the outcome and where it goes |

- No scenario, no observation row, no task, no decision record and no edit to the candidate is an output of this skill.
- The final reply names the claim, the outcome, the entry's location and where it goes.

## Handoffs

- **In.** `firefly-propose`, for a consequential assumption its step 5 cannot settle; the user, naming independent dissent; the close-out, after the requirement owner's decision.
- **Out, `holds`, planning not started.** To the spec author through `firefly-propose`, as an open blocker of the spec; the scope it affects gets no task.
- **Out, `holds`, planning started.** To the controller, for the designated verifier's `fail` or `unverified` row; the change then returns to `firefly-propose` for the scenario and the mapping, and the repair afterwards belongs to `firefly-implement`.
- **Out, `refuted`.** Record only. A trade-off with lasting force: to the controller, through `firefly-docs`, into a decision record under a mandate that permits it.
- **Out, `undecided`.** `ESCALATE` to the requirement owner. After the decision, the closing entry is appended under this skill; a revised promise goes to the spec author through `firefly-propose`.
- **Boundary.** A returned conclusion goes back to the scenario it concerns and brings no new write authority. A spec does not fail only because no dissent report exists, and none of this replaces the final judgment of `firefly-review`.

## Stop and escalate

Stop and return `ESCALATE`, carrying the current conclusion, the missing evidence or authority, and the responsible owner, when:

- **A consequential promise stands `undecided`.** The missing item is the owner's decision, not another opinion. Owner: the requirement owner.
- **This skill is named directly and no recorded mandate covers its writes.** The conclusion is given in the reply only, nothing is written. Owner: the requester, for a mandate that covers the counterexample record.
- **The record's subject cannot be resolved, or a version cannot be obtained for a change.** No change resolves the claim, no spec package version or candidate snapshot can be printed for the stage of a change, and no value is derived by hand; work that has no change records the material it examined and is not stopped here. Owner: the requester.

The fixed end and the preference-dispute return of step 1 are returns, not escalations. Stopping never changes the state of any candidate (contract, candidate states).

---
name: firefly-debug
description: Diagnoses one failure by first obtaining a feedback signal that distinguishes faulty from normal behavior, then separating the competing explanations with experiments that change one condition at a time, and writes the trigger input, the expected result and the root cause back to the task record. Entered when firefly-implement hands over a failure that does not reproduce reliably, that one repair round left unchanged, or that competing explanations predict alike while no existing check separates them, when a mandate asks only for the cause of a failure, and when a mandate asks to find out and fix, whose saved trigger input and expected result become the repair scenario. Not used when the failure reproduces reliably and its cause is known, or when the requirement itself is unclear.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "15"
---

# firefly Debug

One diagnosis at a time. A feedback signal that distinguishes faulty from normal behavior comes before any change to the implementation; the conclusion states which evidence supports the root cause, which experiment ruled out each alternative explanation, and how the same feedback verifies the repair. A repair is never released by this skill: under a delivery mandate it is verified and independently reviewed as a new candidate. The shared rules are in `{{PLATFORM_HOME_ENV}}/firefly/references/handoff-contract.md`: they are referenced here and restated nowhere.

## When to use

- **Handed over from `firefly-implement`.** Under a delivery mandate a verification failure returns to the implementer by default; `firefly-implement` hands it to this skill instead when the failure does not reproduce reliably, when one repair round left the symptom unchanged (the round is recorded with `--progress no` and no further edit is stacked on it), or when competing explanations predict the same symptom and no existing check separates them. The handoff carries the failing scenario, the trigger input, the candidate snapshot and the evidence; the original terminal condition and permitted effects travel with it, this skill's write-back to the task record among them.
- **An investigation mandate.** The mandate asks only for the cause of a failure. The deliverable is the root cause with its discriminating evidence, the trigger input and the expected result; the investigation ends when that conclusion is returned, and it is not continued into `firefly-implement`.
- **The diagnosis half of a compound mandate, "diagnose and fix".** The diagnosis runs as above; its saved trigger input and expected result are the repair scenario, which the repair half takes through `firefly-propose` (`### Take the conclusion`).

## When not to use

- **The failure reproduces reliably and its cause is known.** The repair goes straight to `firefly-implement` as a repair round; there is nothing left for a diagnosis to separate.
- **The requirement itself is unclear.** What cannot be settled is what was asked for, not why the implementation failed: the work goes to `firefly-think`.

## Mandate

**Fixed end.** The conclusion is returned and written to its carrier (`### Write the conclusion back`): either a root cause with the evidence that supports it, the experiments that ruled out the alternative explanations, and how the same feedback verifies the repair; or an unresolved conclusion — a mitigation with its residual risk and the next capture plan, or a cause not located, with the next capture plan. The mandate also ends by `ESCALATE` (`## Stop and escalate`) and by an explicit stop of the user.

**Permitted effects.**

- Save the trigger input, the relevant versions, the environment, the observable symptom and the expected result, before the first change to the implementation (step 1).
- Add temporary probes to, and make diagnostic changes in, the worktree under diagnosis. They stay in that worktree; no probe carrier is created for them, and they are removed with the non-delivery diagnostics at closeout (step 6).
- Make an experimental repair as a means of verifying a root cause: one change at a time, each followed by the same feedback (step 4).
- Write the conclusion to its carrier: under a change, one bullet appended to `openspec/changes/<id>/tasks.md`; with no change, one entry appended to the `## Debug notes` section of the progress record `.superpowers/sdd/progress.md` (step 7).
- Under the delivery mandate of a handoff from `firefly-implement`, the writes are limited to the permitted effects that travelled with it, this skill's write-back among them (contract, Mandate record).

**Not granted.**

- Releasing a repair, or anything that stands in for one. Under a delivery mandate the repair is verified and independently reviewed as a new candidate; this skill never releases its own repair. A root cause returned by this skill does not authorize implementation.
- Continuing an investigation into implementation. The repair half of a compound mandate enters implementation only through the joint review of `firefly-propose`; an expected result that is an inference, or a repair wider than the symptom the user described, goes to the requirement owner first.
- Writing a scenario, building a task or splitting a mapping: the spec author and the planner do that through `firefly-propose`.
- Observation rows in the verification record: the designated verifier writes them. Repair budget rows: `firefly-implement` keeps them.
- Keeping a probe as a durable product signal: a probe is retained long-term only as an intentional product signal reviewed under `firefly-trace`, entering the product tree and travelling with the candidate review.
- Widening the mandate, or changing a promised behavior.

## Inputs

- **The failure.** From a `firefly-implement` handoff: the failing scenario, the trigger input, the candidate snapshot and the evidence. From an investigation mandate: the symptom as the requester described it, with the input, revision and environment the report names.
- **The mandate in force.** The newest row of `## Mandate` of the change, or of `## Mandates` when the work has no change (contract, Mandate record). When this skill is named directly, the recorded mandate must cover the writes this skill makes; when it does not, see `## Stop and escalate`.
- **The scenario map** of the change, `## Scenario map` in `openspec/changes/<id>/tasks.md`: the row of the failing scenario names the task group whose task item list takes the write-back (step 7).
- **The versions.** The candidate snapshot from `"{{PLATFORM_HOME_ENV}}/firefly/bin/firefly" snapshot`, the spec package version from `"{{PLATFORM_HOME_ENV}}/firefly/bin/firefly" snapshot --spec <id>`; nobody derives a version by hand (contract, Recording).

## Procedure

### 1. Fix the facts of the failure

On the anomaly, before the first change to the implementation, save:

| Fact | Content |
|---|---|
| Trigger input | The exact input that produced the symptom |
| Relevant versions | The candidate snapshot and the spec package version, as the runtime prints them for the candidate the failure was observed on |
| Environment | The services, data and configuration the failure was observed on |
| Observable symptom | What was observed, as observed |
| Expected result | What the behavior should have been |

- The facts are saved with the diagnostic material in the worktree under diagnosis, and their values travel into the conclusion's carrier (step 7); the material itself is removed with the non-delivery diagnostics at closeout.
- The expected result belongs to the scenario the failure breaks. When no record holds it, state it as an inference: the repair half of a compound mandate may not proceed on it until the requirement owner confirms it (`## Stop and escalate`).

### 2. Obtain a signal that distinguishes faulty from normal behavior

- No change to the implementation is made before a feedback signal exists that distinguishes the faulty behavior from the normal one on the same trigger input. Changing the implementation without that feedback makes a single non-recurrence uninterpretable: "it did not happen again" would explain nothing.
- The frequency is unstable: improve the capture first. Add temporary probes — logging, counters, timing marks — to the worktree under diagnosis, rerun the saved trigger input, and keep widening the capture until the same input holds the symptom and the normal behavior apart, reliably enough to experiment on.

### 3. Separate the competing explanations

- Write the competing explanations down, and for each what it predicts for the same trigger input. Explanations that predict the same complaint can still predict different results on other observations; those observations are the experiments to run.
- **The empty-download case.** "The page says done; the download is sometimes empty." Publishing `ready` too early and associating the page with the wrong job produce the same complaint and predict different results: under the first, the file recovers once it is visible, and delaying visibility widens the failure window; under the second, even after waiting long enough, the task identity or the file content still does not match. Fix the test input and the job ID, observe the state transition, the time the file becomes readable and the content identity together, and then vary one condition only.
- One experiment changes one condition. The run takes the actual result as it comes, and the result either supports one explanation, rules one out, or sends the capture back to step 2 for what it could not see.

### 4. Repair attempts

- An experimental repair is admissible as a means of verifying a root cause: one change, then the same feedback again.
- One repair that leaves the original symptom unchanged stops the stacking of edits: no further change is made on that path; return to the competing explanations of step 3. The repair budget belongs to `firefly-implement`; no budget row is written here.

### 5. State the conclusion

The conclusion states, in full:

1. **The root cause**, with the evidence that supports it.
2. **The discriminating experiments**, and which alternative explanation each ruled out.
3. **The repair check**: how the same feedback — the saved trigger input against the expected result — verifies the repair, on the candidate without probes.

When the cause was not located, the conclusion never writes a mitigation as a root-cause fix. It separates, labelled as such:

- **The mitigation**: what was changed, and which symptom it relieves, when one exists.
- **The residual risk**: what failure remains possible, with what consequence.
- **The next capture plan**: how the next occurrence is caught with a distinguishing signal.

### 6. Close out

1. **Inventory** the temporary probes and the diagnostic changes of this diagnosis.
2. **Remove the non-delivery diagnostics**: every probe and diagnostic change that is not a delivered change, from the worktree under diagnosis.
3. **Replay the original feedback on the candidate without the probes**: the saved trigger input, against the expected result.
4. **Passing only with a probe** — the symptom disappears only while a probe is in place — leaves the conclusion a cause not located or a timing interference: the cause is not established, or the probe itself disturbed the timing. The conclusion returns a capture plan instead of a root cause, and the capture improves at step 2 with a less intrusive means.
5. **A probe is retained long-term only as an intentional product signal reviewed under `firefly-trace`**: it enters the product tree and travels with the candidate review; every other probe is removed.

### 7. Write the conclusion back

**Under a change** — a handoff from `firefly-implement`, or a diagnosis commissioned on a change — append one bullet to `openspec/changes/<id>/tasks.md`, at the end of the task item list of the task group the failing scenario's `## Scenario map` row names:

```
- Debug note (<YYYY-MM-DD>): trigger <...>; expected <...>; root cause <...>
```

- The date is the day of the write. Each field keeps its text on the one line and holds no `;`.
- The `root cause` field carries the conclusion of step 5 in short: the supporting evidence, the experiment that ruled out each alternative, and the repair check — or, when the cause was not located, the mitigation, the residual risk and the next capture plan, labelled as such.
- Nothing else in `tasks.md` is touched: no task item line takes a note (a note on a task line changes the task package version; this bullet is a new line of its own, not a note on one), no field row of the task group, no row of the `## Ready decision` table. The bullet does not start with `- [ ]`, so the task listing does not count it as a task item.
- **What the write changes.** The write-back changes the task package version. The ready decision in force becomes `historical`, and the change returns to `firefly-propose` for the review of the task package alone, its intersecting mappings included; a new task the repair needs is a minimal task group built by the planner there. From this write until a ready decision is in force again, no repair round and nothing else is dispatched. Those steps are run by `firefly-propose` and `firefly-implement`, not by this skill (`## Handoffs`).
- The `## Scenario map` row of the failing scenario names no task group: `## Stop and escalate`.

**With no change** — an investigation commissioned on its own — append one entry to the `## Debug notes` section of the progress record `.superpowers/sdd/progress.md`. The section has no recorder row; this skill appends its entries there by hand, and no other table row is hand-written (contract, Recording). The entry carries the conclusion of step 5 with the saved trigger input, the expected result and the versions the diagnosis was made against.

### Take the conclusion

- **A root cause, under a delivery mandate.** After the write-back, the flow continues as the write's consequence states: `firefly-propose` reviews the task package, the planner builds the minimal task group, and once a ready decision is in force again `firefly-implement` integrates that task group, dispatches the repair as a new round, and the repair is verified and independently reviewed as a new candidate through `firefly-review`.
- **A root cause, an investigation mandate.** The conclusion returns to the requester and the investigation ends; it is not continued into `firefly-implement`. The trigger input and the expected result saved here are the repair scenario of a compound mandate: they go to the spec author and the planner through `firefly-propose`, and the repair enters implementation once the joint review has passed.
- **An unresolved conclusion.** The mitigation, the residual risk and the next capture plan return with the conclusion, written to the same carrier, labelled as an unresolved cause; nothing is presented as a root-cause fix.

## Outputs

| Fact | Carrier | Written |
|---|---|---|
| Debug note | `openspec/changes/<id>/tasks.md`: one bullet at the end of the task item list of the task group the failing scenario's `## Scenario map` row names | under a change, when the conclusion is produced; never on a task item line |
| Debug notes entry | `.superpowers/sdd/progress.md`, section `## Debug notes` | for a diagnosis with no change, when the conclusion is produced |
| The conclusion | the return to the handoff's sender, or to the requester when this skill was named directly | at the end of the diagnosis |

- No observation row, no task, no scenario, no verdict, no budget row and no durable probe is an output of this skill. The diagnostic material and the temporary probes are removed at closeout (step 6).
- The final reply names the conclusion, the carrier it was written to, and where the repair goes.

## Handoffs

- **In.** `firefly-implement`, for a failure that meets a switch condition of its repair rounds, with the failing scenario, the trigger input, the candidate snapshot and the evidence. The user, naming a diagnosis or the diagnosis half of a compound mandate.
- **Out, under a delivery mandate.** The write-back made, the change returns to `firefly-propose` for the review of the task package alone, its intersecting mappings included; a new task the repair needs is a minimal task group built by the planner there. Once a ready decision is in force again, `firefly-implement` integrates that task group and dispatches the repair as a new round, and the repair is verified and independently reviewed as a new candidate through `firefly-review`. The handoff brings no new write authority beyond the permitted effects that travelled in.
- **Out, an investigation mandate.** The root cause, the discriminating evidence, the trigger input and the expected result return to the requester; the investigation ends. The repair half of a compound mandate is a proposal: the trigger input and the expected result go to the spec author and the planner through `firefly-propose`. An expected result that is an inference, or a repair wider than the symptom the user described, goes to the requirement owner first.
- **Boundary.** A returned conclusion goes back to the decision that commissioned the diagnosis and brings no new write authority.

## Stop and escalate

Stop and return `ESCALATE`, carrying the current conclusion, the missing evidence or authority, and the responsible owner, when:

- **This skill is named directly and no recorded mandate covers its writes.** The conclusion is given in the reply only, and nothing is written — no bullet, no entry. Owner: the requester, for a mandate that covers the carrier of the diagnosis.
- **No distinguishing feedback can be obtained.** The trigger input cannot be executed or observed under the existing authority, tools or environment, and no capture improvement this skill may build changes that. The `ESCALATE` carries what was saved, the capture attempts and their results, the missing capability or access, and the owner of that environment or authority.
- **The `## Scenario map` row of the failing scenario names no task group.** The write-back has no place to go. Owner: the controller, for the planner to map the scenario.
- **An expected result that is an inference, or a repair wider than the symptom the user described, precedes the repair half of a compound mandate.** The missing item is the requirement owner's confirmation of the repair scenario. Owner: the requirement owner.

Stopping never changes the state of any candidate (contract, candidate states).

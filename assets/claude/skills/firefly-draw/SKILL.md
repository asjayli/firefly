---
name: firefly-draw
description: Settles which first user behavior is worth delivering when the questions of firefly-think cannot settle the uncertainty: a one-page comparison when value is unclear, a sequence diagram when the lifetimes of requests, jobs and files are hard to grasp, and a disposable probe when a fact about the product or an approach is not established. Entered when a decision needs a comparison of options, a sequence diagram or an operable prototype rather than another question, when the product's own behavior or an approach's feasibility is untested, or when the user names firefly draw. Not used when only a diagram is wanted (firefly diagram produces it) or when the input is already definite enough to enter the spec directly.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "03"
---

<!-- The independent development of credible alternatives, the criteria agreed in advance of the comparison, and the single falsifiable question of a probe take the mechanism of the superpowers skill `brainstorming` (MIT). -->

# firefly Draw

A concept identifies the first user behavior worth delivering. The shared rules are in `${CLAUDE_HOME:-$HOME/.claude}/firefly/references/handoff-contract.md`: they are referenced here and restated nowhere.

## When to use

- **Named.** The user names `firefly draw` with an uncertainty to settle.
- **Dispatched.** The controller, or `firefly-propose` under a proposal mandate, hands over an uncertainty the questions of `firefly-think` could not settle: deciding it takes a comparison of options, a sequence diagram or an operable prototype rather than another question.
- **An untested claim about this system.** Whether the product itself keeps a behavior, or whether an approach is feasible, is uncertain and no record settles it. A fact that depends on a third party's versioned promise is not settled here: it goes to `firefly-source`.

## When not to use

- **Only a diagram is wanted.** No uncertainty is to be settled; `firefly diagram` produces the diagram.
- **The input is already definite.** The behavior to deliver is settled on record, and the change enters the spec directly under `firefly-propose`.

## Mandate

Dispatched under a mandate, the terminal condition of that mandate governs. Named by the user, the ends below are the mandate's.

**Fixed ends.**

- A concept mandate ends when the handoff to the spec stage is complete: the selected behavior, the rejected interpretations, the counterexamples, the evidence pointers and the first testable slice are on record, each with the pointer that backs it.
- A mandate that commissions only a sequence diagram ends with the diagram and the boundaries it leaves open: no candidate comparison is started and no plan is written on the way.
- The mandate also ends by `ESCALATE` (see "Stop and escalate").

**Permitted effects.**

- Write the work of one question — the comparison page, the prototype, the probe and the observation notes beside them — into one directory under the carrier of the contract's Carriers table: `openspec/changes/<id>/probes/<name>/` when the work has a change, `openspec/think/<date>-<slug>-probe/` when it has none. **Never in the product tree**: a file there enters the candidate snapshot.
- Produce a diagram only with `firefly diagram <feature-name> <output-directory>`, the output directory given under `openspec/think/`: the second argument is the output directory, and the default one sits in the repository's current directory, which would carry the diagrams into the candidate snapshot.
- Dispatched under `firefly-propose`, the writes stay within the permitted effects of the proposal mandate, and of those only the probe directories are this skill's own writes. A returned conclusion goes back to the scenario it concerns and brings no new write authority (contract, Mandate record).

**Not granted.**

- Implementing anything or editing product code. The prototype is disposable and never becomes part of the delivery.
- Writing a spec scenario, a task record row, a mandate row or a progress-record row. A probe result is recorded as a note in its directory, not as an observation row: the verification record holds observations on a candidate snapshot (contract, Observation record), and a probe is not a candidate — it fixes no candidate snapshot.
- Building infrastructure to make an argument rigorous (step 2).

## Inputs

- **The uncertainty**, stated as the claim to settle and what each rival interpretation predicts.
- **What is already on record:** the minutes under `openspec/think/`, the existing specs, and the code the requirement touches.
- **The mandate:** id, objective, permitted effects and terminal condition.
- **Dispatched under `firefly-propose`:** the scenario the work concerns.

## Procedure

### 1. Name the uncertainty and pick the tool

- **The value is unclear** — what the user stands to gain is not settled: a one-page comparison of the current practice, the beneficiaries and the failure conditions.
- **The boundary is hard to grasp** — it is not clear how long a request, a job or a file lives: a sequence diagram that marks the lifecycle of each of them.
- **A fact is not established** — the product's behavior or an approach's feasibility is claimed but untested: a disposable probe that answers one question. Write the question down first; a probe that cannot fail answers nothing.

None of the three tools is mandatory by itself, and none is the deliverable: the diagram and the prototype are not the delivery target; each is discarded once the question is settled.

### 2. Settle the fact

Observe before proposing. In the resumable-export case:

- Inspect the task identifiers and their lifetime across a refresh first.
- The backend keeps the job: test whether the same identity recovers that same job.
- Only when disconnecting really ends the computation are the durable-execution alternatives compared.
- When only the frontend binding has to change, no queue is built to make the argument rigorous.

The probe answers its one question and stops there; a second question gets its own directory under the same carrier.

### 3. Compare the alternatives that remain credible

- Develop the credible candidates independently, then cross-evaluate them against criteria agreed in advance: whether the same intent is recovered, whether output is duplicated, and who carries the operating cost.
- Useful parts of another candidate may be taken into one; after adopting them, recheck the reasons the original choice rested on.
- A choice between behaviors with different consequences that the comparison and the probes cannot settle is a user trade-off: it goes back to `firefly-think` for the minutes (`## Handoffs`).
- A business cost the technical trial cannot settle is not decided here: it is escalated (`## Stop and escalate`).

### 4. Hand the usability dispute to a trial

- The dispute is whether the user can operate it, not whether the service can implement it: the deliverable is a disposable prototype the intended user operates, with the task, the observations and the unresolved obstacles recorded in its directory.
- The agent operating the prototype in the user's place is not a trial. A usability question the intended user has not trialed stays open and returns with the handoff.

### 5. Assemble the handoff

- The selected behavior, the rejected interpretations, the counterexamples, the evidence pointers and the first testable slice, each item naming the probe directory or the diagram that backs it; what nothing on disk backs stays out of the handoff.
- The probe directories keep their notes as they were produced; the handoff points at them rather than copying them.

## Outputs

| Fact | Carrier |
|---|---|
| The work of one question: comparison page, prototype, probe, observation notes | `openspec/changes/<id>/probes/<name>/`; without a change, `openspec/think/<date>-<slug>-probe/` |
| The sequence diagram | Where `firefly diagram` writes it, the output directory given under `openspec/think/` |
| The concept handoff: selected behavior, rejected interpretations, counterexamples, evidence pointers, first testable slice | Returned to the requester or the dispatching skill, each item naming what backs it |

- The observation notes are written as they are produced, before the next step executes (contract, Write on produce).

## Handoffs

- **To the spec stage.** The selected behavior, the rejected interpretations, the counterexamples, the evidence pointers and the first testable slice go to `firefly-propose` through the controller. The handoff continues into a proposal only when the mandate includes one.
- **To `firefly-source`.** A fact that depends on a third party's versioned promise is not probed here: the question goes to `firefly-source`.
- **Back to `firefly-think`.** A user trade-off the comparison and the probes cannot settle goes back to `firefly-think` for the minutes.
- **A diagram-only mandate** returns the diagram and the boundaries it leaves open to the requester and stops.
- **Dispatched under `firefly-propose`,** the conclusion returns to the scenario it concerns and gains no new write authority.

## Stop and escalate

Stop and `ESCALATE` when:

- **A business cost the technical trial cannot settle.** The current conclusion is the trial's result; what is missing is the requirement owner's decision on the cost, and the owner is the requirement owner.
- **A write the work needs is not covered** by the mandate's permitted effects — a probe directory or a diagram output outside them, for example. That write is not made; the work done so far is returned with its pointers. Owner: the requester, who grants the mandate.

An `ESCALATE` carries the current conclusion, the missing evidence or authority, and the responsible owner. It is a return path, not a verdict.

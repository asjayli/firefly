---
name: firefly-arch
description: Settles the interface a public promise rests on and writes the contract back into the spec scenarios before tasks are cut. Entered when firefly-propose hands over a scenario that changes a public interface or two sides that must develop independently, when firefly-tasks returns a dependency cycle that needs a contract, or when firefly-review dispatches the affected checks of the contract axis. It settles disputed vocabulary first, probes an uncertain third-party capability with a disposable probe, and writes states, error semantics, retry conditions and the compatibility window into the scenarios. Not for an internal change that changes no external commitment.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "12"
---

# firefly Arch

The shared rules are in `<skill-root>/references/handoff-contract.md`. This skill adds what settling an interface contract takes.

## When to use

- **From `firefly-propose`.** A scenario changes a public interface, or two sides must develop independently. The controller dispatches this skill under `firefly-propose` before planning starts: the contract is written back into the scenario, and only then are tasks cut.
- **A cycle that needs a contract.** `firefly-tasks` returns a dependency cycle to the controller when separating the two sides needs a contract. The contract is settled, written back into the spec scenarios, and only then is the contract task cut out.
- **The contract axis of a review.** `firefly-review` dispatches this skill for only the affected checks of the contract axis, and the results return to that review.

## When not to use

- **An internal change that changes no external commitment.** No interface is settled and no contract is written: neither the `firefly-propose` handoff nor the review axis is triggered, and the change proceeds without this skill.

## Mandate

**Fixed end.**

- Proposal entry and cycle entry: the contract is settled and written back into the spec scenarios it settles, and the return names which scenarios it went into. Planning starts only after that write-back: `firefly-tasks` cuts the contract task after it, and `firefly-implement` dispatches task groups in parallel only when the interface of each is a contract settled this way and written back into the spec.
- Review entry: a per-check return to the review that dispatched it. The verdict is the independent reviewer's to issue, never this skill's.

**Permitted effects.**

- Write the contract into the scenarios it settles, in `openspec/changes/<id>/specs/**/spec.md`.
- Write a disposable probe and its observation notes under `openspec/changes/<id>/probes/<name>/`, or under `openspec/think/<date>-<slug>-probe/` when the work has no change.
- Under a review dispatch: observation rows through `firefly record observe` with `--observer verifier:firefly-arch`, and the evidence they cite, under `openspec/changes/<id>/evidence/<snapshot12>/`.
- Under `firefly-propose`, these writes sit inside the permitted effects the proposal mandate names; named directly, the mandate on record must cover them.

**Not granted.**

- Writing the contract anywhere but the scenario it settles. `design.md` supports the scenarios and judges nothing, and is in neither package version: a contract recorded there alone judges nothing.
- Writing a decision record. `docs/adr/` is the carrier of `firefly-docs`: the content is handed to the controller, and the record itself is written only under a delegation that permits `firefly-docs`.
- Writing a migration plan. A breaking finding decides that one is needed; it does not write it.
- Changing the candidate, a check, a measurement method, a constraint, the task package or the ready decision.
- Under a review dispatch, anything beyond the observation rows and their evidence: no spec, no contract, no candidate, and none of the four verdict values issued here.
- Writing a compatibility obligation for an interface that has no existing consumers.
- Treating a probe result as the promise. Sketches and probes fix the boundary; the promise itself is the contract in the spec.

## Inputs

- **The scenario** that changes the public interface, or the two sides that must develop independently, with its stable ID `(S-xxx)`, its `- **Source:**` line and the spec package version, from the change `firefly-propose` hands over.
- **The mandate:** id, objective, permitted effects and terminal condition.
- **For a cycle entry,** the two task groups and the promise each waits for, from the controller.
- **For a review entry,** the affected checks of the contract axis: the scenario map rows the review names, the candidate snapshot, the spec version and the evidence pointers.
- **On resumption,** the contract already written back, the probe notes and the observation rows already recorded.

## Procedure

### 1. Pick the starting point

Start from the unknown most likely to overturn the interface. The three starts below are not a sequence to run every time; take the one the unknown calls for.

1. **The same word means different things to the consumer and the provider.** Settle its meaning first (step 2).
2. **The vocabulary is clear and the two sides must develop independently.** Write the contract (step 3).
3. **The third-party capability itself is uncertain.** Run a disposable probe first (step 4). A question about what the dependency promises in its version and configuration belongs to `firefly-source`; the probe here answers whether the capability works, not what is promised.

### 2. Settle disputed vocabulary

- Write the definition into the contract, so that the consumer and the provider cite one text.
- The definition must let the consumer write independent assertions without reading the provider's code. In the export case: the backend calls "complete" the moment the database record is written, the frontend calls "complete" the moment the user can download the file. Write `ready = a correct file retrievable by the authorized requester now` first. Then the interface author handles the three outcomes `queued` / `ready` / `failed` from the status sketch alone, and the provider side states when each status is published, whether a failure can be retried, and whether existing consumers are affected.
- Settling the word would pick between behaviors the records do not settle: that trade-off belongs to the requirement owner. Stop and escalate (see "Stop and escalate").

### 3. Write the contract

- **The contract carries:** the states and when each is published; the success and the error semantics; the retry conditions; the compatibility window. It is written into the scenario it settles, in `openspec/changes/<id>/specs/**/spec.md` — never into `design.md` alone — and the return names the scenarios it went into.
- **The public interface changes.** List the current and the new consumers, the success and the error semantics, the retry conditions and the compatibility window before the window is written. When a current consumer exists, replay at least one representative one against its original contract; the compatibility window states what that replay showed, and the replay's observation notes stay under the probes carrier of step 4.
- **An internal interface with no existing consumers.** State in the contract the basis for that — how the absence of consumers was checked. Write no compatibility window nobody needs, and no obligation nobody owes.
- **A breaking change.** A field name that stays the same while a retryable error becomes a permanent failure is breaking too. Say so in the contract: either the original semantics are restored, or a migration plan is needed. The migration plan is the migration owner's work and is commissioned separately; this skill only decides that the change is breaking and names it as such.

### 4. Probe an uncertain capability

- A capability that the contract would promise but that is not known to work is probed, not promised. Put the probe and its observation notes under `openspec/changes/<id>/probes/<name>/`, or under `openspec/think/<date>-<slug>-probe/` when the work has no change. Never in the product tree: a file there enters the candidate snapshot.
- Where a write's success and its visibility may come apart in time, delay visibility in the controlled probe to distinguish "the write means ready" from "confirmed readable means ready". The probe fixes the boundary; the promise in the scenario remains the contract, never the prototype.

### 5. Hand the rejected alternative to the record

- A rejected alternative that later changes are likely to raise again gets its cost and the conditions for revisiting it written down. Hand that content to the controller: the decision record under `docs/adr/` is written by `firefly-docs` under a delegation that permits it. One decision record, only when the alternative is likely to come back.

### 6. Under a review dispatch, observe the contract axis

- Run only the affected checks of the contract axis. Change no spec, no contract, no candidate: the only writes here are observation rows and their evidence.
- Capture the candidate and spec version before each affected check as specified in the handoff contract's Recording section, then write its row:

  `"<skill-root>/scripts/firefly.sh" record observe --change <id> --candidate <tree-sha> --spec <version> --scenario <S-xxx> --check <name> --result <pass|fail|unverified|not-applicable> --observer verifier:firefly-arch [--evidence <path>] [--note <text>]`

  `--note` carries three things and is never omitted: the conditions observed under, the expected outcome the scenario map row named when the observation was made, and the check it named. `--evidence` names a file under `openspec/changes/<id>/evidence/<snapshot12>/` and must exist: the recorder refuses a `pass` or a `fail` without it. The observer did not produce the candidate, so `--implemented-by-observer` is never set here.
- Return per check: the scenario, the check, the measurement method used, the result (`pass`, `fail` or `unverified`) and the evidence pointer. A check that cannot be observed under the existing authority, tools or environment is returned `unverified` with what is missing; the verdict — `ACCEPT`, `REVISE`, `RECHECK` or `INSUFFICIENT_EVIDENCE` — is the independent reviewer's to issue, never this skill's.

## Outputs

| Fact | Carrier | When |
|---|---|---|
| The contract: states, error semantics, retry conditions, compatibility window | `openspec/changes/<id>/specs/**/spec.md`, written back into the scenarios it settles | In steps 2–3, before planning; the return names the scenarios |
| Probe and its observation notes | `openspec/changes/<id>/probes/<name>/`; with no change, `openspec/think/<date>-<slug>-probe/` | In step 4, while the probe runs |
| Observation rows and evidence for the contract-axis checks | `openspec/changes/<id>/verification.md`; `openspec/changes/<id>/evidence/<snapshot12>/` | In step 6, per affected check, as verifier |
| Cost and revisit conditions of a rejected alternative | Handed to the controller; `docs/adr/` is written by `firefly-docs` | In step 5, only when the alternative is likely to be raised again |

## Handoffs

- **Back to `firefly-propose`.** The contract is written back into the scenarios; planning starts. The return names the scenarios it went into.
- **Back to the controller, from a `firefly-tasks` cycle.** The same write-back; the contract task is cut out only after it.
- **Back to `firefly-review`.** The per-check return: scenario, check, measurement method, result, evidence pointer. The verdict stays with the independent reviewer.
- **To the controller, for `firefly-docs`.** A rejected alternative with lasting force: its cost and revisit conditions, as content for a decision record.
- **`ESCALATE`** — see "Stop and escalate".

## Stop and escalate

Stop and return an `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- **Named directly and the mandate on record does not cover the writes this skill would make.** Give the conclusion in the reply and write nothing. Owner: the requester.
- **Settling the word would pick between behaviors the records do not settle.** Trade-offs whose consequences the owner carries are decided by the requirement owner. Owner: the requirement owner.
- **The probe cannot distinguish the competing rules** with the inputs, versions or environment available. The capability stays unknown and no contract is written on it. Owner: the requester, for the evidence or the environment.
- **The next step needs an effect the mandate does not permit.** Owner: the requester.

An `ESCALATE` carries three things: the current conclusion, the missing evidence or authority, and the responsible owner.

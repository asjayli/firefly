---
name: firefly-perf
description: Measures whether a change shortens the time a user actually waits, compares candidates against a baseline under recorded conditions, and hands a measurement that became a product promise to firefly-bounds and firefly-guard. Use when the user names firefly perf to measure a slow path or to compare candidates against a baseline, when firefly-review dispatches the affected checks of the budget axis, or when a scenario map row names this skill as the verifier of a measurement to interpret. Not for work with no reproducible load or a user-waiting time that cannot be defined — the distinguishing feedback is taken through firefly-debug first.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "19"
---

# firefly Perf

This skill defines the user's clock first, then measures under recorded conditions. An optimization is claimed only when the measurement can tell it from the noise. The shared rules — mandate, carriers, recording, verdicts — are in `${CODEX_HOME:-$HOME/.codex}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere.

## When to use

- **Named.** The user names `firefly perf` to measure a slow path, or to compare candidates against a baseline. The mandate record must cover the writes the work takes.
- **From firefly-review.** The review adds the budget axis when the change touches a performance budget, and dispatches this skill for the affected checks of that axis. Only those checks run, and their results return to that review; no write authority comes with them.
- **From the scenario map.** A row whose check is a measurement to interpret is observed by a verifier who did not implement the candidate (firefly-tasks, Who observes); when the row names this skill, this skill observes it and writes the row.

## When not to use

- **No reproducible load, or a user-waiting time that cannot be defined.** There is nothing to measure under recorded conditions; the distinguishing feedback is taken through firefly-debug first, and this skill is not used.

## Mandate

**Fixed end.**

- Named entry: the terminal condition of the mandate record in force — normally the measurement record and its conclusion returned.
- From a review dispatch: the results of the affected checks returned to that review. The verdict is the independent reviewer's to issue, never this skill's.
- From the scenario map: the observation row written with its evidence, as that row's verifier.

**Permitted effects.**

- Read the repository.
- Write the measurement record — the attempts that influenced the decision, including reverted ones, with their configurations, samples and withdrawal reasons — under `openspec/changes/<id>/evidence/<snapshot12>/`, one directory per measured version, never overwritten.
- Under a review dispatch or a scenario map row: observation rows through `firefly record observe` with `--observer verifier:firefly-perf`, and the evidence they cite.
- Named directly: what the mandate record permits, nothing more.

**Not granted.**

- Optimizing the candidate. The edits that make the code faster belong to `firefly-implement`; this skill defines the clock, measures, predicts and reports.
- Redefining a criterion, a measurement method or a baseline so that a candidate passes.
- Deciding which measured change is acceptable, or consenting to the handover of a constraint or a regression check. These are the requirement owner's decisions; this skill prepares and presents them.
- Issuing the review's verdict.
- Writing the constraint entry beside a scenario — that is firefly-bounds' write. Mounting a check into the project's CI — that is firefly-guard's write, under its own authority.
- Under a review dispatch: changing the candidate, its spec or its measurement conditions; editing a recorded observation row; hand-writing a ledger row.

## Inputs

- The mandate record: which entry this is and what its permitted effects cover.
- Named entry: the slow path or the comparison asked for, and the interval of the wait the requester means.
- The change `openspec/changes/<id>` and the candidate measured: `firefly snapshot` fixes the candidate before the first measurement record is written.
- The constraint entry beside the affected scenario, when one exists: the criterion, the measurement method, the baseline source and the consequence of failure it records (firefly-bounds).
- From a review dispatch or a scenario map row: the affected checks and the rows of `## Scenario map` in `openspec/changes/<id>/tasks.md` that name them — the check with its command or step, the expected outcome, the verifier — together with the candidate snapshot and the spec version the observations are made on.
- On resumption: the measurement records already under `openspec/changes/<id>/evidence/<snapshot12>/` and the observation rows already written.

## Procedure

### 1. Take the entry and its limits

1. **Named entry.** Read the mandate record first. When it does not cover the writes the work takes, give the conclusion in the reply only, write nothing, and `ESCALATE` to the requester.
2. **Review dispatch.** Only the affected checks of the budget axis. Change nothing: not the candidate, not the spec, not the measurement conditions. The observation row and its evidence are the only write. The results return to the review; no write authority comes with them.
3. **Scenario map row.** Write the row as its verifier. The implementer's own run documents a deviation; it never replaces this row.

### 2. Define the user's clock before optimizing

1. Acknowledgement, queue delay, computation and file readability measure different outcomes. Name the interval the requirement asks about before anything is measured or changed.
2. Returning a job ID faster can improve interaction without reducing the time to a correct file: report the interaction gain as interaction, never as a shorter wait for the result.
3. When the requirement asks only for recovery after refresh, that work is not recorded as a performance gain.

### 3. Fix the conditions before the first comparison

1. Choose representative data and concurrency; record the environment, the cache cold or warm, the baseline distribution and the measurement variation in the measurement record.
2. Diagnose the bottleneck in a separate profiling run; the profiler's own overhead stays out of the formal comparison.
3. A load generator that saturates first invalidates the comparison: results from such a run are not used to compare candidates.
4. Before any modification, state which interval the change is expected to improve, and the cost that may be displaced to memory, tail latency or background load.

### 4. Compare under comparable conditions

1. Re-measure the baseline and the candidate alternately under comparable conditions. Two numbers measured under different conditions are not compared directly.
2. Report the end-to-end result and the affected intervals, not the best run.
3. A difference not distinguishable from the recorded variation is an unproven improvement: report it as such.
4. Added complexity without a reproducible benefit: recommend keeping the simpler implementation.
5. A result made under another criterion or measurement method has lapsed (contract, Lapse) and is not compared; the agreed method is rerun on the current candidate.

### 5. Preserve and report

1. Preserve every attempt that influenced the decision, including reverted ones: the configurations, the samples and the reason each was withdrawn, under `openspec/changes/<id>/evidence/<snapshot12>/` (`<snapshot12>` is the first 12 characters of the measured version's snapshot). A later run never overwrites one.
2. The rerun method and its limits are handed to the pull request (`firefly-pr`), so that an independent reviewer can question the measurement design and not only read the numbers.
3. A single labeled ballpark is deliverable only when the user explicitly asked for an order of magnitude and the conditions are named with it. It never chooses between designs.

### 6. Record the observation

Run each affected check under the measurement method the constraint entry and the scenario map row record, and write the row as it is produced, before the next step:

   `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" record observe --change <id> --scenario <S-xxx> --check <name> --result <pass|fail|unverified|not-applicable> --observer verifier:firefly-perf [--evidence <path>] [--rule <text>] --note "<conditions observed under; the expected outcome the scenario map row named when observed; the check that row named>"`

   - `pass` and `fail` need `--evidence` naming an existing path, put under `openspec/changes/<id>/evidence/<snapshot12>/`.
   - `not-applicable` needs `--rule` naming the rule that applies and the reason.
   - `--note` is never omitted: it carries the conditions observed under, the expected outcome the scenario map row named when the observation was made, and the check that row named. The recorder writes them into the `Conditions` column (contract, Recording).
   - The recorder fills in the candidate snapshot and the spec version; nobody reports them by hand. A rejected call writes nothing.
   - The observer did not implement the candidate, so `--implemented-by-observer` is never set here.

Return per check: the scenario, the check, the measurement method used, the result (`pass`, `fail` or `unverified`) and the evidence pointer. The verdict — `ACCEPT`, `REVISE`, `RECHECK` or `INSUFFICIENT_EVIDENCE` — is the independent reviewer's to issue, never this skill's.

### 7. When the result becomes a product promise

1. A measurement became a product promise when its baseline is stable, its tolerance is stated and an owner keeps it. Hand the baseline, the tolerance and the owner to firefly-bounds, to be turned into a constraint beside the scenario. The handover carries no write authority (contract, Mandate record): writing the constraint entry needs a mandate whose permitted effects cover the spec package — a proposal dispatch already covers it; otherwise the constraint is given in the reply and `ESCALATE` to the requester.
2. The repeatable regression check goes to firefly-guard through the same gate: with the requirement owner's consent, a measurement whose method is stable and whose failures have an owner is mounted as a regression check. Mounting writes the project's CI: it takes write authority, which firefly-guard holds under its own mandate. This skill mounts nothing.
3. Without a stable baseline, a stated tolerance or an owner, the result stays an investigation finding: report it as such, and the run ends there.

## Outputs

| What | Carrier | When |
|---|---|---|
| The measurement record: attempts including reverted ones, with their configurations, samples and withdrawal reasons | `openspec/changes/<id>/evidence/<snapshot12>/`, one directory per measured version | As each attempt is made, before the next step |
| The conclusion: which interval changed, by how much, under which conditions — or that the difference is unproven | The return to the requester or the review | With the result |
| The observation row of an affected check | `openspec/changes/<id>/verification.md`, through `firefly record observe` | Under a review dispatch or a scenario map row, as it is produced |
| The evidence an observation cites | `openspec/changes/<id>/evidence/<snapshot12>/` | Before the row that cites it |
| The baseline, tolerance and owner of a product promise | Handed to firefly-bounds; the constraint entry is that skill's write | When the result became a promise |
| The repeatable regression check | Handed to firefly-guard, with the requirement owner's consent | When the method is stable and the failures have an owner |

## Handoffs

- **From firefly-review.** Only the affected checks of the budget axis. Their results return to that review; no write authority comes with them.
- **From the scenario map.** A row whose check is a measurement to interpret names this skill as its verifier; the observation is written on the candidate that row is judged on.
- **To firefly-review.** Per check: the scenario, the check, the measurement method used, the result, the evidence pointer. The verdict stays with the independent reviewer.
- **To firefly-bounds.** A measurement that became a product promise: its baseline, its tolerance and its owner. The handover carries no write authority (contract, Mandate record): writing the constraint entry needs a mandate whose permitted effects cover the spec package; without one, the constraint is given in the reply and `ESCALATE` to the requester.
- **To firefly-guard.** The repeatable regression check of a measurement whose method is stable and whose failures have an owner, with the requirement owner's consent. Guard mounts it under its own write authority; this skill mounts nothing.
- **To firefly-debug.** No reproducible load, or a waiting time that cannot be defined: the distinguishing feedback is taken there first.
- **`ESCALATE`** — see "Stop and escalate".

## Stop and escalate

Stop and `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- **Named directly and the mandate record does not cover the writes this skill would make.** The conclusion goes in the reply, nothing is written. Owner: the requester.
- **No reproducible load, or a user-waiting time that cannot be defined.** The measurement cannot start; the distinguishing feedback is taken through firefly-debug first, and this skill is not used. Owner: the requester.
- **The representative workload cannot be run under the existing authority, tools or environment**, and no comparison can be made without it. Owner: the requester, for the environment.
- **The measured gain and its displaced cost trade off against each other and the records do not settle the choice.** Bring the gain and the cost displaced to memory, tail latency or background load. Owner: the requirement owner.

Or, without stopping: the work has no change behind it — the record and the conclusion go to the progress record, section `## Performance notes` (contract, Carriers), the per-candidate evidence carrier lives under a change directory and does not exist here, and the run ends there. A required measurement cannot be obtained under a review dispatch. Record the row `unverified` with the reason and return it; the review adjudicates `INSUFFICIENT_EVIDENCE` from it.

Noise is not a stop: a difference within the recorded variation is reported as an unproven improvement, and nothing is claimed. An `ESCALATE` is a return path, not a verdict.

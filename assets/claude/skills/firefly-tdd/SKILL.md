---
name: firefly-tdd
description: Carries the test discipline of a delivery: a test worth writing first stably separates the old behavior from the intended one, its failing run is watched on the unchanged baseline before the implementation is written, and every run is recorded through `firefly record observe` with its evidence. Entered when firefly-implement dispatches a task group whose checks are tests, or when the user names `firefly tdd` for the tests of a change. Not used for a change that alters no observable behavior — a pure refactor, whose regression basis is the green of the existing tests; documentation, comments and formatting — nor for a one-off probe.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "13"
---

<!-- Evolved from the test-driven-development skill of obra/superpowers (MIT): writing the failing test before the implementation, the red, green, refactor rhythm, tests kept near the public behavior, and the assertion never weakened to make a run green. The words are firefly's own. -->

# firefly TDD

A test is worth writing first when it separates the old behavior from the intended one, and a run proves something only once it has been watched. This skill carries that discipline into a delivery: the failing run comes before the implementation, the implementation alone changes between the failing and the passing run, and the evidence of every run reaches its carrier. The shared rules — mandate, carriers, recording, verdicts — are in `${CLAUDE_HOME:-$HOME/.claude}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere. What a red record must quote, the alternative-observation declaration and the worked example are in `references/test-evidence.md`.

## When to use

- **Under firefly-implement.** The controller dispatches a task group whose checks are tests: the discipline governs every test the group adds or changes and the observations of its scenario map rows. The writes are the test scripts inside the group's allowed modification scope — a test script in the product tree is part of the candidate snapshot — and the observation rows and evidence of the group's checks.
- **Named.** The user names `firefly tdd` for the tests of a change. The mandate record must cover the writes the work takes; this skill writes what it permits, nothing more.

## When not to use

- **The change alters no observable behavior.** A pure refactor keeps the green of the existing tests as its regression basis: rerun them; no new test is written for a change that changes nothing observable. Documentation, comments and formatting are the same.
- **A one-off probe.** A probe is disposable and never enters the product tree (contract, Carriers); no test of record is written for it.

## Mandate

**Fixed end.** Under the delivery: the fixed end of firefly-implement, so far as the tests of the dispatched task groups reach — every test of a group watched failing on the unchanged baseline before the group's implementation is written, its passing run or its declared alternative observation on the candidate, and the observation rows of the group's checks on record. Under a named entry: the terminal condition of the mandate record in force.

**Permitted effects.**

- Under the delivery: write test scripts inside the task group's allowed modification scope; run the checks the scenario map names; write the observation rows of those checks through `firefly record observe`, with evidence under `openspec/changes/<id>/evidence/<snapshot12>/`.
- Under a named entry: what the mandate record permits, nothing more.

**Not granted.**

- Weakening an assertion, or narrowing a test, to turn a run green. A requirement that itself changed is a scenario revision: it belongs to the requirement owner and the spec author, through `firefly-propose` — never to this skill.
- Counting a red produced by an environment fault as the red the cycle wants.
- Recording a check `pass` from a run that was not made, or from a run that cannot separate a candidate wrong for the promise from a correct one.
- Editing a recorded observation row, or hand-writing a ledger row (contract, Recording).
- Changing the spec, the scenario map or a promised behavior. A failing run that shows the promise itself wrong stops the work here; the promise is never reworded in this skill.

## Inputs

- The change `openspec/changes/<id>` and the dispatched task group: its allowed modification scope, and its rows of `## Scenario map` in `openspec/changes/<id>/tasks.md` — the check with its command, the expected outcome, the verifier, the time and the candidate.
- The scenarios of `openspec/changes/<id>/specs/**/spec.md` with their stable IDs: the behavior promise each test serves.
- The unchanged baseline: the tree the task group starts from — the `Preflight` baseline of the progress record, or the task group baseline `<N>: <sha>` recorded before the dispatch.
- The alternative-observation declaration the task package carries for a check that cannot be automated: the alternative observation, its owner and the risk that stays uncovered. Writing it is the planner's, under `firefly-tasks`; this skill reads it and enforces it.
- On resumption: the observation rows already written, their evidence, and Git.

## Procedure

### 1. Judge the test worth writing

1. A test is written first when it stably separates the old behavior from the intended one: its assertion fails on the old behavior and holds on the intended one, at a run cost the task group can pay on every cycle.
2. Take the seam closest to the behavior the scenario promises. A test that reaches the promise through its public behavior survives changes inside the implementation; one pinned to internal structure breaks with them and tests the structure, not the promise.
3. The test set separates the behaviors the promise distinguishes, the failure branches included — every required scenario has a row for each of its checks and branches, and each branch gets its test. The model is the idempotent submission: keep one submission's intent identifier, arrange the run so the server has accepted the request and its first response never arrives, retransmit under the same identifier and check the two submissions hold one job between them — then submit the same query under a new identifier and check it yields a different job. A set that stops at the retransmission accepts an implementation that permanently reuses the first job for every matching query (`references/test-evidence.md`).
4. A check that cannot be automated at that cost — expensive, unstable — is not forced. Before the task group starts, its promise carries the declared alternative observation in the task package: the alternative observation, its owner and the risk that stays uncovered. Without the declaration nothing of that promise is implemented; the gap returns to planning under `firefly-propose`. The independent review still judges the same behavior promise; the declaration lowers no bar.

### 2. Watch the failing run

1. Run the test on the unchanged baseline, before any file of the task group's implementation is modified. Confirm the failure comes from the expected assertion: not from the environment, not from the data setup, not from the test itself.
2. A red from a fault in the environment — a disconnected database, a missing service, a broken fixture — proves the environment broken and nothing about the behavior. Repair the run conditions or `ESCALATE`; it is never recorded as the red the cycle wants.
3. Record the red run before the implementation is written:

   `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" record observe --change <id> --scenario <S-xxx> --check <name> --result fail --observer implementer:<name> --implemented-by-observer --evidence <path> --note "<conditions observed under, the expected failure reason among them; the expected outcome the scenario map row named when the observation was made; the check that row named>"`

   The implementer writes the test and runs it, so the observer is the implementer, and `--implemented-by-observer` is set: the candidate the recorder names already holds the test this observer wrote. The evidence quotes the actual failing value against the expected value, or the actual error message, and names the check and the baseline version the run was made on. A statement that a run was red is not evidence (`references/test-evidence.md`).
4. The expected red on the unchanged baseline starts no repair round: it is the demonstration that the test separates the behaviors, and its fix is the task group's own implementation — the classification the preflight gives a baseline failure the change exists to fix (`in-scope-red`).

### 3. Read a baseline that already passes

1. A test that passes on the unchanged baseline is one of two things: the promise is already satisfied, or the assertion is too weak to separate. Find out which before any implementation is written: name the behavior the promise requires that the current implementation lacks, and make the assertion reach it.
2. When no assertion can separate the promise from the current behavior, the promise is already delivered or names no behavior to test. Return it to the spec author through `firefly-propose` rather than keeping a test that cannot fail.

### 4. Red, green, refactor

1. **Green.** Change only the implementation. The test revision stays as it is, and the rerun happens under comparable conditions — the same test version, the same inputs, the same environment class; the tests that already passed before the change still pass. The implementation is written to the assertion, never the assertion to the implementation.
2. **Record the passing run** (step 5). When the scenario map names `implementer` for the row — a replayable mechanical check that needs no second identity, no alternative observation and no measurement to interpret — the implementer's own run counts, and only because the failing run of step 2 exists: a test written for this change gets that failing run during implementation, under `firefly-tdd`, before the implementer's own run counts. A check that needs a second identity, an alternative observation or a measurement to interpret is observed by the verifier its row names, replayable or not.
3. **A rerun that still fails is a defect of the implementation**, not of the test: fix the implementation, never the assertion. The one exception stops the work: the run shows the promise itself is wrong (`## Stop and escalate`).
4. **Refactor.** After green, a change that alters no observable behavior keeps the green of the existing tests as its regression basis: rerun them, change no assertion, write no new test for it.

### 5. Record the evidence

1. Every observation of a check the scenario map names goes through the recorder, as it is produced and before the next step runs:

   `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" record observe --change <id> --scenario <S-xxx> --check <name> --result <pass|fail|unverified|not-applicable> --observer verifier:firefly-tdd [--evidence <path>] [--rule <text>] --note "<conditions observed under; the expected outcome the scenario map row named when the observation was made; the check that row named>"`

   - The default observer is `verifier:firefly-tdd`, for a row this skill observes as the verifier its map row names. When the map names `implementer` for the row and the conditions of step 4 hold, the run is recorded `--observer implementer:<name>` with `--implemented-by-observer`. A name given to an implementer or an observer begins with a letter or digit and holds letters, digits and `. _ : @ + -` only: the recorder refuses any other character.
   - `pass` and `fail` need `--evidence` naming an existing path, put under `openspec/changes/<id>/evidence/<snapshot12>/`; a rerun gets a new location and never overwrites an earlier one.
   - `not-applicable` needs `--rule` naming the rule that applies and the reason.
   - `--note` is never omitted. It carries the conditions observed under — the test revision, the inputs and, for a red run, the expected failure reason — the expected outcome the scenario map row named when the observation was made, and the check that row named. The recorder writes them into the `Conditions` column (contract, Recording).
   - The recorder fills in the candidate snapshot and the spec version; nobody reports them by hand. A rejected call writes nothing.
2. A test that serves no mapped row runs in the same cycle as part of the implementation's own verification; the observation rows are the checks the scenario map schedules.
3. An alternative observation is trusted only where it produces different results on a candidate wrong for the promise and on a correct one. Where that separation cannot be shown, its result is `unverified`, never `pass`. A check skipped, cancelled or left without a result is recorded `unverified` (contract, Observation record).

## Outputs

| What | Carrier | Written |
|---|---|---|
| The test scripts of the task group | the product tree, inside the group's allowed modification scope | under the delivery, as each test is written; part of the candidate snapshot |
| The evidence of a run — the red run's quoted failure, the passing run's output | `openspec/changes/<id>/evidence/<snapshot12>/` | before the row that cites it; a rerun gets a new location |
| The observation rows of the checks the scenario map names | `openspec/changes/<id>/verification.md`, through `firefly record observe` | as each observation is made |
| The results returned to the dispatch | the reply to firefly-implement | with the task group's candidate |

## Handoffs

- **From firefly-implement.** The dispatched task group: its scenario map rows, its allowed modification scope and its acceptance commands. The original terminal condition and permitted effects travel with the dispatch; the test scripts written here are part of the candidate the delivery fixes.
- **Named.** The mandate record in force.
- **To firefly-implement.** The observation rows and evidence on the candidate, and the checks actually run with their results and deviations. A red row's candidate is the baseline plus the test script, an earlier snapshot: it is a deviation-documenting row, never the failing scenario of a repair round. The verdict is the independent reviewer's, judged against the same behavior promise where an alternative observation was declared.
- **To `firefly-propose`.** A check that cannot be automated whose task group carries no declaration; a promise no test can separate from the current behavior and no alternative observation covers; a scenario whose promise the tests show already delivered. Each returns to the planner as a gap to fill, never filled in here.
- **To the requirement owner.** A failing run that shows the promise itself wrong.

## Stop and escalate

Stop and `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- The task group carries no declaration for a check that cannot be automated. Nothing of that promise is implemented. Owner: the planner, through `firefly-propose`.
- No test and no alternative observation can separate the promise from the current behavior: its scenario map row has no check that can judge it. Owner: the planner, through `firefly-propose`.
- The run shows the promise itself is wrong, or the fix would change a promised behavior. The promise is never reworded here and no assertion is weakened. Owner: the requirement owner.
- The run cannot be made at all: a missing service, database, fixture or capability. The red proves nothing about the behavior. Owner: the owner of the missing capability or environment.
- Under a named entry, the mandate record does not cover the writes the work takes. The conclusion goes in the reply, nothing is written. Owner: the requester.

An environment fault is repaired in the run or escalated; it is never recorded as the red the cycle wants. An `ESCALATE` is a return path, not a verdict.

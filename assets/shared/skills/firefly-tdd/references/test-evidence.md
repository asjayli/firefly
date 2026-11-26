# Test evidence, the alternative observation, and the worked example

The rules of `SKILL.md` in the form they are applied. Nothing here widens the mandate: the red record, the declaration and the example below say what the observation row and the task package must already carry.

## What a red record quotes

A red record is evidence only when a reader can reconstruct the failure from it:

- the actual failing value set against the expected value, or the actual error message, verbatim;
- the check and the baseline version the run was made on — the tree the run started from, the task group baseline `<N>: <sha>` the progress record keeps;
- the inputs the run used and the environment class it ran in.

A statement that a run was red is not evidence. Neither is a summary that names no value, no message and no version.

An environment red proves the environment. A disconnected database, a missing service or a broken fixture fails the run before the behavior is reached; the record says so, and the run is repaired or escalated — it is never presented as the failing run the cycle wants.

## What a passing run's evidence shows

The passing run's evidence names the same test revision and the same inputs as the failing run it answers, so the two rows differ in the implementation alone. That is what makes the pair an experiment: only the implementation changed between them, under comparable conditions.

## The alternative-observation declaration

A check that cannot be automated at an acceptable run cost — expensive, unstable, or dependent on an environment the task cannot hold still — is not forced into a script. Its promise instead carries a declaration in the task package, written by the planner under `firefly-tasks`, with three things:

1. the alternative observation that replaces the check;
2. the owner of that observation;
3. the risk that stays uncovered while the check is not automated.

The declaration lives with the task group it serves, in `openspec/changes/<id>/tasks.md` (contract, Carriers). Writing it is the planner's write: an implementer never adds it to a task item, and this skill never edits the task package — a task package change ends the ready decision in force and returns the change to `firefly-propose`.

The independent review still judges the same behavior promise. The declaration changes who observes and what evidence exists; it does not lower what must be shown.

An alternative observation is trusted only where it produces different results on a candidate wrong for the promise and on a correct one. Where that separation cannot be shown, the observation is `unverified`, never `pass`.

## The worked example: one promise, two tests

The promise: one submission, one job, however often the same request arrives. Two behaviors hide in it, and a test set that stops at the first accepts a wrong implementation.

1. **Retransmission.** Keep one submission's intent identifier. Arrange the run so the server has accepted the request and its first response never arrives. Retransmit with the same identifier and check the two submissions hold one job between them.
2. **A new intent.** Submit the same query under a new intent identifier and check it yields a different job.

A set that tests only the retransmission accepts an implementation that permanently reuses the first job for every matching query: it passes the first test and fails the second. Both tests are written before the implementation, both watched failing on the unchanged baseline, both rerun on the candidate — the same test revision, the same inputs, the implementation alone changed.

## The `--note` of an observation row

`--note` is never omitted. It carries three things (contract, Recording):

1. the conditions observed under — the test revision, the inputs, the environment class and, for a red run, the expected failure reason;
2. the expected outcome the scenario map row named when the observation was made;
3. the check that row named.

The reviewer sets the last two against the `Expected` and the `Check` the map row carries now; a row whose two are not both present supports no `ACCEPT`.

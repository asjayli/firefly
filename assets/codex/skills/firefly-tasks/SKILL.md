---
name: firefly-tasks
description: Divides a ready spec into tasks when the controller names the skill under firefly-propose, and writes the tasks, the baseline, targeted and integrated commands and the two-way scenario map to openspec/changes/<id>/tasks.md. Also serves the read-only overview when the user names firefly tasks, and then writes nothing. Does not plan before the spec is ready, start implementation, or write the ready decision.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "06"
---

<!-- Evolved in part from the superpowers skill `writing-plans` (MIT). -->

# firefly Tasks

The shared rules are in `${CODEX_HOME:-$HOME/.codex}/firefly/references/handoff-contract.md`. This skill adds what task planning and task queries need.

## When to use

- **Planning entry.** The controller names this skill under `firefly-propose`, with the change id, once the spec is ready to be divided: the change has a spec package version, every required scenario carries its stable ID and decision source, and a contract that `firefly-arch` had to settle is written back into the scenarios. The planner writes the task package.
- **Planning entry, again.** The controller names it when the joint decision returns the task package, when `firefly validate --root` names this change's `tasks.md` as not compliant (the validator as shipped does not read that file), or when a repair scenario handed over from `firefly-debug` needs a minimal task.
- **Query entry.** The user names `firefly tasks`, or asks only which tasks remain. Run the listing command and report its output.

## When not to use

- **The request only asks for task status.** Take the query entry: write no file, tick no item, repair nothing.
- **The spec is not ready.** Do not plan. Return to the controller when any of these holds:
  - the change has no spec package version: `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --spec <id>` exits non-zero;
  - a required scenario lacks its stable ID `(S-xxx)` or its `- **Source:**` line;
  - a scenario changes a public interface, or two sides must develop independently, and the contract is not yet written back into the scenario.
- **The work belongs to another skill**: implementing a task (`firefly-implement`), reviewing a candidate (`firefly-review`), writing the spec (`firefly-propose`).
- **The request is to record the ready decision, an observation or a verdict.** Those rows come from `firefly record`.

## Mandate

**Fixed end**

- Planning entry: `openspec/changes/<id>/tasks.md` is complete and returned to the controller, who sends the spec package and the task package to the joint decision under `firefly-propose`. Its result is the ready decision. The file is complete when:
  1. every task group delivers one independently observable behavior;
  2. the baseline, the targeted and the integrated commands are each specified;
  3. `## Scenario map` maps every required scenario, each of its checks and branches, to a task, a verifier, a check with its expected outcome, a time, a candidate snapshot and the spec package version, and every task lists its scenario IDs back;
  4. every task item the plan adds is unticked, and an item the controller already ticked stays as it is.

  A finished plan is not a start.
- Query entry: the listing is reported as the command printed it.

**Permitted effects**

- Planning entry: write `openspec/changes/<id>/tasks.md`, and nothing else.
- Planning entry: run `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" validate --root <project-root>` and `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --spec <id>`; neither writes a carrier.
- Query entry: none.

**Not granted**

- Writing the ready decision. `## Ready decision` is written only by `firefly record ready`, when the controller records the joint decision.
- Unblocking a dependent. Only the controller does that, on the result integrated on the target baseline.
- Changing the spec, a decided goal or a promise; writing an observation record, evidence or the progress record.
- Clearing a dependency or a cycle by ticking a checklist item.
- A note on a task item in `tasks.md`, at any time. A blocker is carried by the escalation and by the dispatch and budget rows of the progress record.
- Starting implementation.

## Inputs

- The change id, as the controller names it.
- The project root, for strict validation.
- The spec package version, printed by `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --spec <id>`. It is also the content digest of every scenario.
- `openspec/changes/<id>/specs/**/spec.md`: the required scenarios with their stable IDs and `- **Source:**` lines, the contracts written back into the scenarios, the runtime signal requirements and the open blockers.
- `openspec/changes/<id>/design.md`, when present: the details that support the scenarios. It judges nothing and is in neither package version, so a criterion, a measurement method or a signal requirement is never taken from it alone: each is read from the scenarios.
- `openspec/changes/<id>/proposal.md`, section `## Mandate`: the mandate, and the `Minutes: <path>` line after its table. That line points to the requirement record; a file the user named as the requirement is itself the requirement record. For a mandate with no change the same line sits after the `## Mandates` table of the progress record, `.superpowers/sdd/progress.md`.
- Two kinds of mandate. A change may carry more than one row under `## Mandate`, a proposal-only mandate and one or more delivery mandates; the mandate in force is the newest row. A row whose terminal condition is the `accepted` candidate is the delivery mandate (contract, Mandate record). Any other row is proposal-only: it ends with the change ready to start.
- The checks the project already has: its test, lint and build commands. The plan relies on them for evidence.
- The existing `openspec/changes/<id>/tasks.md`, when a task package is being repaired.

## Procedure

### Plan the change (planning entry)

1. Read every input. Run `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --spec <id>`; its output is the spec version the map is judged against.
2. Cut task groups: one group delivers one independently observable behavior. Two behaviors that can be observed apart are two groups. A step with no observable behavior of its own is a sub-item of the group that needs it.
3. Give every group the fields under "Task group". Runtime signal requirements get a group like any other behavior.
4. Walk the dependency edges and settle every cycle under "Cycles".
5. Write `## Scenario map` after the last task group: the three groups of commands, then the map table.
6. Name the verifier of each row under "Who observes", and settle the rows no command can re-run under "Non-replayable observations".
7. Check the package against "Checks the package must pass", then return it to the controller.

Leave an existing `## Ready decision` table untouched, row for row, when repairing a package.

### Task group

```markdown
## N. <Group Name>

Delivers: <the observable behavior this task delivers>
Scenarios: <S-xxx> (<check or branch>), <S-yyy> (<check or branch>)
Spec: <path to the spec file>
Depends on: <none | group numbers>
Needs from dependencies: <the promise each dependency must provide>
Allowed scope: <files, modules and systems this task may change>
Targeted check: <command id from the scenario map>

- [ ] N.1 <step>
- [ ] N.2 <step>
```

- `Delivers`, `Scenarios` and `Spec` give the result, the scenarios and where an implementer who was not in the earlier discussion finds the basis.
- `Allowed scope` is the modification scope. `Targeted check` and the map rows give the verification path.
- Keep the heading `## N. <Group Name>` and the items `- [ ] N.M ...` exactly. `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/task-brief" PLAN_FILE TASK_NUMBER` extracts group N by that heading. The last group's brief runs to the end of the file, so it also carries `## Scenario map`.
- Field lines and map rows never start with `- [ ] `. `firefly tasks` lists every line that does.

### Ticks and edits to `tasks.md`

- A plan is written with every item unticked. Task items are ticked under `firefly-implement`: the controller ticks the items of a task group at once, as soon as that group is integrated on the target baseline. A task group that passes only in a child worktree stays unticked. A tick, like a row the recorder appends to `tasks.md`, is neither part of the task package nor part of the candidate snapshot.
- The planner neither ticks nor unticks. A tick already in the file when a package is repaired is the controller's record and is left as it is.
- A blocked task carries no note in `tasks.md`, at any time. A note on a task line changes the task package version; a blocker is carried by the escalation and by the dispatch and budget rows.
- Any edit to the package other than a tick or a row of the `## Ready decision` table is a task package change: a task added or removed, a mapping changed, a step or a field reworded, a note on a task line. It changes the task package version and triggers the review again under "Handoffs".

### Dependencies

`Scenarios:` is the reverse half of the scenario map: it lists back the scenario IDs the task serves.

A dependency waits for a promise, not for a commit. In the export case:

- Task 1 delivers "the owner submits a fixed small sample and gets back a file with the correct content".
- Task 2 delivers "a retry after the response is lost still points at the same job". It depends on 1.
- Task 3 delivers "recovery after refresh, and no retrieval from another account". It depends on 1.

Tasks 2 and 3 need a callable submit path from task 1. When task 1 has committed only a table schema and has no runnable path, work that depends on the integrated result does not start. The edge opens only when the controller sees the promise hold on the target baseline. A passing child worktree means the candidate is `ready-to-integrate`; the task is not done. So a task group that other groups depend on has the check of the promise it provides observed at `integrated` as well as `task`: the row written on the target baseline is what opens the edge.

### Cycles

When dependency edges form a cycle:

1. Write down, for each of the two tasks, which promise it is waiting for from the other.
2. When separating them needs a contract, return the cycle to the controller. `firefly-arch` produces the contract, it is written back into the spec scenarios, and only then is the contract task cut out.
3. Otherwise merge the two into one delivery slice.

A cycle is never cleared by ticking a box.

### Three groups of commands

They sit inside `## Scenario map`, under the task groups, each saying when it runs and on what:

```markdown
## Scenario map

### Baseline commands

Run once before the first change, on the baseline, to record the starting state.

- B1: <command> — expected on the baseline: <result>

### Targeted commands

Run on the candidate snapshot of the group that delivers the behavior, before integration.

- 1: T1 <command> — verifies the deliverable of group 1

### Integrated commands

Run on the integrated candidate, each time a task group is merged into the target baseline; the run after the last group is merged covers the whole set.

- I1: <command>
- I2: <integrated assertion>
```

- **Baseline commands** record where the change starts. Every existing command that a targeted or an integrated check reuses runs here too, with the result expected before the change. Each one is harmless to run: it deploys nothing, releases nothing, alters no database and writes to no external system.
- **Targeted commands**: each one belongs to a single task group and proves that group's deliverable.
- **Integrated commands** take the targeted commands together, each listed once, plus the integrated assertions: checks that hold only once the groups that share a contract are merged.

Every line is a concrete, runnable command.

### Scenario map table

One row per scenario × check or branch, placed after the three groups of commands:

| Scenario | Check | Task | Verifier | Expected | Observed at | Candidate | Spec version |
|---|---|---|---|---|---|---|---|
| S-003 (retrieval) | T1 | 1 | implementer | file content equals the fixed sample | task, integrated | task candidate, integrated candidate | `<ver>` |
| S-003 (failure) | T4 | 4 | verifier | job shows failure and a next action | integrated | integrated candidate | `<ver>` |

- **Scenario**: the stable ID and the check or branch. **Check**: a command id, or the name of a manual or browser step.
- **Task**: the group that delivers the behavior. With `Scenarios:` on the group, this is the two-way map.
- **Verifier**: see "Who observes".
- **Expected**: the observable outcome of a correct implementation.
- **Observed at**: every row is observed at `integrated` (on the target baseline), because the review judges the integrated candidate only. `task` (before integration) adds an earlier observation. A task group that other groups depend on takes it as well for the check of the promise it provides ("Dependencies").
- **Candidate**: which candidate snapshot the row is observed on: `task candidate`, `integrated candidate`, or both. `firefly record observe` writes the identifier when the observation is made; none is typed here.
- **Spec version**: the spec package version, what `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --spec <id>` prints. It is also the content digest of every scenario. A commit of the task package does not change it; only a change to the spec content does, and it does so whichever scenario is edited.
- **When it changes**. Every observation row and every map row that cites the old version lapses with it, whether or not its own scenario changed. Ready decisions and review packages lapse under the Lapse rule of the handoff contract, and every other record follows its own rule.
- **When a criterion or a measurement method changes**. The version can stay the same while the observation records made under the earlier criterion or method lapse. An observation row carries the spec version and no task package version, so this is judged against the scenario map, where the `Check` and the `Expected` of a row are written. The task package version is its criterion (contract, Recording): once `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --tasks <id>` no longer prints the version a review package pinned, the map is read as the new copy.
- **How versions are compared**. The map, the observation rows and the ready decision rows carry one version. Versions are compared without the `wt:` prefix, in the map, in the observation rows and in a ready decision alike: the prefix only marks uncommitted files, and a commit drops it without changing the version. The `Spec` column of an observation row carries `spec:<version>`, or `spec:wt:<version>` while the spec is uncommitted: compare what follows `spec:`, the `wt:` prefix ignored.

Every required scenario has a row for each of its checks and branches, the failure branches included, and each row has a task. In the export case the retrieval of S-003 belongs to task 1 and the failure of S-003 to task 4, "a failed generation shows failure". A plan that schedules E3 success and leaves the failure invisible has no passing condition.

### Who observes

The `Verifier` cell of a row is `implementer` or `verifier`. The observation decides which:

| The observation | `Verifier` |
|---|---|
| A replayable mechanical check that needs no second identity, no alternative observation and no measurement to interpret (`firefly-tdd`; a `firefly-verify-web` path saved as a replayable project check) | May be `implementer`, provided the check has first failed on a known-wrong candidate. A test written for this change gets that failing run during implementation, under `firefly-tdd`, before the implementer's own run counts. The independent reviewer may rerun the check. |
| Real operation (`firefly-ui`; a `firefly-verify-web` session that is not replayable), a second identity (any check that acts as a second test identity, `firefly-guard` included), an alternative observation, a measurement to interpret (`firefly-bounds`, `firefly-perf`) | Must be `verifier`: someone who did not implement the candidate. |

- A check that falls in both rows takes the second: one that needs a second identity, an alternative observation or a measurement to interpret is observed by `verifier` even when a command can re-run it.
- A `firefly-verify-web` check sits in one row only, and the planner decides by what the check is, not by the skill that makes it. A saved, replayable project check that needs no second identity, no alternative observation and no measurement to interpret is in the first row. A one-off operation in a browser session is in the second. So is a check that acts as a second test identity, account isolation for example: replayable or not, it is in the second row.
- `implementer` is allowed only in the first row, and only once that failing run exists. The observation is then recorded with `--observer implementer:<name>` and `--implemented-by-observer`. A name given to an implementer or an observer begins with a letter or digit and holds letters, digits and `. _ : @ + -` only: the recorder refuses any other character.
- The verifier named in the map writes the observation record of its row. Its `--note` is required. It carries the conditions observed under, the expected outcome the row named when the observation was made, and the check the row named (contract, Recording); the recorder writes them into the `Conditions` column of the observation row, and the reviewer sets the last two against the `Expected` and the `Check` the map row carries now. A row observed without both of them supports no `ACCEPT`. On a row whose `Verifier` is not `implementer`, the implementer's own run documents a deviation and never replaces the record of the designated verifier.

### Non-replayable observations

- A check that no command can re-run is marked `non-replayable` in its `Check` cell, and the row names the observation that replaces it and the evidence that observation must leave.
- Data that can be observed only before the first migration gets a redacted, versioned sample captured before any migration step. In the migration task, name where the sample and its version are kept, and state that the task does not become ready until the sample exists. The capture is not a step of the migration task: it is a task group of its own that the migration task lists under `Depends on`, or a step of a group the migration task already lists there. A capture task group of its own has no row of the map: under `Delivers:` it names the non-replayable row it serves.

### Checks the package must pass

The joint decision checks a task package for failure branches, cycles, non-replayable items and integrated assertions, and walks the map in both directions: from each scenario to its task and observation, and from each task back to the promise that authorizes it. A package that lacks any required mapping returns to planning, never to be filled in afterwards as "tested". Make sure of each point before the handover:

1. Every required scenario, with each check and failure branch, has a row; every task lists, under `Scenarios:`, exactly the rows of the map that name it. The one task group without a row is a capture task group of its own.
2. Every task traces to a scenario whose source is `user-words` or `owner-confirmed`, or to an inferred scenario the return lists for confirmation ("Handoffs"). Nothing is planned for the scope behind any other open blocker. A capture task group of its own is the exception: it serves a non-replayable row and has no scenario of its own.
3. The dependency edges are acyclic.
4. Each non-replayable row names its substitute observation and its evidence. The pre-migration sample is captured outside the migration task, and the migration task depends on where it is captured.
5. The integrated commands include the integrated assertions.
6. Every row of the map has its observation at `integrated`; a group that another group depends on has the check of the promise it provides observed at `task` as well.
7. Every row whose `Verifier` is `implementer` is a replayable mechanical check that needs no second identity, no alternative observation and no measurement to interpret.
8. Every row's `Spec version` is the version step 1 printed.
9. No `Allowed scope` goes beyond what the scenarios the task group serves need, the files their checks need included.
10. No row's judging check is one that a failure of the baseline, already accepted as known-red, keeps red: the planner splits the mapping so that each row's check can pass on a correct implementation (`firefly-implement`, Preflight).
11. Every external side effect is declared in the task package, at the end of the step or the command line that has it, in the form `External effect: <effect>`: a push, a release or a data deletion for example, and what integration needs besides edits, a local commit, a merge of the task group into the target baseline or the creation of a child worktree.
12. Under a proposal-only mandate, the return lists the writes and the side effects the task groups need, as the task package declares them, and says whether a task group needs a child worktree, a local commit or a merge into the target baseline; those three are granted only by the request's words. The delivery mandate is recorded from the request's words plus what the task package declares (`firefly-implement`).
13. No field, command or row is left as a placeholder.

Before the handover, run `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" validate --root <project-root>`. The validator as shipped reads the spec package and not `tasks.md`: the task package is judged by the list above. A failure that names this change's `tasks.md` is repaired here and the command is rerun. A failure that names anything else is returned to the controller as it is: it is not this skill's to repair.

### List tasks (query entry)

1. Run `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" tasks [project_dir]`. Without `project_dir` it reads the current directory.
2. Report the output as printed: active, unarchived changes by creation time ascending, each with only its unfinished checklist items. A change with no unfinished item is not listed.

The listing reads the same `tasks.md` the planning entry wrote; there is no second ticket list to maintain. A ticked or an unticked item says nothing about the ready decision: whether a change may start is read only from `## Ready decision`, by the version comparison under "Handoffs".

## Outputs

- `openspec/changes/<id>/tasks.md`, written during the planning entry and complete before the package is handed to the controller: the task groups with every item the plan adds unticked, then `## Scenario map` with the three groups of commands and the map table.
- `## Ready decision` in the same file is not this skill's output. The controller writes it with `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" record ready --change <id> --spec <ver> --tasks <ver> --reviewer <name> --verdict <value>` when the joint decision is produced. `--spec` and `--tasks` carry what `firefly snapshot --spec <id>` and `firefly snapshot --tasks <id>` print.
- The query entry writes nothing.

## Handoffs

- **From `firefly-propose`.** The controller hands over a ready spec. A scenario's stable ID and decision source belong to the spec author; the map and the tasks belong to the planner.
- **To the joint decision, under `firefly-propose`.** The controller dispatches an independent reviewer who wrote neither package, under the identity `<id>@ready.<spec12>.<tasks12>`: the two package versions without their `wt:` prefix. The dispatch, its record and the storage of the return follow the contract's Recording section.
  - A return that arrives after a package changed records no ready decision for the changed package.
  - A reviewer that does not start, times out or returns an invalid response follows the infrastructure-failure rule of `firefly-review`.
  - A reviewer or an agent is named by one rule. A name begins with a letter or digit and holds letters, digits and `. _ : @ + -` only: it becomes part of a file name, and the recorder refuses any other character.
- **Inferred scenarios.** A scenario whose source is still `agent-inference` counts as unauthorized. Plan and map it like any other required scenario, so that the confirmation is the only thing missing: list those scenarios in the return for the requirement owner to confirm, and neither confirm them nor change their source.
- **Back from the joint decision.** A missing branch or mapping returns to planning: add it to the tasks and the map. The decided goal is not rewritten here. A changed promise goes to the spec author first, through the controller.
- **To `firefly-arch`.** A cycle that needs a contract goes through the controller. The contract task is cut only after the contract is written back into the spec.
- **To `firefly-implement`.** Only when both packages pass the joint decision and a ready decision is in force, and only under a mandate that continues into delivery. A delivery mandate is on record from the start of the change (`firefly-propose`), or is recorded when the user names `firefly implement <change>`, before anything is dispatched. The controller never records it from this skill's return on its own.
  - The newest row of `## Ready decision` is the ready decision in force only when its verdict is `ACCEPT` and both of its package versions equal what `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --spec <id>` and `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --tasks <id>` print now, the `wt:` prefix ignored (contract, Recording). Every other row is `historical`, and so is the newest row when a version differs, whatever verdict it carries.
  - A task-only edit is reviewed again on the tasks and the intersecting mappings; a changed promise is reviewed again with the spec and the affected tasks. Either edit changes a package version, so no start is read from an earlier row.

## Stop and escalate

Stop and return to the controller when:

- the spec is not ready (see "When not to use");
- a required scenario has no check that could observe it, so it cannot be mapped. This goes back to the spec;
- a cycle needs a contract (`firefly-arch`);
- a non-replayable migration has no pre-migration sample, or none can be captured. The migration task stays not ready;
- a task could be completed only by changing a promised behavior.

In the query entry, stop after reporting. When the listing fails or finds no `openspec/changes`, report that as it is; create nothing to make it succeed.

An `ESCALATE` carries three things: the current conclusion, the missing evidence or authority, and the responsible owner.

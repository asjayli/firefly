---
name: firefly-implement
description: Delivers one OpenSpec change that has passed its ready decision, run by the controller, who remains the only flow controller. Use when the user names firefly implement with a change id, when firefly-propose ends, under a mandate that continues into delivery, with the ready decision in force, when a valid REVISE sends the candidate back for repair, or when an implementation mandate in progress is resumed. The controller dispatches one implementer per task group from references/implementer-brief.md, fixes candidate snapshots, completes the designated observations, integrates the task groups and hands the integrated candidate to firefly-review. Not used to propose, to investigate a failure, to review without delivering, or to sync specs, archive, push, merge or release.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "07"
---

<!-- Evolved in part from the superpowers skills `executing-plans` and `subagent-driven-development` (MIT). -->

# firefly Implement

The controller runs this skill. Implementers and verifiers are dispatched from it; the independent reviewer judges the result under `firefly-review`. The shared rules are in `${CLAUDE_HOME:-$HOME/.claude}/firefly/references/handoff-contract.md`: they are referenced here and restated nowhere. The dispatch template is `references/implementer-brief.md`; its rules are part of this skill.

## When to use

- **Named.** The user names `firefly implement <change>`. That naming is the delivery mandate; the controller records it before anything is dispatched when the mandate in force is not one (`### Resolve and read`).
- **Entered from `firefly-propose`.** The joint review passed, the ready decision is in force and the mandate continues into delivery: neither the intake nor the joint review is repeated. After the resumption steps below, start at the first task group whose dependencies are satisfied.
- **Returned from `firefly-review`.** A valid `REVISE` sends the candidate back to `in-progress` for a repair round. A `RECHECK` returns one agreed check for a rerun on the unchanged candidate. A comparison return that states `ACCEPT`, for the incremental implementation of a module-wide simplification. A candidate that changed after its package was fixed comes back `in-progress`, for this skill to complete the designated verifiers' observations on its new snapshot: continue at `### Close the implementation`.
- **Re-entered after the spec version, the task package version or the standards changed under an `accepted` candidate.** The candidate itself did not change: its verdict is `historical`. Under a delivery this skill makes the designated verifiers' observations on it again first; `firefly-review` is entered after that. A task package change also ends the ready decision in force: the change first returns to `firefly-propose` for the review of the task package, and the observations are made once a ready decision is in force again. Continue at `### Close the implementation`.
- **Resumed.** An implementation mandate in progress is taken over, in a new session, by another agent or after context compaction, while its candidate is `in-progress` or `ready-to-integrate`.

## When not to use

Decide each from the records, never from the conversation:

- **No change is named** and no open mandate identifies one.
- **No mandate in force covers the delivery.** The mandate in force is proposal-only, or there is no mandate row, and the request does not name `firefly implement <change>`. `ESCALATE` (`## Stop and escalate`); nothing is dispatched.
- **The change is not an active, unarchived change with a `tasks.md`.** `openspec status --change "<change>" --json` does not resolve it, reports it archived, or its `changeRoot` has no `tasks.md`.
- **No ready decision is in force.** `## Ready decision` has no row, its newest row is not `ACCEPT`, or its two package versions differ from what `firefly snapshot --spec <change>` and `firefly snapshot --tasks <change>` print now. The change returns to `firefly-propose`; nothing is dispatched (`### Resolve and read`).
- **The request asks for another deliverable**: a proposal without implementation (`firefly-propose`), the cause of a failure (`firefly-debug`), a verdict on a candidate (`firefly-review`). A root cause returned by `firefly-debug` does not authorize implementation.
- **A repair scenario from `firefly-debug` has no ready decision.** It enters here only after the spec author wrote it into the spec, the planner built its minimal task group and the joint review passed.
- **The candidate is `pending-verdict`**, which belongs to `firefly-review`, or `accepted`, `rolling-out`, `live` or `archived`, which implementation does not resume, except for the observations a changed spec version, task package version or standard calls for on an `accepted` candidate (`## When to use`). What follows is commissioned separately through `firefly-archive`.
- **The request is spec sync, archive, push, merge or release.** None is an effect of this skill.

## Mandate

**Fixed end.** Every task group of the change is integrated on the target baseline (the line of work the change is built on), every observation the scenario map schedules has its row from the designated verifier on the integrated candidate, and the integrated candidate is `accepted`: a valid `ACCEPT` from every required role on its fixed review package. Any other end is a return to `firefly-propose` under `## Stop and escalate`, an `ESCALATE` boundary or an explicit stop by the user.

**Permitted effects.**

- Edit inside each task group's allowed modification scope, through dispatched implementers.
- Run the baseline, targeted and integrated commands the scenario map names.
- Write the task record's checklist, the `Preflight` section (the task group baselines under it), the repair budget rows, observation rows, evidence and the review package, each to its carrier. In the review phase, write the dispatch and verdict rows.
- The write-back of a `firefly-debug` return to the task record, made by `firefly-debug` in its handoff: the only permitted effect here that changes the task package version, and never on a task item line.
- Record the requester's decision on an existing failure of the baseline as a minutes entry under `openspec/think/`, the words verbatim (contract, Mandate record and Carriers).
- Record the delivery mandate, through `firefly record mandate`, as the newest row with a new id and before anything is dispatched: when the user names `firefly implement <change>` and the mandate in force is not a delivery mandate, and whenever the permitted effects of the mandate in force differ from the delivery effects (step 2 under `### Resolve and read`).
- Create a child worktree for a parallel task group, when the request names it.
- Create a local checkpoint commit, or merge a task group's candidate into the target baseline, only when the mandate's permitted effects explicitly allow that write and the branch policy permits it. Otherwise no commit is made and no merge is performed: the candidate stays uncommitted and is located by its snapshot, and a task group that is `ready-to-integrate` only in a child worktree stays there until the authority is given.

**Not granted.**

- Spec sync, archive, push, merge, release, and a destructive removal. Naming this skill authorizes none of them. A merge of task groups into the target baseline happens only under the condition above; each of the others needs the request to name it.
- A wider scope, a wider mandate, or a change to a promised behavior.
- A verdict on the candidate: it belongs to the independent reviewer.
- A note on a task item in `tasks.md`. A blocker travels in the `ESCALATE` and in the dispatch and budget rows of the progress record.
- Cleaning the worktree, or writing over changes, committed or not, that match no recorded candidate snapshot.

## Inputs

- The change id, from the request or from the open mandate. `openspec status --change "<change>" --json` resolves its `changeRoot`.
- `openspec/changes/<id>/proposal.md`, section `## Mandate`: mandate id, objective, permitted effects, terminal condition, and the `Minutes: <path>` line below the table.
- `openspec/changes/<id>/tasks.md`: the task groups (`## N. <Group>` with its scenarios, spec path, dependencies and allowed scope), `## Scenario map` (the baseline, targeted and integrated commands, and for each scenario × check or branch its task group, verifier, expected outcome, time and candidate), and `## Ready decision`.
- `openspec/changes/<id>/specs/**/spec.md`: the scenarios with their stable IDs and decision sources.
- For a mandate in progress: `openspec/changes/<id>/verification.md`, the progress record `.superpowers/sdd/progress.md` (`Preflight`, `## Repair budget`, review package, dispatch and verdict rows), and Git.
- The runtime: `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly"` with `snapshot` (the candidate, `--spec <change>` and `--tasks <change>`) and `record`, `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/task-brief"`, `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/review-package"`, and `openspec`.

## Procedure

### Resolve and read

1. Run `openspec status --change "<change>" --json` and take `changeRoot` as the change directory. A change that is not found, is archived or has no `tasks.md` is not entered.
2. Read the mandate, the task groups, the scenario map and the ready decision. The mandate in force is the newest row of `## Mandate` (contract, Mandate record).
   - **What a delivery mandate is.** Its terminal condition is the `accepted` candidate, and its permitted effects are the delivery effects below. A proposal-only mandate, whose terminal condition is a change ready to start, is not one.
   - **The delivery effects** are the same whoever records the mandate and whenever it is recorded: what the request's words grant; the modification scopes the task package declares for its task groups, written out group by group in the row; the external side effects it declares that `## Mandate` does not withhold; the write-back of a `firefly-debug` return to the task record; and the record writes of `## Mandate`. Spec sync, archive, push, merge, release, a destructive removal, a child worktree, a local checkpoint commit and a merge into the target baseline are among them only when the request names them.
   - **Recording it.** When the user names `firefly implement <change>` and the mandate in force is not a delivery mandate, the controller records it as the newest row before anything is dispatched: `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" record mandate --change <id> --id <id> --objective <objective> --effects <the delivery effects, and what the request's words add> --terminal <terminal condition>`. The objective is the delivery of the change and the terminal condition is its fixed end. The id is `<change>-delivery` when no row carries it yet, otherwise `<change>-delivery-<n>` with the next free number.
   - **Keeping it current.** A row is read as it is written, never as a reference to the task package. A row recorded before the task package existed names no task group: once the task package is on record, the controller brings it up to date directly, with no confirmation, as a new row that writes the modification scopes out group by group as the task package stands at its ready decision. From then on a task group the planner adds, a scope wider than the row names, or an external side effect the row does not name is not covered until the requirement owner has confirmed it under `firefly-propose`; then a new row records it. An effect the requester adds later, a commit or a merge for example, is recorded the same way. Each such row takes the id `<change>-delivery-<n>`, `<n>` being the next free number, and nothing is dispatched before the mandate in force covers the delivery. A naming that changes none of it continues the mandate in force and writes no row, with one exception: a renewed request for the implementation after a comparison ended in `REVISE` is recorded as a new row with the next id, because that row is what tells the review to compare again rather than return the stored outcome (`firefly-review`, Step 2).
   - **Nothing is dispatched** before the mandate in force covers the delivery. Work with no mandate row on record has no established authority (`ESCALATE` to the requirement owner). A request that is ambiguous about the delivery, or that leaves a proposal-only mandate in force, is `ESCALATE`d to the requester.
3. **Check that the ready decision is in force.** This holds at every entry, resumption included. The newest row of `## Ready decision` is the current ready decision. It is valid only when its verdict is `ACCEPT` and its two package versions equal what `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot --spec <change>` and `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot --tasks <change>` print now. Versions are compared without the `wt:` prefix, here and in every later comparison (contract, Carriers). Every other row is `historical`, and so is the newest row when a version differs. Without a valid ready decision nothing is dispatched; the change returns to `firefly-propose`.

### Resume: three things first

At every start on a mandate in progress, before any dispatch:

1. **The open mandate, by its id.** The same intent raised again continues the mandate already open for it. A second flow is never opened beside it. A resumption is read in this order: a request that names `firefly implement <change>` goes by step 2 under `### Resolve and read`, the delivery mandate recorded first when the mandate in force is not one; a request that names no such thing leaves the decision to the records, and when the mandate in force does not cover the delivery it is `ESCALATE`d and nothing is dispatched, to the requester when the mandate in force is proposal-only and to the requirement owner when there is no mandate row (`## Stop and escalate`).
2. **Open items, before any other content.** Read the pending items of the task record, the progress record, the verification record and the archive record: a pipeline result that arrived outside the session, a removal result not yet returned, an observation window still running. A failed result found in the verification record returns to the implementer as a failing scenario when its candidate is the candidate in force; a failed row on an earlier snapshot that documents the expected red of a test written before its implementation is a deviation record and starts no repair round. Items that belong to another mandate are left where they are and named in the report.
3. **The worktree against the recorded candidate.** Run `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot` and compare it with the candidate the records name: the Candidate of the observation rows, the snapshot in the review package identity, the `Preflight` worktree snapshot, the commits. The comparison is about the implementation: nothing under `openspec/changes/` or `openspec/think/` is in the snapshot (contract, What the candidate is). A difference in the spec, the tasks or the records is not judged here; the spec version and the task package version judge it. A difference in the implementation, committed or not, that matches no recorded candidate snapshot: keep the changes as user work, write nothing on top of them, confirm with the user before continuing, and never clean the worktree.

Then continue from what the carriers prove. `firefly-context` rebuilds the state; this skill acts on it:

- A task group whose checks passed only in its child worktree is `ready-to-integrate`. Locate its candidate snapshot from the task record, Git and the progress record and continue with the integration step under `### One task group, in order`. Do not dispatch the task group again or repeat its implementation.
- A task group whose checks passed on the target baseline and whose items are still unticked is integrated: tick those items and do not dispatch the task group again. One that gained an unticked item after its items were ticked is not integrated any more: the new items go through dispatch, verification and integration like a task group of their own, and the ticked items stay as they are (`### Ticks and the task record`).
- When the baseline moved after those checks ran, the candidate returns to `in-progress` until the affected behavior is re-verified (contract, candidate states).
- An integrated task group without the row of an observation the scenario map schedules at `integrated` for a promise a task group not yet integrated depends on: the designated verifier makes it now on the target baseline, as step 6 under `### One task group, in order` says, before that task group is selected. The integrated task group is not dispatched again. This is the case when the integration was interrupted before the row was written, and when a dependency was added after the integration.
- A `firefly-debug` return was written back to the task record and a ready decision is in force again: a task group the planner added for the repair is dispatched first, like any other, and the repair round for its scenario follows once it is integrated (step 1 under `### Repair rounds and the repair budget`); without such a task group the repair round is dispatched first.
- When the records disagree, decide from the actual diff and the verification evidence. Work is never replayed blindly and no second state store is kept.

### Preflight

Once, before the first candidate file is modified, run the baseline commands the scenario map names and write a `Preflight` section to the progress record `.superpowers/sdd/progress.md` with:

- **Baseline commit**: `HEAD`.
- **Worktree snapshot**: what `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot` prints before any edit.
- **Commands and Exit**: each baseline command and its exit code.
- **Classification**: `clean`, `in-scope-red`, `user-worktree-red` or `unrelated-red`; none of them when a baseline command cannot run at all (the last row of the table below).
- **Evidence**: the path of each saved output, or a summary.

The same baseline is recognized by the three facts the section holds: its Baseline commit, its Worktree snapshot and the baseline commands it ran with their results. On resumption, do not rerun the preflight when the progress record, Git and `tasks.md` together prove that the same baseline already completed it. A baseline that moved is run again.

The `Preflight` section's baseline is the BASE of the change: its Baseline commit when its Worktree snapshot is the tree of that commit, otherwise its Worktree snapshot. It is never `HEAD~1` and never the commit before the last task group.

Sort every existing failure before editing. An extra repair is never mixed into a task group:

| Classification | The existing failure | What follows |
|---|---|---|
| `clean` | None. Every baseline command gives the result the scenario map expects. | Continue. |
| `in-scope-red` | One this change exists to fix. | Record it and continue. Its fix is the change's own task group, not an extra repair. |
| `user-worktree-red` | Caused by uncommitted user modifications. | Keep the modifications as user work and write nothing until the user decides. |
| `unrelated-red` | A baseline command ran and exited red on something the change does not fix: an environment fault (a service, fixture or dependency the command needs is broken), or a problem the mandate does not authorize fixing. | Never repair it inside a task group. `ESCALATE` for the requester's choice among stopping, widening the scope under its own authorization, and accepting the baseline as known-red (`## Stop and escalate`). |
| no classification | A baseline command cannot run at all: it is missing, or a tool or capability it needs is unavailable. | Diagnose, then `ESCALATE`. |

A baseline accepted as known-red needs that explicit authorization and stays visible in the final report. It is never presented as passing. When the requester accepts it, the controller records the requester's words as a minutes entry under `openspec/think/`, as the contract's `Minutes:` rule says: into the file the `Minutes:` line names when that is a minutes file there, otherwise into a new file there. A file the user named is never edited. The controller then notes the acceptance beside that baseline command in the `Preflight` section: `accepted as known-red, minutes <path>`, with the path of that entry. The classification stays `unrelated-red`. When the accepted red is on a check the scenario map schedules for a required scenario, the change returns to `firefly-propose` for the planner to split the mapping, so that the scenario's judging check no longer includes the known red; implementation continues once a ready decision is in force again.

### One task group, in order

The default is one task group at a time: select it, record its baseline, implement, verify, integrate.

1. **Select.** The first task group that is not integrated, whose dependencies are satisfied and whose dispatch package is complete (the four things under **Dispatch**). A task group is integrated once its checks pass on the target baseline, whether or not it is ticked yet, until it gains an unticked item (`### Ticks and the task record`); a check recorded as an existing failure the change does not fix does not keep a task group from being integrated. Only such a task group satisfies a dependency, and only once the observation of its promise scheduled at `integrated` has its row (step 6 under `### One task group, in order`, or the matching item of `### Resume`); one that passes only in a child worktree satisfies nothing. Only the controller unblocks dependents, on the integrated result. A dependency or a cycle is never cleared by ticking an item.
2. **Record the baseline.** Run `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot`: the tree this task group starts from. For the first task group it is the preflight baseline. Write `<N>: <sha>` under the `Preflight` section of the progress record of the target baseline, before the dispatch; it is never written into `tasks.md`.
3. **Dispatch.** Build the brief with `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/task-brief" <changeRoot>/tasks.md <N>` and fill `references/implementer-brief.md`. The brief file is the single source of requirements: exact values are not restated in the dispatch. The dispatch package carries four things: scenario IDs, spec and source pointers, the allowed modification scope, and the acceptance commands. When one is missing from both the brief file and the scenario map, dispatch nothing and return the gap to planning under `firefly-propose`. A dispatch describes one task group, never the session's history. Its context block names every failure the `Preflight` section recorded, the task group, if any, that fixes it, and the checks to keep passing: the checks of the required scenarios whose observation rows show `pass` on the candidate the dispatch starts from, rerun by a repair round (step 2 under `### Repair rounds and the repair budget`).
4. **Collect.** The implementer returns its candidate snapshot, the checks it actually ran, their results and its deviations. It fixes the candidate with `firefly snapshot` before it produces the first evidence. On return, run `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot` again, in the worktree the implementer worked in: a worktree that differs from the snapshot the implementer reported is a new candidate, and it is fixed again before any further evidence.
5. **Verify.** Make the observations the scenario map schedules before integration: the named verifier runs the named check against the expected outcome on the task candidate. When the verifier is not the implementer, dispatch one who did not implement the candidate. The row is written with `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" record observe`. The recorder fills in the candidate snapshot and the spec version from the worktree it runs in, so the row is written before the next edit. `pass` and `fail` need `--evidence` naming an existing path; the verifier puts it under `openspec/changes/<id>/evidence/<snapshot12>/`. The implementer's own runs document deviations; they never replace the designated verifier's row. A `fail` starts the repair rounds below. A check recorded as an existing failure the change does not fix is the exception: it starts no repair round while it shows the result the `Preflight` section recorded. It is recorded as the run shows, never `pass` because the baseline was accepted as known-red: a run that passes is recorded `pass`, and the final report says that the accepted baseline failure no longer shows.
6. **Integrate.** Bring the verified candidate into the target baseline, under the commit and merge condition in `## Mandate`. Then rerun the scenarios the task group shares with task groups already integrated, and make now the observations the scenario map schedules at `integrated` for a promise a downstream task group depends on: the designated verifier observes each on the target baseline and the row is written with `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" record observe`. A downstream task group becomes selectable only once those rows exist; the completion of step 3 under `### Close the implementation` is the fallback for the rows no remaining task group waits for. Its checks passing on the target baseline makes the task group integrated, a check recorded as an existing failure the change does not fix not keeping it from that, and the controller ticks the items of a task group at once, as soon as that group is integrated on the target baseline (`### Ticks and the task record`). Then select the next ready task group (step 1).

Handle the status the implementer returned:

- `DONE`: go on to verification.
- `DONE_WITH_CONCERNS`: read the concerns first. One about correctness or scope is settled, by a repair round or by a dispatch with the missing context, before the task group counts as verified. One that is an observation is carried into the final report's deviations and work continues.
- `NEEDS_CONTEXT`: supply the missing context and dispatch again.
- `BLOCKED`: read the blocker. Missing context: supply it and dispatch again. A failing scenario: the repair rounds. A conflict the supplied evidence cannot settle, or a repair that must change a promised behavior: `## Stop and escalate`.

The same task group is never dispatched again with nothing changed.

### Ticks and the task record

- **Tick at integration.** The controller ticks the items of a task group at once, as soon as that group is integrated on the target baseline. A task group that passes only in a child worktree stays unticked. A tick, like the row `firefly record ready` appends, is not part of the candidate snapshot: the snapshot holds the implementation alone and leaves out everything under `openspec/changes/` (contract, What the candidate is).
- **New items in a ticked task group.** Under a repair entry the planner may add unticked items to a task group whose items are already ticked. Only the items integrated on the target baseline are ticked, so the new ones stay unticked: their behavior is not integrated, and the task group is not integrated any more. The new items go through dispatch, verification and integration like a task group of their own; the items already ticked stay as they are.
- **Nothing but a tick is written into a task item.** A blocked task group keeps its items unchecked and their lines untouched: a note on an item changes the task package version, and the ready decision in force no longer holds. The blocker travels in the `ESCALATE` and the dispatch and budget rows.

### Parallel dispatch

Dispatch task groups in parallel, each in its own child worktree, only when all three hold:

- more than one task group is ready;
- the interface of each is a contract `firefly-arch` settled, written back into the spec;
- the behavior is still verifiable once the candidates are merged: the scenario map names the check that holds only when the merged candidates are together.

Parallel work also needs three things: that the request names the child worktrees; that the mandate's permitted effects cover what integration takes, a commit and a merge of each child worktree's candidate into the target baseline, or the branch policy's equivalent; and that the branch policy permits that write. Without all three the task groups run one at a time.

Editing different files is not a condition.

In parallel, a task group whose checks pass in its child worktree is `ready-to-integrate`: it is a candidate for integration, not a completed task, and nothing that depends on it starts. After each merge, rerun the intersecting scenarios. Green results from separate branches are never assembled into an integration pass: the verdict is asked for on the integrated candidate.

`firefly record` is rooted in the working tree it runs in. Observation rows and evidence produced in a child worktree are written in that child worktree: read them there before integration. At integration the controller appends to the `verification.md` of the target baseline the observation rows the merge has not already brought in, whole rows copied with no field altered, and copies the evidence files as they are into the evidence directory; the Candidate column keeps the snapshot the child worktree had. Moving existing rows is not hand-writing them. After integration, read them in the target baseline. The repair budget is recorded from the worktree of the target baseline, so that the mandate has one budget.

### Repair rounds and the repair budget

A failing scenario, a `fail` on a mapped check or a valid `REVISE` from `firefly-review`, returns to the implementer by default. A check recorded as an existing failure the change does not fix never does: the exception under step 5 of `### One task group, in order` holds here too. A finding that a baseline accepted as known-red still shows is never repaired: a `REVISE` that carries nothing else is `ESCALATE`d to the requester with the package identity, because the fixed end is out of reach until the mapping is split (`## Stop and escalate`), and one that carries other findings is repaired for those only. The controller keeps the repair budget of the mandate in the progress record. A worker never keeps it.

1. **Repair here** when the failure reproduces reliably and the check tells a correct implementation from a wrong one. One round is one change for that one scenario and a rerun of its original check, dispatched with the repair block of `references/implementer-brief.md`. The dispatch names the checks to keep passing: the checks of the required scenarios that passed on the candidate before the change. The findings of a `REVISE` are read from the reviewer's stored return beside the package, `verdict-<role>-<reviewer>.md` (contract, Recording).
2. **Record the round when it is produced**, as soon as the rerun of the original check, and of the checks to keep passing unless the symptom is unchanged, has a result, and before anything else is dispatched: `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" record budget --change <id> --round <n> --scenario <id> --progress <yes|no> --implementer <name> --note <text>`.
   - `<n>` is the next number in the change's `## Repair budget` rows. It never restarts.
   - `--progress yes` only when that scenario shows a checkable improvement and no required scenario that was passing broke: every check to keep passing passed again. A round whose passing required scenarios were not rerun is not recorded `yes`. Anything else is `no`.
   - `--note` names the trigger (the failing check with its candidate snapshot, or the package identity of the `REVISE`), what changed, and what the rerun showed against the expected result.
   - `--implementer` names the implementer who made the round. A name given to an implementer or a verifier begins with a letter or digit and holds letters, digits and `. _ : @ + -` only: the recorder refuses any other character.
3. **On progress**, the result is a new candidate. Fix its snapshot, verify and continue.
4. **Hand to `firefly-debug` instead of another round** when the failure does not reproduce reliably, when competing explanations predict the same symptom and no existing check separates them, or when one round left the symptom unchanged. In the last case stop stacking edits on it; the round stays recorded with `--progress no`. What `firefly-debug` returns, a discriminating signal or a root cause with the trigger input and the expected result, is written back to the task record by `firefly-debug` in its handoff, never on a task item. That write changes the task package version: the ready decision in force becomes `historical`, and the change returns to `firefly-propose` for the review of the task package alone, its intersecting mappings included; a new task it needs is a minimal task group built by the planner there. From that write until a ready decision is in force again, no repair round and nothing else is dispatched here. Once a ready decision is in force again, a task group the planner added for the repair is integrated first and the repair is then dispatched here as a new round, and then verified and independently reviewed as a new candidate.
5. **Stop automatic repair** at three consecutive rounds with `--progress no`, or when three distinct candidate packages of the delivery have each received a valid `REVISE` from a fresh independent review and none an `ACCEPT`: a further `REVISE` is not repaired. The count is of the distinct package identities that carry a `REVISE` row in `## Review verdicts`, not of rows and not of budget rows: several roles returning `REVISE` on one package make one, and a joint review's `REVISE` is not among them. Deliver the candidate with its snapshot and state, the failure history and the open decisions.

A change of implementer, a change of candidate or a resumed session never resets the budget.

Example: an intermittent empty download. The first round leaves the symptom unchanged. Record it with `--progress no`, make no further edit, and hand the scenario to `firefly-debug`.

Not repair rounds:

- A reviewer that does not start, times out or returns an invalid verdict. It is an infrastructure failure handled under `firefly-review`: the controller records it with `firefly record dispatch` and `--status failed`. No budget row is written and no product code is changed for it.
- A `REVISE` recorded for a joint review, `<change>@ready.<spec12>.<tasks12>`. It is the joint review's verdict on the spec package or the task package. It is handled under `firefly-propose` and consumes no repair round.
- `RECHECK` and `INSUFFICIENT_EVIDENCE` (contract, Verdicts and reservations).

Two rules hold throughout:

- **Uncertain external effect.** When it is unclear whether an effect of an earlier dispatch took place, establish what actually took effect, from Git, `firefly snapshot` and the records, before the work is sent again. Never resend blindly.
- **Reruns.** A rerun writes its result to a new evidence location and never overwrites an earlier candidate's evidence.

### Close the implementation

When no task group remains:

1. **Fix the integrated candidate.** Run `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot` before any evidence is produced on it. `<snapshot12>` is the first 12 characters of what it prints.
2. **Check the diff.** Run `git diff --check` against the change's BASE (`git diff --check <BASE>`). A non-zero exit goes back to the implementer; the result is a new candidate, and step 1 runs again.
3. **Complete the observations.** Before `firefly-review` is entered, every observation the scenario map schedules and the designated verifiers have not yet made is made now, on the integrated candidate: every row scheduled after integration, and every earlier row whose observation on the candidate of step 1 is missing, those made on an earlier candidate included. On the entry after the spec version, the task package version or the standards changed under an `accepted` candidate, the lapsed observations are made again on the integrated candidate: all of them when the spec version or the standards changed, and the checks whose scenario map row changed when only the task package did (contract, Lapse). A check that was skipped, cancelled or left without a result is recorded `unverified`, never `pass` (contract, Observation record). Nothing is filled in afterwards as tested. An observation that cannot be made under the existing authority, tools or environment is `ESCALATE`d, not invented. A check recorded as an existing failure the change does not fix starts no repair round while it shows the result the `Preflight` section recorded; it is recorded as the run shows, never `pass` because the baseline was accepted as known-red.
4. **Write the first review package.** Run `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot` once more: it must still print the candidate of step 1. From the repository root, create the package directory, and its parent when absent, then run `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/review-package" <BASE> WORKTREE openspec/changes/<id>/evidence/<snapshot12>/1/package.diff`. Use `HEAD` in place of the `WORKTREE` only when BASE is a commit and the implementation is fully committed: nothing outside `openspec/changes/` and `openspec/think/` differs between the worktree and `HEAD`, untracked files included. Otherwise use the `WORKTREE` form. The identity of this first package is `<change>@<snapshot12>.1`. A snapshot that already has a package is not packaged here: it goes to `firefly-review`, which decides the generation.
5. **Enter `firefly-review`** with that identity. The candidate is `pending-verdict`.

A candidate's packages live in `openspec/changes/<id>/evidence/<snapshot12>/<generation>/package.diff`, from generation 1. This skill writes only the first package of a candidate. The package identity, its generations and the rules for rebuilding a package are in `firefly-review`.

Writing a record never changes the candidate snapshot: the snapshot holds the implementation alone and leaves out everything under `openspec/changes/` and `openspec/think/` (contract, What the candidate is). An edit to the implementation after step 1 makes a new candidate: go back to step 1. A spec edit is not a new candidate: it gives a new spec version, and the package is rebuilt under `firefly-review`.

The verdicts return here:

- `ACCEPT`: the candidate is `accepted` and the mandate has reached its fixed end.
- `REVISE`: the candidate returns to `in-progress`. Run the repair rounds, except for a finding that a baseline accepted as known-red still shows: such a finding is never repaired, and a `REVISE` that carries nothing else is `ESCALATE`d to the requester (`### Repair rounds and the repair budget`). The repaired candidate is a new candidate: it is verified and reviewed again on its own first package.
- `RECHECK`: the designated verifier reruns the agreed check once on the current, unchanged candidate and writes the result to a new evidence location. No repair round is consumed. The new evidence goes back to `firefly-review`, which rebuilds the package under its own rules.
- `INSUFFICIENT_EVIDENCE`, and a reviewer that failed to start, timed out or returned an invalid verdict, are handled under `firefly-review` and consume no repair round.

### Continuous execution

- Implementation runs continuously by default. A completed task group, a passed verification, a merge, a progress report or an ordinary recoverable failure never ends the run and never waits for feedback.
- Warnings, ordinary tool failures and a first failing check are diagnostic inputs, not requests for a decision.
- A progress report names the task group in flight, the candidate state and the next gate. It is not completion.
- Never use completion language or a final delivery format while any task group is unchecked or in progress, or while the verdict of the integrated candidate is outstanding.
- Only the fixed end, a return to `firefly-propose` under `## Stop and escalate`, an `ESCALATE` boundary or an explicit stop by the user ends the run of this skill.

## Outputs

| Fact | Carrier | Written |
|---|---|---|
| Delivery mandate | `openspec/changes/<id>/proposal.md`, `## Mandate`, through `firefly record mandate` | when the user names `firefly implement <change>` and the mandate in force is not a delivery mandate, and whenever the permitted effects of the mandate in force differ from the delivery effects: as the newest row, with a new id, before anything is dispatched |
| Task completion | `openspec/changes/<id>/tasks.md`: `- [ ]` turned to `- [x]` | when a task group is integrated on the target baseline; not part of the candidate snapshot |
| Preflight | `Preflight` section of `.superpowers/sdd/progress.md` | once, before the first candidate file is modified |
| A baseline failure accepted as known-red | the requester's words as a minutes entry under `openspec/think/`: the file the `Minutes:` line names when that is a minutes file there, otherwise a new file there; `accepted as known-red, minutes <path>` beside that baseline command in the `Preflight` section | when the requester accepts the baseline as known-red; the classification stays `unrelated-red` |
| Task group baseline | `<N>: <sha>` under the `Preflight` section of `.superpowers/sdd/progress.md`, in the worktree of the target baseline | before each task group is dispatched; never written into `tasks.md` |
| Candidate snapshot | Git tree object of the implementation, printed by `firefly snapshot` | before the first evidence of every candidate; cited, never typed |
| Observations | `openspec/changes/<id>/verification.md`, through `firefly record observe` | when each observation is made |
| Evidence | `openspec/changes/<id>/evidence/<snapshot12>/` | with each observation; a rerun gets a new location |
| Repair budget | `## Repair budget` of the progress record, through `firefly record budget` | when each round is produced |
| Review package | `openspec/changes/<id>/evidence/<snapshot12>/<generation>/package.diff`; the first package of a candidate is generation 1, `<change>@<snapshot12>.1` | after the last observation on the integrated candidate, before the review |
| Review dispatches and verdicts | `## Review dispatches` and `## Review verdicts` of the progress record, through `firefly record dispatch` and `firefly record verdict` | in the review phase, as each happens |
| Final report | the reply to the requester | at the fixed end or at `ESCALATE` |

An implementer's report file under `.superpowers/sdd/` is short-lived working material, not a carrier.

The final report names the change, the candidate's snapshot and state, the package identity and where the evidence is, every deviation, every baseline failure accepted as known-red and whether it still shows, and what may be commissioned separately. It states that spec sync, archive, push, merge and release were not done, apart from a merge of task groups into the target baseline that the mandate allowed.

## Handoffs

- **From `firefly-propose`.** A change whose ready decision is in force, under a mandate that continues into delivery.
- **From `firefly-context`.** A rebuilt state whose candidate is `in-progress` or `ready-to-integrate`: the resumption steps above run on it.
- **From `firefly-review`.** After a `REVISE`, the findings and the affected scenarios, for repair; the text of a finding is its stored return beside the package. After a `RECHECK`, the agreed check, for one rerun on the current candidate. After a candidate changed once its package was fixed, the new candidate `in-progress`, for this skill to complete the designated verifiers' observations on its snapshot. For a module-wide simplification, only when the mandate is itself one: read the mandate record, and the simplification of a named module is the objective of the mandate, not a consequence of another deliverable. Then `firefly-review` hands over its equivalence comparison, which outputs must stay equal and which must stay different, with the module, its consumers and the invariants to keep, and this skill implements it incrementally. Only a comparison whose return states `ACCEPT` is implemented: a `REVISE` goes back to the requester and `INSUFFICIENT_EVIDENCE` escalates, under `firefly-review`. Before implementing, run `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot`: the return names the snapshot it compared, and the work starts only while that is still the candidate present; otherwise the comparison is `historical` and is made again. Under any other mandate, a simplification that would rewrite a whole module is a separate proposal through `firefly-propose`, and nothing of it is implemented here.
- **To an implementer.** One dispatch per task group or repair round, from `references/implementer-brief.md`.
- **To a verifier.** The scenario map rows assigned to it, observed on the candidate snapshot they name. The dispatch carries, for each row, the scenario ID, the check with its command and the expected outcome, and the supporting material the check reads (the UI state list of `firefly-ui`, the constraint entry beside the scenario); the record command, `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" record observe` with `--observer verifier:<name>` and a `--note` that carries the conditions observed under, the expected outcome and the check the scenario map row names, under the shared rules in `${CLAUDE_HOME:-$HOME/.claude}/firefly/references/handoff-contract.md`; the evidence location, `openspec/changes/<id>/evidence/<snapshot12>/`, a new file for each run; and the name rule of step 2 under `### Repair rounds and the repair budget`. The verifier writes its own row.
- **To `firefly-review`, before any task group is dispatched.** When the mandate is itself a module-wide simplification and the ledger shows no comparison package for the candidate present whose outcome is `ACCEPT` (a `REVISE` that stands decides otherwise, and a return recorded `failed` counts for nothing): the named module, its consumers and its invariants, for the equivalence comparison. Nothing is implemented until that return comes back.
- **To `firefly-review`.** The identity of the first package, `<change>@<snapshot12>.1`, the path of the package file, BASE, and pointers to the carriers: the mandate record, the spec, the scenario map, the observation record and the evidence directory. After a repair, the paths of the previous candidate's stored returns that carry the `REVISE`, for the first package of the repaired candidate to hand their findings to the fresh independent reviewers one by one. A returned verdict changes nothing until the controller acts on it here. This skill writes a package only there, after the integrated candidate is fixed. When the user names `firefly review` directly, that skill fixes the package itself.
- **To `firefly-debug`.** A failure that meets a switch condition under `### Repair rounds and the repair budget`, with the failing scenario, the trigger input, the candidate snapshot and the evidence. The original terminal condition and permitted effects travel with it, that write-back among them. It returns a root cause, discriminating evidence, trigger input and expected result, written back to the task record in its handoff and never on a task item.
- **To the requirement owner, then the spec author.** A repair that must change a promised behavior.
- **Back to planning, under `firefly-propose`.** A task group whose dispatch package lacks one of the four things; one that could be completed only by changing a promised behavior, after the requirement owner confirmed that change under `## Stop and escalate`; or a `firefly-debug` return whose trigger input, expected result and root cause were written to the task record, for the review of the task package alone; or a baseline accepted as known-red on a check the scenario map schedules for a required scenario, for the planner to split the mapping; or a task group the planner added, a scope wider than the delivery mandate row names, or an external side effect the row does not name, for the requirement owner to confirm; once it is confirmed, the controller records the confirmed scope as a new mandate row (step 2) and dispatches from there. The decided goal is not rewritten on the way.
- **After `ACCEPT`.** What may follow is commissioned separately: `firefly-pr` for the pull request, `firefly-docs` for spec sync and decision records, `firefly-archive` for readiness, archive and release.

## Stop and escalate

**Stop and return to `firefly-propose`**, dispatching nothing, when no ready decision is in force (no row, a newest row that is not `ACCEPT`, or package versions that differ from the current ones, the task package changed by a written-back `firefly-debug` return included), or when a task group's dispatch package lacks one of its four things, or when a baseline accepted as known-red is on a check the scenario map schedules for a required scenario, for the planner to split the mapping, or when a task group the planner added, a wider scope or an external side effect is not covered by the delivery mandate row, for the requirement owner to confirm it. This is a handoff, not an end of the session: the work continues under `firefly-propose` with its own terminal condition, and it brings no new write authority.

**Stop and return `ESCALATE`**, carrying the current conclusion, the missing evidence or authority, and the responsible owner, when:

- **The change cannot be resolved.** No change is named and no open mandate identifies one, or the named change is not active and unarchived with a `tasks.md`. A change is never picked from conversation context. The missing item is the change id. Owner: the requester.
- **No mandate row is on record** while a task record, a candidate or evidence of the work exists. Owner: requirement owner.
- **No mandate in force covers the delivery.** The request is ambiguous about whether delivery is asked for, or the mandate in force is proposal-only and no request names `firefly implement <change>`. A change with no mandate row at all is the case above. The `ESCALATE` carries the current conclusion (which mandate is in force and what its terminal condition and permitted effects cover), the missing authority (the delivery mandate), and the owner, the requester. Nothing is dispatched.
- **Preflight, `unrelated-red`.** The failure is never repaired inside a task group. The `ESCALATE` carries three things: the current conclusion (which baseline command exited red, what it showed against the expected result, and the diagnosis, an environment fault or a problem the mandate does not authorize fixing); the missing evidence or authority (the capability or service the environment lacks, or the authority to widen the scope); and the owner, the requester. When the red is on a check the scenario map schedules for a required scenario, the `ESCALATE` says so: that scenario stays `fail` and the fixed end is out of reach until the planner splits the mapping so that the scenario's judging check no longer includes the known red, which is work for `firefly-propose`. The requester then chooses among:
  - stopping here;
  - widening the scope under its own authorization, so that the fix becomes a task group through `firefly-propose`;
  - accepting the baseline as known-red, an explicit authorization that stays visible in the final report and is never presented as passing.
- **A `REVISE` finds nothing but a baseline accepted as known-red still showing.** No repair round is run for it. The `ESCALATE` carries the current conclusion (the package identity, with the stored returns beside it, and the check the scenario map schedules for the required scenario), why the fixed end is out of reach (that judging check still includes the known red, until the planner splits the mapping through `firefly-propose`), and the owner, the requester.
- **Preflight, `user-worktree-red`.** The modifications are kept as user work and nothing is written until the user decides. The `ESCALATE` carries the current conclusion (which baseline command exits red and which uncommitted modifications cause it), the missing authority (the user's decision on those modifications), and the owner (the user who made them).
- **Preflight, a baseline command that cannot run.** It is missing, or a tool or capability it needs is unavailable. Diagnose first. The `ESCALATE` carries the diagnosis as the current conclusion, the missing capability, and the owner of that capability.
- **A task group is `ready-to-integrate` only in its child worktree and the integration is not permitted.** It stays there and nothing is merged. The `ESCALATE` carries the current conclusion (the task group and its candidate snapshot), the missing authority (a commit and a merge into the target baseline, or the branch policy's equivalent, with the branch policy permitting that write), and the owner, the requester.
- **The worktree holds changes, committed or not, that match no recorded candidate snapshot.** They are kept as user work and confirmed before anything continues. Owner: the user who made them.
- **An observation the scenario map requires cannot be made** under the existing authority, tools or environment. Nothing is filled in as tested. Owner: the requirement owner, for the authority; the owner of the missing tool or environment, for the capability.
- **The repair budget is spent.** Three consecutive rounds with `--progress no`, or three distinct candidate packages with a `REVISE` row in `## Review verdicts`, each from a fresh independent review, with no `ACCEPT`. The `ESCALATE` carries the current conclusion (the candidate with its snapshot and state, and the scenario still failing, with the failure history), what is missing (the open decisions), and the owner, the requirement owner, for each open decision. The candidate stays in its current state.
- **A repair must change a promised behavior.** Implementation stops. The requirement owner confirms; the spec author then revises the scenario. The scope is never widened by reading the change as a technical detail, and acceptance is never redefined here. Owner: requirement owner.
- **A plan conflict or a missing authorization** that the brief, the supplied context and the repository evidence cannot settle. Owner: requirement owner.
- **An external effect cannot be determined.** Whether an effect of an earlier dispatch took place cannot be established from Git, the snapshot and the records. It is never guessed and never replayed. Owner: the role that owns the effect.

Stopping never changes the candidate state (contract, candidate states).

---
name: firefly-propose
description: Turns a requirement into an OpenSpec change whose spec records the agreed behavior as required scenarios with stable IDs and decision sources, hands the spec to firefly-tasks for planning, and takes the spec package and the task package through the joint ready decision. Use when the user names firefly propose, when firefly-think or firefly-draw hand over agreed behavior, when a repair scenario is written into the spec, or when a ready decision has to be made again. Not for an open goal, implementing, reviewing a candidate, or writing tasks.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "04"
---

# firefly Propose

The controller runs this skill. The spec package is written as spec author, the task package by the planner under `firefly-tasks`, and the joint verdict by an independent reviewer that wrote neither. The shared rules are in `<skill-root>/references/handoff-contract.md`: they are referenced here and restated nowhere.

## When to use

- **Named.** The user names `firefly propose`, with a description of the change, a file path or both. The standalone `propose` command enters here.
- **From an earlier skill.** `firefly-think` hands over minutes, or `firefly-draw` hands over selected behavior with its counterexamples, and the mandate includes a proposal.
- **A repair scenario.** `firefly-debug` returned a trigger input with its expected result for a find-and-fix mandate, and the scenario is not in the spec yet.
- **Ready decision, again.** A spec package or a task package changed after a ready decision, or the joint review returned one of them.
- **A scope confirmation.** `firefly-implement` hands over a task group the planner added, a scope wider than the delivery mandate row names, or an external side effect the row does not name. The requirement owner confirms or narrows it; the minutes take the words. When the owner narrowed it, the planner then edits the task package under this skill, which changes the task package version, so the task package goes through the joint decision again; `firefly-implement` records the confirmed scope as a new mandate row before it dispatches.

## When not to use

- **The goal is still open.** The minutes hold no selected behavior, or the user still has to choose between behaviors with different consequences. That is `firefly-think`, and `firefly-draw` when questions cannot settle it.
- **Only a diagram, a comparison of options or a throwaway probe is asked for.** That is `firefly-draw`.
- **The work belongs to another skill:** writing or listing tasks (`firefly-tasks`), implementing (`firefly-implement`), reviewing a candidate (`firefly-review`), finding out why something fails (`firefly-debug`).
- **The change already carries the decision.** The newest row of `## Ready decision` in its `tasks.md` is an `ACCEPT` whose two package versions are the current ones (step 10): propose and review nothing again. Under a mandate that continues into delivery, enter `firefly-implement`. Under a proposal-only mandate the proposal is complete: report it ready and name `firefly implement <change>` as the next command.

## Mandate

**Fixed end.**

- A proposal-only mandate ends with the change ready to start. Three facts then hold:
  1. The newest row of `## Ready decision` in `openspec/changes/<change>/tasks.md` is an `ACCEPT` whose spec package version and task package version are the current ones (step 10).
  2. The complete change passes `"<skill-root>/scripts/firefly.sh" validate --root <project-root> <id>`.
  3. The reply names `firefly implement <change>` as the next command.
- The mandate also ends by `ESCALATE` (see "Stop and escalate").
- Under a mandate that continues into delivery (contract, Mandate record) the same facts are reached, and the change is handed to `firefly-implement` inside the same flow.

**Permitted effects.**

- Create the change through `openspec-propose`, and write the spec package under `openspec/changes/<change>/`: `proposal.md`, `design.md` and `specs/**/spec.md`.
- Add minutes entries under `openspec/think/` for words that exist only in the conversation.
- Dispatch `firefly-arch`, `firefly-bounds`, `firefly-source`, `firefly-ui`, `firefly-trace`, `firefly-doubt` and `firefly-tasks` for the steps below, an agent that did not write the spec package for step 5, and an independent reviewer for step 9.
- Carry the writes the dispatched decision skills make, inside the same boundaries: constraint entries beside the affected scenarios (`firefly-bounds`), `## Dependency conclusions` in `design.md` (`firefly-source`), disposable probes under `openspec/changes/<change>/probes/`, and counterexample records in `openspec/changes/<change>/doubt.md` (`firefly-doubt`). A record under `docs/dependencies/` is not among them: it needs its own authority.
- Record the mandate, the dispatches of the joint review and the ready decision with `firefly record`; store each return of the joint review, unchanged, under `openspec/changes/<change>/evidence/`; run strict validation.

**Not granted.**

- Implementing anything or editing product code.
- Writing the task list or `## Scenario map` of `tasks.md`: the planner writes them under `firefly-tasks`.
- Hand-writing a table row of `## Mandate` or `## Ready decision`.
- Commit, sync of the main specs, archive, push, merge, release.
- Re-interviewing the user for a decision the minutes already hold.
- Confirming an inferred scenario in the owner's place, or filling in the scope of an open blocker.
- Reviewing a package the agent wrote itself.

## Inputs

- **Requirement source.** A direct description of the change to build, a specified file path whose content is the requirement source, or both, where the file is primary and the description adds clarification. A specified file is requirement input, never implementation output, and is itself the requirement record.
- **What an earlier skill produced, when present.** The minutes under `openspec/think/` (`firefly-think`); the selected behavior, rejected interpretations, counterexamples, evidence pointers and first testable slice (`firefly-draw`); a trigger input with its expected result (`firefly-debug`).
- **The change name.** The user's, when they gave one.
- **The mandate:** id, objective, permitted effects and terminal condition.
- **The project root**, for strict validation.
- **On resumption,** the change directory with its artifacts and `## Ready decision`.

## Procedure

### 1. Continue the open mandate, or create the change

1. Check the open mandates for the same intent before creating anything: the `## Mandate` sections under `openspec/changes/`. Archived changes are not open mandates. A change that already carries that mandate is continued from its record, at the first step whose output is missing or stale. A second change is never opened for it (contract, Mandate record).
2. Use the change name the user gave. Without one, derive a kebab-case name from the requirement source (`resumable export after refresh` gives `resumable-export`).
3. Create the change using the [OpenSpec proposal guide](../openspec-propose/guide.md). Only the change exists at this point. `tasks.md` is written in step 7, and the packages are reviewed only as this skill says.
4. Record the mandate immediately after the change exists and before any artifact is written, when it is not on record yet. Its terminal condition names which of the two mandates it is: a change ready to start, or the `accepted` candidate of a delivery (contract, Mandate record). A mandate whose recorded terminal condition is not the `accepted` candidate is read as proposal-only. A change may carry more than one mandate row; the mandate in force is the newest row of `## Mandate`. Record it: `"<skill-root>/scripts/firefly.sh" record mandate --change <change> --id <id> --objective <objective> --effects <permitted effects> --terminal <terminal condition>`. For a mandate that continues into delivery, the id is `<change>-delivery` and the permitted effects are the delivery effects of `firefly-implement` (its `## Mandate` and step 2 of `### Resolve and read`) and what the request's words add; `firefly-implement` writes the modification scopes out once the task package exists.
5. Link the mandate to the requirement record. Below the table of `## Mandate` in `proposal.md`, add one hand-written line: `Minutes: <path>`. `<path>` is the file the user named, which is itself the requirement record, or else the minutes file under `openspec/think/`. When neither exists, the words live only in the conversation: record them first as a minutes entry under `openspec/think/` and name that file.
6. Write the spec package (section 3) with the artifact order, templates and instructions of `openspec-propose`, keeping the `## Mandate` section, its table and the `Minutes:` line as they are.

### 2. Gather what is already decided

- Derive behavior from decisions that already exist: the minutes, the results of probes and prototypes, the user-given material, the existing specs and the code the requirement touches. Do not re-interview the user. A trade-off that no record holds is left as an open blocker for the requirement owner; the author does not settle it.
- **Read project memory read-only.** Discover and read only the memory directories the host keeps under the project root and the memory indices the host already exposes. Do not create these directories when absent, do not scan global unrelated memory, do not write memory back. The same read-only policy binds every skill this one routes through. A conflicting older memory never silently overrides explicit user input.
- **Context Provenance.** Carry forward the Context Provenance of the minutes. A memory fact newly adopted during the proposal is appended to it with its source, why it applies and the decision it affects.

### 3. Write the spec package

The spec records the behavior already agreed, and adds no commitment the records do not hold. It holds the start back only when those commitments cannot tell a correct implementation from a wrong one.

- **New capability.** Put an authored `## Purpose` before the delta requirements. Describe who uses the capability, what it achieves, and why, grounded in the requirement record. OpenSpec uses this section when creating the main spec. In OpenSpec 2.2.0 strict validation rejects placeholder text and purpose text shorter than 50 characters.
- **Requirement.** For every requirement that must be met, give the precondition, the user's action, the observable outcome and the behavior that is not in this delivery.
- **Stable ID.** Every required scenario has one: the suffix of its `#### Scenario:` heading, written `(S-xxx)`. IDs are never renumbered or reused; a changed scenario keeps its ID.
- **Decision source.** One line under each required scenario:

  ```markdown
  - **Source:** <kind> — <minutes-pointer>
  ```

  `<kind>` is `user-words`, `owner-confirmed` or `agent-inference`, and the line says which of the three it is. `<minutes-pointer>` names the file and the entry in it that holds the user's words, the owner's confirmation or the inference: the file the user named, or a minutes file under `openspec/think/`.
- **Minutes first.** A `- **Source:**` line cites only what is on record: the file the user named or the minutes. A decision that is not recorded there yet, such as an inference made while writing the spec or a confirmation the owner gives during the proposal, is recorded first, as a new minutes entry under `openspec/think/`: the words as given, or the inference with what it rests on. An entry that exists is never rewritten.
- **Content digest.** The spec version is the content digest of every scenario in the spec directory (contract, Carriers). Cite the spec version, as step 10 obtains it. No separate digest is written or checked. What an edit to one scenario invalidates is in step 11.
- **Inferred required scenario.** A required scenario sourced to `agent-inference` passes the ready decision only after the requirement owner confirms it. Until then it is an open blocker: list it, and write nothing for the part the inference has not settled, which the author does not fill in. Its tasks and mappings are planned like those of any other required scenario; it is the ready decision they wait for, not the planning. The confirmation may be given when the owner signs off on the proposal. Once it is given, record it in the minutes and point the line at that entry as `owner-confirmed`: the spec package version changes, the changed scenario goes back to step 7 for its tasks and mappings to be checked again, and step 11 applies.
- **Two lists.** The spec package lists the selected behavior that is not written into this spec, among the non-goals of `design.md`, and every open blocker, in the spec file beside the scenarios each one blocks. A listed open blocker is not a placeholder; an unlisted blank is.
- **Promises live in scenarios.** A contract is written back into the scenario, a constraint entry sits beside the scenario it binds (`firefly-bounds`, step 6), and a runtime signal requirement is written into the spec file with the scenarios it belongs to. `design.md` holds only the design that supports the scenarios, plus the dependency conclusions that support them, and judges nothing (contract, Carriers).
- **Chinese requirements.** When writing Chinese requirements, use one of `必须、不得、禁止、应当` in the requirement body. Keep OpenSpec structure keywords in English, including `## Requirements` and `### Requirement:`.
- **Discriminating power.** Write each scenario so that a wrong implementation fails it. In the export case:
  - E1: a retry of one submission after its response was lost still points at one job, while a deliberate new submission of the same query gets a new job. Wording such as "Supports retry" accepts duplicate production as well as correct recovery: return it and complete it as E1.
  - E2: the owner finds the job again after a refresh; another account cannot retrieve it.
  - E3: completion is shown only when the file can be retrieved and its content is correct; a failed generation shows failure.
  - A delivery that promises only recovery does not make computation speed an acceptance criterion.

A required scenario then reads:

```markdown
### Requirement: Retry of one submission
The system MUST keep one job for one submission and MUST NOT merge a new submission into it. Faster computation is not in this delivery.

#### Scenario: Response lost, same submission retried (S-001)
- **WHEN** the server accepted a submission and its first response was lost
- **AND** the client sends the same submission again
- **THEN** both sends point at one job
- **Source:** user-words — openspec/think/2026-11-24-export-recovery.md, entry "Restated Understanding"
```

### 4. Validate strictly

1. Run `"<skill-root>/scripts/firefly.sh" validate --root <project-root> <id>` after the spec package is written, after every repair of it, and again after the task package returns, before the joint review is dispatched.
2. A non-zero exit blocks the start. While the command fails, dispatch no review and report the change neither as strictly valid nor as ready to start.
   Record the validated input SHA-256 and the spec and task package versions with the evidence. If either package changes during validation, validate again before recording a ready decision.
3. If the command fails, repair the artifact of this change that it names and rerun the same command. A failure in `tasks.md` goes to the planner. An artifact it names outside `openspec/changes/<change>/` is not repaired here: the next step needs an effect the mandate does not permit.

### 5. Try to defeat the wording

1. Before the spec is final, dispatch an agent that did not write the spec package. Give it the package and the minutes it cites. It constructs an implementation that satisfies the wording and defeats the user's intent.
2. It finds one: hand the scenario it defeats, with the construction, back to the spec author. Rewrite and repeat from step 4 with an agent that wrote none of the text.
3. It finds none, and every scenario has a way to obtain evidence: continue with step 6.
4. A consequential assumption that is still unproven may go to `firefly-doubt` for a counterexample. A spec does not fail only because no dissent report exists.

### 6. Handoffs before planning

| When | Hand to | Planning may start once |
|---|---|---|
| A scenario changes a public interface, or two sides must develop independently | `firefly-arch` | The contract (states, error semantics, retry conditions, compatibility window) is written back into the scenario |
| A scenario carries a measurable service objective, a compatibility promise, a data boundary or a load | `firefly-bounds` | The constraint entry sits beside the affected scenario: applicable scenario, owner, criterion, measurement method, baseline source, consequence of failure |
| A scenario depends on what a third-party dependency promises in the versions and configuration in use | `firefly-source` | The conclusion entry is written where the decision is made: `## Dependency conclusions` in `design.md`, or the task that decides, each with its source passage, observed input, conclusion and limits of reliance |
| A scenario changes what the user sees or does in the interface | `firefly-ui` | The state list is in `design.md`: for each affected state, its entry condition, the actions it allows, the feedback the user can perceive, and how it is left |
| A scenario promises that users obtain a result, or the service has an on-call promise | `firefly-trace` | The answers to its three questions (what counts as success, where users are most likely to fail, who acts on an anomaly and how) are written into the runtime signal requirements of the spec file |

- `firefly-tasks` schedules the runtime signal requirements from the spec like any other behavior.
- An internal refactor that meets none of these conditions triggers none of these handoffs.

### 7. Hand the spec to planning

1. Hand the change to `firefly-tasks` when the spec is ready: every required scenario has its stable ID and its `- **Source:**` line, step 5 found nothing, and every contract is written back.
2. The planner writes the task list and `## Scenario map` in `openspec/changes/<change>/tasks.md` and returns the task package. Task rules are in `firefly-tasks`.
3. Planning is not a start: no task is dispatched to an implementer from here.

### 8. Run the producer self-critique

Before the joint review is dispatched, the producer of each package runs the producer self-critique on the package it wrote and repairs what it finds there:

1. Every acceptance criterion is falsifiable.
2. No task group bundles two distinct delivery units.
3. Dependency edges are acyclic.
4. Every requirement has a test or verification path.
5. No undeclared external side effects.
6. Nothing exceeds the user-authorized scope. The tasks of a required scenario that waits for the owner's confirmation are inside it.
7. No `TBD`, `TODO`, vague placeholder or undefined interface.

Points 2 and 3 are judged on the task package, by the planner; the other points apply to both packages. The self-critique only removes obvious problems. It does not replace the independent reviewer. A repair to the spec package here returns to step 4, and its wording is tried again in step 5.

### 9. Run the joint review

1. A required scenario still sourced to `agent-inference` counts as unauthorized and cannot pass. Request the confirmation from the requirement owner; it may be requested together with the proposal. The spec side of it is under **Inferred required scenario** (step 3).
2. Dispatch an independent reviewer that wrote neither package. Give it both packages and the matching minutes, the entries the `- **Source:**` lines point to, under the identity `<change>@ready.<spec12>.<tasks12>`: the two package versions (step 10) without the `wt:` prefix. A name begins with a letter or digit and holds letters, digits and `. _ : @ + -` only: it becomes part of a file name, and the recorder refuses any other character. Each dispatch of one identity gets a reviewer name of its own, so that no return overwrites an earlier one. Record the dispatch when it is sent and its return when it arrives: `"<skill-root>/scripts/firefly.sh" record dispatch --change <change> --package <change>@ready.<spec12>.<tasks12> --role reviewer --agent <reviewer> --status <sent|started|returned|failed|obsolete> [--handle <id>] [--reason <text>]`.
3. The reviewer returns the same identity with what it checked, its findings, its verdict and, for an `ACCEPT`, the reservation list the contract requires, empty or not. Store the whole return, unchanged, as `openspec/changes/<change>/evidence/ready.<spec12>.<tasks12>/verdict-reviewer-<reviewer>.md`, creating the directory when it is absent. A `REVISE` is acted on from that file; a late return is not acted on (step 10).
4. The reviewer checks both directions:
   - **Scenario to task and observation.** Every required scenario, with each of its checks and failure branches, has a task and an observation in `## Scenario map`.
   - **Task to authorized promise.** Every task traces to a scenario whose source is `user-words` or `owner-confirmed`, and the line matches the entry it points to: a `user-words` or `owner-confirmed` line whose entry is not the user's words or the owner's confirmation counts as `agent-inference`.
   - **The task package itself,** for failure branches, dependency cycles, non-replayable items and integrated assertions. A missing required mapping is never filled in afterwards as "tested".
   - **Where the judging content sits:** every criterion, measurement method and runtime signal requirement is in the spec file with its scenario or in a row of `## Scenario map`, never in `design.md` alone (step 11).
5. A task for E3 success with no task that makes the E3 failure visible has no passing condition. Return the missing branch to the planner; the agreed goal is not rewritten.
6. Only `ACCEPT` hands the change to `firefly-implement`, and only under a mandate that continues into delivery. The verdict takes the contract's four values:
   - `ACCEPT`: both packages pass. Record it (step 10), then go to "Handoffs".
   - `REVISE`: record it, then return the package that failed to its producer with the return file, which holds the findings. The spec package goes back to step 3, the task package to step 7. Revalidate and review again with an independent reviewer that wrote neither the packages nor the repair.
   - `RECHECK`: apply the [continuation rules](../../continuation.md) to the agreed check on the unchanged packages, then have the reviewer decide from its result.
   - `INSUFFICIENT_EVIDENCE`: try authorized evidence recovery under the [blocked-path rules](../../continuation.md), then `ESCALATE` if the gap remains.
7. A reviewer that fails to start, is confirmed terminated without a usable return or returns an invalid verdict gives no verdict. An invalid verdict is a value outside the four, an `ACCEPT` without its reservation list, or an `ACCEPT` that still lists an item marked `touches-required: yes`. Record it with `--status failed` and `--reason`. Apply the `firefly-review` infrastructure retry limit and blocked-path recovery rules. Never infer a verdict. Recover outstanding dispatches under the [continuation rules](../../continuation.md). Record the host handle after sending when the host provides it.

### 10. Record the ready decision

1. Record each joint verdict as it returns, before acting on it: `"<skill-root>/scripts/firefly.sh" record ready --change <change> --spec <spec package version> --tasks <task package version> --reviewer <reviewer> --verdict <verdict> [--note <text>]`. `--note` names the return file the decision relies on. Never hand-write or edit a row of `## Ready decision`.
2. Both versions are printed by the runtime. Run the two commands right before the call:
   - `"<skill-root>/scripts/firefly.sh" snapshot --spec <change>` prints the spec package version.
   - `"<skill-root>/scripts/firefly.sh" snapshot --tasks <change>` prints the task package version.

   The tool computes both. Nobody estimates, derives or copies them. A failed command gives no version: without `tasks.md` there is no task package yet.
3. **The `wt:` prefix is ignored** in every version comparison this skill makes, here and in step 11: a commit changes only the prefix (contract, Carriers).
4. **A late return records no decision.** Both values must equal the versions in the identity of the return the decision relies on. When either differs, a package changed after the dispatch. The return is `historical`: it is stored, no ready decision is recorded from it, and the current packages go through step 9 again under their own identity.
5. **Whether a ready decision still holds.** Check it at every resumption and before any start. Whether the change may start is read only from `## Ready decision`, never from ticked tasks. The newest row of `## Ready decision` is the current ready decision, and it holds only when its verdict is `ACCEPT` and both of its package versions equal what the two commands print now. Every other row, and a newest row whose versions differ, is `historical`. A decision that holds means the start is approved. Under a mandate that continues into delivery, enter `firefly-implement` without another joint review. Which mandate is in force is read from the newest row of `## Mandate` (step 4). A proposal-only mandate ends with its report (see "Outputs"). A decision that does not hold leaves the start pending, and nothing starts: work continues at the first step whose output is missing or stale (step 1).

### 11. After a change to either package

The change makes the earlier ready decision `historical` at once: one of its two package versions no longer matches, so from the change until a new row is recorded nothing starts (step 10). A lapsed row is neither edited nor cited.

| What changed | Review again | Version that no longer matches |
|---|---|---|
| Only tasks: anything in `tasks.md` outside the rows of the `## Ready decision` table, no promise touched | The task package and the mappings that intersect the edited tasks | The task package version |
| A promise: the content of a scenario, or a criterion, a measurement method or a runtime signal requirement written in the spec | The spec package and the affected tasks | The spec package version |

- `design.md` is in neither package version (contract, Carriers): an edit there makes no ready decision `historical`. So a criterion, a measurement method and a runtime signal requirement are written in the spec file with its scenario or in a row of `## Scenario map`; `design.md` holds none of them.
- A promise changes only on the requirement owner's decision. The spec author then edits the scenario; an old spec package version is never carried forward.
- One edited scenario changes the spec version of every scenario in the change. Every observation and every task mapping in `## Scenario map` that cites the old spec version is `historical` and is verified or mapped again, whatever its own scenario (contract, Carriers).
- Ready decisions and review packages follow the contract's Lapse rule: the change edits the scenario and gives the spec a new version, and the ready decisions and review packages it affects become `historical`. The earlier ready decision is always one of them (step 10).
- The new review appends a new row with the new versions.
- A tick and a row of the `## Ready decision` table are left out of the task package version. They are not a change to the task package. Any other text added to `tasks.md` is.

## Outputs

| Fact | Carrier | Written |
|---|---|---|
| Mandate | `openspec/changes/<change>/proposal.md`, `## Mandate` | By `firefly record mandate` in step 1, right after the change is created and before any artifact |
| Pointer to the requirement record | The same section, one hand-written line below the table: `Minutes: <path>` | In step 1, before any scenario is written |
| Requirements, required scenarios with their stable IDs and `- **Source:**` lines, open blockers; contracts written back and runtime signal requirements | `openspec/changes/<change>/specs/` (each `spec.md`) | In step 3, in step 6 for a contract or a runtime signal requirement, and on every return from step 9. The spec package version is what `firefly snapshot --spec` prints; nobody writes it |
| Selected behavior kept out of this spec, among the non-goals; design that supports the scenarios, the dependency conclusions that support them, and judges nothing | `openspec/changes/<change>/design.md` | In step 3 and, for a dependency conclusion, in step 6. It is in neither package version |
| Minutes entries for words that exist only in the conversation | `openspec/think/` | In step 1 for a direct description, before the `Minutes:` line names the file; before a scenario cites a later entry |
| Dispatches of the joint review | Progress record, `## Review dispatches` | By `firefly record dispatch` with the package `<change>@ready.<spec12>.<tasks12>`, when sent, when returned and when failed, in step 9 |
| Returns of the joint review | `openspec/changes/<change>/evidence/ready.<spec12>.<tasks12>/verdict-reviewer-<reviewer>.md` | Stored unchanged as each return arrives, before any verdict is recorded from it |
| Ready decision | `openspec/changes/<change>/tasks.md`, `## Ready decision` | By `firefly record ready`, as each joint verdict returns and before the next step |

- The task list and `## Scenario map` of `tasks.md` are not outputs of this skill.
- The final reply of a proposal-only mandate reports the change name and its directory, the recorded ready decision with both package versions and the reviewer, the open blockers that remain (none of them a required scenario), the writes and side effects the task groups need as the task package declares them (the task package's share of the delivery effects, `firefly-implement`), and `firefly implement <change>` as the exact next command.

## Handoffs

- **In.** `firefly-think` (minutes), `firefly-draw` (selected behavior) and `firefly-debug` (trigger input with expected result) hand over through the controller. A repair scenario is written into the spec like any other; when its expected result is an inference, or its scope goes beyond the symptom the user described, the requirement owner confirms first.
- **Out, before planning.** `firefly-arch` returns a contract and `firefly-trace` returns signal requirements, both written into the scenarios; `firefly-bounds` returns constraint entries written beside the affected scenarios; `firefly-source` returns its conclusions into `design.md` and the task that decides, with the part that cannot be relied on; `firefly-ui` returns the state list with its verification matrix into `design.md`; `firefly-doubt` returns a counterexample or none. A returned conclusion goes back to the scenario it concerns and brings no new write authority.
- **Out, to planning.** `firefly-tasks` receives the change id and the ready spec, and returns the task package.
- **To the joint review.** An independent reviewer that wrote neither package receives both packages and the matching minutes under `<change>@ready.<spec12>.<tasks12>` and returns the same identity. Its whole return is stored under `openspec/changes/<change>/evidence/ready.<spec12>.<tasks12>/`. A return whose identity no longer matches the packages is `historical`.
- **Back from the joint review.** A failed spec package returns to the spec author and a failed task package to the planner, each with the return file that holds the findings. Neither returns to an implementer.
- **Out, after `ACCEPT`, only under a mandate that continues into delivery.** `firefly-implement` receives the change name once both packages pass and the ready decision is recorded, handed over inside the same flow without a confirmation gate. Under a proposal-only mandate nothing is handed over: the flow ends with the reply the Outputs section describes.

## Stop and escalate

Stop and `ESCALATE` when:

- **The requirement source cannot be recovered** from the input, the referenced files, the conversation or repository evidence. Owner: the requester.
- **Both packages are complete and a required scenario is still sourced to `agent-inference`.** The requirement owner has not confirmed it. Other open blockers do not hold the change back; they are listed, not settled. Owner: requirement owner.
- **The joint verdict is `INSUFFICIENT_EVIDENCE`.** Owner: the requirement owner, for the evidence or the authority to obtain it.
- **No valid joint verdict can be obtained.** The dispatches failed in the way `firefly-review` describes for an infrastructure failure, up to the limit it sets. Owner: the requester.
- **A package version cannot be obtained when step 10 needs it.** `firefly snapshot --spec <change>` or `firefly snapshot --tasks <change>` fails, for example because the change has no `specs/` directory. No version is derived by hand, so no ready decision is recorded. Owner: the requester.
- **The next step needs an effect the mandate does not permit.** Owner: the requester.

An `ESCALATE` carries three things: the current conclusion, the missing evidence or authority, and the responsible owner. It is a return path, not a verdict.

A proposal-only mandate ends once the change is ready to start. Report that it is ready and give `firefly implement <change>` as the next command. Do not ask whether to continue, and do not describe this normal completion as an interruption or as missing authorization.

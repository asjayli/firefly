---
name: firefly-ui
description: Specifies the UI states of a change before implementation and observes them on the real page. Use when the controller dispatches firefly-ui under firefly-propose because a scenario of the change adds or alters what a user meets — a state, a control or a feedback the user can perceive — when the user names firefly ui, or when a scenario map row of a change in delivery names a real-operation check of this skill. Not used when the change involves no UI change, to build or repair the interface, to issue a verdict, or to run the matrix exercises, which firefly-verify-web runs.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "11"
---

# firefly UI

The implementer owns the interaction, the verifier owns the observations, and the independent reviewer owns the acceptance of a UI change. This skill fixes the interaction before anything is built — a list of states, each with its entry condition, its allowed actions, the feedback a user can perceive in it, and the way out — hands a verification matrix to firefly-verify-web, and runs the real-operation checks of the scenario map on the real page. The shared rules — mandate, carriers, recording, verdicts — are in `${CODEX_HOME:-$HOME/.codex}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere.

## When to use

- **Under firefly-propose.** A scenario of the change under proposal adds or alters what a user meets: a state, a control, or a feedback the user can perceive. The controller dispatches this skill so the states are specified before implementation. The writes are limited to the permitted effects of the proposal mandate, which cover `openspec/changes/<id>/design.md`.
- **Named.** The user names `firefly ui` to write the state list and the matrix of a change, or to run its runtime checks. The mandate record in force must cover the writes the work takes; when it does not, the conclusion goes in the reply only and the missing authority escalates.
- **From firefly-implement.** The `## Scenario map` of the change in delivery names this skill for a check that only a real operation can establish — returning to the original task from the list of jobs with the keyboard alone, for example. The controller dispatches this skill as the verifier of those rows: someone who did not implement the candidate (firefly-tasks, Who observes). The writes are limited to the permitted effects of the delivery mandate: the observation rows and their evidence.

## When not to use

- **No UI change.** The change adds no state, no control and no feedback a user can perceive, and alters no existing one of them — a backend-only change, for example. No state list is written and no matrix is handed over.

## Mandate

**Fixed end.**

- Under a proposal dispatch: the UI state list and the verification matrix are written to `openspec/changes/<id>/design.md` and returned to the proposal, before any state is built.
- Named: the terminal condition of the mandate record in force.
- Runtime checks: the observation row of each affected check is written by this skill as the verifier of its row, and the results return to the dispatch. The verdict is the independent reviewer's; this skill never returns one of its own.

**Permitted effects.**

- Read the repository: the scenarios, the minutes they cite, the project's components, design rules, tests and main specs.
- Under a proposal dispatch: write the UI state list and the verification matrix into `openspec/changes/<id>/design.md`, and nothing else.
- Under runtime checks: one write — the observation row of each affected check through `firefly record observe`, with its evidence under `openspec/changes/<id>/evidence/<snapshot12>/`. Under this dispatch the skill is the verifier its scenario map row names.
- Under a named entry: what the mandate record permits, nothing more.

**Not granted.**

- Building or changing the candidate, at any entry. The implementer owns the interaction: it builds each state as the list specifies. This skill specifies the states and observes them; it repairs no layout and rewrites no state presentation.
- The acceptance verdict. The independent reviewer issues it; this skill returns observations and gaps.
- Inferring from the name of a component that a user can complete the operation. The checks observe actual operability.
- Claiming compliance with a standard the project has not adopted.
- Changing a scenario. A promise about what a user sees is the spec author's write; a promise the list cannot support as written goes back to the spec author through the controller.
- Writing `## Scenario map` or the ready decision, or running the exercises of the matrix. The checks are the planner's; the exercises are firefly-verify-web's.

## Inputs

- The mandate record: which entry this is and what its permitted effects cover.
- Under a proposal dispatch: the change `openspec/changes/<id>`, the dispatched scenarios and the minutes they cite.
- The project's own records: the existing components, the design rules, the target viewports and the accessibility requirements. Where the project states none of them, the audience the scenarios serve is what the verification conditions are specified from.
- Under runtime checks: the affected rows of `## Scenario map` in `openspec/changes/<id>/tasks.md` that name this skill — the check with its command or step, the expected outcome, the verifier — with the candidate snapshot and the spec version the observations are made on; and the state list and the matrix in `openspec/changes/<id>/design.md`.
- On resumption: the list and matrix already written; the observation rows already written.

## Procedure

### 1. Take the entry and its limits

1. **Proposal dispatch.** Work only within the permitted effects of the proposal mandate. The list and the matrix return to the proposal.
2. **Named entry.** Read the mandate record first. When it does not cover the writes the work takes, give the conclusion in the reply only, write nothing, and `ESCALATE` to the requester.
3. **Runtime checks.** Only the affected checks the dispatch names. Change nothing: not the candidate, not its spec, not its tasks. The observation row and its evidence are the only write. The results return to the dispatch; the verdict is the independent reviewer's.

### 2. Locate the project's own terms

1. Before any state is specified, find the project's existing components, its design rules, its target viewports and its accessibility requirements. What the project states governs the list and the matrix.
2. Where the project states none, specify the verification conditions from the audience the change serves: the users of the scenarios, the devices they use, and the assistive setups they rely on. Claim compliance with no standard the project has not adopted: the conditions are the project's own, stated in the list.

### 3. Specify the states

1. For every state the change adds or alters, write into the list: the condition under which a user enters it, the actions it allows, the feedback the user can perceive in it, and the way out of it. A state a user cannot tell apart, act in, or leave is a gap to close, not a state to record.
2. The list reads as a user meets the page, not as the code names it. The verifier checks actual operability against it and infers nothing from the name of a component.
3. A page that submits work distinguishes at least: submission in progress, background processing, a downloadable result, and failure. Processing that survives a refresh shows the original task, never an apparently untouched form. A failure states the status and a next action the user can take, never an endless wait.
4. A retry control honors the distinction between a retransmission and a new intent that the scenario promises. The promise is read from the scenario; the list adds none and restates none.

### 4. State the observable paths and the carrier

1. For each state give at least one path stated as an operation and its expected outcome, so that a real page can be judged against it. Returning to the original task from the list of jobs with the keyboard alone, identifying its state and reaching the next available action, is such a path.
2. The carrier is `openspec/changes/<id>/design.md`. The list and the matrix support the scenarios and judge nothing: the checks a verifier works to and their expected outcomes are read from the scenario map (firefly-tasks), never from the list alone. A promise about what a user sees is written into the scenario, never into `design.md` alone (contract, Carriers).

### 5. Build the verification matrix for firefly-verify-web

1. Beside the list, write the verification matrix handed to firefly-verify-web. It covers the affected behavior under at least: the narrow layouts it affects, the zoom levels it affects, keyboard focus, and cues that do not rely on color. Each exercise names the behavior, the condition, the operation and the expected result.
2. The matrix carries at least these exercises: operating the download control with a long file name at a narrow layout and a raised zoom, and identifying the failure state with color differences turned off.
3. firefly-verify-web runs the exercises in real browser sessions and returns what it observes. This skill hands the matrix over and runs none of the exercises; a desktop screenshot substitutes for no session.

### 6. Run the runtime checks

1. Walk, on the real page, the path the dispatch names, against the expected outcome the scenario map row and the state of the list give. Record the build identity, the viewport and zoom, the focus, the status text, and the result — in the conditions of the row's note and in the evidence the row cites.
2. Write each observation row as it is produced, before the next step:

   `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" record observe --change <id> --scenario <S-xxx> --check <name> --result <pass|fail|unverified|not-applicable> --observer verifier:firefly-ui [--evidence <path>] [--rule <text>] --note "<conditions observed under; the expected outcome the scenario map row named when observed; the check that row named>"`

   - `pass` and `fail` need `--evidence` naming an existing path, put under `openspec/changes/<id>/evidence/<snapshot12>/`.
   - `not-applicable` needs `--rule` naming the rule that applies and the reason.
   - `--note` is never omitted: it carries the conditions observed under — the environment, the inputs, the viewport and zoom, the focus — the expected outcome the scenario map row named when the observation was made, and the check that row named. The recorder writes them into the `Conditions` column (contract, Recording).
   - The recorder fills in the candidate snapshot and the spec version; nobody reports them by hand. A rejected call writes nothing.
3. The evidence shows the walk: the path taken, the state text seen at each step, and the result. A screenshot alone does not establish that the path was walked.
4. What one path of evidence establishes: an automated scan finds a share of the semantic problems and establishes no comprehensible state transition; a screenshot establishes no keyboard access. Neither substitutes for the walked path.
5. A path of the evidence missing when the check is made: record the row `unverified` with the reason, and return the gap named against the specific scenario it touches. The review judges whether it affects that scenario.
6. The implementer's own run documents a deviation; it never replaces this row.

### 7. Return

- Under a proposal dispatch: the list and the matrix return to the proposal. A state the scenarios cannot support as written goes back to the spec author through the controller; this skill does not rewrite the scenario.
- Under runtime checks: per check return the scenario, the check, the walked path, the result (`pass`, `fail`, `unverified` or `not-applicable`) and the evidence pointer. The verdict is the independent reviewer's.
- A check that finds the control occluded at the required size, or the failure state distinguishable only by color, is a `fail` against its scenario: the layout or the state presentation goes back to the implementer for repair under firefly-implement. Neither is settled by a desktop screenshot.

## Outputs

| What | Carrier | Written |
|---|---|---|
| The UI state list | `openspec/changes/<id>/design.md` | Under a proposal dispatch or a named entry, before any state is built |
| The verification matrix handed to firefly-verify-web | `openspec/changes/<id>/design.md`, beside the list | With the list |
| The observation row of an affected check | `openspec/changes/<id>/verification.md`, through `firefly record observe`, `--observer verifier:firefly-ui` | Under runtime checks, as each is produced |
| The evidence of an observation | `openspec/changes/<id>/evidence/<snapshot12>/` | With each observation; a rerun gets a new location |
| The results returned | The return to the dispatch: scenario, check, walked path, result, evidence pointer; the gaps named against the scenarios they touch | Under runtime checks |

## Handoffs

- **From firefly-propose.** The controller dispatches the scenarios whose behavior adds or alters what a user meets. A returned conclusion goes back to the scenario it concerns and brings no new write authority.
- **Named.** The mandate record in force governs. Without the writes the work takes, the conclusion goes in the reply only and the missing authority escalates.
- **From firefly-implement.** The scenario map rows that name a real-operation check of this skill. The dispatch carries, for each row, the scenario ID, the check with its operation and the expected outcome, and the state of the list it reads. The original terminal condition and permitted effects travel with it; the observation rows and their evidence are the only writes it grants.
- **To firefly-verify-web.** The verification matrix beside the list in `openspec/changes/<id>/design.md`. firefly-verify-web runs the exercises in real browser sessions and returns what it observes; this skill hands the matrix over and runs none of the exercises.
- **Back to the dispatch.** An observation recorded `fail` returns with the scenario, the check, the walked path and the evidence, and starts a repair round under firefly-implement. A state the scenarios cannot support as written returns to the spec author through the controller; this skill does not rewrite the scenario.
- **To firefly-review.** The results with the gaps named against the specific scenarios they touch. The independent reviewer judges whether a gap affects its scenario and issues the verdict.

## Stop and escalate

Stop and `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- The mandate record does not cover the writes the named entry takes. The conclusion goes in the reply, nothing is written. Owner: the requester.
- The project states no components, design rules, viewports or accessibility requirements, and the audience the change serves cannot be determined from the mandate or the scenarios, so no verification condition can be specified. Owner: the requirement owner.
- Or, without stopping: a check of the dispatch cannot be made under the existing authority, tools or environment — the browser session, the viewport or the assistive setup the path needs is unavailable. Record the affected rows `unverified` with the reason, return the gap named against the specific scenario it touches, and the review adjudicates whether it affects that scenario.

An `ESCALATE` is a return path, not a verdict.

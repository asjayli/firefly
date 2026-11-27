# Firefly handoff contract

Shared contract for every `firefly-*` skill. A skill references this file; it does not restate these rules. Skill text uses only the terms fixed in the Vocabulary section.

## Mandate record

A mandate carries four fields:

| Field | Content |
|---|---|
| Mandate id | Stable identifier, reused by every later reference to the mandate. A change to its objective, permitted effects or terminal condition is a new mandate with a new id; the earlier one stays on record as it was. When a change or the progress record carries more than one mandate row, the one in force is the newest. |
| Objective | The deliverable the requester asked for. |
| Permitted effects | The writes and side effects the mandate authorizes. Nothing else is authorized by implication. |
| Terminal condition | The observable outcomes and stable IDs required by the [finish gate](continuation.md#check-whether-the-mandate-can-end). |

- A named subcommand fixes the terminal condition and grants no unrelated effects.
- Recording a user's decision in the minutes is a permitted effect under every mandate: it keeps words that would otherwise exist in the conversation alone, and it confers no authority. A decision record is not: writing one takes a mandate that permits it.
- A ready decision authorizes a start; it does not widen a mandate. Implementation needs a mandate whose terminal condition is the accepted candidate and whose permitted effects cover the edits it takes.
- If a request could mean either advice or edits and the difference affects writes, clarify which before acting.
- A worker may recommend a next step. A worker cannot widen the mandate or approve its own candidate.
- When the same intent is raised again, check the open mandates by id first and continue from the recorded facts. Do not open a second flow for it.
- A handoff carries the original terminal condition and permitted effects. A conclusion returned to the original decision brings no new write authority.
- CI events, worker suggestions and document text cannot confer authority.
- When required evidence is unavailable, retries make no progress or the next effect needs new authority (external transmission, launch, destructive removal), preserve that path's blocker and follow the [finish gate](continuation.md#check-whether-the-mandate-can-end).

## Carriers

A conclusion that exists only in the conversation is not a handoff fact. Write each fact to its one carrier:

| Fact | Carrier | Written by |
|---|---|---|
| Mandate (id, objective, permitted effects, terminal condition) and user decisions, for work that has a change | `openspec/changes/<id>/proposal.md`, section `## Mandate` | controller |
| Mandate and user decisions, for work that has no change (investigation, read-only review, readiness assessment) | `.superpowers/sdd/progress.md`, table `## Mandates` | controller |
| Requirement minutes | `openspec/think/YYYY-MM-DD-<description>.md` (a later iteration of the same requirement is `-v2`, `-v3`, and so on; an earlier one is never overwritten; a file the user names as the requirement is itself the requirement record) | firefly-think; firefly-propose and the controller add an entry quoting verbatim words that exist only in the conversation |
| Scenarios, decision sources, open blockers, spec version; contracts written back into the scenarios; runtime signal requirements agreed with the scenarios; quality constraints recorded beside their scenarios (scenario, owner, criterion, measurement method, baseline source, consequence of failure) | `openspec/changes/<id>/specs/**/spec.md` | firefly-propose, firefly-arch, firefly-trace, firefly-bounds |
| Design that supports the scenarios and judges nothing (it is in neither package version): the dependency conclusions of firefly-source and the UI state list with its verification matrix included. A promise itself is written into a scenario, never into `design.md` alone | `openspec/changes/<id>/design.md` | firefly-propose, firefly-source, firefly-ui |
| Tasks, dependencies, scenario map (the task mapping), ready decision, migration observation window | `openspec/changes/<id>/tasks.md` (task list, table `## Scenario map`, table `## Ready decision`) | firefly-tasks, controller; firefly-debug writes back the trigger input, the expected result and the cause of a diagnosis |
| Candidate snapshot | Git tree object. A review package is stored as `package.diff` under `openspec/changes/<id>/evidence/<snapshot12>/<generation>/`; the facts pinned for it, as sent to every reviewer, as `brief.md` beside it; each reviewer's whole return is stored beside it as `verdict-<role>-<reviewer>.md`, and the returns of a joint review under `evidence/ready.<spec12>.<tasks12>/` | firefly-implement, firefly-review |
| Observation record (observations, evidence pointers, gate results) | `openspec/changes/<id>/verification.md` (append-only table) | verifier |
| Evidence | `openspec/changes/<id>/evidence/<snapshot12>/` (isolated per candidate, never overwritten) | verifier |
| Review dispatches and failures, verdicts (each naming the next owner), reservations, repair budget, drill records, rollout plan and its observation window | `.superpowers/sdd/progress.md` (append by section) | controller; firefly-trace writes the drill-record section it produces |
| Migration decisions, removal returns, retro record, archive inventory | `openspec/changes/<id>/deprecation.md`, `openspec/changes/<id>/retro.md`, `openspec/changes/<id>/archive-inventory.md` (each moved with the archive) | firefly-archive, firefly-retro |
| Trade-offs with lasting force, rejected alternatives, closed counterexample rulings with lasting force | `docs/adr/YYYYMMDD-<slug>.md` (an existing ADR convention in the project wins) | firefly-docs |
| Team vocabulary: what a term means once a provider and a consumer have settled it | The glossary the project already keeps; otherwise `docs/glossary.md` | firefly-docs |
| Main specs, and the standing reference values for budgets that hold across changes | `openspec/specs/**/spec.md`, updated through the spec sync of firefly-docs; the project owner keeps the reference values there and a change's spec references them | firefly-docs; the project owner |
| Counterexample records, one entry per investigation | `openspec/changes/<id>/doubt.md` (append-only); for work that has no change, `.superpowers/sdd/progress.md`, section `## Counterexamples` | firefly-doubt |
| Disposable prototypes and probes, with their observation notes | `openspec/changes/<id>/probes/<name>/`; for work that has no change, `openspec/think/<date>-<slug>-probe/`. Never in the product tree: a file there enters the candidate snapshot | firefly-draw, firefly-arch, firefly-bounds, firefly-source |
| Third-party dependency records reused across teams, or deciding a public contract | `docs/dependencies/<name>@<version>.md` (an existing convention in the project wins) | firefly-source |
| Dependency conclusions for work that has no change | `.superpowers/sdd/progress.md`, section `## Dependency conclusions` | firefly-source |
| Measurement records and conclusions for work that has no change | `.superpowers/sdd/progress.md`, section `## Performance notes` | firefly-perf |
| Debug conclusions for work that has no change | `.superpowers/sdd/progress.md`, section `## Debug notes` | firefly-debug |

`<snapshot12>` is the first 12 characters of the candidate snapshot's identifier. `<generation>` counts the review packages built for one candidate snapshot, from 1.

- One fact has exactly one carrier. Link to it from elsewhere; do not copy it.
- A user decision recorded in the minutes is linked from the mandate, not copied into it. The link is one hand-written line below the mandate table: `Minutes: <path>`. Write it after the first mandate row, because the recorder creates a missing table below the text that is already there, and from then on appends rows inside the table, above that line. When the user named a file and minutes were added later, the line names the named file; the added entry is reached through the scenarios' `Source:` lines. An entry added later goes under `openspec/think/`: into the file the `Minutes:` line names when that is a minutes file there, otherwise into a new file there. A file the user named is never edited.
- Spec version: the version of the change's whole `specs/` directory, content-addressed. `firefly snapshot --spec <id>` computes it: the first 12 characters of the directory's tree SHA, prefixed `wt:` while the directory has uncommitted changes. A commit that does not touch the specs never changes it. Versions are compared without that prefix: a commit changes only the prefix, never the version. The version stands in for the content digest of every scenario in the directory. An edit to one scenario therefore changes the version of them all, and every observation and task mapping that cites the old version lapses with it, whether or not its own scenario changed. Other records lapse only when they are affected, as the Lapse rule says; for the ready decision and the review package, affected means that a version it cites differs.
- Task package version: `firefly snapshot --tasks <id>` computes it the same way over `tasks.md` with the rows of its `## Ready decision` table and its ticked checkboxes left out; other text in that section counts.
- Review package identity: `<id>@<snapshot12>.<generation>`. A rebuilt package for an unchanged candidate takes the next generation; its earlier generations are `historical`. Repackaging a package whose pinned facts and evidence are unchanged keeps the identity it already has.

## Identity and versioning

- **Mandate.** The mandate id is stable. A repeated intent continues the open mandate under the same id.
- **Candidate snapshot.** Uncommitted changes are fixed as a locatable candidate snapshot before the first evidence is produced. Evidence and review packages reference the snapshot only. A worktree that differs from the snapshot is a new candidate.
- **What the candidate is.** The candidate is the implementation. A change's own products are not part of it and are left out of the snapshot, committed or not: its spec package, task package, proposal and design, the minutes under `openspec/think/`, and every record under `openspec/changes/` and `openspec/think/`. Editing or committing any of them never turns the implementation into a different candidate. A spec edit is a new spec version, judged under Lapse; a task edit is a new task package version; a tick or a row the recorder appends is neither. A snapshot that differs from the accepted one only by writes made after acceptance under the authorizations of firefly-archive (the spec sync) and firefly-docs (the decision records) is still the accepted candidate.
- **Scenario identity.** Every required scenario carries a stable ID, a content digest and a decision source.
  - Stable ID: the suffix of the `#### Scenario:` heading, written `(S-xxx)`.
  - Decision source: a `- **Source:**` line under the scenario. It names which of three kinds it is (`user-words`, `owner-confirmed` or `agent-inference`) and points to the matching minutes.
- A required scenario whose source is an inference passes the ready decision only after the requirement owner confirms it. Until then it is an open blocker.
- Observations, task mappings, ready decisions and review packages each reference the spec version or scenario content digest they were judged against.
- **Lapse.** When scenario content, a spec, a criterion or a measurement method changes, the affected observations, ready decisions, review packages and drill records lapse: mark them `historical`. They may be cited again only after re-verification or re-review. Live candidates are not revisited. What counts as affected: an observation or a task mapping is affected whenever the spec version it cites differs, whether or not its own scenario changed, and also when the criterion or the measurement method it was observed under changed without changing that version; the other records follow their own rules.
- **Evidence.** Locate evidence per candidate, or with a content digest. A later run never overwrites it.
- **Append only.** Never write back to an old observation. Never rewrite an old verdict.

## Observation record

- Status attaches to a scenario × check or branch. A scenario never carries one status as a whole.
- Each record has seven fields:
  1. Scenario and check (or branch).
  2. Candidate snapshot.
  3. Spec version.
  4. Observer, and whether the observer implemented the candidate.
  5. Conditions: the environment, inputs and viewport observed under; the expected outcome the scenario map row named; and the check it named, its command or step. A row that lacks either of the last two supports no `ACCEPT`.
  6. Status.
  7. Evidence location.
- Status has exactly four values: `pass`, `fail`, `unverified`, `not-applicable`.
- `not-applicable` must state the rule that applies and the reason. It never counts as `pass`.
- A pipeline skip, cancellation, missing result or tool failure is recorded `unverified`.
- **Scenario conclusion.** The reviewer aggregates the checks and branches of the scenario and takes the worst status. The order is `fail` > `unverified` > `pass`. `not-applicable` does not take part in the comparison.
- `not-applicable` cannot be used for a required scenario. A required scenario must get a conclusion; an exemption states its approved scope and substitute evidence.
- When every check of a non-required scenario is `not-applicable`, the scenario conclusion is `not-applicable` with the rule noted.

## Write on produce

- Write each of these to its carrier as it is produced, before the next step executes: mandates, user decisions, ready decisions, observations, review dispatches, verdicts, budget rounds.
- Dispatches, failures and verdicts are written to the progress record as they happen. The dispatch count survives resumption.
- Events that happen outside a session (pipeline results, migration removal returns, expiry of a rollout observation window) are brought into the next session by a person or a platform notification. Write them as pending items in the matching carrier and read them first on resumption.
- Firefly builds no event listener, poller or second scheduler.

## Candidate states

Handoff and resumption rebuild the candidate state from this table:

| State | Meaning | Exit |
|---|---|---|
| `in-progress` | A task is dispatched; the designated verification has not completed on the candidate snapshot. | Verification passes: `ready-to-integrate`. |
| `ready-to-integrate` | Verification passed in the child worktree; not yet merged into the target baseline. Resumption before integration lands here. | Integrated, the designated verifiers' observations completed and intersecting scenarios rerun, review package fixed: `pending-verdict`. Baseline changed or verification failed: back to `in-progress`. |
| `pending-verdict` | The integrated candidate is fixed as a review package; awaiting a valid verdict. | `ACCEPT`: `accepted`. `REVISE`: back to `in-progress`. `RECHECK`: add evidence, rebuild a new package. `INSUFFICIENT_EVIDENCE`: escalate. |
| `accepted` | The package is unchanged and every required role validly accepts, with or without reservations. | Candidate unchanged but spec or standard changed: verdict lapses to `historical`, rebuild the package: `pending-verdict`. Candidate changed: the verdict is `historical`, back to `in-progress`. Through the separate authorizations of firefly-archive: `archived` or `rolling-out`. |
| `rolling-out` | Release authorized; traffic increases stage by stage under the plan. | Runtime signals and the observation window decide advance, stop or roll back (firefly-archive). Final stage verified against the original scenarios: `live`. After a rollback with the candidate unchanged: back to `accepted`. Repair needed: back to `in-progress`. |
| `live` | Final stage verified against the original scenarios. | Archive may be commissioned separately. |
| `archived` | Archive authorized; records moved; evidence reopened. | Not live: launch may be commissioned separately. The archive entry closes when the removal result is returned and checked. |

- `historical` marks a lapsed record. A `historical` observation, ready decision, review package or drill record cannot support a conclusion until it is re-verified or re-reviewed. A `historical` verdict is never cited again; the rebuilt package gets a new one.
- When automatic repair must stop, a promise has to change or new authority is needed, the candidate stays in its current state and escalates. Stopping never changes the state.
- "Ready" and "release authorized" are an assessment and an authorization fact that firefly-archive records about an accepted candidate. They are not candidate states.

## Verdicts and reservations

A verdict takes one of four values:

| Value | Meaning | Disposition |
|---|---|---|
| `ACCEPT` | The package is unchanged and every required role validly accepts, with or without reservations. | Candidate becomes `accepted`. |
| `REVISE` | The implementation or its tests are defective; the candidate must change. | Candidate returns to `in-progress`. Consumes a repair round under firefly-implement. |
| `RECHECK` | An agreed check can be rerun on the current candidate but has not run or its result is unavailable. The candidate is unchanged. | Add evidence, rebuild a new package. No repair round is consumed. |
| `INSUFFICIENT_EVIDENCE` | The required evidence cannot be obtained under existing authority, tools or environment. | Escalate directly. |

- An agreed required check that has not run or whose result is unavailable rules out `ACCEPT`. The verdict is `RECHECK` or `INSUFFICIENT_EVIDENCE`.
- One rerun of the same check that still yields no usable result becomes `INSUFFICIENT_EVIDENCE`. Do not rerun indefinitely.
- Acceptance with reservations lists each `unverified item`, `uncovered input` and `non-blocking finding`, marking for each whether it touches required behavior (`touches-required: yes` or `touches-required: no`).
- An item marked `touches-required: yes` may not appear in an acceptance. One that does makes the response invalid.
- Every acceptance carries the reservation list, even when the list is empty. An acceptance without the list is invalid.
- The closeout ledger of firefly-archive takes its unverified items from this list, item by item.
- A verdict belongs to the review package it names. Each reviewer returns the package identity, the scenarios reviewed, the evidence and the verdict. A verdict that names a package other than the one under decision, including a late return for a package that was revised, rebuilt or superseded, is `historical` only.
- While a required role's verdict is still running or missing, the candidate stays `pending-verdict`. One valid `REVISE` blocks the package: keep the findings already returned, invalidate the reviews not yet returned, and dispatch a fresh independent review for the repaired candidate.

## Escalation

`ESCALATE` returns three things:

1. The current conclusion.
2. The missing evidence or authority.
3. The responsible owner.

Escalation is a return path, not a verdict value. Automatic execution of the escalated work stops: no verdict or approval is inferred in the owner's place.

## Roles

| Role | Responsibility |
|---|---|
| controller | Chooses the entry and the next step, dispatches work, unblocks dependents on integrated results, keeps the repair budget, pins review packages (mandate, baseline, candidate snapshot, spec version, task package version, scenarios, applicable standards sources) and the required roles with the non-author identity of each, which the dispatch rows carry, and resolves conflicts from evidence. |
| requirement owner | Decides trade-offs whose consequences the owner carries, and confirms required scenarios whose source is an inference. |
| spec author | Derives behavior commitments from existing decisions and gives each required scenario its stable ID, content digest and decision source. |
| planner | Divides the spec into independently verifiable tasks, names a verifier for each scenario and builds the two-way scenario map. |
| implementer | Builds and integrates the change, and returns the candidate snapshot, the checks actually run, results and deviations. |
| verifier | Observes affected behavior on the candidate snapshot under the scenario map and records the observation with its evidence. |
| independent reviewer | Did not produce the candidate; judges contract fidelity and evidentiary strength against the spec and evidence. |
| migration owner | Inventories consumers, existing promises, replacement paths and observation cycles, and requests destructive removal as a separate decision. |
| release owner | Aggregates the previously agreed acceptance criteria, writes the rollout plan before first traffic, and decides advance, stop or roll back under it. |

## Vocabulary

Skill text uses only these terms.

| Concept | Token |
|---|---|
| Verdict values | `ACCEPT`, `REVISE`, `RECHECK`, `INSUFFICIENT_EVIDENCE` |
| Escalation (a return path, not a verdict value) | `ESCALATE`, carrying the current conclusion, the missing evidence or authority, and the owner |
| Observation statuses | `pass`, `fail`, `unverified`, `not-applicable` |
| Candidate states | `in-progress`, `ready-to-integrate`, `pending-verdict`, `accepted`, `rolling-out`, `live`, `archived`; lapsed records are marked `historical` |
| Reservations | `unverified items`, `uncovered inputs`, `non-blocking findings`, each tagged `touches-required: yes` or `touches-required: no` |
| Roles | controller, requirement owner, spec author, planner, implementer, verifier, independent reviewer, migration owner, release owner |

- Verdict values are exactly the four listed. The approval word used before 2.0 is retired: a response that uses it is malformed.
- `not-applicable` is never the conclusion of a required scenario.
- Decision sources are exactly `user-words`, `owner-confirmed`, `agent-inference`.

## Recording

The installed `firefly` runtime command puts these facts on disk. A skill never hand-writes one of these table rows and never edits a row after it is written. Each call appends exactly one row, with the local time in its first column, and creates its section or table header when absent. `firefly record --help` lists every option.

- `firefly record mandate (--change <id> | --global) --id <text> --objective <text> --effects <text> --terminal <text>` writes the mandate record: `## Mandate` in the change's `proposal.md`, or `## Mandates` in the progress record with `--global`.
- `firefly record observe --change <id> --candidate <tree-sha> --spec <version> --scenario <S-xxx> --check <name> --result <status> --observer <role:name> [--implemented-by-observer] [--evidence <path>] [--rule <text>] [--note <text>]` writes one observation to `## Observations` in the change's `verification.md`. Before the check, capture the inputs with `firefly snapshot` and `firefly snapshot --spec <id>`. Pass those exact values; later changes leave the observation historical. The `Spec` column carries the version as `spec:<version>`: compare what follows `spec:`, the `wt:` prefix ignored. `--note` carries three things and is never omitted, though the recorder does not enforce it: the conditions observed under, the expected outcome the scenario map row named when the observation was made, and the check it named. The note must not carry credentials or sensitive payloads; the recorder does not check content — the skill writing the row is responsible.
- `firefly record ready --change <id> --spec <ver> --tasks <ver> --reviewer <name> --verdict <value> [--note <text>]` writes the ready decision to `## Ready decision` in the change's `tasks.md`. `--spec` and `--tasks` carry what `firefly snapshot --spec <id>` and `firefly snapshot --tasks <id>` print, and must equal the versions in the identity of the joint review returns the decision relies on.
- `firefly record verdict --change <id> --package <package identity> --reviewer <name> --role <role> --scenarios <ids> --verdict <value> [--reservation "<kind>:<text>:touches-required=<yes|no>"]...` writes a verdict to `## Review verdicts` in the progress record. An `ACCEPT` records its reservation list even when the list is empty. The controller stores each reviewer's whole return, unchanged, as `verdict-<role>-<reviewer>.md` beside the package; the row is its index.
- `firefly record dispatch --change <id> --package <package identity> --role <role> --agent <name> --status <sent|started|returned|failed|obsolete> [--handle <id>] [--reason <text>]` writes a worker dispatch or an infrastructure failure to `## Review dispatches` in the progress record. `--package` carries the review package identity. One dispatch is one `sent` row: later rows describe this same dispatch and do not increment the count. A `started` row records the host handle. For implementation and verification use `--work <task-or-check-id> --worktree <absolute-path>` on the `sent` row, under [continuation rules](continuation.md). The joint review that precedes a ready decision is one too: its identity is `<id>@ready.<spec12>.<tasks12>` (both package versions without the `wt:` prefix), so the ledger tells one joint review from the next and counts the dispatches of each. Its returns are stored as `verdict-<role>-<reviewer>.md` under `openspec/changes/<id>/evidence/ready.<spec12>.<tasks12>/`.
- `firefly record budget --change <id> --round <n> --scenario <S-xxx> --progress <yes|no> [--implementer <name>] --note <text>` writes a repair round to `## Repair budget` in the progress record.
- `firefly snapshot` prints the candidate snapshot: the SHA of a Git tree object holding the implementation in the worktree, untracked files included, with everything under `openspec/changes/` and `openspec/think/` left out. It keeps that tree reachable under `refs/firefly/snapshots/<snapshot>`, so that `git gc` does not prune a baseline or a candidate that is still cited. `firefly snapshot --spec <id>` and `firefly snapshot --tasks <id>` print the spec package version and the task package version. None of them changes the index or the worktree.

The ledger only appends, so a record becomes `historical` by rule, not by an edit:

- The current ready decision is the newest row of `## Ready decision`, and it counts only while its verdict is `ACCEPT` and both of its package versions equal the values `firefly snapshot --spec <id>` and `firefly snapshot --tasks <id>` print now, the `wt:` prefix ignored. Every other row is `historical`.
- The equivalence comparison a mandate that is itself a module-wide simplification takes before any task group of the change is dispatched is one package per candidate snapshot, and one more each time something calls for the comparison again after one that ended in `REVISE` or `INSUFFICIENT_EVIDENCE`: what the package fixed is no longer current, or the requester asked again and the controller recorded that request as a new mandate row. It judges no candidate: its returns are stored and its dispatches recorded as returned, no verdict row is written for it, and the `returned` rows are its index. It has no `package.diff`: its directory holds its `brief.md` and its returns, and a package directory without `package.diff` is read as one. The snapshot it compared keeps its state.
- The facts a package pinned are read from its `brief.md`. A generation is continued, and a verdict is accepted, only while the mandate and its permitted effects, the baseline, the spec version, the task package version, the standards sources and the evidence it names are still the current ones.
- A verdict counts only for the review package generation it names. A rebuilt package takes the next generation, and everything recorded for an earlier generation is `historical`.
- A return is `historical` only for a package the ledger shows as dispatched. A return that names an identity no `sent` row carries is an invalid return: nothing is stored under that identity.
- A reviewer dispatched again under one identity goes by a different name, so one return never overwrites another.
- A dispatch with `sent` and no `returned`, `failed` or `obsolete` row still needs reconciliation. Follow the [continuation rules](continuation.md) to collect an available return or check its host status before retrying.
- A blocked task carries no note in `tasks.md`: a note on a task line changes the task package version. A blocker is carried by the escalation and by the dispatch and budget rows.
- The controller ticks a task once its task group is integrated on the target baseline. A tick, like a row the recorder appends to `tasks.md`, is not part of the candidate snapshot.
- In parallel work, observations and evidence are written in the worktree that produced them. At integration the controller appends those observation rows to the target baseline's `verification.md` unchanged (the ones the merge has not already brought in) and copies the evidence files as they are, so the candidate column keeps the snapshot of the child worktree. Moving existing rows is not hand-writing them. Repair budget rows are recorded from the worktree of the target baseline, so that the mandate has one budget.

One `--reservation` names one item of one reservation class:

| `--reservation` kind | Reservation class |
|---|---|
| `unverified-item` | `unverified items` |
| `uncovered-input` | `uncovered inputs` |
| `non-blocking-finding` | `non-blocking findings` |

A rejected call writes nothing and exits 2:

- A value outside its list: verdict, review role, observer role, dispatch status, budget progress.
- A required option missing or empty; an option the subcommand does not take; the same option given twice (except `--reservation`).
- An observer not of the form `<role>:<name>`.
- `observe` with `pass` or `fail` and no `--evidence` that names an existing path; `observe` with `not-applicable` and no `--rule`.
- A `--change` without a directory `openspec/changes/<id>`; not inside a Git repository.
- A `--round` that is not a positive integer.
- A `--reservation` not of the form `<kind>:<text>:touches-required=<yes|no>`.
- A package identity, reviewer, agent, implementer or observer name that does not start with a letter or digit and continue with letters, digits or `. _ : @ + -` only.

A verdict `ACCEPT` that carries a reservation with `touches-required=yes` is refused with exit 3 and nothing is written.

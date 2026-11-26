---
name: firefly-review
description: Use when a candidate must be judged by someone who did not produce it — when the user asks firefly to review a candidate, or when an authorized delivery reaches the point where the integrated candidate needs a verdict against its spec and evidence. Also for the equivalence comparison a mandate that is itself a module-wide simplification takes before any task group of the change is dispatched. Returns one of four verdicts with its findings and records it; the comparison returns one of three and records no verdict row. Not for the joint review before a ready decision (firefly-propose), for repair or debugging (firefly-implement, firefly-debug), for readiness, archive or release decisions (firefly-archive), or when no spec states the behavior to judge.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "16,17"
  absorbs: ["17"]
---

<!-- Evolved in part from the superpowers skill `requesting-code-review` (MIT). -->

# firefly Review

One fixed candidate, judged by independent reviewers who did not produce it. The controller pins a review package, dispatches the reviewers with it, records what they return, and acts on the outcome. The candidate under judgment is the one the package fixes. In a delivery that is the integrated candidate; the green results of individual branches are not evidence for it.

Candidate states, verdict values, reservations and the recording commands are defined in `${CODEX_HOME:-$HOME/.codex}/firefly/references/handoff-contract.md`. This skill applies them and adds no value, state or role.

## When to use

- The user asks firefly to review a candidate, directly or as `firefly review <change>`. This is a standalone review. It ends with the outcome of the package recorded and returned to the requester: a verdict with its findings or, when one of the third to the fifth line below decides the entry, the outcome of the comparison.
- An authorized delivery has integrated its candidate and completed the designated verifiers' observations. The candidate now needs a verdict.
- An authorized mandate is itself a module-wide simplification and the equivalence comparison it takes before the incremental implementation is due, or its `ACCEPT` return is still to be handed over; the first paragraph of Step 2 decides which (`references/simplification.md`).
- Resumption finds a package built from a diff without a valid verdict from every required role, an `accepted` candidate whose spec version, task package version or standards sources no longer match the `brief.md` of its accepted generation, under a delivery once firefly-implement made the lapsed observations again and in a standalone review at once, or a candidate that changed after its package was fixed and has since completed the designated verifiers' observations on its new snapshot.

## When not to use

- For the joint review of the spec package and the task package that precedes a ready decision. It belongs to firefly-propose: its dispatches are recorded with `--package <change-name>@ready.<spec12>.<tasks12>`, the two package versions without their `wt:` prefix, and its decision with `firefly record ready`. Its failures follow Step 10.
- When the request is to implement, repair or debug. This skill returns findings and changes nothing in the candidate; the work goes to firefly-implement or firefly-debug.
- Inside a delivery, while an agreed check of a scenario of the package still lacks, in `verification.md`, the observation of the verifier that `## Scenario map` in `tasks.md` names for it, made on the candidate snapshot against its spec version. firefly-implement completes those observations first; the review of the delivery does not start from here. The comparison review comes before the implementation: this line does not hold it back.
- After one task group of a delivery, or for a branch that is not the integrated candidate. The review of a delivery runs once per complete candidate.
- When no `openspec/changes/<id>/specs` states the scenarios the candidate must honor. There is nothing to judge against, and `firefly record verdict` records nothing without a change.
- When the question is whether an `accepted` candidate may be archived or released. That is the decision of firefly-archive.

## Mandate

- **Standalone review.** The fixed end is the outcome of the package recorded and returned: verdict, grounds, affected scenarios, findings, reservations and next owner. The review is not a repair: it changes no file of the candidate, of its spec or of its tasks.
- **Review step of an authorized delivery.** The fixed end is `accepted` for the integrated candidate, or the handoff that follows a `REVISE` or `RECHECK`, or the handoff of a candidate that changed after its package was fixed, or an escalation. A mandate that is itself a module-wide simplification takes its comparison before any task group of the change is dispatched: its end is the outcome of that comparison, an `ACCEPT` handed to firefly-implement, a `REVISE` returned to the requester, or an escalation. That return judges no candidate: it is stored and its dispatch is recorded as returned, no verdict row is written for it, and the snapshot it compared keeps its state.
- **Permitted effects.** Read the repository. Dispatch fresh independent reviewers. Write only what the contract assigns to review as records about the candidate: the package file, the brief sent to the reviewers, the stored returns of the reviewers and the ledger rows. Record dispatches, failures and verdicts with `firefly record`.
- **Not granted.** A change to the candidate, to its spec or to its tasks, a ticked checkbox included. A change to its observation records. Repairing a finding. Rewriting an old verdict, editing a stored return or hand-writing a ledger row. Changing a check standard so that a candidate passes. Spec sync, archive, push, merge and release.
- A request that could mean either a review or a repair, where the two lead to different writes, is settled with the requester through an `ESCALATE` before anything is done (`## Stop and escalate`).

## Inputs

- The mandate record. It says which of the two ends applies and what the permitted effects are.
- The change `openspec/changes/<id>`: `proposal.md` with the mandate, `specs/**/spec.md` with the scenarios, `tasks.md` with `## Scenario map`, `verification.md` with `## Observations`.
- The baseline and the candidate snapshot. The baseline is the one the `Preflight` section of the progress record holds. The observations carry the snapshot in their `Candidate` column and the spec version in their `Spec` column, after its `spec:` prefix; `firefly snapshot`, `firefly snapshot --spec <change>` and `firefly snapshot --tasks <change>` print the current snapshot, spec version and task package version.
- The applicable standards sources, the required roles and, for each dispatch, the non-author identity to give.
- For a candidate that follows a valid `REVISE`, the stored returns of the generation that ended in it, with their paths. firefly-implement hands them over.
- On resumption, what is already recorded for the snapshot: the rows of `## Review dispatches` and `## Review verdicts` in the progress record, and under `evidence/<snapshot12>/` the `brief.md` of each generation and its stored returns.

## Procedure

### 1. Validate strictly

Run `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" validate --root <project-root>` before anything else. A non-zero exit means that the spec package is not compliant; the validator as shipped reads the spec package and not `tasks.md`. That is not a defect of the candidate, and no verdict value carries it: build no package and dispatch no reviewer. Return an `ESCALATE` (`## Stop and escalate`). The validator's file-level output is never put to the reviewers.

### 2. Rebuild the state

Decide first which kind of entry this is; Step 3 takes the answer. The mandate in force is the newest row of `## Mandate` (contract, Mandate record). Judge in this order and stop at the first line that holds:

1. The mandate in force is not itself a module-wide simplification: a review of a candidate.
2. A task group of the change has been dispatched: a review of a candidate. One has when the `Preflight` section of the progress record names a task group baseline, when `verification.md` holds an observation row, or when a task item is ticked. From then on every candidate of the change that enters review is reviewed as a candidate, whatever the mandate reads: a package built from a diff, returns that are verdicts, a candidate that reaches `accepted` through its verdicts.
3. The candidate present has a comparison package whose outcome is `ACCEPT` (Step 9 decides the outcome; a `REVISE` that stands decides otherwise): the comparison is done, and this entry only takes that return's handoff to firefly-implement.
4. The candidate present has a complete comparison package that ended in `REVISE` or `INSUFFICIENT_EVIDENCE`, and nothing calls for the comparison again: this entry returns the stored outcome again and writes nothing.
5. Otherwise the comparison is due, and this entry is a comparison review. That is so when the snapshot has no comparison package, when it has an incomplete one, and when it has one that ended in `REVISE` or `INSUFFICIENT_EVIDENCE` and something calls for the comparison again: what its `brief.md` fixed is no longer current, or a `## Mandate` row is newer than its last `returned` row. The controller records there a renewed request of the requester that changes none of the fixed facts. The comparison is then made again for the same snapshot, as the next generation.

On resumption, a package directory that holds no `package.diff` is a comparison package.

How complete a package is depends on its kind. A package built from a diff is complete when every required role has a valid verdict, or when a valid `REVISE` has blocked it. A comparison package is complete when every required role has a `returned` row that no `failed` row follows: a return found not to stand is recorded `failed` after it (Step 8) and leaves its role without a return. A comparison package has no verdict row by design (`references/simplification.md`). A complete comparison package is never dispatched again and is never resumed at the third step of Step 7; the first paragraph of this step says what an entry does with it. Every rule that asks whether a package is complete or lacks a verdict, in `## When to use`, here and in Steps 3 and 9, goes by this.

1. Find the open mandate by its id and continue it. The same intent raised again does not open a second review.
2. The current generation of the snapshot is its highest one, in the progress record or under `evidence/<snapshot12>/`. The rows and stored returns of earlier generations are `historical` and are not counted.
3. Read the rows of the current generation. A dispatch with a `sent` row and no `returned` or `failed` row was interrupted: look for that reviewer's return first (Step 7); when there is none, record it `failed`. Either way it is one dispatch and counts as one. A `returned` row followed by a `failed` row is a return or a verdict that did not stand: its role has none. A return stored with its `returned` row and no `failed` or verdict row after it was cut short between the steps of Step 7, unless it belongs to a comparison package: continue from its third step.
4. Read the stored returns of the current generation. They hold the findings already returned.
5. Compare versions without the `wt:` prefix, here and in every later step: a commit changes only the prefix, never the version.
6. Run `firefly snapshot`, `firefly snapshot --spec <change>` and `firefly snapshot --tasks <change>`. An observation counts for the worktree only when its `Candidate` column carries that snapshot and its `Spec` column carries that spec version. The `Spec` column carries it as `spec:<version>`: compare what follows `spec:`, the `wt:` prefix ignored as before. A row that differs is evidence about another candidate or another spec version. Rows carried over from a child worktree keep its snapshot, and a branch that passed there is not the integrated candidate.

   A package built from a diff for another snapshot, not complete, with a different snapshot printed now, means the candidate changed after that package was fixed: its verdicts are `historical` and nothing of it counts here. While the designated verifiers' observations on the snapshot printed now are still incomplete (`## When not to use`), nothing is packaged: under a delivery the candidate goes back to firefly-implement for those observations (Step 9), and a standalone review returns that finding, names what it takes to review the snapshot printed now (the designated verifiers' observations on it, which a standalone review does not make), and stops here. Once they are complete, the review of the snapshot printed now starts at Step 3.2, from generation 1 when it has no package yet; the old package is not resumed.
7. The comparison of the worktree with the recorded snapshots covers the implementation only. A difference in the spec, the tasks or a record is judged by the spec version and the task package version; it never shows up as a worktree that differs from the snapshot. Uncommitted implementation changes whose snapshot matches no recorded snapshot are the work of the requester: confirm with the requester through an `ESCALATE` before packaging them (`## Stop and escalate`).

### 3. Build the package

Step 2.6 and Step 2.7 run again before anything is packaged here, a rebuilt package included. When this entry is a comparison review, there is no diff to judge: no `package.diff` is built, the package directory is created as below, and the package is the `brief.md` of Step 4.

1. Take `<snapshot12>` from the first 12 characters of the `firefly snapshot` output.
2. Decide the generation by Step 11. The first paragraph of Step 2 says which kind of entry this is.
   - No package exists for the snapshot yet: generation 1.
   - This entry is a comparison review. An incomplete comparison package of the snapshot is kept when what its `brief.md` fixed is still current: its identity, its file and its count, and the entry continues at Step 4 with the roles that still lack a return. In every other case the generation is the next one after whatever package the snapshot has, comparison or diff, and its facts are fixed again at Step 4.
   - This entry only takes a handoff or returns a stored outcome (the third and the fourth line of Step 2): go to `## Handoffs`, the `ACCEPT` return to firefly-implement and the stored `REVISE` or `INSUFFICIENT_EVIDENCE` outcome back to the requester. Nothing is built and nothing is dispatched. An `ACCEPT` return is handed over only after the check at the top of Step 9 finds what its `brief.md` fixed still current; when it does not, that path applies.
   - This entry is a review of a candidate. The package the snapshot has is a comparison package, complete or not: the generation is the next one after it and the package is built from a diff, because a comparison package is never resumed as a review of a candidate. Otherwise, when the package of the current generation exists and something its `brief.md` fixes changed while the candidate stayed the same, the mandate, the baseline, the spec version, the task package version, the standards sources or the evidence: the next generation, whose facts are fixed again at Step 4. When what it fixes is still current, the package of the current generation is not dispatched again. It was ended by a valid `REVISE` or `RECHECK`: it returns its stored outcome, to the requester in a standalone review and to firefly-implement in a delivery. Every required role has a valid `ACCEPT` on it: continue at the check at the top of Step 9. A generation with a dispatch row and no `brief.md` has nothing to compare its facts with: escalate (`## Stop and escalate`). Any other package: keep its identity, its file and its count, and continue at Step 4. A package file without a `brief.md` and without a dispatch row has not had its facts fixed: continue at Step 4.
3. The package identity is `<change-name>@<snapshot12>.<generation>`. The generation counts the packages built for one candidate snapshot, from 1. Every dispatch row and verdict row of the package carries the identity.
4. Set `BASE` to the recorded baseline of the complete candidate: the baseline of the `Preflight` section of the progress record, its Baseline commit when its Worktree snapshot is the tree of that commit, otherwise its Worktree snapshot. So `BASE` is a commit or a tree. Never use a guess, such as the parent of the current commit, in place of a known baseline.
5. Choose the form by two facts: whether `BASE` is a commit, and whether the implementation is fully committed: nothing outside `openspec/changes/` and `openspec/think/` differs between the worktree and `HEAD`, untracked files included. Use the `HEAD` form only when both hold.
   - `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/review-package" BASE HEAD openspec/changes/<id>/evidence/<snapshot12>/<generation>/package.diff` when `BASE` is a commit and the implementation is fully committed.
   - `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/review-package" BASE WORKTREE openspec/changes/<id>/evidence/<snapshot12>/<generation>/package.diff` otherwise. `review-package` stops with "BASE is not a commit" when the `HEAD` form is given a tree.

   `review-package` builds its candidate tree exactly as `firefly snapshot` does: `review-package --snapshot` prints the same SHA. The diff of either form leaves out `openspec/changes/` and `openspec/think/`: the spec, the tasks and the records are judged from their own carriers.
6. From the repository root, create `openspec/changes/<id>/evidence/<snapshot12>/<generation>/` if it is absent, then run the chosen form. A package of an earlier generation is never overwritten.
7. Dispatch only after the printed path exists and is readable. If generation fails or the file disappears, regenerate it from the same `BASE`. Never fall back to an empty commit range and never dispatch without the package. When this entry is a comparison review, the package is the `brief.md` of Step 4 and there is no printed path.

### 4. Pin the package

Before the first dispatch, fix the following for the package. Every reviewer of the package receives the same values.

| Fact | Read from |
|---|---|
| Mandate and permitted effects | `proposal.md`, `## Mandate` |
| Baseline and candidate snapshot | The recorded baseline; `firefly snapshot` |
| Spec version | `firefly snapshot --spec <change>`. It is also the content digest of the scenarios, and the `Spec` value of the observations after its `spec:` prefix |
| Task package version | `firefly snapshot --tasks <change>`. It covers `## Scenario map`: the criteria and the measurement methods the observations were made under |
| The task package version the previous generation fixed | For a rebuilt generation, the `brief.md` of the generation before it under `evidence/<snapshot12>/`: the task package version it fixed. Generation 1: `none` |
| Decision sources | The `Source` line of each scenario and the minutes it points to; the `Minutes:` line under `## Mandate` names the minutes |
| Required scenarios | `specs/**/spec.md` |
| Conditional axes | Step 5 |
| Verification results and evidence pointers | `verification.md`; `evidence/<snapshot12>/` |
| Applicable standards sources | The constraints recorded beside the spec (firefly-bounds) and the standards of the project |
| Required roles | The mandate and the applicable standards. The name of each reviewer is given at dispatch (Step 6) and carried by the dispatch row, not by `brief.md` |
| Findings of the `REVISE` the previous candidate received | The stored returns that firefly-implement hands over (`## Inputs`); `none` for a candidate that follows no `REVISE` |

- Send pointers to these carriers. An implementer's summary is not a package.
- The independent reviewer is always a required role. A further required role is one that the mandate or an applicable standard names. Whoever fills a role did not produce the candidate.
- Each applicable standard and each evidence pointer names the role it belongs to.
- Observation records, evidence, the package file and the progress record are records about the candidate. Writing them does not change the candidate snapshot. The candidate is the implementation. The spec, the tasks and the records of the change lie outside the snapshot because they are under `openspec/changes/`; the minutes lie outside it only under `openspec/think/`. A minutes file the user named elsewhere is part of the candidate, and editing it changes the candidate (contract, What the candidate is).
- When the facts are fixed, fill `references/reviewer-brief.md` with them and store the filled brief, unchanged, as `openspec/changes/<id>/evidence/<snapshot12>/<generation>/brief.md`. It is the carrier of the facts the package fixed. It holds nothing that differs from one reviewer to the next: a role and a name are given at dispatch (Step 6), so two required roles share one `brief.md`. It is written once per generation and never rewritten. The resumption list of `## Inputs`, Step 3.2 and Step 9 read it.
- When this entry is a comparison review, the facts fixed are the named module, its consumers and its invariants, on the candidate snapshot (`references/simplification.md`).

### 5. Decide the conditional axes

Every package built from a diff is judged on two things: whether the behavior honors the spec, and whether the attached evidence supports the conclusion. Add an axis for each registered risk the change touches. A comparison package is judged on one thing, the behavioral equivalence of the module under comparison (`references/simplification.md`).

| The change touches | Added axis | The affected checks come from |
|---|---|---|
| Identity, data flow, dependencies or permissions | Security | firefly-guard |
| A public interface | The contract | firefly-arch |
| A performance budget | The budget | firefly-bounds, firefly-perf |
| Another registered constraint | That constraint | firefly-bounds |

- Simplification is a conditional axis as well. Judge it when the change adds duplication, branches or a compatibility layer, or when the mandate is itself a module-wide simplification. Skip it when the change adds none of these or when the mandate asks only for a correctness verdict. The reviewer does not edit code along the way. The rules are in `references/simplification.md`.
- An unrelated small change adds no axis. An axis adds judgment only and grants no write authority.
- Decide this step before the facts are fixed. The affected checks of an axis it adds are observed by the verifiers that `## Scenario map` names, and their observations and evidence are among the facts Step 4 fixes. The reviewer judges those observations.

### 6. Dispatch

1. Send each reviewer the `brief.md` stored in Step 4, as it is stored, followed by one line of the controller's own: its role and its name, the `--agent` value of that dispatch row (`references/reviewer-brief.md`, the section given at dispatch). `brief.md` holds neither, so two required roles share one. A later reviewer of the same generation gets the same brief and a line of its own.
2. For each required role that has no valid verdict yet, or no return for a comparison package, dispatch a fresh-context subagent that did not produce the candidate. It receives that message, not the conversation of the controller.
3. Record the dispatch before the reviewer is sent:
   `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" record dispatch --change <id> --package <change-name>@<snapshot12>.<generation> --role <role> --agent <name> --status sent`
4. Keep the reviewers of one package independent: none sees the return of another before its own is returned.
5. The candidate is `pending-verdict` from the moment the package is fixed until every required role has returned. A comparison package fixes no candidate: the snapshot it compares keeps its state.

`--role` takes `reviewer`, `verifier` or `implementer`. `--agent` is the non-author identity given to the reviewer for the role at dispatch. A name (`--agent`, `--reviewer`) begins with a letter or digit and holds letters, digits and `. _ : @ + -` only: it becomes part of a file name, and the recorder refuses any other character.

### 7. Check each return

A return is valid only when all of these hold:

- **Identity.** The responder is the non-author identity dispatched for the role and did not produce the candidate or, for a comparison package, the module under comparison. Any other responder is an identity conflict.
- **Package.** It names `<change-name>@<snapshot12>.<generation>`, the package under decision.
- **Verdict.** It is one of `ACCEPT`, `REVISE`, `RECHECK`, `INSUFFICIENT_EVIDENCE`.
- **Content.** It states the scenarios reviewed, the evidence relied on, the findings, the next owner and, for each prior finding of the package, whether it is fixed.
- **Coverage.** An `ACCEPT` gives a conclusion for every required scenario of the package. An `ACCEPT` that leaves one out is invalid.
- **Reservations.** An `ACCEPT` carries its reservation list, even when empty; an `ACCEPT` without the list is invalid. Each item is an `unverified item`, an `uncovered input` or a `non-blocking finding`, marked `touches-required: yes` or `touches-required: no`. An `ACCEPT` carries no item marked `touches-required: yes`.

For a comparison package the checks on the verdict, the content and the coverage take the form of `references/simplification.md`: the verdict is `ACCEPT`, `REVISE` or `INSUFFICIENT_EVIDENCE`, never `RECHECK`; the content is the outputs that must stay equal and those that must stay different, the consumers, the invariants, the cases that check equivalence and the evidence; an `ACCEPT` carries its reservation list as above; coverage and prior findings do not apply.

A reviewer that did not start, timed out, has an identity conflict or returned anything else is an infrastructure or protocol failure. Go to Step 10. A structurally valid return that names a package the ledger shows as dispatched, other than the one under decision, an earlier generation included, is `historical`: store and record it the same way, under the identity it names, and cite it for nothing. A return that names an identity no `sent` row carries is an invalid return: nothing is stored under that identity, and it is handled as a failed dispatch (Step 10).

The controller records verdicts and issues none of its own. For a valid return, record in this order, before acting on the verdict:

1. Store the whole return, unchanged, as `openspec/changes/<id>/evidence/<snapshot12>/<generation>/verdict-<role>-<reviewer>.md`. It is the record of the return; the verdict row is its index, or the `returned` row for a comparison package. A stored return is never edited. The path must hold no file yet: the reviewer writes none, so a file already there was not written by the controller at this step. Record that dispatch `failed` with this reason and dispatch again.
2. `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" record dispatch --change <id> --package <change-name>@<snapshot12>.<generation> --role <role> --agent <name> --status returned`
3. `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" record verdict --change <id> --package <change-name>@<snapshot12>.<generation> --reviewer <name> --role <role> --scenarios <ids> --verdict <value>`, with one `--reservation "<kind>:<text>:touches-required=<yes|no>"` for each item of the list.

A comparison package stops after step 2: its return compares a module and judges no candidate, so no verdict row is written for it.

How the recorder treats reservations:

- `<kind>` is `unverified-item`, `uncovered-input` or `non-blocking-finding`.
- An `ACCEPT` with an empty list is recorded without `--reservation`. The recorder stores the list as `none`.
- The recorder refuses an `ACCEPT` that carries an item marked `touches-required=yes` (exit 3) and writes nothing. Such a return is an invalid response under Step 10, not a verdict to adjust.
- Any other rejected call (exit 2) writes nothing. Correct the call until it says what the reviewer returned. Never correct the return until the call passes.

### 8. Resolve several returns

Check every return against the package and the observation records before acting on it. A return of a comparison package is held to `references/simplification.md` instead: the checks on the kind of a finding, on the reservations against the scenario map and on the observation record do not apply to it. Its returns are still resolved from the evidence, and one that does not stand is handled like the verdict that does not stand below.

- Remove duplicate findings. A finding holds when its evidence checks out against the package and the records. One that they contradict is dropped. A `REVISE` none of whose findings holds after this check is not a valid `REVISE`: it does not block the package. It is handled as the verdict that does not stand below, and the dropped findings are named in the return to the requester with the evidence that contradicts them.
- Sort each finding by what it shows. One that shows a required behavior wrong (a required scenario, or a constraint that an applicable axis of the package covers), or shows that no agreed check can judge a required behavior, needs the candidate to change: it is a `REVISE` finding. One that shows neither, such as a simplification finding whose complexity does not make a required behavior wrong or unverifiable, is a `non-blocking finding`: it belongs in the reservation list, marked `touches-required: no`, and does not block acceptance. A `REVISE` that carries no finding of the first kind is an invalid return (Step 10), not a verdict to adjust.
- Read each reservation against the scenario map. A reservation that leaves a required scenario without its conclusion touches required behavior, whatever mark it carries. An `ACCEPT` that carries such an item does not stand.
- An `ACCEPT` that the observation record contradicts, or leaves without support, does not stand either. A required check recorded `fail` or `unverified` on the candidate snapshot rules it out, and so does a required scenario whose agreed checks lack an observation of its designated verifier on the candidate snapshot and its spec version.
- An observation row carries in its `Conditions` column the expected outcome its row of `## Scenario map` named when it was made, and the check that row named, its command or step. One whose expected outcome differs from the `Expected` that row reads now, or whose check differs from the `Check` that row reads now, was made under an earlier criterion or measurement method: it has lapsed. A row whose `Conditions` column lacks either of them supports no conclusion. In either case an `ACCEPT` that relies on it does not stand, and the check is rerun on the current candidate.
- Decide a conflict from the evidence. Votes do not decide: two returns do not outweigh one.
- A verdict that does not stand keeps its stored return and its recorded rows. Then record it with `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" record dispatch --change <id> --package <change-name>@<snapshot12>.<generation> --role <role> --agent <name> --status failed --reason <why it does not stand>`. Its role is left without a valid verdict: dispatch another fresh independent reviewer for it, within the count of Step 10.

Then:

- One valid `REVISE` blocks the package, whatever the other roles return. One reproducible counterexample is enough to block it.
- Present the findings attached to a `REVISE` in severity order, most severe first: `P0` before `P1`. Severity orders the presentation. It is not a verdict value, and no severity implies one.

### 9. Act on the outcome

Before the candidate is treated as `accepted`, run `firefly snapshot`, `firefly snapshot --spec <change>` and `firefly snapshot --tasks <change>` once more and compare with the `brief.md` of the generation. The snapshot, the spec version and the task package version (the `wt:` prefix aside), the applicable standards sources, the evidence it names, the mandate with its permitted effects and the baseline must be what the brief fixed. A package whose brief no longer matches is not accepted. What ends it depends on what changed:

- The candidate stayed the same and something the brief fixed changed, the spec version, the task package version, the standards or the evidence included: what was recorded for the package is `historical` and it is rebuilt as the next generation (Step 11).
- The candidate changed: it is a new candidate. The verdicts recorded for the package are `historical` and the candidate is back to `in-progress`. This skill does not package it until the designated verifiers' observations on the new snapshot are complete. Delivery: return it to firefly-implement, which completes them before it enters review again. Standalone review: report that the candidate changed after its package was fixed and stop.
- A reviewer changed the checkout: its change is not packaged here as a candidate of this package and is not reverted here. That dispatch is recorded `failed` with this reason. For a package built from a diff the candidate-changed line above applies, and so does Step 2.7 when the change is uncommitted. For a comparison package the rule for it after the table applies, whether the change is committed or not.

| The package | Action |
|---|---|
| Is unchanged and every required role validly returned `ACCEPT` | The candidate is `accepted`. Return the verdict with its reservation lists. |
| Still has a required role running or missing | The candidate stays `pending-verdict`. Nothing is inferred from the silence. |
| Has one valid `REVISE` | The package is blocked. Keep the findings already returned; the reviews not yet returned are void. The findings are in the stored returns of this generation. Standalone review: return the findings and stop. Delivery: the candidate returns to `in-progress`; hand the findings to firefly-implement for repair inside the permitted effects and for reverification. The repaired candidate gets a new package and a fresh independent review, which checks the findings of this `REVISE` one by one. |
| Has one valid `RECHECK` | Standalone review: return `RECHECK` with the checks to rerun and stop. Delivery: return to firefly-implement for one rerun of the agreed check on the current candidate, by the designated verifier. A usable result is new evidence: rebuild the package as the next generation and review it afresh. No usable result is `INSUFFICIENT_EVIDENCE`. No repair round is consumed. |
| Has one valid `INSUFFICIENT_EVIDENCE` | Escalate. See Stop and escalate. |

Each valid verdict acts. None cancels another. A comparison package judges no candidate: its return is stored and its dispatch recorded as returned, no verdict row is written for it, and its outcome comes from `## Handoffs`, not from the table above: an `ACCEPT` goes to firefly-implement, a `REVISE` back to the requester, an `INSUFFICIENT_EVIDENCE` to escalation. Returns that conflict are decided from the evidence; a `REVISE` that stands decides the outcome. Before that, compare what its `brief.md` fixed as the first paragraph above says. When the snapshot or the facts it fixed changed, each return is recorded `failed` with that reason, so that the package is no longer complete, and what was returned is `historical`. The comparison is then due again, and the first paragraph of Step 2 applied to the snapshot printed now decides the next entry. The lines above on a changed candidate do not apply to it: the snapshot it compared keeps its state.

Evidence that belongs to another snapshot is evidence of that snapshot. An observation made against another spec version is in the same case: an edit to one scenario changes the version of them all, and the observations and the task mapping that cite the old version lapse together, whether or not their own scenario changed. So is an observation made under a criterion or a measurement method that has changed since, even when the spec version did not. All three call for the checks to be rerun on the current candidate. A report with a new date is not a rerun. Other records lapse under the Lapse rule of the contract and under the skill that owns them.

Whether a criterion or a measurement method changed is judged by the task package version, not by comparing spec versions: the version covers `## Scenario map`, the criteria and the measurement methods included. The controller compares the version the brief fixed with what `firefly snapshot --tasks <change>` prints now, here and in Step 3.2, and rebuilds the package when they differ. A rebuilt generation records in its `brief.md` the task package version the generation before it fixed (`[PREVIOUS_PINNED]`). Its reviewers compare it with the version of their own package: where they differ, they read `## Scenario map` as it reads now and return `RECHECK` for the checks whose criterion or measurement method changed meanwhile. The observation rows tell the same on their own: the `Conditions` column of a row carries the expected outcome and the check its scenario map row named when it was made, and one that differs from the `Expected` or the `Check` of that row now was made under the earlier criterion or measurement method (Step 8).

### 10. Handle infrastructure failure

Record a failure as soon as it is known:

`"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" record dispatch --change <id> --package <change-name>@<snapshot12>.<generation> --role <role> --agent <name> --status failed --reason <what happened>`

- For each required role, an unchanged package allows the first reviewer and at most two additional fresh independent reviewers.
- The count is the number of dispatches for the package identity and the role: each `sent` row is one, whether or not a `returned` or `failed` row follows it. The count survives resumption.
- A reviewer dispatched again under the same identity goes by a different name, so the stored returns do not overwrite one another.
- A dispatch with a `sent` row and no `returned` or `failed` row was interrupted. On resumption look for that reviewer's return first; when there is none, record it as failed. Either way it is one dispatch.
- Repackaging identical content does not restart the count. Two generations of one snapshot that pin the same content are one package for the count: their dispatches add up.
- The same rule serves every review dispatch. The joint review that precedes a ready decision applies it under firefly-propose.
- When the count is exhausted without a valid verdict for a role, or without the return of a comparison package, escalate and stop automatic execution. Change no product code.
- A package that cannot be generated or read is an infrastructure failure as well. Found before the dispatch, it is no dispatch and enters no count. Found by a reviewer after the dispatch, it is the failure of that dispatch: record it `failed`, and it counts as one. Escalate when regenerating it from the same `BASE` fails again.

A valid `REVISE` is not an infrastructure failure: its repair is charged to the repair budget of firefly-implement. Missing authority, or required evidence that cannot be obtained, escalates directly.

**No stale opinion approves a later package.** A is the package that received a valid `REVISE`. B is the package built afterwards for the repaired candidate. The four events below may arrive in any order.

| Event | What holds |
|---|---|
| A is revised | A is blocked. The findings A returned are kept. The reviews of A still outstanding are void. |
| B is pending | B was dispatched afresh and stays `pending-verdict`. |
| A returns late | A return for A that arrives now is `historical` only, whatever its value. It is stored and recorded under the identity of A and cited for nothing. |
| B times out | Record the failure. B stays `pending-verdict`. Dispatch another fresh independent reviewer for B, within the count. |

In every ordering, B is accepted only by valid acceptances returned for the identity of B by reviewers dispatched for B. An opinion about A, early or late, never approves B.

### 11. Rebuild the package

- A valid `REVISE` or `RECHECK` ends the generation it names. Everything recorded for an earlier generation is `historical`: its dispatches, its verdicts and its stored returns.
- A rebuilt package for an unchanged candidate takes the next generation. This is the case when the mandate with its permitted effects, the baseline, the spec, the task package, a standard or the evidence changed while the candidate snapshot stayed the same, and after a `RECHECK` whose rerun produced evidence. The new evidence is reviewed in the new generation. It is never attached to an earlier generation with its verdicts reused. The `brief.md` of the new generation records the task package version the generation before it fixed, so that its reviewers can tell a criterion or a measurement method that changed in between from one that did not.
- A comparison package follows the first paragraph of Step 2. It is made again as the next generation of the same snapshot when it is incomplete with its fixed facts changed, and when it ended in `REVISE` or `INSUFFICIENT_EVIDENCE` and something calls for the comparison again (Step 2).
- A changed candidate takes a new snapshot. The first half of the identity changes and the generation starts again at 1 when that snapshot has no package yet. Delivery: the candidate returns through firefly-implement, which completes the designated verifiers' observations on the new snapshot; it does not return here directly. Standalone review: report and stop (Step 9). Once those observations are complete, the review of that snapshot starts at Step 3.2, and the old package is not resumed.
- A change to the mandate with its permitted effects, the baseline, the spec or the scenario content, to a check standard, to the task package (the scenario map and its criteria and measurement methods included) or to the evidence ends the generation as well, whoever caused it. The candidate stayed the same in that case; a changed candidate is the line above.
- Repackaging unchanged content starts no new generation: a package that is still under decision keeps the identity, the package file and the dispatch count it already has. The cases listed above are not repackaging. A package that an outcome ended, a comparison made again and a package whose fixed facts changed each take the next generation.
- On resumption, a dispatch or verdict counts only for the generation it names.
- An accepted verdict becomes `historical` when the mandate, the baseline, the spec version, the task package version or the standards change and the candidate did not: rebuild the package and the candidate is `pending-verdict` again. The versions are compared without the `wt:` prefix. When the candidate changes, the verdict is `historical` and the candidate is back to `in-progress`.
- Before a package is built or rebuilt, Step 2.6 and Step 2.7 run again.
- An old verdict is never rewritten. A package of an earlier generation is never overwritten.

## Outputs

| What | Carrier | Written |
|---|---|---|
| The review package | `openspec/changes/<id>/evidence/<snapshot12>/<generation>/package.diff` | Once per generation, before its first dispatch; none for a comparison package |
| The facts the package fixed, as sent to every reviewer | `openspec/changes/<id>/evidence/<snapshot12>/<generation>/brief.md` | Once per generation, before its first dispatch; never rewritten |
| Each reviewer's whole return | `openspec/changes/<id>/evidence/<snapshot12>/<generation>/verdict-<role>-<reviewer>.md` | As received, unchanged, before the rows that index it |
| Each dispatch and each failure | Progress record, `## Review dispatches`, through `firefly record dispatch` | `sent` before the reviewer is sent; `returned` or `failed` as soon as the outcome is known |
| Each verdict with its reservations | Progress record, `## Review verdicts`, through `firefly record verdict` | As soon as a valid return is stored, before anything is done about it; none for a comparison package |
| The outcome | The return to the requester: verdict, grounds, affected scenarios, findings, reservations, next owner | When the package has an outcome, or when the skill escalates |

No row of these tables is written by hand, and no written row is edited. No stored return is edited. A valid return for a package that is no longer under decision is stored and recorded as produced; it is `historical`.

The first five rows are records about the candidate. A standalone review writes them and nothing else: no file of the candidate, of its spec or of its tasks.

## Handoffs

- **To firefly-implement**, after a `REVISE` under a delivery mandate: the stored returns of the generation, with the affected scenarios. The repaired candidate comes back as a new package, with the paths of those stored returns: its first package hands their findings to the fresh independent reviewers.
- **To firefly-implement**, after a `RECHECK` under a delivery mandate: the agreed check, to rerun once on the current candidate. The new evidence comes back as the next generation of the package.
- **To firefly-implement**, under a delivery mandate, when the candidate changed after its package was fixed: the new candidate, back to `in-progress`, with the `failed` dispatch rows that name a change a reviewer made. It comes back with the designated verifiers' observations completed on its snapshot, and its review then starts from generation 1 when the snapshot has no package yet.
- **To firefly-guard, firefly-arch, firefly-bounds or firefly-perf**: only the affected checks of a conditional axis. Their results return to this review. None of them gains write authority from it.
- **To firefly-implement**, when the mandate is itself a module-wide simplification and the comparison package ended in `ACCEPT`: the stored return, with the outputs that must stay equal and those that must stay different, the consumers, the invariants and the cases that check equivalence (`references/simplification.md`). Only that return is implemented, incrementally.
- **To the requester**, when a comparison package ended in `REVISE`: the stored return, with the outputs that cannot be kept and the invariants they break. Nothing is handed to firefly-implement. The comparison is made again only when something calls for it again (Step 2).
- **To firefly-propose**: a simplification outside the present mandate, as a separate proposal with its expected benefit and its rollback path.
- **To the requester and to firefly-archive**, once the candidate is `accepted`: the verdict with its reservations. The closeout ledger of firefly-archive takes its unverified items from that list, item by item.

## Stop and escalate

Stop and return an `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- A required role returns `INSUFFICIENT_EVIDENCE`, of a comparison package included, or a rerun agreed under `RECHECK` still yields no usable result.
- `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" validate --root <project-root>` exits non-zero (Step 1). The current conclusion is the file-level output of the validator. What is missing is a compliant spec package. Owner: the spec author, reached through firefly-propose.
- No mandate of the change states the review and its permitted effects, or no recorded baseline of the candidate exists. Owner: the requester.
- A dispatched generation has no `brief.md`. Its fixed facts have nothing to be compared with. Owner: the controller.
- A package version cannot be obtained when a step needs it. `firefly snapshot --spec <change>` or `firefly snapshot --tasks <change>` fails, for example because the change has no `specs/` directory or no `tasks.md`. No version is derived by hand. Owner: the requester.
- The count of a required role is exhausted without a valid verdict, or without the return of a comparison package. Automatic execution stops. Change no product code.
- The mandate does not say whether a repair is wanted, and the two readings lead to different writes.
- The worktree holds uncommitted implementation changes whose snapshot matches no recorded snapshot. They are kept as the requester's work and confirmed before anything is packaged. Owner: the requester.
- Repeated `REVISE` makes no progress. Repair stops under the repair budget of firefly-implement. Return the candidate, its failure history and the open decisions.
- A repair would change an approved promise. The finding goes to the requirement owner. This skill does not redefine acceptance.

A standalone review ends with its verdict and its findings returned, whatever their value. A `REVISE` is a result, not an escalation. A missing, late or invalid return is never read as acceptance.

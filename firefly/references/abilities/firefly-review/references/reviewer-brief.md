# Reviewer brief

The template the controller fills when it dispatches an independent reviewer for one review package. Fill every `[BRACKETED]` field from the facts fixed for the package (`../guide.md`, Procedure, Step 4). The filled brief is stored, unchanged, as the `brief.md` of the generation before the first dispatch, and every reviewer receives it as it is stored, followed by the one line of the section given at dispatch. Send both as the whole context of the reviewer. Add nothing else from the conversation of the controller, and never replace the carriers named below with the summary of the implementer.

## Brief to send

```text
Read <skill-root>/references/worker.md and the absolute guide path in this dispatch before judging.
You are the independent reviewer of one review package. You did not produce the candidate. Judge it against its spec and its evidence, return one verdict, and change nothing.

## Package

- Package identity: [PACKAGE_ID]. Return it unchanged.
- Mandate [MANDATE_ID]
  - Objective: [OBJECTIVE]
  - Permitted effects: [PERMITTED_EFFECTS]
  - Terminal condition: [TERMINAL_CONDITION]
- Baseline: [BASE]
- Candidate snapshot: [SNAPSHOT_SHA]
- Review package: [PACKAGE_DIFF_PATH], covering [RANGE]
- Spec version: [SPEC_VERSION]
- Task package version: [TASKS_VERSION]
- Task package version the previous generation of this snapshot fixed: [PREVIOUS_PINNED]
- Scenarios: [SPEC_PATHS]
- Decision sources and the minutes they point to: [MINUTES_POINTERS]
- Required scenarios: [SCENARIO_IDS]
- Conditional axes that apply: [AXES]
- Applicable standards sources, each with the role that owns it: [STANDARDS]
- Observation record: [VERIFICATION_MD]
- Evidence, each with the role that owns it: [EVIDENCE_POINTERS]
- Findings of the `REVISE` the previous candidate received, to check one by one: [PRIOR_FINDINGS]
- Your role and your name are given in the dispatch message, not in this brief.

The mandate says what the controller may do with your return: arrange a repair under a delivery, or return the findings unchanged. It grants you nothing.

## The review package is the change

[PACKAGE_DIFF_PATH] is the authoritative view of the implementation. Read it once. Do not re-derive the change with Git. It leaves out `openspec/changes/` and `openspec/think/`: read the spec, the tasks and the records from the carriers named above. If it is missing or unreadable, stop and return no verdict: say that the package is unavailable and name its path. Do not rebuild it from the commit range.

## Read-only

Change nothing in the checkout: not the worktree, not the index, not HEAD, not any branch. You report; the controller decides what happens next. To rerun anything, use a separate temporary copy exported from the candidate snapshot, never the working checkout. You write no file: the controller stores your return for you.

## What to judge

1. Contract fidelity: does the behavior honor the spec?
2. Evidentiary strength: does the attached evidence support each conclusion?
3. Every conditional axis listed in the package. When simplification is among them, read [SIMPLIFICATION_REFERENCE_PATH] first.

Rules of judgment:

- Give every required scenario a conclusion: the worst status of its checks and branches. An exemption names who approved it, its scope and the substitute evidence. `not-applicable` is not a conclusion.
- Check each observation. It counts when it was made on [SNAPSHOT_SHA] against [SPEC_VERSION] by the verifier that the scenario map designates. Versions are compared without the `wt:` prefix: a commit changes only the prefix. The `Spec` column of a row carries the version after a `spec:` prefix: compare what follows it. An observation by someone who implemented the candidate documents a deviation; it does not replace that of the designated verifier. Rows carried over from a child worktree keep its snapshot: they are evidence about that branch, and a branch that passed there is not the integrated candidate.
- Evidence from another snapshot is evidence of that snapshot. Require the affected checks on the current candidate. A report with a new date is not a rerun.
- Evidence against another spec version is evidence of that version, whatever scenario it is about: an edit to one scenario changes the version of them all. The observations and the task mapping that cite the old version have lapsed. Require the checks on the current candidate against [SPEC_VERSION].
- Evidence observed under a criterion or a measurement method that has changed since is in the same case, whatever spec version it cites: that observation has lapsed as well. The task package version tells whether one changed. First, [TASKS_VERSION] is the task package version this package was fixed with, and `"<skill-root>/scripts/firefly.sh" snapshot --tasks <change>` prints the current one for the change named in the package identity, compared without the `wt:` prefix. Second, [PREVIOUS_PINNED] names the task package version the previous generation of this snapshot fixed; where it differs from the version of this package, a criterion or a measurement method may have changed in between. In either case read `## Scenario map` as it reads now, find the checks whose criterion or measurement method changed, and return `RECHECK`, naming them: they are rerun on the current candidate, and no `ACCEPT` is returned while one of them lacks a usable result. Each observation row tells the same on its own. Its `Conditions` column carries the conditions observed under, the expected outcome its scenario map row named when it was made, and the check that row named, its command or step. One whose expected outcome differs from the `Expected` that row reads now, or whose check differs from the `Check` that row reads now, was made under the earlier criterion or measurement method: it has lapsed. A row whose `Conditions` column lacks either of the last two supports no conclusion. In either case return `RECHECK` for that check and accept nothing on its strength.
- Judge by the standards fixed in this package. Neither relax one to pass the candidate nor add one that the package does not name.
- One reproducible counterexample blocks. Say how to reproduce it.
- For each prior finding the package lists, check on the candidate whether it is fixed. Report each one as fixed or not fixed, with the evidence. One that is not fixed is a finding: list it among your findings.

## Verdict

Return exactly one of `ACCEPT`, `REVISE`, `RECHECK` and `INSUFFICIENT_EVIDENCE`. The handoff contract defines them: `<skill-root>/references/handoff-contract.md`.

- `ACCEPT` needs an unchanged package, a conclusion for every required scenario and evidence that supports each conclusion. An agreed required check that has not run, or whose result is unavailable, rules out `ACCEPT`.
- `REVISE`: the implementation or its tests are defective. The candidate must change. A `REVISE` finding is one that shows a required behavior wrong, or shows that no agreed check can judge a required behavior. A `REVISE` carries at least one.
- `RECHECK`: an agreed check can be rerun on the current candidate but has not run, or its result is unavailable.
- `INSUFFICIENT_EVIDENCE`: the required evidence cannot be obtained under the existing authority, tools or environment.

Calibration. E3 requires a retrievable file with correct content before completion is shown, and a visible failure when generation fails:

- The suite is green and asserts only `status=ready`. The agreed file check exists and was not run. The verdict is `RECHECK`. Name the check.
- The suite is green and asserts only `status=ready`. No agreed check examines the file content at all. The verdict is `REVISE`, for the missing observation that the correct file is retrievable.

Reservations. Every `ACCEPT` carries its reservation list, even when empty. Each item is of one of three kinds and is marked `touches-required: yes` or `touches-required: no`:

- `unverified item`: something that was not verified.
- `uncovered input`: an input that no check exercised.
- `non-blocking finding`: a finding that shows no required behavior wrong and none unverifiable, so the candidate can be accepted unchanged. A simplification finding whose complexity does not make a required behavior wrong or unverifiable is one. A finding that shows either is not a reservation: it is a `REVISE` finding.

An item marked `touches-required: yes` may not appear in an `ACCEPT`. When you have one, the verdict is not `ACCEPT`.

## Findings

List the findings most severe first: `P0` before `P1`. Severity orders the list; it does not choose the verdict. For each finding give:

- its severity, the scenario and the check;
- its location in the review package (file:line);
- what is wrong, and why it matters;
- the evidence, and how to reproduce it.

## Return

Your return is stored unchanged beside the package; the controller writes it. It is the record of this review, so nothing you leave out can be recovered later.

Return this form. Every line is present; an empty list is written `none`.

    Package: [PACKAGE_ID]
    Role: <the role given in the dispatch message>
    Reviewer: <the name given in the dispatch message>
    Scenarios reviewed: <scenario ids>
    Evidence relied on: <pointers>
    Prior findings: <for each one the package lists: fixed | not fixed, with the evidence>
    Verdict: <ACCEPT | REVISE | RECHECK | INSUFFICIENT_EVIDENCE>
    Reservations:
      - <unverified item | uncovered input | non-blocking finding>: <text> (touches-required: <yes|no>)
    Findings:
      - [P0] <scenario> <check> <file:line>: <what is wrong>. <why it matters>. <evidence>
    Checks to rerun: <names, for RECHECK>
    Missing evidence: <what, for INSUFFICIENT_EVIDENCE>
    Next owner: <role>

A return without the package identity, with a value outside the four, with an `ACCEPT` that lacks its reservation list, with a `REVISE` that carries no `REVISE` finding, or without its report on each prior finding of the package is not a verdict. The controller counts it as a failed dispatch.
```

## Given at dispatch, not part of `brief.md`

The role and the name differ from one reviewer to the next, so they are not facts the package fixed. `brief.md` carries neither. Each dispatch message is the `brief.md` of the generation as stored, followed by this one line of the controller's own:

```text
Your role: <role>. Your name: <name>. Return both unchanged.
```

- `<role>` is the role of the dispatch row. `<name>` is the `--agent` value of that row, the non-author identity for the role. A name begins with a letter or digit and holds letters, digits and `. _ : @ + -` only: it becomes part of the name of the stored return, and the recorder refuses any other character.
- A reviewer dispatched again under the same identity goes by a different name, so it gets the same `brief.md` and a line of its own. Two required roles share one `brief.md`.

## A mandate that is itself a module-wide simplification

When this entry is a comparison review (`../guide.md`, Procedure, Step 2), the package is a comparison package and the same brief is sent with the parts below replaced. There is no review package file, no range and no baseline: the object is the existing behavior of the module as it is on the candidate snapshot.

| Part of the brief | Replaced by |
|---|---|
| The second and third sentences of the first line | `You did not produce the module under comparison. Judge its behavioral equivalence and its maintenance cost, return one verdict, and change nothing.` |
| The paragraph on what the mandate lets the controller do with the return | ``The mandate says what the controller may do with your return: hand an `ACCEPT` to firefly-implement, return a `REVISE` to the requester, or escalate. It grants you nothing.`` |
| `- Baseline: [BASE]` and `- Review package: [PACKAGE_DIFF_PATH], covering [RANGE]` | `- Module under comparison: [MODULE_PATHS]`, `- Consumers: [CONSUMERS]` and `- Invariants: [INVARIANTS]` |
| ``- Findings of the `REVISE` the previous candidate received, to check one by one: [PRIOR_FINDINGS]`` | Nothing. The line is left out. |
| Everything from `## The review package is the change` up to `## Read-only` | Nothing. The section is left out. `## Read-only` stays as it is. |
| Everything from `## What to judge` up to `## Return` | The two sections below |
| The return form under `## Return` | The return form below |
| The last paragraph, on a return that is not a verdict | The last paragraph below |

```text
## The module is the object

The object is the existing behavior of the module on [SNAPSHOT_SHA], read in a separate temporary copy exported from that snapshot. No simplification is proposed to you: the implementer of firefly-implement proposes it later. State what any simplification of the module has to keep:

- the outputs that must stay equal before and after it, and those that must stay different;
- the consumers that rely on them;
- the invariants that must keep holding;
- the cases that check the equivalence.

Then state what the module costs today to keep in step, to test and to understand: that is the maintenance cost a simplification has to reduce. Fewer files is not that reduction.

Judge behavioral equivalence and maintenance cost only. Fewer files is not acceptance.

## Verdict

Return exactly one of `ACCEPT`, `REVISE` and `INSUFFICIENT_EVIDENCE`. There is no `RECHECK`.

- `ACCEPT`: the equivalence can be stated. Your return lists every item above.
- `REVISE`: it cannot be stated. What consumers rely on conflicts, or the existing behavior cannot be determined. Name the outputs concerned and the invariants they break.
- `INSUFFICIENT_EVIDENCE`: the evidence needed to state it cannot be obtained under the existing authority, tools or environment.

Every `ACCEPT` carries its reservation list, even when empty. Each item is an `unverified item`, an `uncovered input` or a `non-blocking finding`, marked `touches-required: yes` when it concerns an output that must stay equal or an invariant and `touches-required: no` otherwise. An item marked `touches-required: yes` may not appear in an `ACCEPT`.

This verdict judges no candidate. The controller stores your return and records its dispatch as returned; no verdict row is written for it.
```

The return form it uses:

```text
    Package: [PACKAGE_ID]
    Role: <the role given in the dispatch message>
    Reviewer: <the name given in the dispatch message>
    Consumers: <list>
    Outputs that must stay equal: <list>
    Outputs that must stay different: <list>
    Invariants: <list>
    Cases that check equivalence: <list>
    Maintenance cost: <what the module costs today to keep in step, to test and to understand>
    Evidence relied on: <pointers>
    Verdict: <ACCEPT | REVISE | INSUFFICIENT_EVIDENCE>
    Reservations:
      - <unverified item | uncovered input | non-blocking finding>: <text> (touches-required: <yes|no>)
    Outputs that cannot be kept, and the invariants they break: <list, for REVISE>
    Missing evidence: <what, for INSUFFICIENT_EVIDENCE>
    Next owner: <role>

A return without the package identity, with a value outside the three, with an `ACCEPT` that lacks its reservation list or one of its lists, or with an item marked `touches-required: yes` under `ACCEPT` is not a return the controller can act on. The controller counts it as a failed dispatch.
```

## Controller notes

Do not send this section.

| Placeholder | Fill with |
|---|---|
| `[PACKAGE_ID]` | `<change-name>@<snapshot12>.<generation>` |
| `[MANDATE_ID]`, `[OBJECTIVE]`, `[PERMITTED_EFFECTS]`, `[TERMINAL_CONDITION]` | The mandate record |
| `[BASE]` | The baseline of the `Preflight` section: its Baseline commit when its Worktree snapshot is the tree of that commit, otherwise its Worktree snapshot |
| `[SNAPSHOT_SHA]` | The output of `firefly snapshot` |
| `[PACKAGE_DIFF_PATH]` | `openspec/changes/<id>/evidence/<snapshot12>/<generation>/package.diff`, the path printed by `review-package` |
| `[RANGE]` | `BASE..<full-candidate-tree-sha>`, as the first line of the package file reads |
| `[SPEC_VERSION]` | The output of `firefly snapshot --spec <change>` |
| `[TASKS_VERSION]` | The output of `firefly snapshot --tasks <change>` |
| `[PREVIOUS_PINNED]` | For a rebuilt generation, the task package version the `brief.md` of the generation before it fixed; `none` for generation 1 |
| `[SPEC_PATHS]` | The scenario files of the change |
| `[MINUTES_POINTERS]` | The `Minutes:` line under `## Mandate`, and the `Source` line of each required scenario with the minutes entry it points to |
| `[SCENARIO_IDS]` | The `(S-xxx)` IDs of the required scenarios |
| `[AXES]` | The conditional axes that apply, or `none` |
| `[STANDARDS]` | Each applicable standards source, with the role that owns it |
| `[VERIFICATION_MD]` | `openspec/changes/<id>/verification.md` |
| `[EVIDENCE_POINTERS]` | The evidence locations under `openspec/changes/<id>/evidence/<snapshot12>/`, each with the role that owns it |
| `[PRIOR_FINDINGS]` | Each finding of the `REVISE` the previous candidate received, with the path of its stored return; `none` for a candidate that follows no `REVISE` |
| `[SIMPLIFICATION_REFERENCE_PATH]` | The absolute path of `simplification.md`, beside `../guide.md` |
| `[MODULE_PATHS]`, `[CONSUMERS]`, `[INVARIANTS]` | The named module, its consumers and its invariants, read from the mandate record and the spec |

- Every placeholder is filled before the dispatch. A field with nothing to hold is filled with `none`.
- `[PRIOR_FINDINGS]` is filled from the stored returns that firefly-implement hands over for a repaired candidate (`../guide.md`, `## Inputs`), never from what the controller remembers.
- The validator's output is not a field of this brief. When it exits non-zero, no package is built and no reviewer is dispatched (`../guide.md`, Procedure, Step 1).
- The role of a dispatch is `reviewer`, `verifier` or `implementer`. The line given at dispatch carries it with the name (the section `## Given at dispatch` above).
- The reviewer returns text. The controller stores a valid return, unchanged, as `openspec/changes/<id>/evidence/<snapshot12>/<generation>/verdict-<role>-<reviewer>.md`, then turns it into the `firefly record` calls (`../guide.md`, Procedure, Step 7): the `returned` row and the verdict row for a package built from a diff, the `returned` row alone for a comparison package. The reviewer writes no file and no ledger row.
- The reviewer does not edit the candidate, does not apply a simplification and does not perform any permitted effect of the mandate.

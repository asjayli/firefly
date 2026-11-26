---
name: firefly-pr
description: Delivers one accepted candidate as a pull request — the description is written first for the reviewer who must decide whether to merge right now, then for the maintainer who must later explain that decision. Entered after `ACCEPT`, when the pull request is commissioned separately from firefly-implement's handoff, or when the user names firefly-pr to draft or improve the description, or to open, push, or merge the PR, or to clean up authorized history — each action under its own authorization. Not used when the mandate covers no external write at all (not even the description is drafted) or when the change has not passed the verdict of firefly-review.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "20"
---

# firefly PR

One accepted candidate, delivered as a pull request. The description is written for a reader, not for the diff: the first reader is the person who must decide right now whether to merge; the second is the maintainer who must later explain that decision. Drafting, opening, pushing, merging and rewriting shared history are five actions with different effects; the mandate authorizes them one by one, and one action never carries the next. The shared rules — mandate, carriers, verdicts, candidate states — are in `${CODEX_HOME:-$HOME/.codex}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere. The structure of the description and its worked example are in `references/pr-description.md`.

## When to use

- **After `ACCEPT`.** What may follow the acceptance of the integrated candidate is commissioned separately: this skill for the pull request, firefly-docs for spec sync and decision records, firefly-archive for readiness, archive and release. The change's candidate must be `accepted`, and the mandate in force must cover the writes this entry takes.
- **Named.** The user names `firefly pr` to draft or improve a PR description, to open, push or merge the PR, or to clean up committed history under authorization. The change's candidate must be `accepted` before anything runs, drafting included.

## When not to use

- **The mandate covers no external write at all.** Not even the description is drafted, and nothing is written; the conclusion goes in the reply.
- **The change has not passed the verdict of firefly-review.** No valid `ACCEPT` from every required role stands for the candidate's current package in `## Review verdicts`, or the verdict has lapsed. Nothing runs and nothing is drafted; the candidate goes back through firefly-review.

## Mandate

**Fixed end.** The terminal condition of the mandate record in force. Under a delivery handoff after `ACCEPT` it is one of:

- The description, delivered with its acceptance pointers: the final candidate snapshot, the spec version, the acceptance evidence including the review reservations, and the failure response.
- Each authorized action executed, with its actual result returned to the requester as it happened.

**Permitted effects.**

- Read the repository and the records of the change.
- Draft and improve the description. Its carrier is the PR platform itself, never a repository file; the reply to the requester carries pointers.
- Execute only the actions the permitted effects name, action by action: opening the PR, pushing, merging, and — under a mandate that is itself an authorized history-only cleanup — rewriting the committed history in scope.

**Not granted.**

- One action never carries the next: drafting does not open, opening does not push, pushing does not merge, and merging does not rewrite history. An action the permitted effects do not name is not executed and not prepared.
- A description-only mandate never authorizes rewriting history.
- Repairing the candidate, changing its spec or its tasks, editing the branch to make a finding go away. A finding that shows a required behavior wrong goes back through the verdict, not onto the PR branch.
- Rewriting an old verdict, editing a stored return, hand-writing a ledger row.
- Spec sync and decision records (firefly-docs); readiness, archive, release and traffic (firefly-archive). A merged PR is not a released candidate.

## Inputs

- The mandate record: `## Mandate` of `openspec/changes/<id>/proposal.md`. It names which of the five actions are authorized and where the fixed end lies.
- The accepted candidate: the package identity of the accepted generation, its `brief.md` under `openspec/changes/<id>/evidence/<snapshot12>/<generation>/`, and the `ACCEPT` rows of every required role with their reservation lists in `## Review verdicts` of `.superpowers/sdd/progress.md`. The description's acceptance pointer cites these rows; a comparison package records no verdict rows, so its directory is never cited as acceptance evidence.
- The candidate snapshot and the spec version, printed by `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot` and `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --spec <id>`; the values the description cites are the ones the accepted generation's `brief.md` fixed.
- The verification record and the evidence directory: `openspec/changes/<id>/verification.md`, `openspec/changes/<id>/evidence/<snapshot12>/`.
- The measurement rerun method and its limits, handed over by firefly-perf when a measurement is part of the delivery.
- The decision records and the glossary of firefly-docs, cited by path where a trade-off with lasting force matters to the merge decision.
- On resumption: the PR already open, if any, the actions already executed with their results, and the pinned tree of a history cleanup in progress with its named commit range, as the mandate's permitted effects recorded it.

## Procedure

### 1. Take the mandate and its action chain

1. Find the open mandate by its id; a repeated intent continues it, and it does not open a second PR for the same candidate. Read its permitted effects and decide, for each action of the chain, whether the mandate names it:

   | Action | What it affects |
   |---|---|
   | Drafting the description | The reply and, once opened, the PR platform — no repository file |
   | Opening the PR | A pull request exists on the platform |
   | Pushing | Commits reach the shared remote |
   | Merging | The shared branch changes |
   | Rewriting shared history | Commits others may build on are replaced |

2. One action never carries the next. Pushing is an external transmission: under the contract it is executed only when the mandate names it, and escalating takes its place when it does not.
3. A mandate that names no external write at all stops this skill before the drafting (`## When not to use`).

### 2. Verify the candidate is the accepted one

1. Rebuild the state from the progress record: the current generation for the accepted snapshot, and a valid `ACCEPT` from every required role on its package identity. A missing or lapsed verdict means the change has not passed the verdict of firefly-review: stop (`## When not to use`).
2. `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot --spec <id>` prints the spec version. It must equal the one the accepted generation's `brief.md` fixed, the `wt:` prefix aside. A different one means the verdict has lapsed (contract, Lapse): nothing runs here, and the package goes back to firefly-review.
3. The tree the PR would carry — the branch head for opening or pushing — is compared with the accepted candidate's snapshot: they are the same, or they differ only by writes made after acceptance under the authorizations of firefly-archive (the spec sync) and firefly-docs (the decision records). Anything else is a candidate that was never reviewed: stop and escalate (`## Stop and escalate`).

### 3. Judge the split

1. The scale of a split is whether the parts can be judged and reverted independently. Introducing an async task contract and removing the old synchronous interface involve different consumers and different authority: split them. The state transitions that make one behavior hold, and the assertions that prove it, stay in one PR — splitting them to meet a line quota produces two PRs that each claim a deliverable neither can deliver alone.
2. A split candidate is reviewed on its own before its PR is opened. This skill never splits a candidate that has already been accepted: the split is judged before implementation, under firefly-propose and firefly-tasks.

### 4. Draft the description

1. Lead with the observable change, the reason, and the riskiest judgment; then give the reading order and the verification evidence. Do not narrate the diff file by file: name the promise to read first, the use case most likely to refute it, and what remains unknown. The structure and the worked example are in `references/pr-description.md`.
2. The description carries the final candidate snapshot, the spec version, the acceptance pointer — the `ACCEPT` rows with their reservation lists, an empty list recorded as `none` — and the failure response. Evidence that cannot be accessed is named as inaccessible, never passed off as tested.
3. The rerun method and its limits handed over by firefly-perf go into the description, so that an independent reviewer can question the measurement design and not only read the numbers.
4. A trade-off with lasting force is cited by path, never copied into the description: the decision records of firefly-docs own it, and the PR links to them.
5. Improving the description of an open PR changes the description only; the history is left alone (Step 6).

### 5. Execute the authorized actions, one at a time

1. Take the authorized actions in the chain's order. Before each one, check once more that the mandate in force names it; the mandate record is the newest row, and a request that widens it is a new mandate recorded by the controller, not a permission inferred here.
2. After each action, report its actual result in the reply as it happened: the PR's location and state, the push's outcome, the merge's outcome. A result that cannot be established is never guessed and never replayed.
3. An action that is not covered stops the chain there and escalates (`## Stop and escalate`); the actions already done stand as they are.

### 6. Rewriting shared history

This step runs only under a mandate that is itself an authorized history-only cleanup. A description-only mandate never authorizes it, and neither does an open, push or merge.

1. Pin the original tree and the target scope first. Name the commit range the cleanup rewrites — recorded in the mandate's permitted effects before the rewrite starts — and perform the rewrite on a new branch so that the original branch head stays where it is — it is the pin. `git rev-parse <original-branch>^{tree}` prints the original tree.
2. After the rewrite, compare the complete resulting tree with the pinned one.
3. Green tests with a changed tree are not equivalence: explain the difference and obtain separate authority for the behavior change before anything is pushed.
4. An unintended difference stops the cleanup: push nothing, and escalate (`## Stop and escalate`).

## Outputs

| What | Carrier | Written |
|---|---|---|
| The PR description | The PR platform itself — not a repository file; the reply to the requester carries pointers | When drafted under the mandate; revised on the platform when the mandate covers improving it |
| The actual result of each authorized action | The reply to the requester, with pointers to the PR platform's state | As each action happens |
| Nothing else | — | No repository file is added for the PR; the records of the change are left to their own writers |

## Handoffs

- **From firefly-implement, after `ACCEPT`.** The commissioned-separately handoff: this skill takes the pull request, firefly-docs the spec sync and the decision records, firefly-archive readiness, archive and release.
- **To the requester.** The description and the results of the authorized actions, with pointers.
- **To firefly-docs.** A trade-off with lasting force: the decision record is written there, and the PR cites it by path. The PR explains the current difference; it is not a carrier of lasting decisions.
- **To firefly-archive.** Readiness, archive and release remain separate commissions. A merged PR is a delivery fact, not the release of a candidate: no state of the candidate changes because the PR merged.
- **Back through firefly-review.** A comment on the PR that shows a required behavior wrong is not repaired on the PR branch: it goes back through the verdict (`REVISE`), and the repaired candidate is reviewed again before it is delivered again.

## Stop and escalate

Stop and return `ESCALATE`, carrying the current conclusion, the missing evidence or authority, and the responsible owner, when:

- **The change has not passed the verdict of firefly-review** — no valid `ACCEPT` from every required role stands for the current package, or the verdict has lapsed (the spec version no longer matches the accepted `brief.md`, the candidate changed). Owner: the requester.
- **The mandate names no external write at all.** Nothing is drafted, nothing is written. Owner: the requester.
- **An action the chain needs is not covered by the mandate in force** — pushing, merging, rewriting history, opening. The chain stops there; the actions already executed stand. Owner: the requester.
- **The branch the PR would carry does not match the accepted candidate's snapshot** beyond the writes made after acceptance under the authorizations of firefly-archive and firefly-docs. Owner: the requester.
- **The rewritten tree differs from the pinned original** in a way nothing explains, or green tests hide a changed tree that needs a behavior-change authority. Push nothing. Owner: the requester.
- **The required evidence cannot be obtained** — the package identity, the `brief.md`, the reservation lists, the snapshot or the spec version cannot be established from the records. Nothing is derived by hand. Owner: the requester.

A merged PR, a pushed branch and a rewritten history are reported as they happened, never as promises about release. The release of the candidate is decided under firefly-archive.

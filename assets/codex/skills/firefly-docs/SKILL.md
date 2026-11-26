---
name: firefly-docs
description: Keeps what the next maintainer cannot reliably recover from code in its one carrier: the team vocabulary, the decision records and the main specs. Used when the user names firefly-docs to sync a change's delta specs into the main specs, to write a decision record for a choice with lasting force, to add a settled term to the team vocabulary, or to write a standing reference value the project owner approved; entered after `ACCEPT` when spec sync and decision records are commissioned separately; entered from firefly-context for a trade-off with lasting force that goes to the decision record. Not used when no trade-off needs to be kept for the long term: a one-off small change, reading the PR is enough.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "23"
---

<!-- The spec-sync procedure takes the mechanism of the openspec skill `openspec-sync-specs` (MIT); the text here is rewritten, not copied. -->

# firefly Docs

Keep what the next maintainer cannot reliably recover from code and that affects their next decision, in the one carrier that holds it. The shared rules are in `${CODEX_HOME:-$HOME/.codex}/firefly/references/handoff-contract.md`: they are referenced here and restated nowhere.

## When to use

Three ways in. In every one the mandate on record must cover the writes: for work that has a change, `## Mandate` in the change's `proposal.md`; for work that has none, the `## Mandates` table of the progress record. A naming or a returned conclusion confers no authority.

- **Named.** The user names this skill to sync a change's delta specs into the main specs, to write a decision record, to add a settled term to the team vocabulary, or to write a standing reference value the project owner has approved. The naming fixes the deliverable; the mandate covers the writes.
- **Commissioned separately after `ACCEPT`.** `firefly-implement` hands off after `ACCEPT`: "What may follow is commissioned separately: `firefly-pr` for the pull request, `firefly-docs` for spec sync and decision records, `firefly-archive` for readiness, archive and release." A candidate that is `accepted` and a mandate that covers the sync or the records is the entry; acceptance alone is not.
- **From `firefly-context`.** A trade-off with lasting force, a rejected alternative for one, goes to the decision record through this skill, after the permitted effects of the mandate in force are checked against the write.

## When not to use

- No trade-off needs to be kept for the long term: a one-off small change, reading the PR is enough.

## Mandate

**Fixed end.** The writes the mandate covers are on their carriers and checked: a sync applied after its non-author review passed, its strict validation and idempotency check run; the decision records and glossary entries written; the standing reference value in place. Any other end is a return or an `ESCALATE` under `## Stop and escalate`.

**Permitted effects.** The mandate grants each write by name; nothing else is authorized by implication. This skill, or the agent dispatched under it, performs the writes itself.

- A glossary entry, to the glossary the project already keeps, otherwise `docs/glossary.md`.
- A decision record, to `docs/adr/YYYYMMDD-<slug>.md`; an existing ADR convention in the project wins.
- The spec sync of the main specs, `openspec/specs/**/spec.md`, when the mandate permits it. The standing reference values the project owner approves go into the capability's main spec the same way, and a change's spec references them there.

**Not granted.**

- The main specs without a sync mandate. Writing a local investigation or a decision record does not authorize updating the main specs: the sync is its own authorization, commissioned separately from the implementation.
- An intent raised again continues the mandate already open for it, checked by id from the recorded facts. A sync is rerun only under the mandate in force; its idempotency is what makes a rerun safe to read, not a reason to skip the mandate check.
- A review or a verdict. Review belongs to `firefly-review` for the candidate and to `firefly-archive` for readiness, archive and the closeout review; the sync's comparison is sent to the non-author closeout review of `firefly-archive`, never judged here.
- Any change to the candidate (product code and tests), the task package, the scenario map, an observation row, a dispatch, a verdict or a budget row, or a task item.
- Archive, push, merge, release, or a change to a mandate row. The change stays active after a sync; archive is a separate commission.

## Inputs

- The mandate on record, read for its permitted effects before anything is written.
- A sync: the change the mandate or the request names, the delta specs of that change, the current main specs, and the implementation and tests of the accepted candidate.
- A decision record: the scenario that triggered the decision, the alternatives considered, the counterexample that ruled one out, the conditions under which the choice should be reconsidered, and the pointer to the evidence that carries the inputs and the outputs.
- A glossary entry: the term and its meaning as a provider and a consumer have settled it.
- A standing reference value: the value the project owner approved and the capability it belongs to.

## Procedure

### Decide what is kept, and where

Kept is what a future maintainer cannot reliably recover from code and that affects their next decision. Assign it to one carrier and link to it from the others; the same conclusion is never maintained twice.

- What a term means, once a provider and a consumer have settled it: the team vocabulary.
- Public behavior: the spec.
- A choice with lasting force, a rejected alternative, and the conditions for reconsideration: a decision record.
- Reading guidance that explains only the current difference: the PR, under `firefly-pr`, not a carrier of this skill.

`ready` is defined where the UI, the worker and the verifier can share it: it is behavior, so the spec or the vocabulary holds it, and each of the three cites the same definition. Why query equality is not intent identity is a choice the future may reopen — an optimization can raise it again — so it takes a decision record carrying what triggered it, the alternative that was considered, the counterexample that ruled it out, and when to reconsider; the experiment's inputs and its full outputs stay at the evidence location, and the record points to them.

### Write a glossary entry

Write the term with the meaning the provider and the consumer settled, and a pointer to the spec or the decision record that defines the behavior the term names. Do not restate that definition here: the glossary holds the term, the carrier behind the pointer holds the conclusion.

### Write a decision record

One file per decision, `docs/adr/YYYYMMDD-<slug>.md` unless the project keeps another convention, carrying:

- The scenario that triggered the decision, and the choice made.
- The alternatives that were considered, and the counterexample or evidence that ruled one out.
- The conditions under which the choice should be reconsidered.
- The pointer to the evidence location that holds the experiment's inputs and its full outputs.

When only history can suggest why, separate what was observed, what is documented as the reason, and what is still unknown; never reconstruct the original author's intent. A record that a later decision replaces is marked with its status and its successor. Leave enough primary evidence for a maintainer who disagrees to argue with, not only another summary to quote.

### Sync the main specs

A sync is a write with effects: it changes the main specs that hold the long-lived behavior. It runs only under a mandate that permits it, for a candidate that is `accepted`, after the commitments are enumerated, reconciled with the implementation and the tests, checked against the current main specs, and compared before and after by a reviewer who did not produce the sync. The mechanical steps — resolving the change and its planning root, taking the delta files, the four preconditions of the plan, the comparison and the non-author review, the apply, and the strict validation and the idempotency check after it — are in `references/spec-sync.md`; this skill reports their outcome and stops where they stop. The sync changes the main specs only: the change's spec package version, its observations and its ready decision are computed over the change's own `specs/` directory, and none of them moves.

### Write a standing reference value

The project owner approves the value; this skill writes it into the main spec of the capability it belongs to, and a change's spec references it there. The write needs the same sync authorization as any other change to the main specs; an investigation, a decision record or a review carries none of it.

## Outputs

| Fact | Carrier | Written |
|---|---|---|
| Team vocabulary | the glossary the project already keeps, otherwise `docs/glossary.md` | when the term is settled between a provider and a consumer |
| Decision record | `docs/adr/YYYYMMDD-<slug>.md`, an existing ADR convention in the project winning | when a choice with lasting force is made, or a rejected alternative would be raised again |
| Main specs | `openspec/specs/**/spec.md` | after the non-author review passes and the strict validation and the idempotency check run |
| Standing reference value | the main spec of the capability, kept by the project owner | once the owner approves and the sync authorization covers the write |

The report to the requester names each carrier written, what it now holds, the pointers others should cite, and, for a sync, the capabilities updated and the outcome of the validation. The change stays active.

## Handoffs

- The before/after comparison of a sync goes to the non-author closeout review of `firefly-archive`, before anything is applied. A repair after it returns to the plan; a fresh review sees it again before the apply.
- The finished writes return to the controller: which carriers changed, what they hold, and where the pointers go. The original terminal condition and permitted effects travel unchanged.
- A decision record and a glossary entry are linked, not copied: the change's spec, the PR and the minutes cite them by path. The conclusion lives once.
- What follows a sync is the archive path through `firefly-archive`, when it is commissioned; nothing is archived here.

## Stop and escalate

Stop and return `ESCALATE`, carrying the current conclusion, the missing evidence or authority, and the responsible owner, when:

- **The mandate does not cover the write.** The conclusion goes in the reply and nothing goes on disk: a naming, a returned conclusion or a decision record does not carry the authority for the main specs. Owner: the requester, who grants the mandate.
- **The candidate is not `accepted`.** A mandate that covers the sync does not replace the acceptance: the sync waits for it. Owner: the requester.
- **The change cannot be resolved.** Several active changes remain equally plausible and the evidence does not name one; the `ESCALATE` carries the candidates, the evidence and a recommended default. Owner: the requester.
- **A precondition of the sync plan cannot be met** inside the mandate's permitted effects: an operation resolves to no single target, or applying it would drop content outside its intent. Owner: the requester, for the authority, and the requirement owner, when a promise would have to change.
- **The non-author review does not pass and the repair would change a promise.** The plan returns to repair for what the mandate permits; a promise change belongs to the requirement owner. Owner: requirement owner.
- **The strict validation or the idempotency check cannot pass** inside the permitted effects. Owner: the requester.

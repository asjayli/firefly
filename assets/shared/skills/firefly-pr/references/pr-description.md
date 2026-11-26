# The PR description

The carrier of the description is the PR platform itself. Nothing of it becomes a repository file; the reply to the requester carries pointers. This reference fixes the structure the description follows; the rules about who may open, push, merge or rewrite are in `SKILL.md`.

## The two readers

The first reader is the person who must decide right now whether to merge. The second is the maintainer who must later explain that decision — without the conversation that produced the change. Everything the first reader needs stands before everything the second needs to reconstruct it.

## Lead, order, verification

1. **Lead** with the observable change, the reason, and the riskiest judgment — the judgment a wrong outcome would cost the most.
2. **Then the reading order.** Name the promise to read first in the spec, the use case most likely to refute it, and what remains unknown after this PR. The reviewer decides with this order; the maintainer reconstructs the decision from it.
3. **Then the verification evidence.** Where the observations and the evidence live, which scenarios were observed on the candidate, and by whom.

Do not narrate the diff file by file. The reviewer needs three things from the author, none of them a diff tour: which promise to read first, which use case is most likely to overturn it, and what remains unknown.

## The worked example

An export change can lead like this:

> Check first how E1 distinguishes a retransmission after a lost response from the same user's deliberate new export the next day, and compare the task identifiers of the two inputs. The account isolation of E2 is covered by the independent verification record. Faster computation is not promised by this delivery.

The three sentences do the three jobs: the riskiest judgment with the input pair that tests it, the pointer to the verification record for the isolation promise, and the exclusion that keeps the reviewer from reviewing what was never promised.

## The acceptance block

The description carries, each by pointer or printed value:

- **The final candidate snapshot** — the one the accepted review package fixed.
- **The spec version** — `firefly snapshot --spec <change>` as the accepted generation's `brief.md` fixed it, the `wt:` prefix aside.
- **The acceptance pointer** — the `ACCEPT` rows of every required role in `## Review verdicts` of the progress record, with their reservation lists. An empty list is recorded as `none`; an item marked `touches-required: yes` cannot appear there, so every reservation the description repeats is one the reviewer can weigh. A comparison package records no verdict rows and is never cited as acceptance evidence.
- **The verification pointers** — `openspec/changes/<id>/verification.md` and `openspec/changes/<id>/evidence/<snapshot12>/`, with the scenarios observed on the candidate snapshot.
- **The failure response** — what happens when the delivery does not hold after merge: the rollback or disablement path and its owner. Stating no path is stating a promise nobody made.

## Inaccessible evidence

Evidence the author could not access is named as inaccessible, with the reason — never passed off as tested. "Tested" without a pointer is a claim about a conversation, not a handoff fact; the record the reviewer can open is the only thing that counts. An `unverified` observation is quoted as `unverified`, with its reservation and its `touches-required` mark.

## The measurement rerun method

When firefly-perf handed over a rerun method and its limits, they go into the description: an independent reviewer must be able to question the measurement design, not only read the numbers. The baseline conditions, the variation and the rerun command or step are stated as firefly-perf recorded them.

## Splitting before drafting

The scale of a split is whether the parts can be judged and reverted independently:

- **Split.** Introducing an async task contract and removing the old synchronous interface: different consumers, different authority, each independently revertable.
- **Do not split.** The state transitions that make one behavior hold and the assertions that prove it: neither PR delivers alone, and a line quota is not a scale.

A split is judged before implementation, under firefly-propose and firefly-tasks. A candidate that has already been accepted is delivered as it was accepted; this skill does not split it at PR time.

## Lasting trade-offs

A trade-off with lasting force is cited by path, never copied into the description: the decision records of firefly-docs own it. The description links to the record and states the one sentence the merge decision needs; the record holds the reasoning.

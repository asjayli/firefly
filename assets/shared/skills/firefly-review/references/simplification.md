# Simplification

The simplification axis of firefly-review. It is a deliberate judgment made inside the review. The reviewer does not edit code along the way: it reports what could be simpler and why that is worth doing. The controller routes the result, and an implementer with authorization applies it.

## When to judge

Judge when either holds:

- The change adds duplication, branches or a compatibility layer.
- The mandate is itself a module-wide simplification.

Skip it when the change adds none of these, or when the mandate asks only for a correctness verdict.

## What a valid finding states

A simplification finding is valid only when it states all four of these:

1. **The element that would be removed.** Name it in the review package.
2. **The maintenance cost that disappears.** What no longer has to be kept in step, tested or understood.
3. **The invariant that must keep holding.** The behavior a consumer relies on.
4. **The equivalence check.** The cases that show the behavior is unchanged after the removal.

"Too much abstraction" or "this looks duplicated", on their own, do not ask the implementer to widen the change.

## Two status maps: merge, or keep the boundary

An API and a user interface each carry a status mapping table. The two look alike. Whether they should be one table is decided by what they map and by who has to change them together.

**Merge.** The two tables map every allowed state to the same result, and a change to one must always be made to the other at the same time. The finding is valid: generate both from a single contract, or reuse one for both. The equivalence check examines each state on its own: `queued`, `ready`, `failed`.

**Keep the boundary.** One table expresses the state of the domain. The other groups several internal steps for the user. The resemblance is on the surface only; the two have different duties. Merging them would let a change in storage reach the interaction layer. The conclusion is to keep the boundary, even at the cost of one more table.

## What happens to a finding

| The simplification | Disposition |
|---|---|
| Touches only this change | The implementer may apply it inside the existing authorization, then reverify. The candidate then changes: it returns to firefly-implement, which completes the designated verifiers' observations, and it is reviewed as a new package. |
| Needs a rewrite of the whole module, the removal of a protection or a new public contract | Delivered as a separate proposal, with the expected benefit and the rollback path. |
| Would be out of scope for the fix under review | Does not block that fix, unless the current complexity itself makes a required behavior wrong or unverifiable. |

## When the mandate is the simplification

- The comparison is taken before any task group of the change is dispatched, on the candidate present at that time. The review is a comparison review when the mandate in force is itself a module-wide simplification, no task group has been dispatched, and the comparison is still due: Step 2 of `SKILL.md` decides, line by line. A comparison that ended in `REVISE` is made again for the same snapshot, as the next generation, when something calls for it again (Step 2 of `SKILL.md`). Once a task group has been dispatched, every candidate that enters review is reviewed as a candidate, from a diff: its returns are verdicts, and it reaches `accepted` through them.
- The inputs of the review become the named module, its consumers and its invariants.
- The object under comparison is the existing behavior of the module on the candidate snapshot. No simplification is proposed here: the implementer of firefly-implement proposes it. The reviewer states what any simplification of the module has to keep: the outputs that must stay equal before and after it, the outputs that must stay different, the consumers, the invariants, and the cases that check the equivalence.
- The comparison is made by an independent reviewer who did not produce that module, in a temporary copy exported from that snapshot.
- The review is one review package, a comparison package. It has the package identity, the package directory, the `brief.md` (the facts it fixes are the named module, its consumers and its invariants), the dispatch rows (`sent`, then `returned`) and the stored return. No verdict row is written for it: the return judges no candidate, and the snapshot it compared keeps its state.
- The package is complete when each required role has a `returned` row that no `failed` row follows. A return found not to stand is recorded `failed` after it and leaves its role without a return. A complete package is never dispatched again; what an entry does with it is decided by Step 2 of `SKILL.md`.
- The verdict follows the comparison, and there is no `RECHECK`. The equivalence can be stated: `ACCEPT`, with its reservations; the stored return goes to firefly-implement, which implements it incrementally. It cannot be stated, because what consumers rely on conflicts or the existing behavior cannot be determined: `REVISE`; the stored return goes back to the requester, and nothing is handed to firefly-implement. The comparison is made again, as the next generation, when something calls for it again (Step 2 of `SKILL.md`). The evidence needed to state it cannot be obtained: `INSUFFICIENT_EVIDENCE`; the package escalates.
- A reservation of the comparison touches required behavior when it concerns an output that must stay equal or an invariant. Such an item may not appear in an `ACCEPT`.
- The return states what the module costs today to keep in step, to test and to understand: that is the maintenance cost a simplification has to reduce. Fewer files is not that reduction.
- The reviewer judges behavioral equivalence and maintenance cost only. Fewer files is not acceptance. That the judgment is hosted in a review does not prevent an authorized implementation from being handed to firefly-implement.

## Recording

- A simplification finding that does not touch required behavior is recorded in the reservations of the verdict: kind `non-blocking-finding`, marked `touches-required=no`. It does not block acceptance.
- When the current complexity itself makes a required behavior wrong or unverifiable, the finding is a finding about that required behavior. It is judged and reported like any other finding on required behavior, and it is not recorded as a non-blocking reservation.

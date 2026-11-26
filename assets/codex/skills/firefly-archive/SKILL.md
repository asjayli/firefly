---
name: firefly-archive
description: Owns three separately commissioned endpoints around a change whose candidate has passed independent review - a read-only launch readiness assessment that delivers the closeout ledger, the local archive of one named change (sync of its delta specs, closeout reviews, the move), and a launch under its own mandate that writes the rollout plan and advances, stops or rolls back under it. Use when the user commissions one of the three, or when firefly-implement hands off after `ACCEPT` and a commission for what may follow exists. Not used when the change has not passed the review of firefly-review with `ACCEPT`, or when the user has not separately commissioned the archive or the launch.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "25,22"
  absorbs: ["22"]
---

# firefly Archive

Three separately commissionable endpoints around a change whose candidate has passed independent review: a readiness assessment that reads and reports, the local archive of one named change, and a launch under its own mandate. Each is commissioned on its own, and none of them authorizes the actions of the other two. The shared rules — mandate, carriers, candidate states, reservations, recording — are in `${CODEX_HOME:-$HOME/.codex}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere. The rules of a change that retires a legacy capability sit behind the one pointer in the archive endpoint below.

## When to use

- **A readiness assessment.** The user asks whether a fixed change is ready to launch. The candidate is `accepted`, or `archived` and not yet `live`; the assessment is read-only and its mandate sits in the `## Mandates` table of the progress record — readiness assessment is work that has no change of its own (contract, Carriers).
- **A local archive.** The user explicitly names one change to archive. The archive and the launch are work on the named change: their mandates sit in the `## Mandate` section of its `proposal.md`.
- **A launch.** The user commissions the launch of a change whose candidate is `accepted`, or `archived` and not yet `live`, under a launch mandate.
- **Commissioned separately after `ACCEPT`.** `firefly-implement` hands off: "What may follow is commissioned separately: `firefly-pr` for the pull request, `firefly-docs` for spec sync and decision records, `firefly-archive` for readiness, archive and release." The handoff is a route, not a commission; each endpoint still needs its own.

## When not to use

- **The change has not passed the review of `firefly-review`.** No verdict of `ACCEPT` stands for the candidate the request names: its candidate is not `accepted`, and no authorization of this skill has taken it further. Nothing here assesses, archives or launches it.
- **No separate commission.** The user has not separately commissioned the assessment, the archive or the launch. Acceptance alone, a finished sync alone, a readiness conclusion alone — none of them opens another endpoint.

## Mandate

**Fixed end.**

- A readiness assessment: the closeout ledger delivered in the reply with its evidence pointers, and one conclusion — launch-ready, or not launch-ready naming the missing response and its owner.
- A local archive: the named change's directory moved to the archive location, its evidence reopened, and the strict validation green after the sync.
- A launch: the rollout plan on the progress record before first traffic, the stages advanced, stopped or rolled back under the plan as the signals decide, and the final stage verified against the original scenarios and the runtime signals — or the containment and the escalation the plan directs.

**Permitted effects.**

- A readiness assessment: none. It is read-only; the reply is its carrier.
- A local archive: the sync of the change's delta specs into the main specs, applied after its non-author review passed; the archive inventory, and the migration decision of a change that retires a legacy capability, written into the change's directory; the local archive move of the change directory; the reopening of the evidence; the deletion of the change's snapshot refs under `refs/firefly/snapshots/`; and repairs to the sync result or the archive package inside this envelope.
- A launch: the rollout plan and its observation records appended to the progress record, and the traffic actions the approved plan directs, inside the launch mandate.

**Not granted.**

- Push, release, history rewriting. The archive authorization covers the spec sync and the local archive move; it never covers a push, a release or a rewrite of shared history.
- A traffic action under a readiness or an archive commission.
- A surprise gate. The assessment aggregates the acceptance criteria agreed before; it adds no criterion of its own at the end.
- Executing a migration removal. The archive stores the migration decision with its open removal item and keeps it open; the removal itself is a separate destructive change.
- A repair outside the archive authorization envelope: a validation failure that is neither in the sync result nor in the archive package is returned with its evidence, not fixed here.

**The authorized writes are not a candidate change.** The sync and the archive move are writes made after acceptance under this skill's authorizations. A snapshot that differs from the accepted one only by writes made after acceptance under the authorizations of this skill (the spec sync) and of firefly-docs (the decision records) is still the accepted candidate (contract, Identity and versioning). Nothing here revives a candidate or reopens its verdict.

## Inputs

- The named change, from the commission; a change is never picked from conversation context. It must exist; the archive target must not be archived already.
- A readiness assessment: the final candidate snapshot — printed by `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" snapshot` for an active change, or the final candidate recorded in `archive-inventory.md` for an archived one, whose refs were dropped at the archive; the accepted candidate's verdict with its reservations — the stored returns beside the review package and the rows of `## Review verdicts`; the applicable project checks, a gate promoted after acceptance included; the runtime observation method and the response owner; the drill records, where `firefly-trace` was triggered; and the acceptance criteria agreed before.
- A local archive: the sync plan of `firefly-docs`, its before/after semantic comparison; the change's delta specs and the current main specs; and the archive inventory's three contents — the change to be archived, its final candidate, its evidence ledger.
- A launch: the launch mandate; the release owner; the drill record and the runtime signal requirements of the spec; and the service objectives and the baselines the thresholds come from.

## Procedure

**Resolve the change and the commission.** The commission names its endpoint and its change. Verify the change exists; for the archive, that it is not archived already; for every endpoint, that a verdict of `ACCEPT` stands for its candidate. Read the mandate on record for the endpoint's writes: no mandate, or one that does not cover them, is the first stop below. Nothing else of the change is inferred from context.

### Readiness assessment (read-only)

**Three proofs, one delivery.** Launch readiness is three separate proofs: the candidate is correct; a runtime anomaly is detectable; someone can respond to it. The release owner aggregates the acceptance criteria agreed before. For this one delivery, the final candidate snapshot, the independent verdict with its reservations, the applicable project checks, the runtime observation method and the response owner must cover the same delivery.

Where `firefly-trace` was triggered, the drill record must name the same candidate. The candidate or a runtime signal requirement changed after the drill: the drill is made again first — the rule is `firefly-trace`'s, and this assessment reads its conclusion. Only the spec version changed while every signal requirement is intact: the drill record carries the new version and the reason it was unaffected, and the drill is not repeated. A gate promoted after acceptance is part of the applicable project checks: an archived candidate that is not yet `live` is checked against it at this assessment.

**The closeout ledger.** One row per acceptance criterion agreed before, each row openable. In the export case the rows are: the two inputs of E1 — a retry after a dropped connection reuses the running task, a deliberate re-import creates a new one; E2's refresh recovery and account isolation, each with its result; E3's state transition together with the correct file and the failure signal — a status change alone is not a row's result. Each row names the candidate, the observed result, the evidence location, the reviewer and the unverified items.

The unverified items are taken item by item from the reservation list of the verdict on the incrementally implemented, accepted candidate, each with its mark for touching required behavior. A comparison package records no verdict row and holds no reservations; nothing is taken from it. An unverified item marked as touching required behavior fails the readiness assessment.

The ledger lives in the delivery summary — the reply — with its evidence pointers; no standalone file is written.

**The runtime questions.** Who observes backlog or download failure; when new traffic stops; what happens to the jobs still in the queue — how they are saved, or how their users are told. An answer that names no owner is no answer.

**The conclusion.** Code and tests can pass while withdrawing the new version would lose outstanding jobs: the conclusion is "code accepted; not launch-ready", naming the missing response and its owner. Ready, release authorized and `live` are three different facts: the first is this assessment, the second an authorization fact, the third a candidate state; the reply uses each for itself and never one for another. This endpoint writes nothing, performs no traffic action and archives nothing.

### Local archive

1. **The sync plan goes to a non-author review.** The before/after semantic comparison that `firefly-docs` prepared goes, before anything is applied, to a reviewer who did not produce the sync — the closeout review. The reviewer checks the comparison clause by clause and its preservation statement against the main spec itself; an accessible file is not proof of preservation. A review that does not pass returns the plan for repair under the sync authorization, and a fresh non-author review sees it again before anything is applied.
2. **After the review passes, the sync is applied** under the archive authorization, by the sync steps `firefly-docs` owns.
3. **The applied result is checked against the original scope.** Every clause the plan does not mention is unchanged; every rename keeps its old-to-new mapping with its scenarios and references. Semantic loss stops the archive: repair inside the authorized envelope and have the repair re-reviewed; the existence of a file is never accepted in place of the content check.
4. **Validate.** Run `"${CODEX_HOME:-$HOME/.codex}/firefly/bin/firefly" validate --root <project-root>`. Repair only issues in the sync result or the archive package that are inside the archive authorization envelope, then revalidate and have the repair re-reviewed. Any other failure is diagnosed and returned with `ESCALATE` and its evidence, never repaired outside the envelope.
5. **A non-author confirms the archive inventory.** Write `openspec/changes/<id>/archive-inventory.md` — the change to be archived, its final candidate and its evidence ledger. A non-author confirms the inventory matches the named change, the final candidate and the evidence that exists, opening its entries; a file's presence is not the match.
6. **Move and reopen; drop the snapshot refs.** The change directory moves to the archive location the project's OpenSpec layout keeps. After the move, reopen the evidence and tell a normal expiry from a loss. Then delete the refs `refs/firefly/snapshots/` holds for this change's candidate trees: they kept the trees reachable while the change was live, and after the archive they only grow with every candidate. The deletion is a local Git write inside the archive authorization.

A change that retires a legacy capability takes its migration decision into `openspec/changes/<id>/deprecation.md`, with an open removal item that stays open until the removal result is returned and checked — the rules are in `references/deprecation.md`.

The archive authorization covers no traffic action and no launch: the change may be launched before or after its archive, under a launch commission of its own.

### Launch

**Its own commission.** The launch runs only under a launch mandate. The launch mandate covers no archive move and writes no readiness conclusion; each of those is its own commission.

**The rollout plan, before first traffic.** The release owner puts the plan into the progress record — the carrier of the rollout plan and its observation window (contract, Carriers); no recorder subcommand covers it, so the controller appends it by hand. It carries: the candidate snapshot; the scope of every stage; the observation window of every stage; the promotion and the stop thresholds; the disposition of in-flight jobs; the stop and the rollback actions the mandate authorizes; the executor of each. The numbers come from the service objectives and the baselines; a uniform rollout percentage is never copied over them.

**Advancing, stopping, rolling back.** An incomplete observation or a stop threshold prohibits expanding traffic. Contain within the approved plan — stop or roll back as it directs; an effect the plan and the mandate do not cover escalates immediately to the owner holding the authority. A signal that arrives mid-rollout — a gate promoted after acceptance included — never rolls traffic back by itself: the release owner decides advance or stop under the plan.

**Windows that outlive the session.** When an observation window outlives the session, its end and its successor are kept with the plan; at expiry the next session checks the signals before deciding whether to advance.

**The final stage.** It is verified against the original scenarios and the runtime signals of the drill. Record the actual execution, the residual impact and the successor. Only then is the change reported live and verified — the candidate state `live`. A rollback that leaves the candidate unchanged returns it to `accepted`; a repair returns it to `in-progress`.

## Outputs

| Fact | Carrier | Written |
|---|---|---|
| The closeout ledger, with its evidence pointers | the delivery summary (the reply); no standalone file | at the end of a readiness assessment |
| The archive inventory | `openspec/changes/<id>/archive-inventory.md`, moved with the archive | before the move, after the non-author confirmation |
| The migration decision and its open removal item; the removal return | `openspec/changes/<id>/deprecation.md`, moved with the archive | the decision at the archive; the return when the executor reports |
| The rollout plan, its observation windows, the observation records | `.superpowers/sdd/progress.md` | the plan before first traffic; the records as observed |
| The archived change directory, its evidence reopened | the archive location the project's OpenSpec layout keeps | after the move |

## Handoffs

- **From `firefly-implement`.** After `ACCEPT`: "What may follow is commissioned separately: `firefly-pr` for the pull request, `firefly-docs` for spec sync and decision records, `firefly-archive` for readiness, archive and release." Acceptance is the precondition; each endpoint still needs its own commission.
- **From `firefly-docs`.** The before/after comparison of a sync comes here, to the non-author closeout review, before anything is applied. A repair after it returns to the plan, and a fresh review sees it again.
- **From `firefly-trace`.** The drill record, handed to the release owner. The readiness assessment reads its conclusion and checks it names the same candidate; the final stage of a launch is verified against the same signals.
- **To the release owner.** The closeout ledger and the drill record's conclusion. Under a launch mandate the release owner owns advance, stop and rollback.
- **To the migration owner.** The open removal item of `deprecation.md`; the return that closes it comes back through the delivery path, and the migration owner checks it.
- Every conclusion returns to the original decision and brings no new write authority.

## Stop and escalate

Stop and return `ESCALATE`, carrying the current conclusion, the missing evidence or authority, and the responsible owner, when:

- **The change cannot be resolved.** None is named, the named change does not exist, or the archive target is already archived. A change is never picked from conversation context. The missing item is the change id. Owner: the requester.
- **No separate commission covers the endpoint.** Acceptance, a finished sync or a readiness conclusion opens none of the others, and no mandate on record covers the writes the endpoint takes. Owner: the requester.
- **The candidate has not passed the review of `firefly-review`.** No verdict of `ACCEPT` stands for the candidate the request names. Owner: the requester.
- **Semantic loss the envelope cannot repair.** The sync result or the archive package loses semantics and the repair would leave the archive authorization envelope; the evidence travels with the escalation. Owner: the requester, for the authority, and the requirement owner, when a promise would have to change.
- **A validation failure outside the envelope.** Neither in the sync result nor in the archive package: it is diagnosed and returned with its evidence, never repaired here. Owner: the owner of the product that failed.
- **The launch needs more than the plan authorizes.** A stop threshold is reached and containment inside the approved plan cannot hold it, or an effect beyond the mandate is needed. Owner: the holder of the authority the plan names.

The fixed ends and the stops above are the whole set of exits; apart from them the work ends when the user stops it.

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

Three separately commissionable endpoints around a change whose candidate has passed independent review: a readiness assessment that reads and reports, the local archive of one named change, and a launch under its own mandate. Each is commissioned on its own, and none of them authorizes the actions of the other two. The shared rules — mandate, carriers, candidate states, reservations, recording — are in `<skill-root>/references/handoff-contract.md`; they are referenced here and restated nowhere. The rules of a change that retires a legacy capability sit behind the one pointer in the archive endpoint below.

## When to use

- **A readiness assessment.** The user asks whether a fixed change is ready to launch. The candidate is `accepted`, or `archived` and not yet `live`. Keep the read-only mandate in the request context.
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
- A local archive: the sync of the change's delta specs into the main specs, applied after its non-author review passed; the archive inventory, and the migration decision of a change that retires a legacy capability, written into the change's directory; the local archive move of the change directory; the reopening of the evidence; and repairs to the sync result or the archive package inside this envelope.
- A launch: the rollout plan and its observation records appended to the progress record, and the traffic actions the approved plan directs, inside the launch mandate.

**Not granted.**

- Push, release, history rewriting. The archive authorization covers the spec sync and the local archive move; it never covers a push, a release or a rewrite of shared history.
- A traffic action under a readiness or an archive commission.
- A surprise gate. The assessment aggregates the acceptance criteria agreed before; it adds no criterion of its own at the end.
- Executing a migration removal. The archive stores the migration decision with its open removal item and keeps it open; the removal itself is a separate destructive change.
- A repair outside the archive authorization envelope: a validation failure that is neither in the sync result nor in the archive package is returned with its evidence, not fixed here.

**The authorized writes are not a candidate change.** The sync and the archive move are writes made after acceptance under this skill's authorizations. A snapshot that differs from the accepted one only by writes made after acceptance under the authorizations of this skill (the spec sync) and of firefly-docs (the decision records) is still the accepted candidate (contract, Identity and versioning). Nothing here revives a candidate or reopens its verdict.

## Inputs

- The named change comes from the commission. A change is never picked from conversation context. For a new local archive it must be active. For an interrupted archive, use the inventory matching the same mandate and candidate in the active directory or its recorded destination.
- A readiness assessment: take the candidate SHA from the accepted verdict package for an active change or from `archive-inventory.md` for an archived change. For an active change compare the worktree with `"<skill-root>/scripts/firefly.sh" snapshot --check <candidate-sha>`. If it differs, compare the worktree against the accepted tree using read-only Git commands and reconcile each difference with approved post-acceptance spec and decision records. Treat all other differences as a candidate change. Read the accepted verdict and reservations, applicable project checks, any drill record, and agreed acceptance criteria.
- A local archive: the sync plan of `firefly-docs`, its before/after semantic comparison; the change's delta specs and the current main specs; and the archive inventory's three contents — the change to be archived, its final candidate, its evidence ledger.
- A launch: the launch mandate; the release owner; the drill record and the runtime signal requirements of the spec; and the service objectives and the baselines the thresholds come from.

## Procedure

**Resolve the change and the commission.** The commission names its endpoint and its change. Verify that a verdict of `ACCEPT` stands for its candidate and read the mandate on record for the endpoint's writes. On an archive resumption, find the matching inventory before planning the sync. If the recorded destination already holds the change and the active directory is absent, go directly to the evidence and digest check in step 4.

### Readiness assessment (read-only)

**Three proofs, one delivery.** Launch readiness is three separate proofs: the candidate is correct; a runtime anomaly is detectable; someone can respond to it. The release owner aggregates the acceptance criteria agreed before. For this one delivery, the final candidate snapshot, the independent verdict with its reservations, the applicable project checks, the runtime observation method and the response owner must cover the same delivery.

Where `firefly-trace` was triggered, the drill record must name the same candidate. The candidate or a runtime signal requirement changed after the drill: the drill is made again first — the rule is `firefly-trace`'s, and this assessment reads its conclusion. Only the spec version changed while every signal requirement is intact: the drill record carries the new version and the reason it was unaffected, and the drill is not repeated. A gate promoted after acceptance is part of the applicable project checks: an archived candidate that is not yet `live` is checked against it at this assessment.

**The closeout ledger.** One row per acceptance criterion agreed before, each row openable. In the export case the rows are: the two inputs of E1 — a retry after a dropped connection reuses the running task, a deliberate re-import creates a new one; E2's refresh recovery and account isolation, each with its result; E3's state transition together with the correct file and the failure signal — a status change alone is not a row's result. Each row names the candidate, the observed result, the evidence location, the reviewer and the unverified items.

The unverified items are taken item by item from the reservation list of the verdict on the incrementally implemented, accepted candidate, each with its mark for touching required behavior. A comparison package records no verdict row and holds no reservations; nothing is taken from it. An unverified item marked as touching required behavior fails the readiness assessment.

The ledger lives in the delivery summary — the reply — with its evidence pointers; no standalone file is written.

**The runtime questions.** Who observes backlog or download failure; when new traffic stops; what happens to the jobs still in the queue — how they are saved, or how their users are told. An answer that names no owner is no answer.

**The conclusion.** Code and tests can pass while withdrawing the new version would lose outstanding jobs: the conclusion is "code accepted; not launch-ready", naming the missing response and its owner. Ready, release authorized and `live` are three different facts: the first is this assessment, the second an authorization fact, the third a candidate state; the reply uses each for itself and never one for another. This endpoint writes nothing, performs no traffic action and archives nothing.

### Local archive

1. **Stage the sync.** Use the `firefly-docs` sync mechanics to prepare the proposed main files in an isolated project copy. Write the before/after semantic comparison and validate the staged result with `"<skill-root>/scripts/firefly.sh" validate --root <isolated-project-root> -- <id>`. The non-author checks every affected commitment, the unchanged clauses, and the rename mappings and approves the exact staged result.
2. **A non-author confirms the archive inventory before publication.** In `openspec/changes/<id>/archive-inventory.md` record the mandate ID, final candidate, evidence ledger, exact archive destination, and each main file's relative path and before/after content digests. Resolve the paths within the same local project. Record absent files explicitly and keep both immutable copies with the change's evidence. Record the staged validation and the non-author decision. A changed plan requires a new validation and review.
3. **Resume or publish the approved result.** Recover this inventory before planning another sync. For each affected file inside the archive authorization envelope, compare current content with the approved before/after digests. Write the approved after content only over the reviewed before state. Skip files already matching the after state. Stop on a third state or conflicting archive destination and retain the inventory and evidence for reconciliation. A partial failure keeps the same inventory open. Retry the pending writes when possible, or restore reviewed before content only where the current state still matches the approved after content. Preserve concurrent edits.
4. **Validate, move and reopen.** After all files match the approved after state, run `"<skill-root>/scripts/firefly.sh" validate --root <project-root> -- <id>` again. On failure keep the active directory and use step 3 to resume or restore the approved before state. On success move the active change to the recorded destination. If the destination already contains this inventory and the active directory is absent, reopen the saved evidence and verify the applied digests. Preserve `refs/firefly/snapshots/`: their identity is shared by every change and worktree that references the same Git tree. Ref cleanup needs separate authorization and verification of all consumers.

Repair only issues in the sync result or the archive package that are inside the archive authorization envelope. Revalidate and obtain a new review if the approved result changes. Other failures are reported with `ESCALATE` and evidence, never repaired outside the envelope.

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

- **The change cannot be resolved.** None is named, the named change does not exist, or the archive target is already archived under a different mandate. Matching inventory at the recorded destination permits resumption. The missing item is the change ID or the matching inventory. Owner: the requester.
- **No separate commission covers the endpoint.** Acceptance, a finished sync or a readiness conclusion opens none of the others, and no mandate on record covers the writes the endpoint takes. Owner: the requester.
- **The candidate has not passed the review of `firefly-review`.** No verdict of `ACCEPT` stands for the candidate the request names. Owner: the requester.
- **Semantic loss the envelope cannot repair.** The sync result or the archive package loses semantics and the repair would leave the archive authorization envelope; the evidence travels with the escalation. Owner: the requester, for the authority, and the requirement owner, when a promise would have to change.
- **A validation failure outside the envelope.** Neither in the sync result nor in the archive package: it is diagnosed and returned with its evidence, never repaired here. Owner: the owner of the product that failed.
- **The launch needs more than the plan authorizes.** A stop threshold is reached and containment inside the approved plan cannot hold it, or an effect beyond the mandate is needed. Owner: the holder of the authority the plan names.

The fixed ends and the stops above are the whole set of exits; apart from them the work ends when the user stops it.

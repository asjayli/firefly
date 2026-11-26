# Deprecation and migration (design 22)

The rules a change that retires a legacy capability follows: when the replacement counts as done, what a removal request carries, and how the archive keeps the decision open until the removal is returned and checked. The shared rules — mandate, carriers, recording, verdicts — are in `{{PLATFORM_HOME_ENV}}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere.

## Two separate decisions

That the replacement capability is available and that the legacy capability may be removed are two separate decisions. The migration owner takes the second one only after:

- inventorying the consumers of the legacy capability, the promises it carries, the replacement paths and the observation cycles that matter;
- verifying, consumer by consumer, that every real consumer has switched.

A notice sent, a deadline reached and a deployed replacement entry point — none of them alone establishes that nobody depends on the old entry.

## A quiet week outside the cycle proves little

The web UI can be entirely on the async export while a month-end batch job still calls the synchronous interface. A week of no calls that does not include the month-end day cannot decide retirement. The owner of the batch job inspects its configuration and its execution schedule, and the replacement path — and the consistency of its results — is observed over a window that covers the real cycle.

## Consumers that cannot be identified or observed

A consumer whose identity is unknown, or that cannot be observed, is never recorded as migrated. Keep the risk statement and extend compatibility, add observation, or obtain an explicit risk acceptance.

## The removal request

A removal request carries five things:

1. The consumer evidence: who has switched, and how each was verified.
2. The retirement order: the sequence in which the old entry points become unavailable.
3. The recovery method.
4. The executor.
5. Its own separate approval.

Three rollbacks that look alike are different operations: withdrawing new traffic, restoring the old interface and recovering deleted data. Name which of them the recovery method is. Where recovery is impossible, state the consequences and hand the decision to whoever holds the authority.

## The archive keeps the decision open

The archive stores the migration decision in `openspec/changes/<id>/deprecation.md`, with an open removal item. The archive preserves and reviews the decision; archiving a new capability never executes the removal by itself.

The actual switch-over or deletion is a destructive change under its own mandate and follows the delivery path: tasks under `firefly-tasks`, implementation under `firefly-implement`, independent review under `firefly-review`. Its review scenarios include at least: the old entry point is unavailable as declared, and migrated consumers still obtain results from the replacement path.

The authorized executor follows the retirement order and returns the time of execution, the actual impact and the residual risk; the return is appended to `deprecation.md`, the migration owner checks it and closes the item. Until the return has arrived and been checked, the item stays open.

When an observation window spans a complete business cycle, its end and its successor are written to the task record — the task record is where the migration observation window lives.

## Public interfaces whose consumers cannot be enumerated

Where the consumers of a public interface cannot be fully enumerated, the migration owner also supplies:

- the notice channel;
- the old-to-new usage;
- the support window;
- the contact and the risk acceptor.

Advised migration and a mandatory deadline are kept apart. Zero traffic before a complete business cycle has ended is not a basis for removal.

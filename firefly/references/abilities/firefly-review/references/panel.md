# Independent panel

Activate only when requested with `firefly review <change> --panel`. Use two independent reviewers by default and three when requested. Record the panel mode and required reviewer slots in the generation's `brief.md` before dispatch. Changing the panel requirements changes the pinned mandate and requires a new generation.

Send the same fixed package to every reviewer in a fresh context. Begin the dispatch with the [worker instructions](../../../worker.md), identify the slot and the distinct reviewer identity, and keep results private until all reviewers have returned. Use distinct review focuses when relevant. Every reviewer still addresses all required scenarios.

Record dispatch and verdict under the existing reviewer role with a unique agent name that includes its slot, such as `panel-1-a`. On retry reuse the slot with a new agent name. Apply the reviewer retry limits per slot. On resumption read slot assignments from the brief and dispatch rows. Dispatch only uncovered slots. All must validly accept for the candidate to be accepted. One valid `REVISE` blocks the generation immediately. Reconcile pending slots under the [continuation rules](../../../continuation.md) without replacing obsolete dispatches. Use the existing verdict routing for defects and evidence gaps.

Report each consolidated finding with its evidence, independent confirmation count and any conflicting result. Keep any reproducible finding from a single reviewer. If conflicting results cannot be resolved, report the gap under the existing evidence rules.

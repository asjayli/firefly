# Continue and recover dispatches

The controller owns each dispatch through a terminal outcome. A progress report, host wait timeout, or context compaction does not end the mandate. Before returning, check active children and remaining authorized work. A handoff within the same mandate continues at the receiving guide. Stop when the terminal condition is met, the user interrupts, or the applicable escalation conditions hold.

## Check whether the mandate can end

1. At entry, derive one stable ID and an observable outcome for each required condition from the user's request and the selected capability's fixed endpoint. Include explicitly required environments and evidence. Record the list in the terminal condition of the existing mandate record, using entries such as `local-tests — suite passes; host-resume — isolated host resumes after reconnect`. For the read-only `firefly next` entry, keep the fixed endpoint in the current context. On resumption, recover the list from the original mandate and check it against the request and the agreed scope. Apply an authorized change of scope through a new mandate record. Internal handoffs carry the original list.
2. Before a completion or escalation reply, copy the recorded IDs into `required`. Build `conditions` separately by reconciling the current task, Git, evidence and progress records. Check evidence against the agreed environment and current candidate or input version where relevant. Scan the authorized queue for ready work beyond the listed conditions, including available recovery paths, and reconcile dispatches under [Recover a dispatch](#recover-a-dispatch).
3. Send this JSON on standard input to `node "<skill-root>/scripts/continuation.mjs"` with `kind` set to `"finish"`, the `required` array, the `conditions` array, a boolean `workReady` for other authorized work that can run now, and a `dispatches` object. IDs use letters, digits, dots, underscores and hyphens, starting with a letter or digit. Each condition row carries its `id` and `status`.

| Condition status | Required basis |
|---|---|
| `ready` | An authorized action or materially different recovery path can run now. |
| `waiting` | An in-flight check, pipeline or observation window can still produce its result. Set `evidence` to its run, handle or record reference. |
| `verified` | The required outcome is established. Set `evidence` to its observation, artifact, integration commit or verdict reference. |
| `blocked` | Existing authority, capabilities and remaining recovery paths cannot deliver the outcome. Set `reason` to the exact missing condition and `owner` to whoever can resolve it. |

Set `dispatches.status` to `clear` once all dispatches are reconciled, `waiting` while any live or recoverable dispatch remains, or `blocked` when reconciliation requires an unavailable capability or new authority. For `waiting` supply an `evidence` reference. For `blocked` supply a `reason` and `owner`. Keep a waitable dispatch in `waiting` even when another dispatch is blocked.

| Decision | Next action |
|---|---|
| `continue-work` | Execute ready authorized work and check again. |
| `reconcile-conditions` | Recover the missing rows from the mandate, queue and evidence. Repeat the check with their actual status. |
| `wait` | Use bounded host waits or poll the pending result. Refresh the queue and run the check again. |
| `escalate` | Return each unresolved blocker with its missing condition and owner. Keep the mandate open for resumption. |
| `complete` | Return the completed mandate with its evidence. |

On invalid input, repair the input from the authoritative records and rerun. The helper validates the supplied inventory and status fields. The controller is responsible for extracting the full scope, validating evidence and invoking the gate.

## Recover a dispatch

For implementation, verification, repair, recheck and review dispatches, append `sent` before calling the host and append `started --handle <id>` as soon as it returns a queryable identifier. Record the host and session in the reason only if needed to locate the handle. Use identifiers the host exposes for this purpose and omit credentials. `sent` counts once. `started` attaches the handle to the same dispatch. A host without a queryable handle can still deliver a result. Preserve its status as unknown until a result or independent evidence resolves it.

For implementation, repair and verification, record from the target worktree so the controller can recover every dispatch in one ledger. Use `record dispatch --work <task-or-check-id> --worktree <absolute-worktree>` on the `sent` row. Use the work's role and stable identity. The implementation or repair identity includes the change, task group and baseline or repair round. The verification or recheck identity includes the change, candidate and check or recheck key. Use a filename-safe value in `--package` and carry the full check or key in `--work`. Use the same package, role and agent on subsequent rows. Include the worktree and the evidence destination in the briefing, and record the final disposition after collecting the result. Locally executed commands use an evidence record and need no host handle.

On recovery, read the saved return, then query or reclaim the host dispatch through its handle or the host's active list. If a validated return was already stored and its verdict row was not written, finish recording that return once. Check the existing rows first to avoid duplicates. An absent file or a timeout while waiting does not establish that the host stopped.

Use the stateless decision script `node "<skill-root>/scripts/continuation.mjs"` with a JSON object on standard input. For dispatches use `kind: "dispatch"`, `host: "active" | "finished" | "unknown"`, and booleans `savedReturn`, `obsolete` and `cancelSupported`. `finished` means the host confirmed exit, failed launch or cancellation and the controller tried to collect the result. Set `savedReturn` for a recoverable return after collecting from the host or reading the saved return.

| Decision | Next action |
|---|---|
| `wait` | Keep the original dispatch active and poll again after a bounded wait. Continue other authorized work whose inputs are independent. |
| `collect-return` | Validate the return against its original package and finish any missing recording steps. |
| `record-failure` | Record `failed` with the confirmed reason. Retry only within the applicable budget. |
| `cancel-and-wait` | Request cancellation and wait for acknowledgement, or wait for normal exit when cancellation fails. |
| `close-obsolete` | Record `obsolete`. Keep any late result as historical evidence associated with the original dispatch. It cannot decide the package or reopen a slot. |
| `reconcile` | Try host lookup and inspect Git and evidence before replaying work. If the status stays unknown, a read-only review may be superseded once under its retry limit after its return is fenced to the original identity. Record the old dispatch as obsolete with the unresolved status as the reason. For workers that may still write, wait until their writes are fenced, independently establish that they stopped, or escalate if neither is possible. |

## Recover when the ledger is lost

Try to recover the original ledger from the original worktree or a surviving copy. Reconstruct the state that Git, the task package, candidate snapshots, observations, saved briefs and results can prove. Query active workers before replaying anything. Historical returns remain evidence. Refresh missing observations or ask for an independent recovery review of a fixed package when still authorized. Record fresh results normally and keep recovered facts distinct from new observations. Do not invent verdicts, lost counters, permissions or previously completed writes.

Mark unrecoverable counters as unknown. Continue independent work and evidence recovery. If a new write or repeat attempt depends on a lost count and the mandate does not otherwise authorize it, route that action to its owner as a blocker while continuing the rest.

## Continue around a blocked path

Treat an exhausted budget as a stop for the exhausted path. Preserve its remaining blocker and continue any ready work whose prerequisites and authorization still hold. When no independent work is ready, try a materially different recovery action that can supply the missing fact without repeating the exhausted operation. Examples include diagnosing the tool failure, recovering evidence from the host, or collecting equivalent evidence through an approved method. An alternative cannot replace a required independent reviewer or waive an agreed check.

Use the decision script with `kind: "blocked-path"` and booleans `independentReady` and `alternativeReady`. It returns `continue-independent`, `try-alternative`, or `escalate`. Recompute after each action with only untried recovery paths marked ready. Keep existing retry limits. Escalate when the outstanding result still requires new authority, a person-only decision, or unavailable evidence or capability. Identify the missing condition and its owner. A progress report, phase completion or routine retry needs no confirmation.

## Finish a blocked review generation

A valid `REVISE` immediately blocks its generation. Apply it ahead of pending-slot checks. Cancel or collect any outstanding children using the table above. Record their disposition as `obsolete` after reconciliation. Keep a late return associated with that generation. Dispatch no replacement for an obsolete slot. Enter repair, or report a standalone result, after the retiring generation's workers have been reconciled. All slots must accept to grant acceptance.

## Recheck once per unresolved check

For each proposed rerun, write a stable key in the preserved review return using the fixed input identities, the mapped scenario and check, the expected outcome, and the materially relevant execution conditions. For candidate review use the candidate and spec version. For joint planning review use the spec and task package versions. Remove the `wt:` prefix from versions. Use the same canonical key for the same check across generations. Do not use the generation, timestamp or evidence filename as identity.

Record the key and rerun command beside the change's existing evidence before dispatching the rerun. Append the result and include the evidence when rebuilding the brief. On resumption, recover an outstanding verifier as above before deciding that its attempt is incomplete. Read keys for the same inputs from previous generations and the current evidence, including any incomplete or unusable attempt after its dispatch is reconciled. A new check or materially changed execution condition has its own key. A request that only names the same outstanding question keeps the original key.

Use the decision script with `kind: "recheck"`, `key` (the fixed identity for this rerun), `attempts` (recorded keys), and `evidence: "answers" | "missing"`. If current evidence already answers the question, have the reviewer decide from it. If the key has not been attempted and evidence is missing, rerun once. If evidence is still missing after an attempt, escalate with the missing fact and owner. A repeated request whose evidence already answers the question is an invalid review return when the reviewer cannot identify a new gap. Apply the existing infrastructure retry limit; do not rebuild the package or use a repair round for that return.

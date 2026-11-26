---
name: firefly-context
description: Loads working context on demand for any firefly mandate and compresses handoffs for a successor. Applies inside every skill while it works, keeping the mandate, active scenario, task and evidence pointers in view and opening source, logs and history only for a specific judgment. Named directly when the user asks to take over a mandate that is in progress (after an interruption, in a new session, or after context compaction) or to compress a handoff. Not used when the mandate has just started and has no progress records, or when no successor takes the work.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "10"
---

<!-- The progress-recovery rules take the mechanism of the "Durable Progress" section of the superpowers skill `subagent-driven-development` (MIT). -->

# firefly Context

Load working context on demand. At a handoff, add only what the project's durable facts cannot give back. The shared contract is referenced here and restated nowhere: `${CLAUDE_HOME:-$HOME/.claude}/firefly/references/handoff-contract.md`.

## When to use

Two ways in.

### Loaded by the skill that is working

Not entered by name. While any firefly skill works under a mandate, it loads context by `### Load on demand`. Before it passes the work to a successor, it compresses the handoff by `### Compress a handoff` and checks a received one by `### Check a handoff on receipt`.

### Named by the user

- **Take over.** The user asks to resume, continue or take over a mandate that is in progress: the session was interrupted, another session or agent picks the work up, or the context was compacted.
- **Compress.** The user asks for a handoff summary for a successor.

The state is rebuilt whenever a mandate is resumed and after each context compaction.

## When not to use

- The mandate has just started and has no progress records: no task item is checked, no candidate snapshot is recorded, there is no observation row and no row in the progress record. Nothing is rebuilt and no summary is written; the skill named for the deliverable starts from its own beginning.
- No successor takes the work and the context is not being compacted: no handoff summary is written.
- The state was already rebuilt in this context and nothing has been compacted since: it is not rebuilt again.
- The user asks for the deliverable itself (implementing, reviewing, proposing): enter that skill. Its context still loads by the rules here.
- No mandate is on record and no task record, candidate or evidence of the intent exists: nothing can be taken over, and the request is handled as a new one.

## Mandate

Loaded by another skill, this skill sets no endpoint of its own; the terminal condition of that skill stands.

Named by the user, it ends at a fixed point:

- **Take over:** the rebuilt state is returned (see `## Outputs`) and control passes on. Nothing is implemented, repaired, re-verified or reviewed on the way.
- **Compress:** the handoff summary is returned.

The skill also ends by `ESCALATE` (`## Stop and escalate`).

Allowed effects:

- Read every carrier in the contract's Carriers table, the Git history and the evidence.
- Run `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot` to read the identifier of the candidate present, and `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot --spec <id>` or `--tasks <id>` to read the current spec package version or task package version. None of them changes the index or the worktree.
- Write back a trade-off that still binds before a summary is sent. A user's decision goes into the minutes, quoting the user's words; the controller writes it under every mandate. A choice with lasting force goes into the decision record through `firefly-docs`: check first that the mandate's permitted effects cover that write, and the party it authorizes to write that carrier puts it on disk. Without that authority, `## Stop and escalate`.

Not granted:

- No change to the candidate (product code and tests), to the spec or to the task record. No task item is flipped.
- No observation, ready decision, verdict, dispatch or budget row, no mandate row, and no edit to a row already written. The trade-off write-back above is its only record write.
- No second flow for an intent that already has an open mandate, and no change to its objective, permitted effects or terminal condition. This skill rewrites no mandate.
- No summary changes the mandate: it adds, drops or relaxes no limit and grants no effect.
- No push, merge, archive or release, and no cleanup of the worktree.

## Inputs

- The request: take over (a change id, a mandate id, or the intent stated again), or compress.
- The carriers in the contract's Carriers table, each read where the table puts it. Three of them carry the state:
  - The task record states the delivery commitments.
  - Git states where the change actually is.
  - The verification record states on which candidate what was observed.
- A handoff summary, when the predecessor left one. It is a list of pointers to open, never a source of facts.

## Procedure

### Load on demand

- Keep the resident context in view: the mandate (id, objective, permitted effects, terminal condition), the active scenario, the task and the evidence pointers.
- Open source, logs and history (earlier discussion, minutes, superseded conclusions) only for the specific judgment that needs them. Before opening one, name the judgment to be made and the fact it needs, and open only when the resident context does not hold that fact. Afterwards keep the pointer, not the content.
- Whether a fact is still in force is read from its carrier. A record marked `historical` supports no conclusion (lapse rules in the contract).
- A brief handed to a worker carries the resident context for its task and its pointers. Earlier conclusions travel as pointers to their carriers, not as pasted history. A task group (a `## N. <Group>` heading of the task record with its items) is handed as its brief file: `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/task-brief" <tasks.md> <N>`.

### Read in this order on resumption

1. **The open mandate, by its id.** An intent raised again continues the mandate already open for it. With a change, read `## Mandate` in `openspec/changes/<id>/proposal.md`; the minutes behind its decisions are at the path on the hand-written line `Minutes: <path>` after the mandate table. Without one (investigation, read-only review, readiness assessment), read `## Mandates` in the progress record, with the same hand-written `Minutes: <path>` line after its table. When the user named a file and minutes were added later, that line names the named file; the added entries are reached through the scenarios' `Source:` lines.
2. **Open items first**, before any other content: the pending items of the task record (`openspec/changes/<id>/tasks.md`), the progress record (`.superpowers/sdd/progress.md`), the verification record (`openspec/changes/<id>/verification.md`) and the archive record (`openspec/changes/<id>/deprecation.md`, `archive-inventory.md`). They include a pipeline result that arrived outside the session, a removal result not yet returned and an observation window still running.
3. **The candidate that is actually present.** Read the identifier `firefly snapshot` prints and the Git history, against the snapshot the records name. The comparison is between implementations. The candidate is the implementation: nothing under `openspec/changes/` or `openspec/think/` is part of its snapshot, committed or not, so a difference in the spec, the tasks or the records never shows up as a worktree that differs from the snapshot (contract, What the candidate is). It is judged by the spec version and the task package version instead, the `wt:` prefix ignored. Where the records are read depends on integration. Before integration they are read in the worktree that produced them: a candidate in a child worktree has its observation rows and evidence in that worktree. After integration they are read in the target baseline, where the controller has appended those rows to `verification.md` unchanged and copied the evidence as it is, the candidate column keeping the child worktree's snapshot. A check is marked `unverified` when the place that applies has been read and holds no evidence for it, or when that place cannot be read.
4. **The rest, as a judgment needs it.** Scenarios, decision sources and open blockers: `openspec/changes/<id>/specs/**/spec.md`. Task completion, dependencies and the ready decision: the task record. Observations: the verification record. Verdicts, dispatches and repair budget: the progress record. Rejected alternatives: `docs/adr/`. What a review found, a `REVISE` for one: the reviewer's return beside its package, for the joint review too (see `### Rebuild the state from what the carriers prove`).

What the controller does with what it reads (continuing the same mandate; keeping uncommitted changes to the implementation that match no recorded snapshot as user work and confirming first) is in `firefly-implement`.

### Rebuild the state from what the carriers prove

- A task group is complete only when the task record, Git and the verification record corroborate it. Each is evidence; none of them is a completion on its own.
- When they disagree, rebuild from the candidate snapshot that can be checked and the evidence behind it, following the candidate states table of the contract.
- Missing evidence is marked `unverified`. A predecessor's assurance that it is already fine fills nothing.
- **Versions.** Every version comparison in this skill ignores the `wt:` prefix: a commit changes only the prefix, never the version (contract, Carriers). To compare the spec version a record cites with the present one, set aside the `spec:` a row writes before its version and use what `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot --spec <id>` prints.
- **Lapse of observations and task mappings.** It is decided by spec package version (contract, Carriers). One edited scenario changes the version of every scenario in the change, so every observation and every task mapping that cites the old version lapses with it, in whichever scenario it was made. An observation lapses the same way when the criterion or the measurement method it was observed under changed without changing that version (contract, Lapse); that is judged against the scenario map, not by comparing versions. A `pass` in such a row supports nothing until it is re-verified. Other records lapse only when they are affected, each by its own rule: ready decisions and review packages by the contract's Lapse rule.
- Cite a candidate by the identifier `firefly snapshot` printed when it was fixed; its first 12 characters name its evidence directory, `openspec/changes/<id>/evidence/<snapshot12>/`. Cite the baseline as the `Preflight` section records it: its Baseline commit when its Worktree snapshot is the tree of that commit, otherwise that Worktree snapshot. An uncommitted candidate is located by the content digest of its fixed snapshot.
- Branch pass is not integrated pass. A candidate verified only in a child worktree is `ready-to-integrate`. An observation proves only the candidate in its Candidate column: a row carried over from a child worktree is not a pass for the integrated candidate.
- Continue from the first task group that is incomplete and whose dependencies are satisfied. A dependency is satisfied only by a task group integrated on the target baseline, whether or not it is ticked yet, and, for a promise a downstream task group depends on, only once its check scheduled at `integrated` has the observation row of the designated verifier, and only until it gains an unticked item; one that passes only in a child worktree satisfies nothing.
- **Ticks.** The controller ticks a task group once it is integrated on the target baseline; a group that passed only in a child worktree is not ticked. A tick is not part of the candidate snapshot: the snapshot holds the implementation only, and nothing under `openspec/changes/` is in it (contract, What the candidate is). On resumption one consequence follows. A task group that is integrated on the target baseline but not ticked counts as incomplete. What is missing is the tick that belongs to integration, not the implementation: nothing is implemented again. The rebuilt state says so; the tick is the controller's, made at integration, under `firefly-implement`.
- **Blockers.** A blocker is read from the dispatch and budget rows of the progress record and from the escalation, not from the task record: a note on a task line changes the task package version, and the task record carries none (contract, Recording).
- **The ready decision.** Take the newest row of the `## Ready decision` table in the task record and compare its two package versions with what `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot --spec <id>` and `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot --tasks <id>` print now, the `wt:` prefix ignored on either side.
  - The row carries `ACCEPT` and both versions match: the start is cleared. Work continues at the first task group named above and the joint review is not repeated.
  - A version does not match: the row is `historical`, like every earlier row. The mandate is still waiting for review; implementation has not been cleared to start.
  - The versions match without `ACCEPT`, there is no row, or a call fails: the mandate is still waiting for review; implementation has not been cleared to start.

  **The joint review behind it.** Its identity is `<id>@ready.<spec12>.<tasks12>`, the two package versions without the `wt:` prefix. The dispatch rows of that identity on the progress record show whether it was already sent; the rebuilt state reports it as sent, not as a decision. Its returns are stored as `verdict-<role>-<reviewer>.md` under `openspec/changes/<id>/evidence/ready.<spec12>.<tasks12>/`: a successor of a mandate that is still waiting for review reads there what the joint review found wrong. A return whose identity names other package versions than the current two came back for packages that have changed since; it supports no ready decision for the present ones.
- **A review package.** The verdict rows in the progress record name it `<id>@<snapshot12>.<generation>`. Its package (`package.diff`) and each reviewer's full return (`verdict-<role>-<reviewer>.md`) are in `openspec/changes/<id>/evidence/<snapshot12>/<generation>/`. To learn what a `REVISE` found, take the identity from its verdict row and open the return beside the package. The row is the index; the return says what was wrong. Only the highest generation of a candidate counts; the rows and returns of earlier generations are `historical` (contract, Recording).
- **Dispatches.** A dispatch row with `sent` and no `returned` or `failed` row, the joint review's included, is an interrupted dispatch: on resumption look for that reviewer's return first (contract, Recording). The rebuilt state reports it as interrupted, with whether the return exists. Recording `failed` when there is none is the controller's write, under the skill that owns the dispatch.
- The progress record is not tracked by Git and can be gone. Dispatch counts, repair budget and verdict rows are then not recoverable: a candidate with no surviving verdict record is not `accepted`, and the rebuilt state says so. A return that outlives its verdict row is read for what it says; it is not the verdict record.

A record that lags behind what the snapshot and the evidence prove is reported, not edited here. It is corrected only to reflect a completion the evidence proves, under the skill that owns the record.

### Compress a handoff

1. **Write back first.** A trade-off that still binds in a summary is written back to the decision record or to the minutes; it does not stay in the summary. No mandate row is appended and none is edited.
   - A user decision goes to the minutes, never into a mandate row. A decision that exists only in the conversation is added first as a minutes entry quoting the user's words, by the controller under every mandate (contract, Carriers). The entry goes under `openspec/think/`: into the file the `Minutes: <path>` line names when that is a minutes file there, otherwise into a new file there, whose path is given in the return to the requester. A file the user named is never edited: it is part of the candidate. A conclusion the agent inferred is not a user decision.
   - A choice with lasting force, a rejected alternative for one, goes to the decision record through `firefly-docs`. Before that write-back, check that the mandate's permitted effects cover the write; the party the mandate authorizes to write that carrier puts it on disk, and without that authority the summary is not sent (`## Stop and escalate`).
   - A trade-off that changes the objective, the permitted effects or the terminal condition is a new mandate, not a write-back: no mandate row is written here, a decision of the user among them goes to the minutes first as above, and the summary is not sent with the trade-off still only in it (`## Stop and escalate`).
   - A trade-off the requirement owner has not yet decided is an open blocker, not a binding trade-off. One that exists only in the conversation is recorded first as a minutes entry, under the rule above; it is then an open blocker of the spec, listed under `firefly-propose`.

   The summary then carries the pointers.
2. **Make the candidate locatable.** Fix uncommitted changes as a candidate snapshot before citing them, and cite as under `### Rebuild the state from what the carriers prove`.
3. **Compress in this order.** Keep, first to last: the authority and the endpoint (mandate id, permitted effects with every limit, terminal condition); the candidate location (snapshot, baseline, candidate state); unresolved failures (scenario and check, status, evidence pointer; for a `REVISE`, the return beside its package); rejected options with the reason; the next executable check. Drop repeated process first: narration, superseded drafts, steps the carriers already record.
4. **Add only what the durable facts cannot recover:** the key trade-offs, open assumptions, blocker reasons and the next executable check. Progress that the task record, Git and the verification record already hold is pointed to, never recopied. The summary is not another progress ledger.
5. **Redact.** Remove credentials, tokens and personal or customer data from the summary and from every excerpt before the recipient sees them. What cannot be redacted stays behind a pointer.
6. **Temporary evidence.** Evidence outside the candidate's evidence location (an implementer's report under the worktree's `.superpowers/sdd/`, a pipeline log) may not reach the recipient. Migrate only the excerpt the next check needs, and only when the mandate's permitted effects cover writing it to the candidate's evidence location, which the verifier writes (contract, Carriers). Otherwise mark the item `unverified`.
7. **Test the summary** against `### A qualified handoff` before sending it.

The summary is text handed to the successor: the dispatch, or the reply to the requester when no successor is dispatched in this session. It is not a carrier. Nothing may exist only in it.

### E1 handoff summary

Every identifier below is a placeholder. In a real summary each one is a value read from the carrier named: `<snapshot-sha>` is what `firefly snapshot` printed when the candidate was fixed, and `<baseline>` is what the `Preflight` section records as the baseline, a commit or a worktree snapshot.

```text
Mandate <mandate-id>: a retry after a lost response reuses the original export job.
  Permitted effects: the export service and its tests. Do not release. No push, archive or launch.
  Terminal condition: the integrated candidate holds a valid independent verdict.
Candidate: the intent-ID change is snapshot <snapshot-sha>, state ready-to-integrate.
  Its checks passed in the child worktree only. Nothing is integrated.
Baseline: <baseline>, unchanged since those checks ran.
Open: the lost-response check has no observation on the integrated candidate. unverified.
Rejected: deduplicating by query conditions. A retry after a lost response and a deliberate
  re-export of the same query the next day carry the same query; E1 allows treating only the
  former as the same job. Reason and counterexample: docs/adr/YYYYMMDD-<slug>.md; scenario (S-xxx).
Next check: scenario (S-xxx), the lost-response replay, run on <baseline> once the candidate
  is integrated into it.
```

### A qualified handoff

Three tests. The sender applies them before sending; the recipient applies them on receipt. A successor who took no part in the conversation must be able to:

1. **Find the original decision.** Every rejected option and every binding trade-off points to a carrier that opens: the mandate record, the minutes, the decision record or the scenario. Each limit the summary carries is checked against the permitted effects of the mandate record, one limit at a time. In the other direction, each limit of the mandate record is found in the summary: a limit the summary dropped altogether is a lost limit.
2. **Tell a branch pass from an integrated pass.** Every candidate is named with its snapshot, its baseline, where it was verified and its candidate state. Nothing verified only in a child worktree reads as integrated.
3. **Continue without asking the user again.** The summary carries the mandate, the open items and the next executable check. Nothing the successor needs exists only in the predecessor's conversation. Check it on the next executable check: each fact it depends on is in the summary or behind a pointer that opens.

A summary that fails a test is compressed again before it is sent.

### Check a handoff on receipt

- The carriers alone rebuild the state; the summary only shortens the search. Open the key pointers and do not act on the summary's description of them: the mandate record, the decision behind each rejected option, the evidence of each unresolved failure (for a `REVISE`, found through the package identity on its verdict row), the observation row of each check the summary calls passed, the minutes behind a decision the summary relies on, and the candidate present (`firefly snapshot`, compared with the snapshot the summary names).
- A pointer that does not open marks its item `unverified` in the rebuilt state. A pointer that shows something other than what the summary says settles the item: the rebuilt state follows the carrier, and the summary's claim is dropped. The predecessor's description of it is not evidence.
- An item the summary marks `unverified` stays `unverified` until a designated verifier observes it.
- A check the summary calls passed is `pass` only when the verification record holds its `pass` row on the candidate the summary names and that row has not lapsed; otherwise it is `unverified`.
- A summary that fails a test of `### A qualified handoff` on receipt is not acted on: each failing item is taken from its carrier and marked `unverified` where no carrier holds it.
- A summary that has lost or relaxed a limit of the mandate is void. For a mandate that does not authorize release, a summary missing `do not release` is void: discard it and work from the mandate record. The original mandate governs.

## Outputs

- **Take over: the rebuilt state**, returned in the reply when the takeover ends, before control passes on. It names the mandate (id, objective, permitted effects, terminal condition), the open items read, each candidate with its snapshot, baseline and candidate state, the first incomplete task group whose dependencies are satisfied, whether the start is cleared or still waiting for review (and, when it is waiting, whether the joint review of the present packages was already sent), every gap marked `unverified`, and every pointer that failed to open.
- **Compress: the handoff summary**, returned after the write-back and the snapshot, before the successor is addressed.
- **Write-back of a binding trade-off**, before the summary is sent: a user's decision to the minutes, written by the controller under every mandate; a choice with lasting force to the decision record (`firefly-docs`), by the party the mandate authorizes to write that carrier. No mandate row is written here.
- **No progress table of its own.** Progress is written when produced, by the skill that produces it: each fact goes to its carrier before the next step executes (contract, Write on produce). This skill reads those carriers back. When a fact produced in the session is not yet on its carrier as a handoff is compressed, the skill that produced it writes it first.
- **No observation, ready decision, verdict, dispatch, budget or mandate row, and no task item.** A gap is reported in the rebuilt state; the designated verifier records the observation.

## Handoffs

- The rebuilt state goes back to the controller, which chooses the next step from it (`firefly`). A takeover brings no new write authority: the original terminal condition and permitted effects travel with it.
- Under a mandate that continues into delivery, a mandate cleared to start and a candidate that is `in-progress` or `ready-to-integrate` go to `firefly-implement`. It checks at its entry that the mandate in force covers the delivery, and it performs the resumption steps on the rebuilt state.
- A candidate that is `pending-verdict` goes to `firefly-review`.
- A change with no ready decision that clears the start is still waiting for the joint decision under `firefly-propose`; nothing is dispatched to implementation.
- A candidate that is `accepted`, `rolling-out`, `live` or `archived` is not resumed by implementation. What may follow is commissioned separately through `firefly-archive`.
- A trade-off with lasting force goes to the decision record through `firefly-docs`; a user decision goes to the minutes, written by the controller. A trade-off the requirement owner has not yet decided is an open blocker of the spec, listed under `firefly-propose`.
- A trade-off that changes the objective, the permitted effects or the terminal condition is a new mandate, not a write-back. It goes back to the requester by `ESCALATE`; once the user has decided, the controller records it with `firefly record mandate` (contract, Recording).
- The handoff summary goes to the successor, who takes over through this skill and then enters the skill the state calls for.

## Stop and escalate

Stop and return `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- **No open mandate is on record** while a task record, a candidate or evidence for the intent exists. The authority for the work cannot be established. Owner: requirement owner.
- **The carriers disagree and the surviving snapshots and evidence cannot settle the state**, in particular when an external or irreversible side effect cannot be determined. Never guess it or replay it. Owner: the role that owns the effect in question (contract, Roles).
- **A pointer the next step depends on does not open** and no carrier holds the fact. The item is `unverified` and the next step does not run on it. Owner: the requirement owner, for the authority an observation needs, and the owner of the missing tool or environment, for the capability; the independent reviewer for a verdict.
- **The progress record is gone** and the next step needs a verdict, a dispatch count or the repair budget it held. Owner: controller.
- **A write-back needs authority the mandate does not grant**: the permitted effects do not cover the write to the decision record. The summary is not sent with the trade-off still only in it. Owner: the requester, who grants the mandate.
- **A trade-off changes the mandate**: its objective, its permitted effects or its terminal condition. It is a new mandate, not a write-back, and no mandate row is written here; the user's words are in the minutes first when the user has decided. The summary is not sent with the trade-off still only in it. Owner: the requester, who grants the mandate.

A worktree that differs from the recorded snapshot is reported in the rebuilt state; what happens to it is decided under `firefly-implement`. A summary that lost or relaxed a limit of the mandate is not escalated: it is void, and the mandate record governs.

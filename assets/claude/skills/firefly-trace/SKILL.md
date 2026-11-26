---
name: firefly-trace
description: Agrees the runtime signal requirements a change ships with — the signals an operator needs to tell whether users obtained the promised result — and writes them into the spec file beside the scenarios before planning, then drills the signals on a candidate in a test environment before release and hands the drill record to the release owner. Use when firefly-propose dispatches a scenario that promises users obtain a result or a service with an on-call promise, when the controller dispatches the pre-release drill, or when the user names firefly trace. Not for an internal refactor that meets neither condition.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "24"
---

# firefly Trace

Signals ship with the feature. What ships with it is what an operator needs to tell whether users obtained the promised result: the runtime signals address the product's behavior, not the agent's own steps. Under a proposal dispatch this skill answers three questions and writes the runtime signal requirements into the spec file beside the scenarios; before release it drills the signals on a candidate in a test environment and hands the drill record to the release owner. The shared rules — mandate, carriers, recording, verdicts — are in `${CLAUDE_HOME:-$HOME/.claude}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere. The form of a runtime signal requirement is in `references/signal-requirement.md`; the form of a drill record is in `references/drill-record.md`.

## When to use

- **Under `firefly-propose`.** A scenario promises that users obtain a result, or the service has an on-call promise. The controller dispatches this skill before planning starts, so that the answers to its three questions are written into the runtime signal requirements of the spec file. The writes sit inside the permitted effects of the proposal mandate: the spec package.
- **Before release.** A candidate exists and release is being considered. The controller dispatches the drill; the mandate on record must cover the writes the drill takes — the fault injections in a test environment and the drill record in the progress record.
- **Named.** The user names `firefly trace`, to agree or revise the runtime signal requirements of a change, or to run or repeat a drill. The mandate record must cover the writes the work takes.

## When not to use

- **An internal refactor that meets neither condition.** No scenario promises that users obtain a result and the service has no on-call promise: neither the proposal handoff nor the drill is triggered, and the change proceeds without this skill.

## Mandate

**Fixed end.**

- Under a proposal dispatch: the runtime signal requirements, agreed before planning, written into the spec file beside the scenarios they belong to. The return names which scenarios they went into.
- The drill: either the drill record, bound to the candidate snapshot and the spec version, written into the progress record and handed to the release owner; or the missing signals returned to the implementer.
- Named: the terminal condition of the mandate record in force.

**Permitted effects.**

- Under a proposal dispatch: write runtime signal requirements into `openspec/changes/<id>/specs/**/spec.md`, beside the scenarios they belong to. This skill is a writer of the spec scenarios (contract, Carriers): it writes the requirements itself and reports which scenarios they went into.
- Under a drill dispatch: induce the faults in the test environment the mandate names, and append the drill record under `## Drill records` in `.superpowers/sdd/progress.md`.
- Named: what the mandate record permits, nothing more.

**Not granted.**

- Implementing the signals, or any product code. Missing signals are returned to the implementer; this skill does not add them itself.
- Passing the drill without it. "Logging is enabled" is not acceptance; wired-in logs do not stand in for the drill.
- Treating a dashboard curve as the alert chain having passed.
- Deciding release readiness. The drill record is handed to the release owner; advancing, stopping and rolling back are theirs.
- Editing a scenario's behavior commitment. The runtime signal requirements sit beside the scenarios; the commitments themselves are the spec author's.

## Inputs

- Under a proposal dispatch: the change id; the scenarios the dispatch names, with their stable IDs and the minutes they cite.
- The signals the service already keeps — its metrics, logs and traces — and the records that answer the three questions: the minutes, the main specs, the runbook, the on-call arrangement.
- Under a drill dispatch: the candidate snapshot and the spec version, printed by `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot` and `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot --spec <id>`; a test environment in which the two faults can be induced; someone who did not implement the candidate, to read the signals; the named responder and the runbook.
- On resumption: the runtime signal requirements already written, with the spec package version, and the drill records already appended.

## Procedure

### 1. Take the entry and its limits

1. **Proposal dispatch.** Work only within the permitted effects of the proposal mandate. The requirements are written into the spec file by this skill, and the return names which scenarios they went into.
2. **Drill dispatch.** The mandate on record must cover the fault injections in the test environment and the drill record in the progress record. When it does not, give the conclusion in the reply only, write nothing, and `ESCALATE` to the requester.
3. **Named.** Read the mandate record first; the same rule applies when it does not cover the writes the work takes.

### 2. Answer the three questions from the record first

1. The three questions, answered before any new measurement is chosen: **what counts as success; where users are most likely to fail; who acts on an anomaly and how.**
2. Take the answers from the record first — the minutes, the main specs, the runbook, the signals the service already keeps, the on-call arrangement. An existing signal that answers a question is reused; only a question no existing signal answers gets a new measurement, and the fewest that answer it: a metric, a log line or a trace.
3. A question no record answers is put to the requirement owner through the controller. The owner's answer is written into the runtime signal requirement itself: the spec file beside its scenario is its carrier.

### 3. Keep the two failures an operator treats differently apart

1. The most easily misjudged pair in an async export: **"the request was accepted" and "the file is available."** Submission success can coexist with a growing export backlog, and a job can be set ready while its file cannot be downloaded.
2. The two failures take different remedies: the first asks for the waiting state of unfinished work, the second for the retrieval outcome after the ready state. One undifferentiated error count must not cover both: a signal set that shows no more than "an error happened" cannot tell an operator which remedy to take.
3. Metric dimensions stay bounded. Neither user ids nor job ids become high-cardinality labels. Correlating an individual case uses a scoped, redacted record; report contents are not stored.

### 4. Write the runtime signal requirements beside the scenarios

1. The carrier is `openspec/changes/<id>/specs/**/spec.md`, beside the scenarios the requirements belong to — never `design.md` alone: it is in neither package version (contract, Carriers). The template and the worked examples are in `references/signal-requirement.md`.
2. Writing or editing a requirement changes the spec package version.
3. The return to the proposal names which scenarios the requirements went into. `firefly-tasks` schedules the runtime signal requirements from the spec like any other behavior; a requirement no task delivers has no passing condition.

### 5. Run the drill in a test environment

1. Induce the two faults separately — delayed processing in one run, unreadable output in the other.
2. Ask someone who did not implement the candidate — a person or an agent — to read the signals, locate the failed stage, and name the responsible component to check next. The executor's reading is the drill's result; this skill does not read its own signals in the executor's place.
3. The drill passes only when the two failure stages are told apart into their two remedies. When the signals show no more than "an error happened" and cannot distinguish the two paths, the missing signals go back to the implementer and the drill is not passed.
4. "Logging is enabled" is not acceptance: wired-in logs do not replace the drill.

### 6. Record the drill and hand it to the release owner

1. Bind the drill record to the candidate snapshot, the spec version, the induced faults and the executor. Both values are printed by the runtime; nobody derives them:
   - `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot` prints the candidate snapshot.
   - `"${CLAUDE_HOME:-$HOME/.claude}/firefly/bin/firefly" snapshot --spec <id>` prints the spec version.
2. Append the record under `## Drill records` in `.superpowers/sdd/progress.md` — the one section of the progress record this skill appends, and only the record of a drill this skill ran. It is appended, never rewritten; a lapsed drill record is read as `historical` by rule and is never edited. The form of the record is in `references/drill-record.md`.
3. The record carries the candidate snapshot, the spec version, the induced faults, the executor, what the executor could and could not distinguish, the observation method, the owner and the next step on an anomaly.
4. The drill record is handed to the release owner. The release decision is theirs.
5. **When the drill is repeated.** The candidate changed after the drill, or a runtime signal requirement changed after the drill: run the drill again on the new candidate and the new requirements. Only the spec version changed while every runtime signal requirement is unchanged: the drill is not repeated; append a line to the drill record naming the new spec version and the reason the drill is unaffected.

### 7. The on-call chain

1. **With an on-call promise,** interrupt the telemetry in the test environment as a third induction: a silent signal source must be told apart from an absence of failures — "no data" is not "no failures".
2. Verify that the notification reaches the named responder and that the runbook leads from the alert to a next step. Record the trigger, the channel, the receipt and the recovery.
3. A working dashboard curve does not pass the alert chain: the chain passes only when the responder was reached and could act.
4. A chain that reaches no named responder, or a runbook with no next step, is recorded as it happened, and its missing part goes back with the drill's other missing signals.
5. **Without an on-call promise,** no alert chain is drilled: the drill record and the return state that the change is observable but will not actively notify.

## Outputs

| Fact | Carrier | Written |
|---|---|---|
| Runtime signal requirements: the three answers, the reused signals, the added measurements, the bounded-dimension and redaction rules | `openspec/changes/<id>/specs/**/spec.md`, beside the scenarios | Under a proposal dispatch, as agreed; every edit changes the spec package version |
| The drill record: candidate snapshot, spec version, induced faults, executor, what was and was not distinguished, observation method, owner, next step on an anomaly; the on-call chain's trigger, channel, receipt and recovery, or the visibility-without-notification statement | `.superpowers/sdd/progress.md`, section `## Drill records` | After the drill, before the handover to the release owner |
| The missing signals | The return, to the implementer through the controller | When the drill is not passed |

## Handoffs

- **From `firefly-propose`.** The controller dispatches the scenarios where a scenario promises that users obtain a result, or the service has an on-call promise. A returned conclusion goes back to the scenario it concerns and brings no new write authority.
- **Back to `firefly-propose`.** The signal requirements are written into the scenarios; the return names which scenarios they went into, and planning starts.
- **From the controller, before release.** The drill dispatch, with a mandate covering the fault injections and the drill record.
- **To the implementer, through the controller.** The missing signals the drill could not distinguish.
- **To the release owner.** The drill record with its candidate snapshot, the observation method, the owner and the next step on an anomaly. The release decision is theirs.
- `firefly-tasks` schedules the runtime signal requirements from the spec like any other behavior.

## Stop and escalate

Stop and `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- **The mandate on record does not cover the writes this entry takes** — a named entry, or a drill dispatch without coverage. The conclusion goes in the reply, nothing is written. Owner: the requester.
- **A question no record answers, and the requirement owner has not answered it**, while the runtime signal requirements cannot be agreed without it. Owner: the requirement owner.
- **The test environment cannot induce the faults, or no one who did not implement the candidate can read the signals.** The drill cannot run as designed. Owner: the requester, for the environment or the executor.

An `ESCALATE` is a return path, not a verdict.

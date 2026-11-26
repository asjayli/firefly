# Drill record: form and rules

The drill record is appended under `## Drill records` in `.superpowers/sdd/progress.md` — the one section of the progress record `firefly-trace` appends, and only the record of a drill this skill ran. The recorder has no subcommand for it, so the record is appended as text. It is appended, never rewritten: a lapsed drill record is read as `historical` by rule and is never edited, the way the contract treats every append-only record.

## Form

One block per drill, appended under the section heading:

```markdown
- **<YYYY-MM-DD> — <change id>**
  - Candidate: <the candidate snapshot, as `firefly snapshot` printed it at drill time>
  - Spec version: <the spec package version, as `firefly snapshot --spec <id>` printed it at drill time>
  - Faults induced: delayed processing; unreadable output — separately
  - Executor: <who read the signals: a person or an agent who did not implement the candidate>
  - Distinguished: <the stage the executor located, and the responsible component named>
  - Not distinguished: <none, or what the signals could not tell apart>
  - Observation method: <which metrics, logs and traces the executor read, and where>
  - Owner: <who owns the signals and the anomaly response>
  - Next step on anomaly: <the action the owner takes when the signals show a failure>
  - On-call chain: <trigger, channel, receipt, recovery — or "no on-call promise: observable, no active notification">
```

Every field is bound to the drill that produced it. The candidate snapshot and the spec version are the values the runtime printed at drill time — never a value recomputed or estimated afterwards.

## Rules

- **Bound to candidate and spec version.** The record names the candidate snapshot and the spec version it was drilled against. A reader can tell whether it still describes the current candidate and the current requirements.
- **Passed only on distinction.** The record states what the executor could and could not distinguish. When the signals showed no more than "an error happened" over the two failure stages, the drill is not passed: the missing signals go back to the implementer, and that return — not a softened record — is the outcome. "Logging is enabled" is not acceptance.
- **Repeat.** The candidate changed after the drill, or a runtime signal requirement changed after the drill: run the drill again on the new candidate and the new requirements, and append a new block. Only the spec version changed while every runtime signal requirement is unchanged: the drill is not repeated; append one further line to the block naming the new spec version and the reason the drill is unaffected.
- **The on-call chain.** With an on-call promise, the block carries the chain's trigger, channel, receipt and recovery — the notification was stopped in test, "no data" was told from "no failures", the named responder was reached and could follow the runbook to a next step. A working dashboard curve does not pass the alert chain. Without an on-call promise, the block states it: observable, no active notification.
- **Handover.** The completed record is handed to the release owner, with the observation method, the owner and the next step on an anomaly. The release decision is theirs.

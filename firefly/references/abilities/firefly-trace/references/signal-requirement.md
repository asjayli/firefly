# Runtime signal requirement: template and examples

Each runtime signal requirement lives in the spec file of the change, beside the scenario it belongs to: `openspec/changes/<id>/specs/**/spec.md`. There is no separate signal list: a requirement separated from its scenario is not read when the scenario ships, and a promise recorded in `design.md` alone judges nothing — `design.md` is in neither package version. The requirement is in the spec package, so writing or editing it changes the spec package version, and the observations, mappings and packages that cite the old version lapse under the Lapse rule of the contract.

## The fields

```markdown
**Runtime signals:** <one line naming what the operator must be able to tell>
- **Applies to:** <the scenario it belongs to, and when the requirement applies>
- **Success:** <what counts as success for that scenario>
- **Failure stages:** <where users are most likely to fail, each stage named>
- **On anomaly:** <who acts on an anomaly and how: the owner and the next step>
- **Signals:** <the existing signals reused, and the fewest added measurements — a metric, a log line or a trace — one per unanswered question>
- **Correlation:** <how an individual case is correlated: a scoped, redacted record; never user or job ids as labels>
- **On-call:** <the on-call promise the service makes, or "none: observable, no active notification">
```

- **Applies to** names the scenario by its stable ID and states when the requirement holds. It is the line the drill record cites back to.
- **Success** answers the first question: what counts as success. For the export case it is not "the server accepted the request" but "the requester retrieved a file with the correct content".
- **Failure stages** answers the second: where users are most likely to fail, each stage named so a reader of the signals can locate which one failed. In an async export the two named stages are queue waiting and post-ready retrieval — two failures an operator treats differently.
- **On anomaly** answers the third: who acts on an anomaly and how. It names the owner and the next step, so a responder reached by an alert can act without re-deriving the diagnosis.
- **Signals** lists what is reused first. An existing signal that already answers a question is reused; only a question no existing signal answers gets a new measurement, and the fewest that answer it.
- **Correlation** keeps metric dimensions bounded: neither user ids nor job ids become high-cardinality labels, report contents are not stored, and correlating an individual case uses a scoped, redacted record.
- **On-call** states whether the service has an on-call promise. With one, the alert chain is drilled (SKILL, step 7); without one, the delivery states that the change is observable but will not actively notify.

## Example: the async export, two failure stages kept apart

```markdown
**Runtime signals:** an operator can tell whether an export reached its requester, and which stage failed when it did not
- **Applies to:** (S-003) retrieval of the generated file — every delivery of this scenario
- **Success:** the requester retrieved a file whose content matches the submitted sample
- **Failure stages:** queue waiting (the job is accepted but unfinished); post-ready retrieval (the job is ready but the file cannot be downloaded)
- **On anomaly:** the export service owner checks the waiting depth first, then the retrieval errors after ready; the runbook names both steps
- **Signals:** reused — the existing submission counter and job-state log; added — queue waiting time by bounded age bucket, and retrieval outcome (bytes served or error class) after ready
- **Correlation:** a scoped, redacted job record keyed by a case id; no user or job id as a metric label; report contents are not stored
- **On-call:** the service pages the named responder on a sustained waiting depth or a retrieval failure rate over the stated line
```

Submission success can coexist with a growing export backlog, and a job can be set ready while its file cannot be downloaded. The two failures take different remedies, so one undifferentiated error count must not cover both: the requirement names the two stages, and the drill proves a reader of the signals can tell them apart.

## Example: reuse only

When the signals the service already keeps answer all three questions, the requirement records the reuse and adds nothing:

```markdown
**Runtime signals:** an operator can tell whether a sync page render reached its requester, from the signals the service already keeps
- **Applies to:** (S-005) rendering of the summary page
- **Success:** the render completed within the response, as the existing request log already shows
- **Failure stages:** request rejected at the edge; render error — both already logged by stage
- **On anomaly:** the platform owner follows the existing runbook entry for render errors
- **Signals:** reused — request log and render error counter; added — none
- **Correlation:** the existing request id, already scoped and redacted
- **On-call:** none: observable, no active notification
```

## What is not written as a requirement

- A new measurement for a question the existing signals already answer.
- An unbounded label: user ids or job ids as metric dimensions, or report contents kept in logs.
- A signal set that shows no more than "an error happened" over the two failure stages an operator treats differently.
- An alert-chain claim: a dashboard curve is not a delivered notification, and "logging is enabled" is not acceptance. The drill, not the wiring, is what the requirement's delivery is judged by.

# CI gates: mounting, promotion and pipeline results (design 21)

This reference carries the mechanical steps of the third entry of firefly-guard: mounting gates into the host platform's gate mechanism in the consuming project's CI. The shared rules — mandate, carriers, observation records, recording, verdicts — are in `<skill-root>/references/handoff-contract.md`; they are referenced here and restated nowhere.

## What belongs in the pipeline

- A requirement with a defined input, a repeatable outcome and a failure someone can act on belongs in the pipeline.
- firefly-bounds defines the quality bars (05); a web delivery deposits the replayable checks it distinguished (14); firefly-perf hands over the regression baselines of measurements that became product promises (19). Security gates enter the same way: this skill receives functional and security gates alike, not scanners only.
- Trade-offs, exception approvals and the authorization of irreversible actions stay with people. A checker judges the candidate it receives; it cannot ratify a decision for a person. The presence of an item in a pipeline is not evidence that the check is valid.
- Each mounted gate pins five things: its trigger scope, the candidate, the actual exit status, the failure owner and the replay method.

## Mount a gate

1. Mount only under write authority: the mandate's permitted effects must cover writes to the consuming project's CI configuration. Wire the gate into the host platform's gate mechanism and state what each failure means.
2. A read-only mandate proposes instead of applying: it hands an identified owner a configuration task pending authorization and writes no project configuration. A read-only review proposes configuration changes rather than applying them.
3. The failure owner and the replay method ride with the gate. A check mounted without a failure owner is a suggestion, not a gate.

## Promote a suggested check to a blocking one

1. Before promotion, test the check's power to distinguish: run one candidate with a known violation and one candidate that should pass. An E3 check that only searches for the text `ready` accepts an error page; check the actual file contents instead, and only then consider promotion.
2. Record as a trial what the rule would have blocked. A trial changes no existing verdict.
3. Promote only when the results are stable, every false block is explained, and a failure owner is identified.
4. A promoted gate counts as a changed measurement method (contract, Lapse). It reaches the standing records of the check it now enforces:

| Candidate | What the promoted gate does |
|---|---|
| Accepted, not yet serving traffic | The observations and verdicts of its affected scenarios lapse; the review package is rebuilt for re-review, with the gate's result as evidence in the package. |
| In rollout | Traffic is not rolled back automatically. The gate's result goes to the release owner, who decides advance or stop under the plan. |
| Live | Not revisited. |
| Archived but not yet live | Checked against the gate at readiness assessment. |

## Record each result

Every result carries the candidate snapshot, the check, the status, the redacted evidence location and the owner.

- A behavioral failure returns to the implementer of the change.
- Tool failure, unavailable input, and any required job that was skipped, cancelled or produced no result are recorded `unverified` and returned to firefly-review — even when the pipeline's overall light is green.
- Justified non-applicability is recorded separately, with its rule: `not-applicable` needs `--rule`.
- Not-run, non-applicable and passed never share one green mark.
- Write the observation row for a check the scenario map of the change names this skill the verifier of:

  `"<skill-root>/scripts/firefly.sh" record observe --change <id> --candidate <tree-sha> --spec <version> --scenario <S-xxx> --check <name> --result <pass|fail|unverified|not-applicable> --observer verifier:firefly-guard [--evidence <path>] [--rule <text>] --note "<conditions observed under, the pipeline run included; the expected outcome the scenario map row named when observed; the check that row named>"`

- The evidence goes under `openspec/changes/<id>/evidence/<snapshot12>/`, redacted: no report contents, no credentials, no raw sensitive output. Before the check, capture the inputs with `firefly snapshot` and `firefly snapshot --spec <id>`. Pass those exact values; later changes leave the observation historical.

## Results that arrive outside a session

- Pipeline results usually arrive after the session ends. Write the status of the matching check into the verification record; the next session's resumption reads it and returns it to the owner.
- Build no listener and no poller for gates (contract, Write on produce).

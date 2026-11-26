# Rule candidates and the ## Retro rules section (design 26)

This reference carries the five fields of a rule candidate and the rows firefly-retro appends to `## Retro rules` in `.superpowers/sdd/progress.md`. The shared rules — mandate, carriers, recording — are in `${CODEX_HOME:-$HOME/.codex}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere.

## The five fields

A rule candidate is stated with five fields, none omitted:

1. **Scope.** Which rule text or gate it amends, and which checks it applies to.
2. **Base revision.** The version of the rule text it amends — the version the shadow-score ran against.
3. **Expected misses prevented.** The class of error it is expected to stop, with the incident that motivates it.
4. **Possible false blocks.** What correct work it could block that the existing rule does not.
5. **Withdrawal condition.** The observed state under which the rule is withdrawn — stated before activation, so a withdrawal is a judgment against a recorded condition, not a change of mood.

A candidate stated without one of the five is returned to its author, not recorded.

## The ## Retro rules rows

- `## Retro rules` lives in `.superpowers/sdd/progress.md`. It is appended by hand — the recorder has no subcommand for it — and never rewritten. firefly-retro appends the rows of the candidates it produced; the controller appends the rest.
- A candidate's row carries: the candidate id, the five fields, the shadow and held-out results that support it, and its version, from v1.
- **Approval and activation are two records.** The approval of the improvement proposal records the candidate. Activation is a separate approval; its row names who approved it and the version that takes effect. Until that row exists, the candidate is a proposal, not a rule.
- **After activation**, the version and the rollback basis stay on record. Withdrawal appends a row citing the withdrawal condition as observed; it edits no earlier row.

## Adoption rules

- Prefer the cheaper equivalent when two interventions remove the cause equally.
- Reject a candidate whose benefit no one can review: a claimed improvement with no comparable record behind it is not a benefit.
- A candidate that introduces a new false block on a required scenario in the held-out cases, without a risk acceptance the requester or the requirement owner recorded, is rejected. A rule already active meets its withdrawal condition.
- An unwired bad-file fixture is not a rule matter: the fixture is fixed and routed to firefly-guard's gate-mounting entry; the review instructions are not updated for it.

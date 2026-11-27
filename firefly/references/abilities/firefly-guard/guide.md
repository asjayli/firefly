---
name: firefly-guard
description: Use when the user commissions a read-only security check of a named scope — whether another identity can read a file, what a change to permissions exposes — when a review dispatches the affected checks of the security axis because a change touches identity, data flow, dependencies or permissions, or when functional gates (quality bars, replayable checks, regression baselines) or security gates must be mounted into the consuming project's CI. Returns coverage and results stated separately, and mounts gates only under write authority. Not for an unrelated small change, which triggers no full audit.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "18,21"
  absorbs: ["21"]
---

# firefly Guard

Security checks and gate mounting. The two checking entries share one set of criteria and differ in what they may write: a named commission from the user, and the affected checks of a review's security axis. Gate mounting is the host's third entry: functional and security gates enter through this skill and are wired into the host platform's gate mechanism in the consuming project's CI. The shared rules — mandate, carriers, observation records, recording, verdicts — are in `<skill-root>/references/handoff-contract.md`; they are referenced here and restated nowhere. The pipeline mechanics of the third entry are in `references/ci-cd.md`.

## When to use

- **Named.** The user commissions this skill to check a named scope — to learn, for example, whether another identity can read a file, or what an edited permission set exposes. A read-only investigation: the conclusion returns to the requester, and nothing is written that the mandate does not cover.
- **From firefly-review.** The review dispatches only the affected checks of the security axis: the change touches identity, data flow, dependencies or permissions. Only those checks run; their results return to that review; the verdict stays with the independent reviewer.
- **Gate mounting — the host's third entry.** Functional gates and security gates enter through this skill together, not scanners only: the quality bars firefly-bounds agrees (05), the replayable checks a web delivery deposits (14), the regression baselines of measurements that became product promises (19), and the security gates beside them. This skill wires them into the host platform's gate mechanism in the consuming project's CI and states what each failure means. Mounting takes write authority; a read-only mandate raises a configuration task pending authorization. The mechanical steps are in `references/ci-cd.md`.

## When not to use

- An unrelated small change triggers no full audit. A change that touches no identity, data flow, dependency or permission adds no security axis, and a dispatch that names no affected check runs nothing.

## Mandate

**Fixed end.**

- Named: the conclusion, coverage and results stated separately, returned to the requester.
- From a review: the results of the affected checks returned to that review, per check the scenario, the check, the measurement method used, the result and the evidence pointer. The verdict is the independent reviewer's.
- Gate mounting: under write authority, the gates mounted with the meaning of each failure stated; under a read-only mandate, a configuration task pending authorization, with its receiver, returned to the requester.

**Permitted effects.**

- Read the repository and the records of the named scope, or of the change a dispatch belongs to.
- From a review: one write — the observation row of each affected check, through `firefly record observe`, with its evidence under `openspec/changes/<id>/evidence/<snapshot12>/`. Under this dispatch this skill is the verifier its scenario map row names.
- Gate mounting, under write authority: the consuming project's CI configuration, within the permitted effects of the mandate, as `references/ci-cd.md` describes; and the observation row of a check whose scenario map names this skill the verifier, a mounted gate's included.
- Named: nothing is written. The conclusion lives in the reply.

**Not granted.**

- Finding a risk grants no edit to configuration, no external transmission, no deletion and no release. The two checking entries differ in what they may write, never in the criteria they apply.
- The verdict of a review.
- Executing an irreversible disposition.
- Overriding an action the project prohibits with an ad hoc approval.
- Repairing what a check finds. A finding goes to its owner or back to the review.

## Inputs

- The mandate record: for work that has no change, the `## Mandates` table of the progress record; for work under a change, the `## Mandate` section of its `proposal.md`. It says which entry this is and what its permitted effects cover.
- The named scope; or the affected checks of the security axis with their rows of `## Scenario map` in `openspec/changes/<id>/tasks.md` — the check with its command or step, the expected outcome, the verifier — together with the spec version and the candidate snapshot the observations are made on.
- The test identities the checks take, with the roles they hold: one owner identity and one other authorized identity per boundary, at least.
- The control catalog the project keeps — identity, privacy, dependencies, secrets management — where there is one.
- For gate mounting: each gate with its source, its failure owner and its replay method, and a mandate whose permitted effects cover writes to the consuming project's CI.

## Procedure

### 1. Take the entry and its permissions

1. **Named.** Read the mandate record first. The mandate must cover every write the work takes; this entry writes nothing and returns its conclusion in the reply. A write it would need — mounting a gate, say — that no mandate covers goes to `## Stop and escalate`.
2. **From a review.** Run only the checks the dispatch names. Change nothing: not the candidate, not its spec, not its tasks. The observation row and its evidence are the only write. The results return to the review; no write authority comes with them.
3. **Gate mounting.** Mount only under write authority. Under a read-only mandate, raise a configuration task pending authorization instead and write no project configuration (`references/ci-cd.md`).

### 2. State asset, permitted actor and trust boundary

1. For each affected asset, state what is protected, who is permitted access, and where the trust boundary runs. Then give each boundary two testable cases, one on each side.
2. The export case E2: the positive case is the owner retrieving the owner's own report with a test identity; the negative case is another authorized test identity that must not read the report and must not obtain its contents from any return value.
3. When the project keeps no control catalog, propose the minimal applicable list from the actual boundaries and refer the unknowns to the project's security owner. Declare no whole-product safety.

### 3. Test both sides and record each status separately

1. Run the positive and the negative case as two checks; record a status for each of them. The scenario conclusion takes the worst of the checks and branches (contract, Observation record).
2. Owner success alone settles nothing: when only the owner path ran, the conclusion is "normal function passed, isolation unverified".
3. A check that acts as a second test identity is observed by a verifier who did not implement the candidate — the `## Scenario map` row decides, and such a row never names `implementer`.

### 4. Map assets and flows to the applicable controls

1. Map the affected assets and data flows to the controls the project applies — identity, privacy, dependencies, secrets management. For each control, list the owner, the check, the redacted evidence or the reason it was not examined.
2. Identity checks that pass on both sides while the logs carry report contents still fail the privacy control.
3. An action the project prohibits cannot be overridden by an ad hoc approval.

### 5. Record observations and redacted evidence

1. For each affected check of a review dispatch, and for a mounted gate whose check the scenario map names this skill the verifier, write the observation row as it is produced, before the next step:

   `"<skill-root>/scripts/firefly.sh" record observe --change <id> --candidate <tree-sha> --spec <version> --scenario <S-xxx> --check <name> --result <pass|fail|unverified|not-applicable> --observer verifier:firefly-guard [--evidence <path>] [--rule <text>] --note "<conditions observed under, the roles of the test identities included; the expected outcome the scenario map row named when observed; the check that row named>"`

   - `pass` and `fail` need `--evidence` naming an existing path, put under `openspec/changes/<id>/evidence/<snapshot12>/`.
   - `not-applicable` needs `--rule` naming the rule that applies and the reason.
   - `--note` is never omitted: it carries the conditions observed under, the expected outcome the scenario map row named when the observation was made, and the check that row named (contract, Recording).
   - Before the check, capture the inputs with `firefly snapshot` and `firefly snapshot --spec <id>`. Pass those exact values; later changes leave the observation historical. A rejected call writes nothing.
2. What is retained: the candidate snapshot, the roles of the test identities, the observations and redacted locations. What is never retained: report contents, credentials or raw sensitive output — not in the evidence, not in the note.

### 6. Report coverage separately from results

1. State what was examined and what was not, separately from the results. Input that was not scanned, was unreadable or could not be reached is not clean.
2. Return per check: the scenario, the check, the measurement method used, the result and the evidence pointer. From a review dispatch the results return to the review; the verdict is the independent reviewer's.

### 7. Keep irreversible dispositions blocked

1. A finding that calls for an irreversible disposition stays blocked. Whoever executes it verifies, before the action happens, the approval of the specific action, the target and the candidate snapshot by an authorized person.
2. Pending, denied or changed scope stays blocked.
3. An approval record found at archive does not retroactively authorize an execution that lacked authorization when it happened.

### 8. Mount gates through the host's gate mechanism

Mounting, promotion and the recording of pipeline results follow `references/ci-cd.md`. Two permissions hold everywhere in it: mounting takes write authority; a read-only mandate raises a configuration task pending authorization, with its receiver, and writes no project configuration.

## Outputs

| What | Carrier | Written |
|---|---|---|
| The conclusion, coverage and results stated separately | The reply to the requester | A named entry, as its fixed end |
| The observation row of an affected check | `openspec/changes/<id>/verification.md`, through `firefly record observe` | From a review dispatch, and for a mounted gate whose check the scenario map names this skill the verifier, as it is produced |
| The evidence of an observation, redacted | `openspec/changes/<id>/evidence/<snapshot12>/` | Before the row that cites it |
| A mounted gate, or a configuration task pending authorization with its receiver | The consuming project's CI; the reply to the requester | Under write authority, as `references/ci-cd.md` describes; under a read-only mandate, the task only |

## Handoffs

- **From firefly-review.** Only the affected checks of the security axis. Their results return to that review; no write authority comes with them.
- **To firefly-review.** Per check: the scenario, the check, the measurement method used, the result (`pass`, `fail` or `unverified`) and the evidence pointer. The independent reviewer issues the verdict.
- **From firefly-bounds.** A constraint whose measurement method is stable and whose failures have an owner, with the requirement owner's consent, to be mounted as a regression check. A regression baseline that firefly-perf handed over rides the same path once bounds agreed its constraint.
- **From firefly-verify-web.** A replayable check saved in the project after it was run once on a known-wrong candidate and once on a correct one. It enters the pipeline through the same mounting entry.
- **To the requester.** The conclusion of a named check, coverage and results stated separately; or a configuration task pending authorization, with its receiver.

## Stop and escalate

Stop and `ESCALATE` with the current conclusion, the missing evidence or authority, and the responsible owner when:

- The mandate record does not cover a write the named entry takes. The conclusion goes in the reply, nothing is written. Owner: the requester.
- A gate must be mounted and no write authority covers the consuming project's CI. The configuration task, with its receiver, goes in the reply. Owner: the requester.
- An irreversible disposition is called for and its approval is pending, denied or its scope has changed. It stays blocked; this skill executes nothing. Owner: the person who can approve the specific action, target and candidate snapshot.
- The test identities a boundary's two cases need do not exist and cannot be created under the existing authority. Owner: the requester.

A conclusion limited by unexamined inputs is a result, not an escalation: report the coverage gap with it. An `ESCALATE` is a return path, not a verdict.

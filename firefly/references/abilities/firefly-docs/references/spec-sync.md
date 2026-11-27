# Spec sync

The mechanical steps of one sync: applying a change's delta specs to the main specs under a mandate that permits it. What is kept, where, and under whose authority is decided in `../guide.md`; this file carries the steps and stops where `../guide.md` stops.

## 1. Resolve the change and its planning root

- The mandate or the request names the change. When none does, run `openspec list --json` and keep the active changes that carry delta specs. Conversation and repository evidence identify the target first. One plausible target is taken as named. When several remain equally plausible, report them back instead of applying anything: the `ESCALATE` carries the candidates, the evidence and a recommended default.
- Run `openspec status --change "<name>" --json` and read `planningHome.root` from it. It is the authoritative planning root of the change: every main spec path below derives from it, never from the current working directory.

## 2. Take the delta specs

- `artifactPaths.specs.existingOutputPaths` from the status JSON is the list of the change's delta spec files.
- The list is empty when the change declares no spec deltas: report that and stop. Nothing is applied and no main spec is created.
- Each delta file holds some of these sections:

```markdown
## ADDED Requirements

### Requirement: <name>
The system SHALL ...

#### Scenario: <case>
- **WHEN** ...
- **THEN** ...

## MODIFIED Requirements

## REMOVED Requirements

## RENAMED Requirements

- FROM: `### Requirement: <old>`
- TO: `### Requirement: <new>`
```

## 3. List the commitments

Before anything is edited, enumerate what this sync commits to, operation by operation: the capability, the requirement, the operation (`ADDED`, `MODIFIED`, `REMOVED`, `RENAMED`), and the target it names. Reconcile each commitment with the implementation and the tests of the accepted candidate, and record where each one lives in them. A commitment the implementation or the tests do not bear is recorded as a gap and travels with the comparison to the non-author review; it does not slip into the main spec as if it were settled; a commitment the reviewer does not pass is not applied: the plan drops it or the sync stops under `../guide.md`, `## Stop and escalate`.

## 4. Check the four preconditions

For each planned operation, against the current main spec of its capability:

1. **Mapping.** The delta operation resolves to exactly one target: one requirement in the current main spec, or one main spec file to create.
2. **Content preservation.** Everything the operation does not mention stays as it is: scenarios, descriptions, references, and every other clause of the capability.
3. **Applicability.** The operation can be applied to the main spec as it stands: a `MODIFIED` or `RENAMED` operation names a requirement that is there, and an `ADDED` operation names a requirement the main spec does not already hold in the delta's form.
4. **Idempotency.** Applying the plan twice changes nothing the second time: each operation is expected to reach its end state in one application.

A precondition that fails is repaired in the plan — the main spec is not touched in this step — and the same check runs again. A precondition that cannot be met inside the mandate's permitted effects stops the sync under `../guide.md`, `## Stop and escalate`.

## 5. Send the before/after comparison to the non-author review

- Assemble the before/after semantic comparison: per capability, what the main spec commits to before the sync and after it, commitment by commitment, with the old-to-new mapping of every rename and the preservation statement of step 4.
- Send it to the non-author closeout review of `firefly-archive`: a reviewer who did not produce the sync. An accessible file is not proof of preservation: the reviewer checks the comparison clause by clause and the preservation statement against the main spec itself.
- Apply only after the review passes. A review that does not pass sends the plan back to step 4, repaired, with an updated comparison; a fresh non-author review sees it again before anything is applied.

## 6. Apply the plan

Apply to `<planningHome.root>/openspec/specs/<capability>/spec.md`; the file may not exist yet.

**`ADDED Requirements`:**

- The requirement is not in the main spec: add it.
- It is already there: update it to match the delta's intent — an implicit modification, visible in the comparison.

**`MODIFIED Requirements`:**

- Find the requirement in the main spec and apply the delta's changes: a scenario added, a scenario changed, the description changed.
- Preserve every scenario and every clause the delta does not mention.

**`REMOVED Requirements`:**

- Remove the whole requirement block. The comparison carries the removal; nothing else of the capability is touched.

**`RENAMED Requirements`:**

- Find the `FROM` requirement and rename it to `TO`. Its description, scenarios and references are kept as they are: a rename changes the identifier, never the content.
- Record the old-to-new mapping in the decision record that covers this sync (`../guide.md`, `### Write a decision record`), so a citation of the old identifier — in an observation row, a verdict, an evidence path or an earlier record — can be traced to the requirement it names now. Delete-and-add loses that history silently and is never used in its place.

**A capability with no main spec yet:**

- Create `<planningHome.root>/openspec/specs/<capability>/spec.md` with the authored `## Purpose` from the delta and a `## Requirements` section holding the added requirements. If the delta lacks a usable purpose, write one from the approved requirement before the comparison goes to review. Preserve any existing main spec purpose unless the approved plan explicitly changes it.

The delta states intent, not a wholesale replacement: a scenario is added by including that scenario under `MODIFIED`, not by copying the ones that already exist. Merge with judgment, and let the comparison of step 5 carry every judgment made.

## 7. Validate and check idempotency

- Run the strict spec validation: `"<skill-root>/scripts/firefly.sh" validate --root "<planningHome.root>" --change "<id>"`. It fails: repair the applied result inside the mandate's permitted effects and rerun the same failed validation. A repair that changes what the comparison states — a commitment moved, renamed or dropped — returns the plan to step 5 before it is applied again.
- Check idempotency and preservation by rereading the applied main specs against the plan: applying the same plan again changes nothing, and every clause the delta does not mention is unchanged. A difference is repaired as above.
- Validation or idempotency that cannot be made to pass inside the permitted effects stops the sync under `../guide.md`, `## Stop and escalate`.

## 8. Report

Report through `../guide.md`: the capabilities updated, the operations applied per capability (added, modified, removed, renamed), the mapping recorded for a rename, the outcome of the strict validation and the idempotency check, and that the change stays active — archive is a separate commission under `firefly-archive`.

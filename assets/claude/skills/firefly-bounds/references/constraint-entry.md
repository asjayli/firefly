# Constraint entry: template and examples

Each quality constraint lives in the spec file of the change, beside the scenario it constrains: `openspec/changes/<id>/specs/**/spec.md`. There is no separate constraint list: an entry separated from its scenario is not read when the scenario is judged. The entry is in the spec package, so writing or editing it changes the spec package version, and the observations, mappings and packages that cite the old version lapse under the Lapse rule of the contract.

## The six fields

```markdown
**Constraint:** <one line naming what is bounded>
- **Applies to:** <the scenario it constrains, and when the constraint applies>
- **Owner:** <the requirement owner, who carries the consequence of failure>
- **Criterion:** <the line the measured value is judged against, or the invariant that holds>
- **Method:** <workload, environment and sampling: how the number is produced>
- **Baseline source:** <the project record the baseline comes from>
- **On failure:** <what happens when the constraint fails>
```

- **Applies to** names the scenario by its stable ID and states the conditions the constraint holds under. This is the field a standard revision changes when the facts change.
- **Owner** is the requirement owner: the role that decides trade-offs whose consequences it carries, and decides which measured changes are acceptable.
- **Criterion** is decidable. "Fast" is not a criterion; a value judged against a stated line is.
- **Method** states the workload, the environment and the sampling. A load constraint is comparable only under the conditions its method states; two numbers measured under different conditions are not compared directly.
- **Baseline source** points to a project record: an existing test, a service objective, a standing reference value in the main specs, or a measurement recorded under `openspec/changes/<id>/probes/<name>/` with its workload and variation. Never a bare number.
- **On failure** states the consequence: the delivery is blocked and the finding goes back to the review, or — once the requirement owner consents — the constraint is handed to firefly-guard to mount as a regression check.

## Hard constraint: the denial is the evidence

A hard constraint has no tolerance, and a pass by one identity never proves it. "Only the requester can download the export":

```markdown
**Constraint:** only the requester can download the export
- **Applies to:** (S-002) another account cannot retrieve the file — every time, no tolerance
- **Owner:** requirement owner
- **Criterion:** a download attempt from another account is denied, and the denial is observable
- **Method:** a check that acts as a second test identity, observed on the integrated candidate
- **Baseline source:** the existing authorization tests of the project
- **On failure:** the delivery is blocked; the owner's own success record does not count for this constraint
```

The owner's success record cannot substitute for another account's denial record. A constraint like this one needs the denial check itself, observed as the second identity.

## Load constraint: comparability is stated

"A large report stays within the memory budget":

```markdown
**Constraint:** a large report stays within the memory budget
- **Applies to:** (S-003) retrieval of the report, at the stated input size and concurrency
- **Owner:** requirement owner
- **Criterion:** peak memory stays within <the standing reference value the main spec keeps, or the limit the requirement owner approved>
- **Method:** measured at the stated input size, concurrency, environment and sampling method; reported as a distribution, not a best run
- **Baseline source:** the standing reference value `openspec/specs/<capability>/spec.md` keeps, or the measurement under `openspec/changes/<id>/probes/<name>/` with its workload and variation
- **On failure:** the delivery is blocked until the reference value or the implementation is changed by the owner's decision
```

The entry states input size, concurrency, environment and sampling method. Without them the number is not comparable to anything. A number without a defensible basis is not written as a budget: measure the original version first, record the workload and the variation, and let the requirement owner decide which changes are unacceptable.

## What is not written as a constraint

- A number chosen without a defensible basis is not a budget.
- A result too noisy to distinguish is observed only, never a constraint.
- A one-off exception is recorded in the entry it excepts, with its scope and its expiry; it is not the default standard of the next work.
- Without a measurement method there is no criterion any agreed check can judge, so there is no entry.

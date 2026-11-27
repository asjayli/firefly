# Shadow-score and held-out assessment (design 26)

This reference carries the shadow-score of a rule candidate and the assessment on held-out cases. The shared rules — mandate, carriers, recording — are in `<skill-root>/references/handoff-contract.md`; they are referenced here and restated nowhere.

## The case sets

- **The tuning cases.** The same normal and failing inputs every comparator is scored on. The failing inputs include the incident the retro started from; the normal inputs are correct work the rules must not block.
- **The held-out cases.** Cases that take no part in tuning the rules: not shown to whoever adjusts the candidate, not used to pick between comparators.

## The shadow-score

1. Three comparators run on the tuning cases: **the existing rule**, **the smallest mechanical check** that addresses the same failure, and **the candidate**.
2. Each run records only what that comparator would have ruled on each case — would have blocked, or would have let it through, with the reason. Nothing is blocked for real: a shadow record changes no verdict in force, and no live gate is altered by it.
3. The shadow records, with the case sets they ran on, go into the change's `retro.md`, written by this skill.

## The held-out assessment

1. The held-out cases go to an independent review that took no part in tuning the rules — no author of the candidate, no one who adjusted it against the tuning cases.
2. It compares the three comparators on four things, stated side by side:
   - **Misses** — failures let through.
   - **False blocks** — correct work blocked.
   - **Interruptions** — times a person had to be pulled in.
   - **Cost** — what running the comparator takes.
3. From that comparison: prefer the cheaper equivalent when the results are the same; reject a candidate whose benefit no one can review.
4. A new false block on a required scenario in the held-out cases, without a risk acceptance the requester or the requirement owner recorded, rejects the candidate. A rule already active meets its withdrawal condition.
5. The assessment itself — the four counts and the conclusion drawn from them — is written to the change's `retro.md` with the shadow records.

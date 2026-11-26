# The retro record (design 26)

This reference carries the form of `openspec/changes/<id>/retro.md`, the attribution of a failure to one layer, and the handling of disputed causes in recurring incidents. The shared rules — mandate, carriers, recording — are in `${CLAUDE_HOME:-$HOME/.claude}/firefly/references/handoff-contract.md`; they are referenced here and restated nowhere.

## Form of the record

`retro.md` is written by firefly-retro for the named change. It moves with the archive when firefly-archive is commissioned (contract, Carriers). It holds, in this order:

1. **The event.** The failure or repeated rework the retro starts from: what was being delivered, and which acceptance or task came back.
2. **Contemporary facts.** The input at the time, the decision taken, the tool result and the actual consequence — taken from the change's records (the observation record, the stored review returns, the progress record), never reconstructed from memory of the conversation.
3. **Later inferences.** A part of their own, each item marked as inference. A reader can tell a fact from an inference at a glance.
4. **The layer decision.** Which layer the cause sits at, and the counterfactual that was asked: would the observed failure still have passed if the chosen change had been in place last time?
5. **The shadow records.** What each comparator would have ruled on each case, with the case sets named.

## What enters the record

- Scoped, redacted facts related to this change. An entire transcript is not a learning asset; the record keeps what the attribution and the rule candidate need, nothing more.
- Credentials, report contents and raw sensitive output never enter the record.

## Attribution: one symptom, three layers

The export case: an export was accepted as delivered while its file could not be read.

| What the facts show | The intervention |
|---|---|
| The product published `ready` before the file existed | Product code, plus a regression for the same failure — a delivery commissioned separately |
| The test fixture always returned a readable file | The environment or the fixture |
| The evidence was adequate to tell the two apart, and the reviewer repeatedly treated status 200 as a successful download | Only then is changing the review instructions considered |

- Ask the counterfactual first: **would the observed failure still have passed if this change had been in place last time?** A change that would not have prevented it is not adopted for it, whatever its other merits. The lesson is not written into every skill.
- Choose the smallest intervention that removes the cause among those that pass the counterfactual. The choice is tested on the next comparable work of the same kind; a retro does not declare its own choice proven.
- A fixture that always returns a readable file and is wired into no gate is not a rule matter at all: it is routed to firefly-guard's gate-mounting entry, and the review instructions are not updated for it.

## Recurring incidents with disputed causes

- The same symptom recurs across independent incidents and the cause is still disputed: the responsible owner scopes the readable evidence first — what may be read, of which events, by whom. Until the scope is defined, nothing is read beyond the change's own records.
- Non-authors test the two explanations against the same facts, separately: one reads the events as a judgment error, the other as a tooling defect. Each returns what its explanation predicts and where it fails. Neither briefing names the other's conclusion.
- The synthesis keeps the contrary evidence, not only the consensus: whatever one explanation cannot account for stays in the record beside it. A synthesis that quotes only the agreement is incomplete on its face.

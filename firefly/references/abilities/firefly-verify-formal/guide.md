---
name: firefly-verify-formal
description: Select and apply a formal verification method to a named property of a fixed candidate.
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "27"
---

# Formal verification

## When to use

Use when the user requests `firefly verify-formal`, or a scenario explicitly needs formal verification of a named invariant.

## When not to use

Use an ordinary integration or regression test when it can establish the required behavior at the agreed scope.

## Mandate

Return findings about the given property and candidate. Read existing artifacts and use available tools. Create or change checked-in proof artifacts only when the mandate permits it.

## Inputs

Read the invariant, the fixed candidate, the spec version, the tool version, and the assumptions and bounds to which the conclusion must apply.

## Procedure

1. Choose by property. Use a state-machine checker such as TLC for interleavings and state transitions, a bounded model checker such as Kani for Rust code over bounded inputs, or a proof assistant such as Lean for a theorem requiring explicit assumptions and unbounded reasoning.
2. Explain how the implementation maps to the model. Record the implementation revision and model revision together. Check that each abstraction covers the behavior the result will be used to judge.
3. Demonstrate that the property can fail. In an isolated fixture, weaken the implementation assumption or introduce a controlled violation and check that the tool returns a counterexample or rejects the proof. Revert the fixture before verification. If this demonstration is infeasible, report the gap.
4. Verify the fixed candidate and request an independent cold read of the property, abstractions, assumptions and evidence. Give the reader the [worker instructions](../../worker.md).

## Outputs

Report the tool and version, commands, assumptions, model bounds, candidate, spec version, result, and evidence. A bounded result speaks only for the explored bounds. A timeout or incomplete proof is `unverified`. Carry out the same cold read again if the model or source revision changes.

## Handoffs

Send the result and evidence to the designated verifier or requester. The existing Firefly review owns any candidate verdict.

## Stop and escalate

Report the property and owner when the chosen tool is unavailable, the model cannot be tied to the implementation, or a necessary assumption is unconfirmed.

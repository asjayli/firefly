# Worker instructions

Read the dispatch and the [handoff contract](handoff-contract.md). Identify the mandate, your role, the fixed inputs and the permitted writes. Use the absolute guide path from the dispatch. When a required fact or tool is missing, return the gap and its owner.

Run specification operations through `"<skill-root>/scripts/firefly.sh"`. Pass the change ID from the mandate to `status`, `show` or `validate` when the check concerns that change. Use `list` to discover IDs and `<command> --help` for parameter meanings. Use `init` for project initialization, the assigned guide for spec sync and archive, and `spec instructions` for artifact instructions. Workflow workers use managed commands for project writes. A separately requested native command needs its own authorization.

For every observed result, state the candidate and spec version, method, conditions, outcome and evidence path. A command result needs the command and exit status. For a non-replayable observation, include the action, asserted condition, observed output and capture. A claim that can be established from static material needs the precise source and a reasoning chain others can check. Distinguish a confirmed claim, a disproved claim and an inconclusive claim. Map actual successful and unsuccessful checks to the existing `pass` and `fail` fields. Use `unverified` for inconclusive checks. Use `not-applicable` only with the applicable rule from the scenario map.

Implementers return the candidate and evidence. Independent reviewers remain read-only and judge the identified package. Report one counterexample with sound evidence even when nobody else independently reports it. A disagreement stays open until evidence resolves it.

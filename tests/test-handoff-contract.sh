#!/usr/bin/env bash
# Content contract of assets/shared/references/handoff-contract.md.
#
# The handoff contract is the one shared statement of carriers, identities,
# observation records, candidate states, verdicts and vocabulary that every
# firefly-* skill references. This test pins that the file keeps every
# required section, every term of the fixed vocabulary (THINKING D2) and every
# carrier path (THINKING D1), and that both rendered platform copies are
# byte-identical to the source (the contract carries no platform token).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"

CONTRACT="$ROOT_DIR/assets/shared/references/handoff-contract.md"

[[ -f "$CONTRACT" ]] || { echo "missing $CONTRACT" >&2; exit 1; }

count=0

# expect_token <token> — the token must occur as a whole word.
expect_token() {
  local token="$1"
  if ! grep -Fqw -- "$token" "$CONTRACT"; then
    echo "FAIL: handoff contract lacks the token: $token" >&2
    exit 1
  fi
  count=$((count + 1))
}

# expect_text <text> — the fixed string must occur.
expect_text() {
  local text="$1"
  if ! grep -Fq -- "$text" "$CONTRACT"; then
    echo "FAIL: handoff contract lacks the text: $text" >&2
    exit 1
  fi
  count=$((count + 1))
}

# 1. The ten required second-level sections, verbatim.
for heading in \
  'Mandate record' \
  'Carriers' \
  'Identity and versioning' \
  'Observation record' \
  'Write on produce' \
  'Candidate states' \
  'Verdicts and reservations' \
  'Escalation' \
  'Roles' \
  'Vocabulary'
do
  expect_text "## $heading"
done
echo "handoff contract: 10 sections present"

# 2. Every token of the fixed vocabulary.
for token in \
  ACCEPT REVISE RECHECK INSUFFICIENT_EVIDENCE \
  ESCALATE \
  pass fail unverified not-applicable \
  in-progress ready-to-integrate pending-verdict accepted rolling-out live archived historical \
  'unverified items' 'uncovered inputs' 'non-blocking findings' \
  'touches-required: yes' 'touches-required: no' \
  controller 'requirement owner' 'spec author' planner implementer verifier 'independent reviewer' \
  'migration owner' 'release owner' \
  user-words owner-confirmed agent-inference
do
  expect_token "$token"
done
echo "handoff contract: vocabulary complete"

# 3. Every carrier path.
for text in \
  'openspec/changes/<id>/proposal.md' \
  '## Mandate' \
  '.superpowers/sdd/progress.md' \
  '## Mandates' \
  'openspec/think/' \
  'openspec/changes/<id>/specs/**/spec.md' \
  '(S-xxx)' \
  '- **Source:**' \
  'openspec/changes/<id>/design.md' \
  'openspec/changes/<id>/tasks.md' \
  '## Scenario map' \
  '## Ready decision' \
  'openspec/changes/<id>/evidence/<snapshot12>/<generation>/' \
  'openspec/changes/<id>/verification.md' \
  'openspec/changes/<id>/deprecation.md' \
  'openspec/changes/<id>/retro.md' \
  'openspec/changes/<id>/archive-inventory.md' \
  'docs/adr/' \
  'openspec/think/YYYY-MM-DD-<description>.md' \
  'openspec/changes/<id>/doubt.md' \
  'openspec/changes/<id>/probes/<name>/' \
  'docs/dependencies/<name>@<version>.md' \
  'docs/glossary.md' \
  'openspec/specs/**/spec.md' \
  'Never in the product tree: a file there enters the candidate snapshot'
do
  expect_text "$text"
done
echo "handoff contract: carrier paths complete"

# 3b. Rules that phase 1's independent review found missing (HC-01 to HC-37).
for text in \
  'points to the matching minutes' \
  'A review package is stored as `package.diff` under' \
  'firefly snapshot --spec <id>' \
  'firefly snapshot --tasks <id>' \
  'The current ready decision is the newest row of `## Ready decision`, and it counts only while its verdict is `ACCEPT`' \
  'A verdict counts only for the review package generation it names' \
  'The controller ticks a task once its task group is integrated on the target baseline' \
  'A blocked task carries no note in `tasks.md`' \
  'The candidate is the implementation' \
  'A tick, like a row the recorder appends to `tasks.md`, is not part of the candidate snapshot' \
  'A spec edit is a new spec version, judged under Lapse; a task edit is a new task package version; a tick or a row the recorder appends is neither' \
  'the minutes under `openspec/think/`' \
  'is still the accepted candidate' \
  'and also when the criterion or the measurement method it was observed under changed without changing that version' \
  'the line names the named file; the added entry is reached through the scenarios' \
  'It keeps that tree reachable under `refs/firefly/snapshots/<snapshot>`' \
  '--scenario <S-xxx> --progress <yes|no>' \
  'appends those observation rows to the target baseline' \
  '<id>@ready.<spec12>.<tasks12>' \
  'that does not start with a letter or digit and continue with letters, digits or `. _ : @ + -` only' \
  'with everything under `openspec/changes/` and `openspec/think/` left out' \
  'Versions are compared without that prefix' \
  'Other records lapse only when they are affected, as the Lapse rule says' \
  'the ones the merge has not already brought in' \
  'Repair budget rows are recorded from the worktree of the target baseline' \
  'An observer not of the form `<role>:<name>`' \
  'A `--round` that is not a positive integer' \
  'quoting verbatim words' \
  'A reviewer dispatched again under one identity goes by a different name' \
  'A dispatch row with `sent` and no `returned` or `failed` row is an interrupted dispatch' \
  'Write it after the first mandate row' \
  'None of them changes the index or the worktree' \
  "stores each reviewer's whole return, unchanged" \
  'Review dispatches and failures, verdicts (each naming the next owner)' \
  'the facts pinned for it, as sent to every reviewer, as `brief.md` beside it' \
  'The facts a package pinned are read from its `brief.md`' \
  'One dispatch is one `sent` row' \
  'It judges no candidate: its returns are stored and its dispatches recorded as returned, no verdict row is written for it' \
  'the expected outcome the scenario map row named when the observation was made' \
  'A row that lacks either of the last two supports no `ACCEPT`' \
  'one more each time something calls for the comparison again after one that ended in `REVISE` or `INSUFFICIENT_EVIDENCE`' \
  'a package directory without `package.diff` is read as one' \
  '`--note` carries three things and is never omitted, though the recorder does not enforce it' \
  'the required roles with the non-author identity of each, which the dispatch rows carry' \
  'firefly-debug writes back the trigger input, the expected result and the cause of a diagnosis' \
  'A return is `historical` only for a package the ledger shows as dispatched' \
  'the spec version, the task package version, the standards sources and the evidence it names are still the current ones' \
  'The `Spec` column carries the version as `spec:<version>`' \
  'A ready decision authorizes a start; it does not widen a mandate' \
  "Recording a user's decision in the minutes is a permitted effect under every mandate" \
  'A change to its objective, permitted effects or terminal condition is a new mandate with a new id' \
  'When a change or the progress record carries more than one mandate row, the one in force is the newest' \
  'An entry added later goes under `openspec/think/`' \
  'A file the user named is never edited' \
  'runtime signal requirements agreed with the scenarios' \
  'Design that supports the scenarios and judges nothing (it is in neither package version)' \
  'A verdict belongs to the review package it names' \
  'A `historical` verdict is never cited again' \
  'Aggregates the previously agreed acceptance criteria' \
  'Every acceptance carries the reservation list, even when the list is empty.'
do
  expect_text "$text"
done
echo "handoff contract: review fixes present"

# 3c. The Recording section names all six recorder subcommands and the
#     snapshot command, and forbids hand-written rows.
expect_text '## Recording'
for call in 'firefly record mandate' 'firefly record observe' 'firefly record ready' \
  'firefly record verdict' 'firefly record dispatch' 'firefly record budget' 'firefly snapshot'
do
  expect_text "$call"
done
expect_text 'A skill never hand-writes one of these table rows'
echo "handoff contract: Recording section lists the six subcommands"

# expect_absent <text> — a retired rule must not come back.
expect_absent() {
  if grep -Fq -- "$1" "$CONTRACT"; then
    echo "FAIL: handoff contract still carries a retired rule: $1" >&2
    exit 1
  fi
  count=$((count + 1))
}

# 4. The contract carries no platform token, so both rendered copies equal
#    the source byte for byte.
if grep -q '{{PLATFORM_' "$CONTRACT"; then
  echo "FAIL: handoff contract must not contain a platform token" >&2
  exit 1
fi
for platform in codex claude; do
  rendered="$ROOT_DIR/assets/$platform/references/handoff-contract.md"
  if ! cmp "$CONTRACT" "$rendered"; then
    echo "FAIL: $rendered differs from the shared source" >&2
    exit 1
  fi
done
echo "handoff contract: rendered copies identical to the source"

# 5. Rules that were tried and withdrawn stay out.
for retired_rule in 'the window' 'is not edited' 'before the candidate snapshot of the implementation is fixed' 'kept at their committed state' 'the records that cite the old version lapse together' 'What counts as affected is read from the versions a record cites'; do
  expect_absent "$retired_rule"
done
echo "handoff contract: withdrawn rules stay out"

echo "handoff contract test passed ($count checks)"

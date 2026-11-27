#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_file_contains() {
  local path="$1"
  local needle="$2"

  if [[ ! -f "$path" ]]; then
    echo "expected file to exist: $path" >&2
    exit 1
  fi
  if [[ "$(cat "$path")" != *"$needle"* ]]; then
    echo "expected $path to contain: $needle" >&2
    exit 1
  fi
}

assert_file_not_contains() {
  local path="$1"
  local needle="$2"

  if [[ "$(cat "$path")" == *"$needle"* ]]; then
    echo "expected $path to not contain: $needle" >&2
    exit 1
  fi
}

assert_files_equal() {
  local expected="$1"
  local actual="$2"

  if ! cmp -s "$expected" "$actual"; then
    echo "expected managed mirror files to match: $expected $actual" >&2
    exit 1
  fi
}

assert_occurrences_at_least() {
  local path="$1"
  local needle="$2"
  local minimum="$3"
  local count

  count="$({ grep -F -o -- "$needle" "$path" || true; } | wc -l | tr -d ' ')"
  if (( count < minimum )); then
    echo "expected $path to contain $needle at least $minimum times, found $count" >&2
    exit 1
  fi
}

assert_file_in_order() {
  local path="$1"
  shift
  local remaining
  local needle

  remaining="$(<"$path")"
  for needle in "$@"; do
    if [[ "$remaining" != *"$needle"* ]]; then
      echo "expected $path to contain in order: $needle" >&2
      exit 1
    fi
    remaining="${remaining#*"$needle"}"
  done
}

assert_review_contract() {
  local path="$1"

  assert_file_in_order "$path" \
    'Objective: the authorized outcome.' \
    'Scope: the allowed repositories, changes, files, and systems.' \
    'Constraints: the binding process, architecture, safety, and platform rules.' \
    'Authorized effects: the writes and side effects allowed to the controller.' \
    'Terminal condition: the state at which this workflow must stop.' \
    'candidate producer identity' \
    'candidate artifacts, action, or diff' \
    'verification evidence' \
    'assumptions and risks'
  assert_file_in_order "$path" \
    'reviewer fails to start, times out, crashes, or returns an invalid verdict' \
    'reuse the unchanged review package' \
    'at most two new independent review agents' \
    'collected infrastructure evidence' \
    'never infer `APPROVE`'
  assert_file_contains "$path" 'The controller validates only reviewer identity, verdict structure, and supporting evidence; it does not recursively review the verdict.'
}

assert_controller_lifecycle() {
  local path="$1"

  assert_file_contains "$path" 'A progress report, host wait timeout, or context compaction does not end the mandate.'
  assert_file_contains "$path" 'Before returning, check active children and remaining authorized work.'
  assert_file_contains "$path" 'A valid `REVISE` immediately blocks its generation.'
  assert_file_contains "$path" 'Dispatch no replacement for an obsolete slot.'
  assert_file_contains "$path" 'the terminal condition is met'
  assert_file_contains "$path" 'Mark unrecoverable counters as unknown.'
  assert_file_contains "$path" 'Treat an exhausted budget as a stop for the exhausted path.'
  assert_file_in_order "$path" \
    'Record the list in the terminal condition of the existing mandate record' \
    'copy the recorded IDs into `required`' \
    'Build `conditions` separately' \
    '`continue-work`' \
    '`reconcile-conditions`' \
    '`wait`' \
    '`escalate`' \
    '`complete`'
}

assert_controller_lifecycle "$ROOT_DIR/firefly/references/continuation.md"
assert_file_contains "$ROOT_DIR/firefly/SKILL.md" 'Before a completion or escalation reply, run the gate and carry out its decision.'
assert_file_in_order "$ROOT_DIR/firefly/SKILL.md" \
  '## First use' \
  'bash "<skill-root>/scripts/manage.sh" bootstrap' \
  'continue the requested capability in the same turn' \
  '## When to use'

assert_obsolete_reviewer_lifecycle() {
  local path="$1"

  assert_file_contains "$path" 'An invalidated reviewer is obsolete and non-blocking.'
  assert_file_contains "$path" 'A final-state check counts only reviewers that remain required for the current candidate.'
}

assert_template_function_contains() {
  local path="$1"
  local function_name="$2"
  local needle="$3"
  local function_body

  function_body="$(awk -v function_name="$function_name" '
    $0 == "export function " function_name "() {" { capture = 1 }
    capture { print }
    capture && /^}/ { exit }
  ' "$path")"

  if [[ "$function_body" != *"$needle"* ]]; then
    echo "expected $path function $function_name to contain: $needle" >&2
    exit 1
  fi
}

firefly_paths=(
  "$ROOT_DIR/firefly/SKILL.md"
)

for path in "${firefly_paths[@]}"; do
  # v2 controller: mandate-scoped routing, four entries, continuous execution,
  # the registry of commands; the old review protocol is retired.
  assert_file_contains "$path" 'It does not include spec sync, commit, archive, push, merge or release'
  assert_file_contains "$path" 'A local checkpoint commit happens only when the permitted effects explicitly allow it and the branch policy permits'
  assert_file_contains "$path" 'it does not authorize push or release'
  assert_file_contains "$path" 'a worker cannot widen the mandate or approve its own candidate'
  assert_file_contains "$path" 'ESCALATE'
  assert_file_contains "$path" '## Commands'
  assert_file_contains "$path" '## Registry and health'
  assert_file_contains "$path" 'firefly next'
  assert_file_not_contains "$path" 'objective authorization envelope'
  assert_file_not_contains "$path" 'APPROVE'
  assert_file_not_contains "$path" 'requesting-code-review'
done

firefly_propose_paths=(
  "$ROOT_DIR/firefly/references/abilities/firefly-propose/guide.md"
)

# firefly-propose (v2). Verdicts take the contract's four values and an
# escalation is a return path that carries three things. The three-state
# protocol, the old review contract and the old reviewer lifecycle rules are
# superseded, so their assertions are gone; `REVISE` and `ESCALATE` are still
# used and stay pinned. The phrases below are the skill's own wording.
for path in "${firefly_propose_paths[@]}"; do
  assert_file_contains "$path" '`REVISE`'
  assert_file_contains "$path" '`ESCALATE`'
  assert_file_contains "$path" 'The requirement source cannot be recovered'
  assert_file_contains "$path" 'from the input, the referenced files, the conversation or repository evidence'
  assert_file_contains "$path" 'An `ESCALATE` carries three things: the current conclusion, the missing evidence or authority, and the responsible owner'
  assert_file_not_contains "$path" "Stop and clarify"
  assert_file_contains "$path" 'A proposal-only mandate ends once the change is ready to start'
  assert_file_contains "$path" 'Report that it is ready and give `firefly implement <change>` as the next command'
  assert_file_contains "$path" 'do not describe this normal completion as an interruption or as missing authorization'
  assert_file_contains "$path" 'Do not ask whether to continue'
done

firefly_archive_paths=(
  "$ROOT_DIR/firefly/references/abilities/firefly-archive/guide.md"
)

for path in "${firefly_archive_paths[@]}"; do
  # v2: three independently commissioned ends; old three-value protocol retired.
  assert_file_contains "$path" '`ESCALATE`'
  assert_file_contains "$path" 'Repair only issues in the sync result or the archive package that are inside the archive authorization envelope'
  assert_file_contains "$path" 'never repaired outside the envelope'
  assert_file_contains "$path" 'no traffic action and archives nothing'
  assert_file_contains "$path" 'covers no traffic action and no launch'
  assert_file_not_contains "$path" '`APPROVE`'
  assert_file_not_contains "$path" 'Independent review contract'
  assert_file_not_contains "$path" 'automatically repair an authorized `REVISE` or validation failure before review'
done

firefly_implement_paths=(
  "$ROOT_DIR/firefly/references/abilities/firefly-implement/guide.md"
)

# firefly-implement (v2). The three-state protocol, the old review contract and
# the unbounded repair-review loop up to an approval are superseded by the four
# verdict values, the repair budget and the candidate states. Continuous
# execution, the stop rule and the repair path remain, pinned in the skill's
# own wording.
for path in "${firefly_implement_paths[@]}"; do
  assert_file_contains "$path" '`REVISE`'
  assert_file_contains "$path" '`ESCALATE`'
  assert_file_contains "$path" 'a first failing check are diagnostic inputs, not requests for a decision'
  assert_file_contains "$path" 'Continue the authorized mandate there.'
  assert_file_contains "$path" "Implementation runs continuously by default."
  assert_file_contains "$path" 'Never use completion language or a final delivery format while any task group is unchecked or in progress, or while the verdict of the integrated candidate is outstanding'
  assert_file_contains "$path" 'A failing scenario, a `fail` on a mapped check or a valid `REVISE` from `firefly-review`, returns to the implementer by default.'
  assert_file_contains "$path" 'The repaired candidate is a new candidate: it is verified and reviewed again on its own first package.'
done

path="$ROOT_DIR/firefly/references/abilities/firefly-verify-web/guide.md"
  # v2: verify-web observes and returns findings; it issues no verdict and
  # keeps the old three-value protocol and the ledger status word out.
  assert_file_contains "$path" '`ESCALATE`'
  assert_file_contains "$path" 'a standalone investigation that returns findings only'
  assert_file_contains "$path" 'unverified'
  assert_file_contains "$path" 'firefly record observe'
  assert_file_not_contains "$path" '`APPROVE`'
  assert_file_not_contains "$path" 'browser-evidence'

# firefly-review (v2). A standalone review still returns findings and changes
# nothing of the candidate, but it does write records about the candidate: the
# package, the stored returns and the ledger rows; no ledger row is written by
# hand and no stored return is edited. The dispatch template moved to
# references/reviewer-brief.md, and the package path is no longer passed as
# `DIFF_FILE`.
{
  path="$ROOT_DIR/firefly/references/abilities/firefly-review/guide.md"
  assert_file_contains "$path" '`REVISE`'
  assert_file_contains "$path" '`ESCALATE`'
  assert_file_contains "$path" 'This is a standalone review'
  assert_file_contains "$path" 'Standalone review: return the findings and stop'
  assert_file_contains "$path" 'A `REVISE` is a result, not an escalation'
  assert_file_contains "$path" 'The review is not a repair: it changes no file of the candidate, of its spec or of its tasks'
  assert_file_contains "$path" 'A standalone review writes them and nothing else: no file of the candidate, of its spec or of its tasks'
  assert_file_contains "$path" 'No row of these tables is written by hand, and no written row is edited'
  assert_file_contains "$path" 'Dispatch only after the printed path exists and is readable'
  assert_file_contains "$path" 'BASE <full-candidate-tree-sha> openspec/changes/<id>/evidence/<snapshot12>/<generation>/package.diff'
  assert_file_contains "$ROOT_DIR/firefly/references/abilities/firefly-review/references/reviewer-brief.md" 'the path printed by `review-package`'
}

path="$ROOT_DIR/firefly/references/abilities/firefly-think/guide.md"
  # v2: think clarifies and records; it dispatches no review and issues no
  # verdict. Autonomy is the mandate default: minutes are written under
  # openspec/think/ without a confirmation gate.
  assert_file_contains "$path" '`ESCALATE`'
  assert_file_not_contains "$path" "independent review"
  assert_file_not_contains "$path" '`APPROVE`'
  assert_file_not_contains "$path" "Wait for explicit confirmation"
  assert_file_not_contains "$path" "Do not skip the confirmation step"

echo "autonomous workflow contract test passed"

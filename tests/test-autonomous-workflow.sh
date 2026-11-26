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

  assert_file_contains "$path" 'An active reviewer is not a terminal state.'
  assert_file_contains "$path" 'do not emit a final response, completion summary, or user-facing wait request'
  assert_file_contains "$path" 'Before any final response, confirm that no active reviewer remains'
  assert_file_contains "$path" 'On the first valid `REVISE`, invalidate reviews of that candidate'
  assert_file_contains "$path" 'Repair the candidate, revalidate it, and dispatch a fresh independent review'
}

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
  "$ROOT_DIR/assets/codex/skills/firefly/SKILL.md"
  "$ROOT_DIR/assets/claude/skills/firefly/SKILL.md"
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
  "$ROOT_DIR/assets/codex/skills/firefly-propose/SKILL.md"
  "$ROOT_DIR/assets/claude/skills/firefly-propose/SKILL.md"
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
  "$ROOT_DIR/assets/codex/skills/firefly-archive/SKILL.md"
  "$ROOT_DIR/assets/claude/skills/firefly-archive/SKILL.md"
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
  "$ROOT_DIR/assets/codex/skills/firefly-implement/SKILL.md"
  "$ROOT_DIR/assets/claude/skills/firefly-implement/SKILL.md"
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
  assert_file_contains "$path" 'Only the fixed end, a return to `firefly-propose` under `## Stop and escalate`, an `ESCALATE` boundary or an explicit stop by the user ends the run of this skill.'
  assert_file_contains "$path" "Implementation runs continuously by default."
  assert_file_contains "$path" 'Never use completion language or a final delivery format while any task group is unchecked or in progress, or while the verdict of the integrated candidate is outstanding'
  assert_file_contains "$path" 'A failing scenario, a `fail` on a mapped check or a valid `REVISE` from `firefly-review`, returns to the implementer by default.'
  assert_file_contains "$path" 'The repaired candidate is a new candidate: it is verified and reviewed again on its own first package.'
done

for path in \
  "$ROOT_DIR/assets/codex/skills/firefly-verify-web/SKILL.md" \
  "$ROOT_DIR/assets/claude/skills/firefly-verify-web/SKILL.md"
do
  # v2: verify-web observes and returns findings; it issues no verdict and
  # keeps the old three-value protocol and the ledger status word out.
  assert_file_contains "$path" '`ESCALATE`'
  assert_file_contains "$path" 'a standalone investigation that returns findings only'
  assert_file_contains "$path" 'unverified'
  assert_file_contains "$path" 'firefly record observe'
  assert_file_not_contains "$path" '`APPROVE`'
  assert_file_not_contains "$path" 'browser-evidence'
done

# firefly-review (v2). A standalone review still returns findings and changes
# nothing of the candidate, but it does write records about the candidate: the
# package, the stored returns and the ledger rows; no ledger row is written by
# hand and no stored return is edited. The dispatch template moved to
# references/reviewer-brief.md, and the package path is no longer passed as
# `DIFF_FILE`.
for platform in codex claude; do
  path="$ROOT_DIR/assets/$platform/skills/firefly-review/SKILL.md"
  assert_file_contains "$path" '`REVISE`'
  assert_file_contains "$path" '`ESCALATE`'
  assert_file_contains "$path" 'This is a standalone review'
  assert_file_contains "$path" 'Standalone review: return the findings and stop'
  assert_file_contains "$path" 'A `REVISE` is a result, not an escalation'
  assert_file_contains "$path" 'The review is not a repair: it changes no file of the candidate, of its spec or of its tasks'
  assert_file_contains "$path" 'A standalone review writes them and nothing else: no file of the candidate, of its spec or of its tasks'
  assert_file_contains "$path" 'No row of these tables is written by hand, and no written row is edited'
  assert_file_contains "$path" 'Dispatch only after the printed path exists and is readable'
  assert_file_contains "$path" 'BASE HEAD openspec/changes/<id>/evidence/<snapshot12>/<generation>/package.diff'
  assert_file_contains "$path" 'BASE WORKTREE openspec/changes/<id>/evidence/<snapshot12>/<generation>/package.diff'
  assert_file_contains "$ROOT_DIR/assets/$platform/skills/firefly-review/references/reviewer-brief.md" 'the path printed by `review-package`'
done

assert_file_contains "$ROOT_DIR/assets/codex/skills/firefly/SKILL.md" '`spawn_agent`'
assert_file_contains "$ROOT_DIR/assets/claude/skills/firefly/SKILL.md" '`Task`'

for path in \
  "$ROOT_DIR/assets/codex/skills/firefly-think/SKILL.md" \
  "$ROOT_DIR/assets/claude/skills/firefly-think/SKILL.md"
do
  # v2: think clarifies and records; it dispatches no review and issues no
  # verdict. Autonomy is the mandate default: minutes are written under
  # openspec/think/ without a confirmation gate.
  assert_file_contains "$path" '`ESCALATE`'
  assert_file_not_contains "$path" "independent review"
  assert_file_not_contains "$path" '`APPROVE`'
  assert_file_not_contains "$path" "Wait for explicit confirmation"
  assert_file_not_contains "$path" "Do not skip the confirmation step"
done

# OpenSpec layer (v2). The injected three-state protocol, the review contract
# and the reviewer lifecycle rules are gone from these files, and none of them
# dispatches a review or reports a verdict: each names the firefly skill that
# owns the review in a `## Review ownership` section. The groups below pin what
# stays, in the files' own wording.
for path in \
  "$ROOT_DIR/assets/codex/skills/openspec-propose/SKILL.md" \
  "$ROOT_DIR/assets/claude/skills/openspec-propose/SKILL.md" \
  "$ROOT_DIR/assets/codex/skills/openspec-apply-change/SKILL.md" \
  "$ROOT_DIR/assets/claude/skills/openspec-apply-change/SKILL.md" \
  "$ROOT_DIR/assets/codex/skills/openspec-archive-change/SKILL.md" \
  "$ROOT_DIR/assets/claude/skills/openspec-archive-change/SKILL.md" \
  "$ROOT_DIR/assets/codex/skills/openspec-explore/SKILL.md" \
  "$ROOT_DIR/assets/claude/skills/openspec-explore/SKILL.md" \
  "$ROOT_DIR/assets/claude/commands/opsx/propose.md" \
  "$ROOT_DIR/assets/claude/commands/opsx/apply.md" \
  "$ROOT_DIR/assets/claude/commands/opsx/archive.md" \
  "$ROOT_DIR/assets/claude/commands/opsx/explore.md" \
  "$ROOT_DIR/assets/claude/commands/opsx/sync.md" \
  "$ROOT_DIR/assets/openspec/dist/core/templates/workflows/propose.js" \
  "$ROOT_DIR/assets/openspec/dist/core/config-prompts.js"
do
  # `ndependent` catches `independent reviewer`, `independently review` and the
  # `Independent review contract` heading alike.
  for needle in 'APPROVE' 'REVISE' 'ESCALATE' 'authorization envelope' \
    'ndependent' 'Reviewer lifecycle'; do
    assert_file_not_contains "$path" "$needle"
  done
done

openspec_apply_paths=(
  "$ROOT_DIR/assets/codex/skills/openspec-apply-change/SKILL.md"
  "$ROOT_DIR/assets/claude/skills/openspec-apply-change/SKILL.md"
  "$ROOT_DIR/assets/claude/commands/opsx/apply.md"
)

for path in "${openspec_apply_paths[@]}"; do
  assert_file_contains "$path" '## Review ownership'
  assert_file_contains "$path" 'Code candidates are judged by firefly review (16).'
  assert_file_contains "$path" 'it does not dispatch a final review and does not issue a verdict'
  assert_file_contains "$path" 'Invoked outside firefly, report the candidate as unreviewed.'
  assert_file_contains "$path" 'Diagnose and repair in-scope design issues and first test failures within scope'
  assert_file_not_contains "$path" "Error or blocker encountered"
  assert_file_not_contains "$path" "Pause on errors, blockers, or unclear requirements"
  assert_file_in_order "$path" \
    'Complete every task.' \
    'Run integration and global verification across the complete implementation.' \
    'Report the candidate as ready for review once every task is checked and the declared verification has run.' \
    'The verdict belongs to firefly review.'
  assert_file_contains "$path" 'When apply instructions report `state: "all_done"`, resume at integration and global verification; do not congratulate, suggest archive, or report completion yet.'
  assert_file_contains "$path" 'Implementation runs continuously by default.'
  assert_file_contains "$path" 'Phase boundaries, progress reports, and ordinary recoverable failures are not confirmation gates.'
  assert_file_contains "$path" 'Return to the user only when a decision, an authorization, or a piece of evidence is missing, and state what is missing and who decides.'
  assert_file_contains "$path" 'Before returning a completion summary, confirm every completion gate:'
  assert_file_contains "$path" '`git diff --check` succeeds'
done

openspec_archive_paths=(
  "$ROOT_DIR/assets/codex/skills/openspec-archive-change/SKILL.md"
  "$ROOT_DIR/assets/claude/skills/openspec-archive-change/SKILL.md"
  "$ROOT_DIR/assets/claude/commands/opsx/archive.md"
)

for path in "${openspec_archive_paths[@]}"; do
  assert_file_contains "$path" '## Review ownership'
  assert_file_contains "$path" 'Spec sync, the archive package, and readiness are judged by firefly archive (25), which uses firefly docs (23) for the sync.'
  assert_file_contains "$path" 'it does not review and does not decide readiness'
  # Every place that named openspec-sync-specs (step 4 and the guardrails) now carries this sentence.
  assert_occurrences_at_least "$path" 'Sync delta specs through firefly docs when it is installed; otherwise use the OpenSpec spec-sync skill.' 2
  assert_file_not_contains "$path" 'openspec-sync-specs'
  assert_file_contains "$path" "Auto-select if only one active change exists"
  assert_file_contains "$path" '<planningHome.root>/openspec/specs/<capability>/spec.md'
  assert_file_not_contains "$path" "Ask the user to confirm"
  assert_file_not_contains "$path" "Prompt user for confirmation"
  assert_file_not_contains "$path" "Archive without syncing"
  assert_file_not_contains "$path" "Proceed if user confirms"
  assert_file_not_contains "$path" "Do NOT guess or auto-select a change"
done

openspec_propose_paths=(
  "$ROOT_DIR/assets/codex/skills/openspec-propose/SKILL.md"
  "$ROOT_DIR/assets/claude/skills/openspec-propose/SKILL.md"
  "$ROOT_DIR/assets/claude/commands/opsx/propose.md"
)

for path in "${openspec_propose_paths[@]}"; do
  assert_file_contains "$path" '## Review ownership'
  assert_file_contains "$path" 'Planning artifacts are judged by the joint ready decision in firefly propose (design position 04).'
  assert_file_contains "$path" 'it does not review planning packages and does not report a change as ready to implement'
  assert_file_contains "$path" 'Invoked outside firefly, report the created change as unreviewed.'
  assert_file_contains "$path" 'After the ready decision, implementation runs through firefly Implement.'
  assert_file_contains "$path" 'When invoked as a phase of an already-authorized complete firefly delivery, return the resolved change name to the controller'
  assert_file_contains "$path" 'State that the standalone proposal reached its apply-ready terminal condition.'
  assert_file_contains "$path" 'Next command: `firefly implement <name>`'
  assert_file_contains "$path" 'Do not ask whether to proceed'
  assert_file_in_order "$path" \
    'Validate the current planning package.' \
    'If validation fails, repair only the matching planning artifact type and rerun the same validation.' \
    'Continue only after that planning validation passes.' \
    'After all apply-required artifacts are complete, run `openspec validate "<name>" --strict --no-interactive` for the complete change' \
    'If strict validation fails, repair the indicated proposal, design, specs, or tasks and rerun strict validation.'
done

# The producer self-critique is carried by the skill on both platforms. It no
# longer defers to a reviewer dispatched here.
for path in \
  "$ROOT_DIR/assets/codex/skills/openspec-propose/SKILL.md" \
  "$ROOT_DIR/assets/claude/skills/openspec-propose/SKILL.md"
do
  assert_file_contains "$path" 'Run the producer self-critique on the current planning package:'
  assert_file_contains "$path" 'it does not replace the joint ready decision in firefly propose.'
done

for path in \
  "$ROOT_DIR/assets/codex/skills/openspec-explore/SKILL.md" \
  "$ROOT_DIR/assets/claude/skills/openspec-explore/SKILL.md"
do
  assert_file_contains "$path" '## Review ownership'
  assert_file_contains "$path" 'Explorations are not reviewed. Findings are input to firefly think (02) or firefly propose (04).'
done

# /opsx:sync is a thin shell: the sync and its review run through firefly docs.
assert_file_contains "$ROOT_DIR/assets/claude/commands/opsx/sync.md" '## Review ownership'
assert_file_contains "$ROOT_DIR/assets/claude/commands/opsx/sync.md" 'firefly docs'

# v2: the 0.1.0 three-value review wording is gone from INSTALL; the 0.2.0
# upgrade path (hash-pinned retirement backups) is documented instead.
assert_file_not_contains "$ROOT_DIR/INSTALL.claude.md" "artifact, confirmation, and versioning rules"
assert_file_not_contains "$ROOT_DIR/INSTALL.claude.md" "independent-review, and versioning rules"
assert_file_contains "$ROOT_DIR/INSTALL.claude.md" "retired/"

propose_template="$ROOT_DIR/assets/openspec/dist/core/templates/workflows/propose.js"
# The routing hooks and the review ownership section appear once per template
# function, so each is expected at least twice.
assert_occurrences_at_least "$propose_template" '## Review ownership' 2
assert_occurrences_at_least "$propose_template" 'Planning artifacts are judged by the joint ready decision in firefly propose (design position 04).' 2
assert_occurrences_at_least "$propose_template" 'it does not review planning packages and does not report a change as ready to implement' 2
assert_occurrences_at_least "$propose_template" 'Invoked outside firefly, report the created change as unreviewed.' 2
assert_occurrences_at_least "$propose_template" 'After the ready decision, implementation runs through firefly Implement.' 2
assert_occurrences_at_least "$propose_template" 'State that the standalone proposal reached its apply-ready terminal condition.' 2
assert_occurrences_at_least "$propose_template" 'Next command: \`firefly implement <name>\`' 2
assert_occurrences_at_least "$propose_template" 'Do not ask whether to proceed' 2
for function_name in getOpsxProposeSkillTemplate getOpsxProposeCommandTemplate; do
  assert_template_function_contains "$propose_template" "$function_name" '## Review ownership'
  assert_template_function_contains "$propose_template" "$function_name" 'When invoked as a phase of an already-authorized complete firefly delivery, return the resolved change name to the controller'
done
assert_file_in_order "$propose_template" \
  'Validate the current planning package.' \
  'If validation fails, repair only the matching planning artifact type and rerun the same validation.' \
  'Continue only after that planning validation passes.' \
  'After all apply-required artifacts are complete, run \`openspec validate "<name>" --strict --no-interactive\` for the complete change' \
  'If strict validation fails, repair the indicated proposal, design, specs, or tasks and rerun strict validation.'

tracked_internal_planning="$(git -C "$ROOT_DIR" ls-files -- \
  'openspec/**' \
  'docs/plans/**' \
  '.firefly/**' \
  '.superpowers/**')"
if [[ -n "$tracked_internal_planning" ]]; then
  echo "repository-local planning or runtime artifacts must not be tracked:" >&2
  echo "$tracked_internal_planning" >&2
  exit 1
fi

tracked_local_client_state="$(git -C "$ROOT_DIR" ls-files -- '.claude/**' '.codex/**')"
if [[ -n "$tracked_local_client_state" ]]; then
  echo "repository-local Claude and Codex state must not be tracked:" >&2
  echo "$tracked_local_client_state" >&2
  exit 1
fi

for internal_path in openspec/ docs/plans/ .firefly/ .superpowers/; do
  if ! git -C "$ROOT_DIR" check-ignore -q "$internal_path"; then
    echo "expected repository-local path to be ignored: $internal_path" >&2
    exit 1
  fi
done

tracked_openspec_assets="$(git -C "$ROOT_DIR" ls-files -- 'assets/openspec/**')"
if [[ -z "$tracked_openspec_assets" ]]; then
  echo "expected product OpenSpec assets to remain tracked" >&2
  exit 1
fi

assert_file_contains "$ROOT_DIR/AGENTS.md" '不得使用 `git add -f`'
assert_file_contains "$ROOT_DIR/AGENTS.md" 'Codex 与 Claude Code 共同支持的能力交集'
# v2 README wording: continuous execution is the mandate default; the old
# "re-confirmation per phase" phrasing must stay out.
assert_file_not_contains "$ROOT_DIR/README.md" "等你确认"
assert_file_contains "$ROOT_DIR/README.md" "独立评审"
assert_file_contains "$ROOT_DIR/README.md" "不重走访谈"
assert_file_not_contains "$ROOT_DIR/README_EN.md" "waits for your confirmation"
assert_file_contains "$ROOT_DIR/README_EN.md" "independent review"
assert_file_contains "$ROOT_DIR/README_EN.md" "rather than repeating intake"

echo "autonomous workflow contract test passed"

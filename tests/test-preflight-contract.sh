#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Pins the baseline preflight contract introduced in task group 5 on both
# rendered platforms. firefly-implement and
# openspec-apply-change must each carry:
#   - the once-before-first-modification baseline verification
#   - a Preflight section recorded in the SDD progress ledger
#   - HEAD + worktree + Verification Contract identity, with resumption skip
#   - the four-way red classification (clean / in-scope-red / unrelated-red /
#     user-worktree-red)
#   - the known-red visibility rule (stays in the final report)
#
# firefly-implement (v2) keeps every item but no longer names a Verification
# Contract: the same baseline is recognized by the Baseline commit, the
# Worktree snapshot and the baseline commands with their results. Its
# assertions below use the skill's own wording.

assert_contains() {
  local path="$1"
  local needle="$2"
  [[ -f "$path" ]] || { echo "missing file: $path" >&2; exit 1; }
  grep -qF "$needle" "$path" || {
    echo "expected [$needle] in $path" >&2
    exit 1
  }
}

for platform in codex claude; do
  implement="$ROOT_DIR/assets/$platform/skills/firefly-implement/SKILL.md"
  apply="$ROOT_DIR/assets/$platform/skills/openspec-apply-change/SKILL.md"

  # firefly-implement (v2): same items, wording of its Preflight section.
  # Once, before the first candidate modification.
  assert_contains "$implement" 'Once, before the first candidate file is modified, run the baseline commands the scenario map names'
  # Recorded under a Preflight section in the SDD progress ledger.
  assert_contains "$implement" "Preflight"
  assert_contains "$implement" ".superpowers/sdd/progress.md"
  # Identified by Baseline commit + Worktree snapshot + baseline commands with
  # their results; resumption skips rerun.
  assert_contains "$implement" 'The same baseline is recognized by the three facts the section holds: its Baseline commit, its Worktree snapshot and the baseline commands it ran with their results'
  assert_contains "$implement" 'On resumption, do not rerun the preflight when the progress record, Git and `tasks.md` together prove that the same baseline already completed it'
  # Four-way red classification.
  assert_contains "$implement" "in-scope-red"
  assert_contains "$implement" "unrelated-red"
  assert_contains "$implement" "user-worktree-red"
  # Known-red stays visible in the final report.
  assert_contains "$implement" "known-red"
  assert_contains "$implement" "stays visible in the final report"

  skill="$apply"
    # Once, before the first candidate modification.
    assert_contains "$skill" "baseline verification once"
    # Recorded under a Preflight section in the SDD progress ledger.
    assert_contains "$skill" "Preflight"
    assert_contains "$skill" ".superpowers/sdd/progress.md"
    # Identified by HEAD + worktree + Verification Contract; resumption skips rerun.
    assert_contains "$skill" "Verification Contract"
    assert_contains "$skill" "already completed, do not rerun"
    # Four-way red classification.
    assert_contains "$skill" "in-scope-red"
    assert_contains "$skill" "unrelated-red"
    assert_contains "$skill" "user-worktree-red"
    # Known-red stays visible in the final report.
    assert_contains "$skill" "known-red"
    assert_contains "$skill" "stays visible in the final report"
done

# Rendered copies must stay in sync with the shared source.
node "$ROOT_DIR/scripts/sync-platform-assets.mjs" --check

echo "preflight contract test passed"

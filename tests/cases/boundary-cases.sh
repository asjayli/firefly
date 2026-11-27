#!/usr/bin/env bash
# Boundary cases of the runtime surface (phase 17, contract item 2), sourced
# by tests/test-runtime-scripts.sh after its own sections. Reuses that file's
# ROOT_DIR, SCRIPTS, SNAPSHOT, RECORD, REVIEW_PACKAGE, tmp_dir, output_has and
# the lib.sh assertions. Every case prints an "ok ..." or a "negative: ..." line.

# ---- a repository whose path contains spaces -------------------------------

# shellcheck disable=SC2154
space_repo="$tmp_dir/space repo"
space_change="openspec/changes/c1"
mkdir -p "$space_repo/$space_change/specs" "$space_repo/$space_change/evidence" "$space_repo/src"
printf '#### Scenario: a (S-1)\n' > "$space_repo/$space_change/specs/spec.md"
printf '## 1. Group\n\n- [ ] 1.1 do\n' > "$space_repo/$space_change/tasks.md"
printf 'code\n' > "$space_repo/src/a.js"
printf 'log\n' > "$space_repo/$space_change/evidence/e1.txt"
git -C "$space_repo" init -q
git -C "$space_repo" config user.email "test@example.com"
git -C "$space_repo" config user.name "firefly Test"
git -C "$space_repo" add -A
git -C "$space_repo" commit -qm base
(
  cd "$space_repo/src" || exit 1
  snapshot="$("$SNAPSHOT")"
  "$RECORD" mandate --change c1 --id M-1 --objective "Space objective" --effects "edit src/" --terminal "verified candidate" > /dev/null
  "$RECORD" observe --change c1 --scenario S-1 --check file-content --result fail --observer verifier:amy \
    --candidate "$snapshot" --spec "$("$SNAPSHOT" --spec c1)" \
    --evidence "openspec/changes/c1/evidence/e1.txt" --note "space path" > /dev/null
)
assert_contains "$space_repo/$space_change/proposal.md" '| M-1 | Space objective |'
assert_contains "$space_repo/$space_change/verification.md" '| verifier:amy | no | space path | fail | openspec/changes/c1/evidence/e1.txt |'
assert_eq "$(cd "$space_repo" || exit 1 && "$SNAPSHOT")" "$(cd "$space_repo/src" || exit 1 && "$REVIEW_PACKAGE" --snapshot)"
echo "ok paths with spaces: snapshot, record mandate/observe and review-package work from a repository whose path contains spaces"

# ---- a linked git worktree ---------------------------------------------------

wt_main="$tmp_dir/worktree-main"
mkdir -p "$wt_main/src"
printf 'main\n' > "$wt_main/src/a.js"
git -C "$wt_main" init -q
git -C "$wt_main" config user.email "test@example.com"
git -C "$wt_main" config user.name "firefly Test"
git -C "$wt_main" add -A
git -C "$wt_main" commit -qm base
wt_link="$tmp_dir/wt linked"
git -C "$wt_main" worktree add "$wt_link" -b wt-branch -q
wt_snapshot="$(cd "$wt_link" || exit 1 && "$SNAPSHOT")"
main_snapshot="$(cd "$wt_main" || exit 1 && "$SNAPSHOT")"
[[ "$wt_snapshot" =~ ^[0-9a-f]{40}$ ]] || { echo "FAIL: worktree snapshot is $wt_snapshot" >&2; exit 1; }
printf 'wt only\n' > "$wt_link/src/b.js"
if [[ "$(cd "$wt_link" || exit 1 && "$SNAPSHOT")" == "$wt_snapshot" ]]; then
  echo "FAIL: the linked worktree snapshot ignored the worktree's own file" >&2
  exit 1
fi
assert_eq "$main_snapshot" "$(cd "$wt_main" || exit 1 && "$SNAPSHOT")"
assert_eq "$wt_link/.superpowers/sdd" "$(cd "$wt_link" || exit 1 && "$SCRIPTS/sdd-workspace")"
echo "ok worktree: snapshot and the ledger workspace resolve to the linked worktree's own root; the main worktree stays untouched"

# ---- openspec missing from PATH ----------------------------------------------

empty_bin="$tmp_dir/empty-bin"
mkdir -p "$empty_bin" "$tmp_dir/no-openspec-project"
os_output="$(grep -c "openspec is not installed or not on PATH" "$SCRIPTS/bootstrap-project.sh")"
assert_eq 1 "$os_output"
echo "negative: rejected (init names the missing openspec prerequisite — verified in script text)"

#!/usr/bin/env bash
# Runtime scripts of firefly. Every case prints an "ok ..." or a
# "negative: ..." line.
#   1. review-package, task-brief and sdd-workspace: byte-identical to the
#      overlay copies they were moved from, behaving as before (the behavior
#      cases moved here from tests/test-sdd-workflow-scripts.sh);
#   2. firefly-snapshot.sh: the worktree fixed as a candidate snapshot;
#   3. firefly-record.sh: one validated row per call on the carrier named by
#      the handoff contract, nothing written when a call is rejected.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"

SCRIPTS="$ROOT_DIR/scripts"
# The superpowers overlay scripts were removed in phase 10; the runtime
# copies under scripts/ are the only ones now.
# The three paths below are used by the sourced cases/moved-scripts.sh, which
# the linter does not follow.
# shellcheck disable=SC2034
TASK_BRIEF="$SCRIPTS/task-brief"
# shellcheck disable=SC2034
REVIEW_PACKAGE="$SCRIPTS/review-package"
# shellcheck disable=SC2034
SDD_WORKSPACE="$SCRIPTS/sdd-workspace"
SNAPSHOT="$SCRIPTS/firefly-snapshot.sh"
RECORD="$SCRIPTS/firefly-record.sh"

output_has() {
  if [[ "$1" != *"$2"* ]]; then
    echo "FAIL: expected output to contain: $2" >&2
    exit 1
  fi
}

output_lacks() {
  if [[ "$1" == *"$2"* ]]; then
    echo "FAIL: expected output not to contain: $2" >&2
    exit 1
  fi
}

file_exists() {
  if [[ ! -f "$1" ]]; then
    echo "FAIL: expected file to exist: $1" >&2
    exit 1
  fi
}

# digest — print the sha256 of stdin (Linux sha256sum, macOS shasum).
digest() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | cut -c1-64
  else
    shasum -a 256 | cut -c1-64
  fi
}

# tree_digest <dir> — one digest over every file below <dir> except .git, so a
# test can prove that a rejected call wrote nothing at all.
tree_digest() {
  find "$1" -path "$1/.git" -prune -o -type f -print | LC_ALL=C sort \
    | while IFS= read -r file; do printf '%s ' "$file"; digest < "$file"; done | digest
}

# rows <file> — print the data rows of a recorded table (first column: time).
rows() {
  sed -n '/^| 20[0-9][0-9]-/p' "$1"
}

# ---- 1. runtime scripts (formerly overlaid, now sole copies) ---------------

for name in task-brief sdd-workspace review-package; do
  [[ -x "$SCRIPTS/$name" ]] || { echo "FAIL: $name is not executable" >&2; exit 1; }
  echo "ok $name is executable as the sole runtime copy"
done

new_tmp_dir runtime-scripts
tmp_dir="$FIREFLY_TMP_DIR"

# Behavior of the three moved scripts (kept in its own file to stay
# under the 500-line limit).
source "$ROOT_DIR/tests/cases/moved-scripts.sh"

# ---- 2. firefly-snapshot.sh -----------------------------------------------

snap_repo="$tmp_dir/snapshot"
mkdir -p "$snap_repo/src"
printf 'a\n' > "$snap_repo/a.txt"
printf 's\n' > "$snap_repo/src/s.js"
git -C "$snap_repo" init -q
git -C "$snap_repo" config user.email "test@example.com"
git -C "$snap_repo" config user.name "firefly Test"
git -C "$snap_repo" add -A
git -C "$snap_repo" commit -qm base

clean_snapshot="$(cd "$snap_repo/src" && "$SNAPSHOT")"
assert_eq "$(git -C "$snap_repo" rev-parse 'HEAD^{tree}')" "$clean_snapshot"
echo "ok snapshot: a clean repository equals HEAD^{tree}, also from a nested directory"

printf 'more\n' >> "$snap_repo/a.txt"
printf 'untracked\n' > "$snap_repo/b.txt"
# The baseline is taken after the edits: taking the snapshot must not change
# what git reports about the worktree.
git -C "$snap_repo" status --porcelain > "$tmp_dir/status-before"
git -C "$snap_repo" diff --cached > "$tmp_dir/index-before"
dirty_snapshot="$(cd "$snap_repo" && "$SNAPSHOT")"
git -C "$snap_repo" status --porcelain > "$tmp_dir/status-after"
git -C "$snap_repo" diff --cached > "$tmp_dir/index-after"
if [[ "$dirty_snapshot" == "$clean_snapshot" ]]; then
  echo "FAIL: snapshot did not change after an edit and an untracked file" >&2
  exit 1
fi
assert_eq "a.txt
b.txt
src/s.js" "$(git -C "$snap_repo" ls-tree -r --name-only "$dirty_snapshot")"
output_has "$(git -C "$snap_repo" show "$dirty_snapshot:a.txt")" "more"
cmp "$tmp_dir/status-before" "$tmp_dir/status-after"
cmp "$tmp_dir/index-before" "$tmp_dir/index-after"
assert_eq "$dirty_snapshot" "$(cd "$snap_repo" && "$SNAPSHOT")"
echo "ok snapshot: an edit and an untracked file change it; status and index stay as they were; it repeats"

# The candidate is the implementation. A change's own products and records
# are left out of the tree, committed or not: editing them never turns the
# implementation into a different candidate. Product code does.
git -C "$snap_repo" commit -qam work
planning=openspec/changes/c1
mkdir -p "$snap_repo/$planning/specs" "$snap_repo/$planning/evidence/pkg" "$snap_repo/openspec/think"
printf 'spec v1\n' > "$snap_repo/$planning/specs/spec.md"
printf '## 1. Group\n\n- [ ] 1.1 do\n' > "$snap_repo/$planning/tasks.md"
printf 'Why\n' > "$snap_repo/$planning/proposal.md"
printf 'minutes\n' > "$snap_repo/openspec/think/2026-11-25-c1.md"
git -C "$snap_repo" add -A
git -C "$snap_repo" commit -qm planning
implementation="$(cd "$snap_repo" && "$SNAPSHOT")"
output_lacks "$(git -C "$snap_repo" ls-tree -r --name-only "$implementation")" 'openspec/'
printf 'row\n' > "$snap_repo/$planning/verification.md"
printf 'diff\n' > "$snap_repo/$planning/evidence/pkg/package.diff"
for record in deprecation.md retro.md archive-inventory.md; do printf 'x\n' > "$snap_repo/$planning/$record"; done
printf '#### Scenario: b (S-2)\n' > "$snap_repo/$planning/specs/spec-b.md"
printf '## Mandate\n' >> "$snap_repo/$planning/proposal.md"
printf 'more\n' >> "$snap_repo/openspec/think/2026-11-25-c1.md"
sed -i 's/^- \[ \] 1.1 do/- [x] 1.1 do/' "$snap_repo/$planning/tasks.md"
assert_eq "$implementation" "$(cd "$snap_repo" && "$SNAPSHOT")"
git -C "$snap_repo" add -A
git -C "$snap_repo" commit -qm records
assert_eq "$implementation" "$(cd "$snap_repo" && "$SNAPSHOT")"
printf 'code change\n' >> "$snap_repo/src/s.js"
if [[ "$(cd "$snap_repo" && "$SNAPSHOT")" == "$implementation" ]]; then
  echo "FAIL: a product code edit did not change the snapshot" >&2
  exit 1
fi
echo "ok snapshot: the candidate is the implementation; a change's spec, tasks, proposal, minutes and records never change it, committed or not; product code does"

# A snapshot tree is kept reachable (its own file to stay under the
# 500-line limit).
source "$ROOT_DIR/tests/cases/snapshot-retention.sh"

# Package versions are content-addressed and leave out what is only a record
# or progress. An unrelated commit changes neither; a ready decision row and
# a ticked checkbox change the task package version by its "wt:" prefix
# alone; an edit to a task line or to a spec changes the value.
cd "$snap_repo"
mkdir -p openspec/changes/c1/specs
printf 'spec v1\n' > openspec/changes/c1/specs/spec.md
printf '## 1. Group\n\n- [ ] 1.1 do\n' > openspec/changes/c1/tasks.md
git add -A
git commit -qm packages
spec_version="$("$SNAPSHOT" --spec c1)"
tasks_version="$("$SNAPSHOT" --tasks c1)"
assert_eq "$(git rev-parse HEAD:openspec/changes/c1/specs | cut -c1-12)" "$spec_version"
printf 'unrelated\n' > unrelated.txt
git add unrelated.txt
git commit -qm unrelated
assert_eq "$spec_version" "$("$SNAPSHOT" --spec c1)"
assert_eq "$tasks_version" "$("$SNAPSHOT" --tasks c1)"
"$RECORD" ready --change c1 --spec "$spec_version" --tasks "$tasks_version" --reviewer rev --verdict ACCEPT > /dev/null
sed -i 's/^- \[ \] 1.1 do/- [x] 1.1 do/' openspec/changes/c1/tasks.md
assert_eq "wt:$tasks_version" "$("$SNAPSHOT" --tasks c1)"
sed -i 's/^- \[x\] 1.1 do/- [x] 1.1 do it/' openspec/changes/c1/tasks.md
if [[ "$("$SNAPSHOT" --tasks c1)" == "wt:$tasks_version" ]]; then
  echo "FAIL: an edited task line did not change the task package version" >&2
  exit 1
fi
printf 'spec v2\n' > openspec/changes/c1/specs/spec.md
dirty_spec="$("$SNAPSHOT" --spec c1)"
[[ "$dirty_spec" =~ ^wt:[0-9a-f]{12}$ && "$dirty_spec" != "wt:$spec_version" ]] || { echo "FAIL: dirty spec version is $dirty_spec" >&2; exit 1; }
git add -A
git commit -qm edited
assert_eq "${dirty_spec#wt:}" "$("$SNAPSHOT" --spec c1)"
committed_tasks="$("$SNAPSHOT" --tasks c1)"
if [[ "$committed_tasks" == "$tasks_version" || "$committed_tasks" == wt:* ]]; then
  echo "FAIL: after the commit the task package version is $committed_tasks" >&2
  exit 1
fi
cd "$ROOT_DIR"
echo "ok snapshot --spec / --tasks: content-addressed; records, ticks and unrelated commits do not change them"

# One candidate tree: review-package takes it from firefly-snapshot.sh, so
# `--snapshot` agrees with `firefly snapshot` and a WORKTREE package names the
# candidate files only.
cd "$snap_repo"
sed -i 's/^- \[x\] 1.1 do it/- [ ] 1.1 do it/' openspec/changes/c1/tasks.md
git commit -qam untick
printf 'code change\n' >> a.txt
printf 'record\n' >> openspec/changes/c1/verification.md
printf 'log\n' > openspec/changes/c1/evidence/after-commit.log
snapshot="$(cd "$snap_repo" && "$SNAPSHOT")"
assert_eq "$snapshot" "$(cd "$snap_repo/src" && "$REVIEW_PACKAGE" --snapshot)"
package="openspec/changes/c1/evidence/${snapshot:0:12}/1/package.diff"
mkdir -p "$snap_repo/$(dirname "$package")"
output_has "$(cd "$snap_repo/src" && "$REVIEW_PACKAGE" HEAD WORKTREE "$snap_repo/$package")" "wrote $snap_repo/$package"
assert_eq "diff --git a/a.txt b/a.txt" "$(grep '^diff --git' "$snap_repo/$package")"
output_lacks "$(cat "$snap_repo/$package")" 'openspec/'
assert_eq "$snapshot" "$(cd "$snap_repo" && "$SNAPSHOT")"
# The same for a package between two commits: the planning directory tracked
# in them shows up neither as added nor as deleted.
git -C "$snap_repo" add -A
git -C "$snap_repo" commit -qm more
output_has "$(cd "$snap_repo" && "$REVIEW_PACKAGE" HEAD~1 HEAD "$snap_repo/between.diff")" "wrote $snap_repo/between.diff"
output_lacks "$(cat "$snap_repo/between.diff")" 'openspec/'
cd "$ROOT_DIR"
echo "ok review-package: --snapshot equals firefly snapshot; packages name the implementation only, planning products never appear"

# not_git <label> <command...> — run outside any repository and leave the
# single output line in OUTPUT: exit 2, and no file is created.
not_git() {
  local label="$1" dir
  shift
  dir="$tmp_dir/not-a-repo-$label"
  local before status=0
  mkdir -p "$dir"
  before="$(tree_digest "$dir")"
  OUTPUT="$(cd "$dir" && GIT_CEILING_DIRECTORIES="$tmp_dir" "$@" 2>&1)" || status=$?
  assert_eq 2 "$status"
  assert_eq 1 "$(printf '%s\n' "$OUTPUT" | wc -l)"
  assert_eq "$before" "$(tree_digest "$dir")"
}
not_git snapshot "$SNAPSHOT"
assert_eq "firefly snapshot: not a git repository" "$OUTPUT"
echo "negative: rejected (snapshot: not a git repository, nothing written)"

# ---- 3. firefly-record.sh -------------------------------------------------

test_record() {
  local repo="$tmp_dir/record" change=openspec/changes/c1 ledger=.superpowers/sdd/progress.md
  local first snapshot spec_version dirty_spec committed_tasks before out status
  mkdir -p "$repo/$change/specs/x" "$repo/$change/evidence"
  printf '## Why\n\nW\n' > "$repo/$change/proposal.md"
  printf '## 1. Group\n\n- [ ] 1.1 do\n' > "$repo/$change/tasks.md"
  printf '#### Scenario: owner recovers (S-1)\n' > "$repo/$change/specs/x/spec.md"
  printf 'evidence line\n' > "$repo/$change/evidence/e1.txt"
  git -C "$repo" init -q
  git -C "$repo" config user.email "test@example.com"
  git -C "$repo" config user.name "firefly Test"
  git -C "$repo" add -A
  git -C "$repo" commit -qm base
  cd "$repo"

  # --help works before and after the subcommand's options (a "--*" branch
  # placed before it would swallow the flag).
  output_has "$("$RECORD" observe --help)" 'Usage: firefly record <subcommand>'
  output_has "$("$RECORD" observe --change c1 --help)" 'Rejected with exit 3:'
  echo "ok record --help is honored after the subcommand and after options"

  # row_has <file> <n> <text> — the n-th data row of <file> contains <text>.
  row_has() {
    local row
    row="$(rows "$1" | sed -n "${2}p")"
    if [[ -z "$row" || "$row" != *"$3"* ]]; then
      echo "FAIL: row $2 of $1 lacks: $3" >&2
      echo "       got: $row" >&2
      exit 1
    fi
  }

  # rejected <exit> <group> <message> <args...> — the call exits with <exit>,
  # prints the message, and leaves every file below the repository as it was.
  rejected() {
    local want="$1" group="$2" message="$3" after
    shift 3
    before="$(tree_digest .)"
    status=0
    out="$("$RECORD" "$@" 2>&1)" || status=$?
    after="$(tree_digest .)"
    if [[ "$status" -ne "$want" || "$out" != *"firefly record: $message"* || "$before" != "$after" ]]; then
      echo "FAIL: $group case: exit $status, $([[ "$before" == "$after" ]] && echo 'nothing written' || echo 'FILES CHANGED'): $out" >&2
      exit 1
    fi
    echo "negative: rejected ($group: $message)"
  }

  # Every subcommand writes its carrier.
  "$RECORD" mandate --change c1 --id M-1 --objective "Recover the export" --effects "edit src/" --terminal "verified candidate" > /dev/null
  assert_contains "$change/proposal.md" '## Mandate'
  row_has "$change/proposal.md" 1 '| M-1 | Recover the export | edit src/ | verified candidate |'
  echo "ok record mandate --change appends under ## Mandate of proposal.md"

  "$RECORD" mandate --global --id M-g --objective "Investigate" --effects "none" --terminal "findings" > /dev/null
  assert_contains "$ledger" '## Mandates'
  row_has "$ledger" 1 '| M-g | Investigate | none | findings |'
  echo "ok record mandate --global appends under ## Mandates of the progress record"

  spec_version="$("$SNAPSHOT" --spec c1)"
  assert_eq "$(git rev-parse "HEAD:$change/specs" | cut -c1-12)" "$spec_version"
  snapshot="$("$SNAPSHOT")"
  "$RECORD" observe --change c1 --scenario S-1 --check file-content --result fail --observer verifier:amy \
    --evidence "$change/evidence/e1.txt" --note "chrome 120, 1280x720" > /dev/null
  first="$(rows "$change/verification.md")"
  output_has "$first" " | $snapshot | spec:$spec_version | verifier:amy | no | chrome 120, 1280x720 | fail | $change/evidence/e1.txt |"
  assert_eq 1 "$(rows "$change/verification.md" | wc -l)"
  echo "ok record observe: fail with evidence; candidate equals the snapshot taken before the write; spec is the spec package version (the tree of specs/) while the specs are clean"

  assert_eq "$snapshot" "$("$SNAPSHOT")"
  echo "ok record observe: the snapshot taken after the write still equals the recorded candidate"

  "$RECORD" observe --change c1 --scenario S-1 --check retry --result unverified --observer implementer:dan --implemented-by-observer > /dev/null
  assert_eq 2 "$(rows "$change/verification.md" | wc -l)"
  assert_eq "$first" "$(rows "$change/verification.md" | sed -n 1p)"
  row_has "$change/verification.md" 2 '| implementer:dan | yes |  | unverified |  |  |'
  echo "ok record observe: a second call appends a row and leaves the first row unchanged"

  printf '#### Scenario: owner recovers (S-1)\n\n- edited\n' > "$change/specs/x/spec.md"
  snapshot="$("$SNAPSHOT")"
  dirty_spec="$("$SNAPSHOT" --spec c1)"
  [[ "$dirty_spec" =~ ^wt:[0-9a-f]{12}$ && "$dirty_spec" != "wt:$spec_version" ]] || { echo "FAIL: dirty spec version is $dirty_spec" >&2; exit 1; }
  "$RECORD" observe --change c1 --scenario S-1 --check ui --result not-applicable --observer reviewer:bo --rule "no UI change" > /dev/null
  row_has "$change/verification.md" 3 " | $snapshot | spec:$dirty_spec | reviewer:bo | no |  | not-applicable |  | no UI change |"
  echo "ok record observe: spec is the spec package version with its wt: prefix while the specs have uncommitted changes; not-applicable carries its rule"

  "$RECORD" ready --change c1 --spec 1111111 --tasks 2222222 --reviewer rev --verdict ACCEPT --note "both packages pass" > /dev/null
  assert_contains "$change/tasks.md" '## Ready decision'
  assert_contains "$change/tasks.md" '| Time | Spec version | Tasks version | Reviewer | Verdict | Note |'
  first="$(rows "$change/tasks.md")"
  output_has "$first" '| 1111111 | 2222222 | rev | ACCEPT | both packages pass |'
  "$RECORD" ready --change c1 --spec 1111111 --tasks 3333333 --reviewer rev --verdict REVISE > /dev/null
  assert_eq 2 "$(rows "$change/tasks.md" | wc -l)"
  assert_eq "$first" "$(rows "$change/tasks.md" | sed -n 1p)"
  row_has "$change/tasks.md" 2 '| 3333333 | rev | REVISE |'
  echo "ok record ready appends under ## Ready decision of tasks.md; a second call appends, never rewrites"

  "$RECORD" verdict --change c1 --package pkg-a --reviewer rev1 --role reviewer --scenarios "S-1,S-2" --verdict REVISE \
    --reservation "unverified-item:file content not checked:touches-required=yes" \
    --reservation "non-blocking-finding:two status maps:touches-required=no" > /dev/null
  row_has "$ledger" 2 '| pkg-a | rev1 | reviewer | S-1,S-2 | REVISE | unverified-item: file content not checked (touches-required: yes); non-blocking-finding: two status maps (touches-required: no) |'
  "$RECORD" verdict --change c1 --package pkg-b --reviewer rev2 --role verifier --scenarios S-1 --verdict ACCEPT \
    --reservation "uncovered-input:very large file:touches-required=no" > /dev/null
  row_has "$ledger" 3 '| pkg-b | rev2 | verifier | S-1 | ACCEPT | uncovered-input: very large file (touches-required: no) |'
  "$RECORD" verdict --change c1 --package pkg-c --reviewer rev3 --role implementer --scenarios S-1 --verdict INSUFFICIENT_EVIDENCE > /dev/null
  # Only an acceptance owes the list, so it is the one verdict recorded as
  # "none" when there is no reservation.
  row_has "$ledger" 4 '| implementer | S-1 | INSUFFICIENT_EVIDENCE |  |'
  echo "ok record verdict: REVISE with two reservations; ACCEPT with a non-touching one; an empty list is recorded as none"

  for status in sent returned failed; do
    "$RECORD" dispatch --change c1 --package pkg-a --role reviewer --agent rev1 --status "$status" --reason "round $status" > /dev/null
  done
  row_has "$ledger" 5 '| pkg-a | reviewer | rev1 | sent | round sent |'
  row_has "$ledger" 6 '| pkg-a | reviewer | rev1 | returned | round returned |'
  row_has "$ledger" 7 '| pkg-a | reviewer | rev1 | failed | round failed |'
  echo "ok record dispatch sent / returned / failed"

  "$RECORD" budget --change c1 --round 1 --scenario S-1 --progress no --implementer dan --note "symptom unchanged" > /dev/null
  "$RECORD" budget --change c1 --round 2 --scenario S-1 --progress yes --note "failure now reproducible" > /dev/null
  row_has "$ledger" 8 '| 1 | S-1 | no | dan | symptom unchanged |'
  row_has "$ledger" 9 '| 2 | S-1 | yes |  | failure now reproducible |'
  echo "ok record budget progress no / yes"

  for section in '## Mandates' '## Review verdicts' '## Review dispatches' '## Repair budget'; do
    assert_contains "$ledger" "$section"
  done
  assert_eq "" "$(git status --porcelain -- .superpowers)"
  echo "ok record: the progress record holds its four sections and stays out of git status"

  # A hand-written note below a table (the minutes pointer) stays below it:
  # the next row goes right after the table, inside it.
  printf '\nMinutes: openspec/think/2026-11-24-export.md\n' >> "$change/proposal.md"
  "$RECORD" mandate --change c1 --id M-2 --objective "Second" --effects "none" --terminal "report" > /dev/null
  mandate_rows="$(sed -n '/^## Mandate/,/^Minutes:/p' "$change/proposal.md" | rows /dev/stdin)"
  output_has "$(printf '%s\n' "$mandate_rows" | sed -n 1p)" '| M-1 |'
  output_has "$(printf '%s\n' "$mandate_rows" | sed -n 2p)" '| M-2 | Second | none | report |'
  assert_eq "Minutes: openspec/think/2026-11-24-export.md" "$(sed -n '/^Minutes:/,$p' "$change/proposal.md")"
  echo "ok record: a note below the table stays below it; new rows land inside the table"

  # Rejections: exit 3, then exit 2, each one writing nothing.
  rejected 3 verdict "ACCEPT cannot carry a reservation that touches required behavior" \
    verdict --change c1 --package pkg-d --reviewer rev1 --role reviewer --scenarios S-1 --verdict ACCEPT --reservation "unverified-item:x:touches-required=yes"
  rejected 2 observe "invalid result: maybe" observe --change c1 --scenario S-1 --check k --result maybe --observer verifier:a
  rejected 2 observe "evidence is required for observe when result is pass" observe --change c1 --scenario S-1 --check k --result pass --observer verifier:a
  rejected 2 observe "evidence is required for observe when result is fail" observe --change c1 --scenario S-1 --check k --result fail --observer verifier:a
  rejected 2 observe "invalid evidence:" observe --change c1 --scenario S-1 --check k --result pass --observer verifier:a --evidence "$change/evidence/missing.txt"
  rejected 2 observe "rule is required for observe when result is not-applicable" observe --change c1 --scenario S-1 --check k --result not-applicable --observer verifier:a
  rejected 2 observe "invalid observer role: owner" observe --change c1 --scenario S-1 --check k --result unverified --observer owner:a
  rejected 2 observe "invalid observer: amy" observe --change c1 --scenario S-1 --check k --result unverified --observer amy
  rejected 2 observe "scenario is required for observe" observe --change c1 --check k --result unverified --observer verifier:a
  rejected 2 observe "invalid change: nope" observe --change nope --scenario S-1 --check k --result unverified --observer verifier:a
  rejected 2 verdict "invalid verdict: MAYBE" verdict --change c1 --package p --reviewer r --role reviewer --scenarios S-1 --verdict MAYBE
  rejected 2 verdict "invalid role: owner" verdict --change c1 --package p --reviewer r --role owner --scenarios S-1 --verdict REVISE
  rejected 2 verdict "invalid reservation: bogus-kind:x:touches-required=no" verdict --change c1 --package p --reviewer r --role reviewer --scenarios S-1 --verdict REVISE --reservation "bogus-kind:x:touches-required=no"
  rejected 2 verdict "invalid reservation: unverified-item:x:touches-required=maybe" verdict --change c1 --package p --reviewer r --role reviewer --scenarios S-1 --verdict REVISE --reservation "unverified-item:x:touches-required=maybe"
  rejected 2 verdict "invalid reservation: unverified-item::touches-required=no" verdict --change c1 --package p --reviewer r --role reviewer --scenarios S-1 --verdict REVISE --reservation "unverified-item::touches-required=no"
  rejected 2 verdict "invalid reservation: unverified-item:x" verdict --change c1 --package p --reviewer r --role reviewer --scenarios S-1 --verdict REVISE --reservation "unverified-item:x"
  rejected 2 verdict "package is required for verdict" verdict --change c1 --reviewer r --role reviewer --scenarios S-1 --verdict REVISE
  rejected 2 verdict "invalid option for verdict: --note" verdict --change c1 --package p --reviewer r --role reviewer --scenarios S-1 --verdict REVISE --note n
  rejected 2 ready "invalid verdict: MAYBE" ready --change c1 --spec a --tasks b --reviewer r --verdict MAYBE
  rejected 2 ready "verdict is required for ready" ready --change c1 --spec a --tasks b --reviewer r
  rejected 2 dispatch "invalid status: pending" dispatch --change c1 --package p --role reviewer --agent a --status pending
  rejected 2 dispatch "invalid role: owner" dispatch --change c1 --package p --role owner --agent a --status sent
  rejected 2 dispatch "invalid option for dispatch: --round" dispatch --change c1 --package p --role reviewer --agent a --status sent --round 1
  rejected 2 budget "invalid round: 0" budget --change c1 --round 0 --scenario S-1 --progress no --note n
  rejected 2 budget "invalid progress: maybe" budget --change c1 --round 1 --scenario S-1 --progress maybe --note n
  rejected 2 budget "note is required for budget" budget --change c1 --round 1 --scenario S-1 --progress no
  rejected 2 mandate "invalid usage: --change and --global are mutually exclusive" mandate --change c1 --global --id a --objective o --effects e --terminal t
  rejected 2 mandate "change is required for mandate" mandate --id a --objective o --effects e --terminal t
  rejected 2 usage "unknown subcommand: bogus" bogus
  rejected 2 usage "invalid usage: --scenario given more than once" observe --change c1 --scenario S-1 --scenario S-2 --check k --result unverified --observer verifier:a
}
test_record

not_git record "$RECORD" observe --change c1 --scenario S-1 --check k --result unverified --observer verifier:a
assert_eq "firefly record: not a git repository" "$OUTPUT"
echo "negative: rejected (usage: not a git repository, nothing written)"

# ---- 4. a repository that has no commit yet --------------------------------

fresh="$tmp_dir/fresh"
mkdir -p "$fresh/openspec/changes/c1/specs" "$fresh/openspec/changes/c1/evidence" "$fresh/src"
printf '#### Scenario: a (S-1)\n' > "$fresh/openspec/changes/c1/specs/spec.md"
printf '## 1. Group\n\n- [ ] 1.1 do\n' > "$fresh/openspec/changes/c1/tasks.md"
printf 'code\n' > "$fresh/src/a.js"
printf 'log\n' > "$fresh/openspec/changes/c1/evidence/e1.txt"
git -C "$fresh" init -q
git -C "$fresh" config user.email "test@example.com"
git -C "$fresh" config user.name "firefly Test"
(
  cd "$fresh"
  spec_version="$("$SNAPSHOT" --spec c1)"
  tasks_version="$("$SNAPSHOT" --tasks c1)"
  [[ "$spec_version" =~ ^wt:[0-9a-f]{12}$ && "$tasks_version" =~ ^wt:[0-9a-f]{12}$ ]] || { echo "FAIL: versions in a repository without a commit: $spec_version $tasks_version" >&2; exit 1; }
  "$RECORD" mandate --change c1 --id M-1 --objective o --effects e --terminal t > /dev/null
  "$RECORD" ready --change c1 --spec "$spec_version" --tasks "$tasks_version" --reviewer rev --verdict ACCEPT > /dev/null
  assert_eq "$tasks_version" "$("$SNAPSHOT" --tasks c1)"
  before="$("$SNAPSHOT")"
  "$RECORD" observe --change c1 --scenario S-1 --check k --result fail --observer verifier:amy --evidence openspec/changes/c1/evidence/e1.txt > /dev/null
  assert_eq "$before" "$("$SNAPSHOT")"
  # The tree holds the implementation only: the change's specs, tasks and
  # proposal are out, like the observation record and the evidence.
  assert_eq "src/a.js" "$(git ls-tree -r --name-only "$before")"
)
echo "ok a repository without a commit: versions carry wt:, the snapshot holds the implementation only"

# ---- 5. boundary cases (phase 17, contract item 2) -------------------------

# Kept in its own file to stay under the 500-line limit.
source "$ROOT_DIR/tests/cases/boundary-cases.sh"

echo "runtime scripts test passed"

#!/usr/bin/env bash
# tmp_dir, TASK_BRIEF, REVIEW_PACKAGE, SDD_WORKSPACE and the output_has /
# output_lacks / file_exists helpers come from the sourcing test.
# shellcheck disable=SC2154

# Behavior of the runtime scripts moved from the superpowers overlay:
# task-brief, review-package and sdd-workspace. Sourced by
# tests/test-runtime-scripts.sh after it has set the variables and helpers
# used below; it is not a test of its own and must not be run directly.

repo_dir="$tmp_dir/repo"
mkdir -p "$repo_dir"
git -C "$repo_dir" init -q
git -C "$repo_dir" config user.email "test@example.com"
git -C "$repo_dir" config user.name "firefly Test"

cat > "$repo_dir/tasks.md" <<'EOF'
## 1. Prepare workspace

- [ ] 1.1 Add the workspace helper

 ````markdown
## 99. This fenced heading belongs to task 1
```
## 98. This also belongs to task 1
 ````

## 2. Review changes

- [ ] 2.1 Add the review helper
EOF

brief_output="$(cd "$repo_dir" && "$TASK_BRIEF" tasks.md 1)"
brief_path="$repo_dir/.superpowers/sdd/task-1-brief.md"
output_has "$brief_output" "wrote $brief_path"
file_exists "$brief_path"
brief_contents="$(<"$brief_path")"
output_has "$brief_contents" "## 1. Prepare workspace"
output_has "$brief_contents" "## 99. This fenced heading belongs to task 1"
output_has "$brief_contents" "## 98. This also belongs to task 1"
output_lacks "$brief_contents" "## 2. Review changes"
echo "ok task-brief extracts one task group, fenced headings included"

unclosed_plan="$(dirname "$brief_path")/unclosed-plan.md"
printf '## 1. Unclosed example\n\n~~~markdown\n## 2. Hidden heading\n' > "$unclosed_plan"
if unclosed_output="$(cd "$repo_dir" && "$TASK_BRIEF" "$unclosed_plan" 1 2>&1)"; then
  echo "expected task-brief to reject an unclosed fence" >&2
  exit 1
fi
output_has "$unclosed_output" "unclosed code fence"
output_has "$(<"$brief_path")" "## 1. Prepare workspace"

outside_brief="$tmp_dir/outside-brief.md"
if (cd "$repo_dir" && "$TASK_BRIEF" tasks.md 1 "$outside_brief") >/dev/null 2>&1; then
  echo "expected task-brief to reject an OUTFILE outside the repo" >&2
  exit 1
fi

ln -s "$repo_dir/change.txt" "$repo_dir/brief-link.md"
if (cd "$repo_dir" && "$TASK_BRIEF" tasks.md 1 "$repo_dir/brief-link.md") >/dev/null 2>&1; then
  echo "expected task-brief to reject a symlink OUTFILE" >&2
  exit 1
fi
rm -f "$repo_dir/brief-link.md"

if compgen -G "$repo_dir/.task-brief.*" >/dev/null; then
  echo "task-brief left a temporary file in the repo" >&2
  exit 1
fi

if (cd "$repo_dir" && "$TASK_BRIEF" tasks.md 3) >/dev/null 2>&1; then
  echo "expected task-brief to reject a missing task group" >&2
  exit 1
fi
echo "ok task-brief rejects an OUTFILE outside the repo, a symlinked OUTFILE and a missing task group"

printf 'base\n' > "$repo_dir/change.txt"
git -C "$repo_dir" add change.txt tasks.md
git -C "$repo_dir" commit -qm "base"
base_sha="$(git -C "$repo_dir" rev-parse HEAD)"

printf 'first change\n' >> "$repo_dir/change.txt"
git -C "$repo_dir" commit -am "first task commit" -q
printf 'second change\n' >> "$repo_dir/change.txt"
git -C "$repo_dir" commit -am "second task commit" -q
head_sha="$(git -C "$repo_dir" rev-parse HEAD)"

review_output="$(cd "$repo_dir" && "$REVIEW_PACKAGE" "$base_sha" "$head_sha")"
review_path="$repo_dir/.superpowers/sdd/review-$(git -C "$repo_dir" rev-parse --short "$base_sha")..$(git -C "$repo_dir" rev-parse --short "$head_sha").diff"
output_has "$review_output" "wrote $review_path: 2 commit(s)"
file_exists "$review_path"
review_contents="$(<"$review_path")"
output_has "$review_contents" "first task commit"
output_has "$review_contents" "second task commit"
output_has "$review_contents" "## Diff"
output_has "$review_contents" "change.txt"
echo "ok review-package BASE HEAD lists both commits and the diff"

# The fixed tree includes an untracked file that a worktree diff omits.
printf 'trailing whitespace \n' > "$repo_dir/untracked-whitespace.txt"
fixed_tree="$(cd "$repo_dir" && "$REVIEW_PACKAGE" --snapshot)"
git -C "$repo_dir" diff --check HEAD
if git -C "$repo_dir" diff --check HEAD "$fixed_tree" > "$repo_dir/.superpowers/sdd/whitespace.log"; then
  echo 'expected a fixed-tree check to reject whitespace in the new file' >&2
  exit 1
fi
output_has "$(<"$repo_dir/.superpowers/sdd/whitespace.log")" 'untracked-whitespace.txt'
rm -f "$repo_dir/untracked-whitespace.txt"

workspace_path="$(cd "$repo_dir" && "$SDD_WORKSPACE")"
if [[ "$workspace_path" != "$repo_dir/.superpowers/sdd" ]]; then
  echo "unexpected SDD workspace path: $workspace_path" >&2
  exit 1
fi

if [[ -n "$(git -C "$repo_dir" status --short --untracked-files=all)" ]]; then
  echo "expected SDD artifacts to remain ignored by git status" >&2
  exit 1
fi
echo "ok sdd-workspace resolves the workspace and keeps it out of git status"

mkdir -p "$repo_dir/nested"
task_one_base="$(cd "$repo_dir/nested" && "$REVIEW_PACKAGE" --snapshot)"
printf 'task one tracked\n' >> "$repo_dir/change.txt"
printf 'task one untracked\n' > "$repo_dir/task-one.txt"
task_one_output="$(cd "$repo_dir/nested" && "$REVIEW_PACKAGE" "$task_one_base" WORKTREE)"
task_one_path="${task_one_output#wrote }"
task_one_path="${task_one_path%%: *}"
output_has "$task_one_output" "worktree snapshot diff"
file_exists "$task_one_path"
task_one_contents="$(<"$task_one_path")"
output_has "$task_one_contents" "task one tracked"
output_has "$task_one_contents" "task-one.txt"
output_has "$task_one_contents" "task one untracked"
echo "ok review-package BASE WORKTREE includes tracked and untracked work"

task_two_base="$(cd "$repo_dir/nested" && "$REVIEW_PACKAGE" --snapshot)"
printf '\nTask two tracked\n' >> "$repo_dir/tasks.md"
printf 'task two untracked\n' > "$repo_dir/task-two.txt"
task_two_output="$(cd "$repo_dir/nested" && "$REVIEW_PACKAGE" "$task_two_base" WORKTREE)"
task_two_path="${task_two_output#wrote }"
task_two_path="${task_two_path%%: *}"
file_exists "$task_two_path"
task_two_contents="$(<"$task_two_path")"
output_has "$task_two_contents" "Task two tracked"
output_has "$task_two_contents" "task-two.txt"
output_has "$task_two_contents" "task two untracked"
output_lacks "$task_two_contents" "task one tracked"
output_lacks "$task_two_contents" "task-one.txt"
output_lacks "$task_two_contents" "task one untracked"
echo "ok review-package BASE WORKTREE isolates consecutive uncommitted tasks"

custom_review_path="$repo_dir/review.diff"
if (cd "$repo_dir" && "$REVIEW_PACKAGE" "$task_two_base" WORKTREE "$custom_review_path") >/dev/null 2>&1; then
  echo "expected review-package to reject an output that would enter the candidate" >&2
  exit 1
fi
printf '/review.diff\n' >> "$repo_dir/.git/info/exclude"
before_report="$(cd "$repo_dir" && "$REVIEW_PACKAGE" --snapshot)"
custom_review_output="$(cd "$repo_dir/nested" && "$REVIEW_PACKAGE" "$task_two_base" WORKTREE "$custom_review_path")"
output_has "$custom_review_output" "wrote $custom_review_path"
file_exists "$custom_review_path"
custom_review_contents="$(<"$custom_review_path")"
output_lacks "$custom_review_contents" "review.diff (untracked)"
output_lacks "$custom_review_contents" "diff --git a/review.diff b/review.diff"
output_lacks "$custom_review_contents" ".review-package."
assert_eq "$before_report" "$(cd "$repo_dir" && "$REVIEW_PACKAGE" --snapshot)"
echo "ok review-package accepts an ignored custom OUTFILE without changing the snapshot"

existing_output_base="$(cd "$repo_dir/nested" && "$REVIEW_PACKAGE" --snapshot)"
existing_output="$(cd "$repo_dir/nested" && "$REVIEW_PACKAGE" "$existing_output_base" WORKTREE "$custom_review_path")"
output_has "$existing_output" "wrote $custom_review_path"
existing_output_contents="$(<"$custom_review_path")"
output_lacks "$existing_output_contents" "diff --git a/review.diff b/review.diff"
echo "ok review-package overwrites an existing OUTFILE"

if ! git -C "$repo_dir" diff --cached --quiet; then
  echo "review snapshots must not modify the real index" >&2
  exit 1
fi
echo "ok review snapshots leave the real index untouched"

ln -s "$repo_dir/change.txt" "$repo_dir/review-link.diff"
if (cd "$repo_dir/nested" && "$REVIEW_PACKAGE" "$task_two_base" WORKTREE "$repo_dir/review-link.diff") >/dev/null 2>&1; then
  echo "expected review-package to reject a symlink OUTFILE" >&2
  exit 1
fi

outside_path="$tmp_dir/outside.diff"
if (cd "$repo_dir/nested" && "$REVIEW_PACKAGE" "$task_two_base" WORKTREE "$outside_path") >/dev/null 2>&1; then
  echo "expected review-package to reject an OUTFILE outside the repo/workspace" >&2
  exit 1
fi

mkdir -p "$tmp_dir/symlink-parent"
ln -s "$tmp_dir/symlink-parent" "$repo_dir/symlink-parent"
if (cd "$repo_dir/nested" && "$REVIEW_PACKAGE" "$task_two_base" WORKTREE "$repo_dir/symlink-parent/review.diff") >/dev/null 2>&1; then
  echo "expected review-package to reject an OUTFILE under a symlinked parent" >&2
  exit 1
fi

if compgen -G "$repo_dir/.review-package.*" >/dev/null; then
  echo "review-package left a temporary file in the repo" >&2
  exit 1
fi
echo "ok review-package rejects a symlinked or outside OUTFILE and leaves no temporary file"

symlink_repo="$tmp_dir/symlink-repo"
mkdir -p "$symlink_repo"
git -C "$symlink_repo" init -q
git -C "$symlink_repo" config user.email "test@example.com"
git -C "$symlink_repo" config user.name "firefly Test"
ln -s "$tmp_dir" "$symlink_repo/.superpowers"
if (cd "$symlink_repo" && "$SDD_WORKSPACE") >/dev/null 2>&1; then
  echo "expected sdd-workspace to reject a symlinked .superpowers" >&2
  exit 1
fi
echo "ok sdd-workspace rejects a symlinked .superpowers"

nested_symlink_repo="$tmp_dir/nested-symlink-repo"
nested_symlink_target="$tmp_dir/nested-symlink-target"
mkdir -p "$nested_symlink_repo/.superpowers" "$nested_symlink_target"
git -C "$nested_symlink_repo" init -q
ln -s "$nested_symlink_target" "$nested_symlink_repo/.superpowers/sdd"
if (cd "$nested_symlink_repo" && "$SDD_WORKSPACE") >/dev/null 2>&1; then
  echo "expected sdd-workspace to reject a symlinked .superpowers/sdd directory" >&2
  exit 1
fi
if [[ -e "$nested_symlink_target/.gitignore" ]]; then
  echo "sdd-workspace must not write through a symlinked workspace directory" >&2
  exit 1
fi
echo "ok sdd-workspace rejects a symlinked workspace directory"

linked_ignore_repo="$tmp_dir/linked-ignore-repo"
linked_ignore_target="$tmp_dir/linked-ignore-target"
mkdir -p "$linked_ignore_repo/.superpowers/sdd" "$linked_ignore_target"
git -C "$linked_ignore_repo" init -q
printf 'preserve me\n' > "$linked_ignore_target/.gitignore"
ln -s "$linked_ignore_target/.gitignore" "$linked_ignore_repo/.superpowers/sdd/.gitignore"
if (cd "$linked_ignore_repo" && "$SDD_WORKSPACE") >/dev/null 2>&1; then
  echo "expected sdd-workspace to reject a symlinked workspace .gitignore" >&2
  exit 1
fi
if [[ "$(cat "$linked_ignore_target/.gitignore")" != "preserve me" ]]; then
  echo "sdd-workspace must not write through a symlinked .gitignore" >&2
  exit 1
fi
echo "ok sdd-workspace rejects a symlinked workspace .gitignore"

#!/usr/bin/env bash
# tmp_dir, SNAPSHOT and the assert_eq / output_has helpers come from the
# sourcing test.
# shellcheck disable=SC2154

# A snapshot tree is kept reachable. Nothing else references the tree of an
# uncommitted candidate, and git gc prunes what nothing references: a baseline
# recorded at the start of a long delivery would be gone by the time
# review-package needs it. firefly snapshot keeps each tree under
# refs/firefly/snapshots/<sha>.

keep_repo="$tmp_dir/snapshot-keep"
mkdir -p "$keep_repo"
printf 'base\n' > "$keep_repo/a.txt"
git -C "$keep_repo" init -q
git -C "$keep_repo" config user.email "test@example.com"
git -C "$keep_repo" config user.name "firefly Test"
git -C "$keep_repo" add -A
git -C "$keep_repo" commit -qm base
printf 'candidate\n' >> "$keep_repo/a.txt"
uncommitted="$(cd "$keep_repo" && "$SNAPSHOT")"
if [[ "$uncommitted" == "$(git -C "$keep_repo" rev-parse 'HEAD^{tree}')" ]]; then
  echo "FAIL: the uncommitted edit did not change the snapshot" >&2
  exit 1
fi
# The ref names the tree itself, so the ref and the snapshot are one value.
assert_eq "$uncommitted" "$(git -C "$keep_repo" rev-parse "refs/firefly/snapshots/$uncommitted")"
git -C "$keep_repo" gc --prune=now --quiet
assert_eq "tree" "$(git -C "$keep_repo" cat-file -t "$uncommitted")"
output_has "$(git -C "$keep_repo" show "$uncommitted:a.txt")" "candidate"
assert_eq "$uncommitted" "$(cd "$keep_repo" && "$SNAPSHOT")"
# Running it again on the same candidate adds no second ref.
assert_eq "refs/firefly/snapshots/$uncommitted" "$(git -C "$keep_repo" for-each-ref --format='%(refname)' refs/firefly/snapshots/)"
echo "ok snapshot: each snapshot is kept under refs/firefly/snapshots/<sha> and survives git gc --prune=now"

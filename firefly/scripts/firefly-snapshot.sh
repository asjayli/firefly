#!/usr/bin/env bash
# firefly snapshot — identify the candidate in the worktree and its packages.
#
#   firefly snapshot
#     One line: the SHA of a Git tree object that captures the candidate in the
#     working tree, untracked files included (files ignored by Git are not part
#     of it). The tree is built in a temporary index, so the real index and the
#     worktree are never touched and nothing is created under .superpowers/.
#     The one write is a ref per snapshot, refs/firefly/snapshots/<sha>: it
#     keeps the tree reachable, because git gc prunes what nothing references.
#
#   firefly snapshot --spec <change>
#     One line: the spec package version of openspec/changes/<change>.
#
#   firefly snapshot --tasks <change>
#     One line: the task package version of openspec/changes/<change>.
#
# The candidate is the implementation. The products and records of a change
# are not part of it and are left out of the tree, committed or not: its spec
# package and task package (versioned on their own, see below), its proposal,
# design, minutes, observation records, evidence, review packages and archive
# records under openspec/changes/ and openspec/think/. Editing or committing
# any of them never turns the implementation into a different candidate. A
# spec edit is a new spec version, not a new candidate: the package is rebuilt
# for the same candidate. The progress record is excluded by its own
# .gitignore. A repository that tracks nothing under those two directories
# snapshots to its HEAD tree when clean.
#
# A package version is content-addressed, so an unrelated commit never changes
# it and a value written into the ready decision can be recomputed later:
#   --spec    the first 12 characters of the tree SHA of the change's specs/
#             directory as the worktree has it;
#   --tasks   the first 12 characters of the blob SHA of the change's tasks.md
#             with the rows of its "## Ready decision" table and every ticked
#             checkbox removed: the ready decision is a record about the
#             packages and a tick is progress, neither is part of the package.
# Only the rows of the "## Ready decision" table are left out; other text in
# that section is part of the task package. Either is prefixed "wt:" while its
# files have uncommitted changes.
#
# Handoff contract (firefly/references/handoff-contract.md): uncommitted
# changes are fixed as a locatable candidate snapshot before the first
# evidence is produced. Evidence and review packages reference the snapshot
# only. A worktree that differs from the snapshot is a new candidate.
#
# Run from anywhere inside the repository. A repository that has no commit yet
# snapshots its worktree as it is and reports every package as uncommitted.
#
# Exit codes:
#   0  success — one identifier on stdout
#   2  not inside a Git repository, or an unknown change

set -euo pipefail

# What a candidate is not: the planning products and records of the changes.
PLANNING_PATHS=(openspec/changes openspec/think)

refuse() {
  echo "firefly snapshot: $1" >&2
  exit 2
}

usage() {
  sed -n '2,/^$/p' "$0" | sed -e 's/^# \{0,1\}//' >&2
}

mode=candidate
change=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec|--tasks)
      [[ $# -ge 2 ]] || refuse "invalid option: $1 needs a change name"
      mode="${1#--}"
      change="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      refuse "unknown option: $1"
      ;;
  esac
done

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || refuse "not a git repository"
# A repository may have no commit yet (a change proposed before the first
# commit).
have_head=false
git -C "$repo_root" cat-file -e 'HEAD^{tree}' 2>/dev/null && have_head=true

# dirty <path> — true while <path> has uncommitted changes, which is always
# the case in a repository without a commit.
dirty() {
  [[ -n "$(git -C "$repo_root" status --porcelain -- "$1")" ]]
}

# Package versions are printed with the first 12 characters, prefixed "wt:"
# while the package has uncommitted changes.
short_version() {
  version="${object:0:12}"
  if dirty "$path" || [[ "$mode" == spec && "$object" != "$(git -C "$repo_root" rev-parse --verify --quiet "HEAD:$path")" ]]; then
    version="wt:$version"
  fi
  printf '%s\n' "$version"
}

if [[ "$mode" == tasks ]]; then
  path="openspec/changes/$change/tasks.md"
  [[ "$change" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || refuse "invalid change: $change"
  [[ -f "$repo_root/$path" ]] || refuse "invalid change: $change (no file $path)"
  # Only the rows of the "## Ready decision" table are records about the
  # packages; any other text in that section belongs to the task package. The
  # heading, the rows and the blank lines of that section are skipped, so an
  # appended section leaves nothing behind. Blank lines elsewhere are held
  # back until a text line follows, so trailing blank lines do not count.
  object="$(awk '
    BEGIN { held = 0 }
    $0 == "## Ready decision" { skip = 1; next }
    /^## / { skip = 0 }
    skip && (/^\|/ || $0 == "") { next }
    match($0, /^[[:space:]]*- \[[xX]\]/) { sub(/\[[xX]\]/, "[ ]") }
    $0 == "" { held++; next }
    { while (held-- > 0) print ""; held = 0; print }
  ' "$repo_root/$path" | git -C "$repo_root" hash-object --stdin)"
  short_version
  exit 0
fi

# A private directory keeps the temporary index out of reach of other users;
# the index file itself must not exist before Git creates it.
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/firefly-snapshot.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

indexed() {
  GIT_INDEX_FILE="$tmp_dir/index" git -C "$repo_root" "$@"
}

# Nothing else references the tree of an uncommitted candidate, and git gc
# prunes what nothing references: a baseline recorded at the start of a long
# delivery would be gone by the time review-package needs it. One ref per
# snapshot keeps it. A ref that cannot be written is reported and is not fatal:
# the snapshot still identifies the candidate while the object lives.
keep_reachable() {
  git -C "$repo_root" update-ref "refs/firefly/snapshots/$1" "$1" >/dev/null 2>&1 ||
    echo "firefly snapshot: warning: could not keep $1 reachable (refs/firefly/snapshots/$1); git gc may prune it" >&2
}

if [[ "$mode" == candidate ]]; then
  if $have_head; then indexed read-tree HEAD; else indexed read-tree --empty; fi
  indexed add -A
  indexed rm -r --cached -q --ignore-unmatch -- "${PLANNING_PATHS[@]}"
  tree="$(indexed write-tree)"
  keep_reachable "$tree"
  echo "$tree"
  exit 0
fi

# --spec: the tree of the change's specs/ directory as the worktree has it,
# including local planning files ignored by Git.
path="openspec/changes/$change/specs"
[[ "$change" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || refuse "invalid change: $change"
[[ -d "$repo_root/$path" ]] || refuse "invalid change: $change (no directory $path)"
indexed read-tree --empty
indexed add -f -A -- "$path"
tree="$(indexed write-tree)"
object="$(git -C "$repo_root" rev-parse --verify --quiet "$tree:$path")" || refuse "invalid change: $change"
short_version

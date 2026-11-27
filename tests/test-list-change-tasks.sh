#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/firefly/scripts/list-change-tasks.sh"

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "expected output to contain: $needle" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "expected output to not contain: $needle" >&2
    exit 1
  fi
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

project_dir="$tmp_dir/project"
mkdir -p "$project_dir/openspec/changes/archive"
mkdir -p "$project_dir/openspec/changes/alpha"
mkdir -p "$project_dir/openspec/changes/beta"
mkdir -p "$project_dir/openspec/changes/archive/old-change"

cat > "$project_dir/openspec/changes/alpha/.openspec.yaml" <<'EOF'
schema: spec-driven
EOF

cat > "$project_dir/openspec/changes/beta/.openspec.yaml" <<'EOF'
schema: spec-driven
EOF

cat > "$project_dir/openspec/changes/archive/old-change/.openspec.yaml" <<'EOF'
schema: spec-driven
EOF

cat > "$project_dir/openspec/changes/alpha/tasks.md" <<'EOF'
## 1. Alpha

- [ ] 1.1 First alpha task
- [x] 1.2 Done alpha task
  - [ ] Nested alpha task
  3. [~] Pending alpha task
  - [A](https://example.test) Related link
EOF

cat > "$project_dir/openspec/changes/beta/tasks.md" <<'EOF'
## 1. Beta

- [ ] 1.1 First beta task
- [ ] 1.2 Second beta task
EOF

cat > "$project_dir/openspec/changes/archive/old-change/tasks.md" <<'EOF'
## 1. Old

- [ ] 1.1 Archived task
EOF

touch -t 202601010101 "$project_dir/openspec/changes/alpha/.openspec.yaml"
touch -t 202601020101 "$project_dir/openspec/changes/beta/.openspec.yaml"

help_output="$("$SCRIPT" --help)"
assert_contains "$help_output" "firefly tasks <变更ID|all>"

if missing="$("$SCRIPT" --root "$project_dir" 2>&1)"; then
  echo "expected tasks to reject an omitted target" >&2
  exit 1
fi
assert_contains "$missing" "firefly tasks all"
assert_not_contains "$missing" "First alpha task"

scoped="$("$SCRIPT" alpha --root "$project_dir")"
assert_contains "$scoped" "First alpha task"
assert_contains "$scoped" "Nested alpha task"
assert_contains "$scoped" "Pending alpha task"
assert_not_contains "$scoped" "Related link"
assert_not_contains "$scoped" "First beta task"
mkdir "$project_dir/openspec/changes/all"
printf '%s\n' '- [ ] Literal all task' > "$project_dir/openspec/changes/all/tasks.md"
literal="$("$SCRIPT" --root "$project_dir" -- all)"
assert_contains "$literal" "Literal all task"
assert_not_contains "$literal" "First alpha task"
mkdir "$project_dir/openspec/changes/unplanned"
assert_contains "$("$SCRIPT" unplanned --root "$project_dir")" "尚未生成任务表"

output="$("$SCRIPT" all --root "$project_dir")"

assert_contains "$output" "📋 Active change tasks"
assert_contains "$output" "🗂️ alpha"
assert_contains "$output" "🗂️ beta"
assert_contains "$output" "First alpha task"
assert_contains "$output" "First beta task"
assert_contains "$output" "Second beta task"
assert_contains "$output" "Literal all task"
assert_contains "$output" "变更 unplanned 尚未生成任务表"
assert_not_contains "$output" "Done alpha task"
assert_not_contains "$output" "Archived task"

alpha_line="$(printf '%s\n' "$output" | nl -ba | rg '🗂️ alpha' | awk '{print $1}')"
beta_line="$(printf '%s\n' "$output" | nl -ba | rg '🗂️ beta' | awk '{print $1}')"
if [[ "$alpha_line" -ge "$beta_line" ]]; then
  echo "expected alpha to appear before beta" >&2
  exit 1
fi

# Reverse mtimes so beta becomes older than alpha. Output order must flip to
# beta-before-alpha. If stat-based mtime were broken (the original BSD-only
# `stat -f '%m'` bug on GNU/Linux), ordering would silently fall back to the
# find lexical order (alpha, beta) and this assertion would fail.
touch -t 202601030101 "$project_dir/openspec/changes/alpha/.openspec.yaml"
touch -t 202601010101 "$project_dir/openspec/changes/beta/.openspec.yaml"

reverse_output="$("$SCRIPT" all --root "$project_dir")"
reverse_alpha_line="$(printf '%s\n' "$reverse_output" | nl -ba | rg '🗂️ alpha' | awk '{print $1}')"
reverse_beta_line="$(printf '%s\n' "$reverse_output" | nl -ba | rg '🗂️ beta' | awk '{print $1}')"
if [[ -z "$reverse_alpha_line" || -z "$reverse_beta_line" ]]; then
  echo "expected both changes in reversed-mtime output" >&2
  exit 1
fi
if [[ "$reverse_beta_line" -ge "$reverse_alpha_line" ]]; then
  echo "expected beta to appear before alpha after reversing mtimes" >&2
  exit 1
fi

echo "list change tasks test passed"

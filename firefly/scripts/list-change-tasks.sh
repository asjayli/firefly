#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
用法：firefly tasks <变更ID|all> [--root 目录]
  变更ID  只读取该活跃变更的 tasks.md。用 firefly list 查询 ID。
  all    遍历活跃变更，按变更元数据修改时间从早到晚列出未完成项。缺少元数据时使用目录时间。
  --root 可选。指定项目根，默认从当前目录向上查找本地项目。
示例：firefly tasks all
      firefly tasks -- all（只查询 ID 恰好为 all 的变更）
EOF
}

refuse() {
  printf '%s\n' "firefly tasks: $1" >&2
  exit 2
}

if [[ $# == 1 && ( "$1" == --help || "$1" == -h ) ]]; then
  usage
  exit 0
fi

project_dir=''
target=''
literal=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)
      [[ $# -ge 2 && -z "$project_dir" && -n "$2" && "$2" != -* ]] ||
        refuse '请为 --root 指定一个项目目录。'
      project_dir="$2"
      shift 2
      ;;
    --)
      [[ $# == 2 && -z "$target" ]] || refuse '请在 -- 后指定一个变更 ID。'
      literal=true
      target="$2"
      shift 2
      ;;
    *)
      [[ -z "$target" && "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] ||
        refuse '请指定一个变更 ID 或 all。用 firefly tasks --help 查看用法。'
      target="$1"
      shift
      ;;
  esac
done
[[ "$target" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && "$target" != archive ]] ||
  refuse '请指定变更 ID（用 firefly list 查询），或运行 firefly tasks all。'
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
paths="$script_dir/project-paths.mjs"
if [[ -n "$project_dir" ]]; then
  project_dir="$(node "$paths" root "$project_dir")"
else
  project_dir="$(node "$paths" root)"
fi

# Cross-platform mtime: GNU stat uses -c '%Y', BSD/macOS stat uses -f '%m'.
# Probe once with a stable target instead of sniffing `uname`.
if stat -c '%Y' / >/dev/null 2>&1; then
  stat_mtime() { stat -c '%Y' "$1"; }
else
  stat_mtime() { stat -f '%m' "$1"; }
fi

# Match the OpenSpec checkbox grammar, including nested and ordered items.
# Only x/X marks completion. A single-character Markdown link is not a task.
list_unfinished_tasks() {
  awk '
    {
      rest = $0
      if (!sub(/^[[:space:]]*([-*+]|[0-9]+[.)])[[:space:]]*\[/, "", rest)) next
      end = index(rest, "]")
      if (!end) next
      raw = substr(rest, 1, end - 1)
      marker = raw
      gsub(/[[:space:]]/, "", marker)
      following = substr(rest, end + 1, 1)
      if (length(marker) > 1 || marker ~ /^[xX]$/) next
      if ((following == "(" || following == "[") && !(raw ~ /^[[:space:]]+$/)) next
      print
    }
  ' "$1"
}

check_link_target() {
  if [[ -L "$1" ]]; then node "$paths" within "$project_dir" "$1"; fi
}

print_change_tasks() {
  local change_dir="$1"
  local tasks_file="$change_dir/tasks.md"
  local unfinished
  check_link_target "$change_dir" || exit "$?"
  if [[ ! -e "$tasks_file" && ! -L "$tasks_file" ]]; then
    printf '\n变更 %s 尚未生成任务表。\n' "${change_dir##*/}"
    printed=1
    return 0
  fi
  check_link_target "$tasks_file" || exit "$?"
  [[ -f "$tasks_file" ]] || refuse "任务表不是常规文件：$tasks_file"
  unfinished="$(list_unfinished_tasks "$tasks_file")" || exit "$?"
  [[ -n "$unfinished" ]] || return 0
  printf '\n🗂️ %s\n📄 %s\n%s\n' "${change_dir##*/}" "$tasks_file" "$unfinished"
  printed=1
}

changes_root="$project_dir/openspec/changes"

if [[ ! -d "$changes_root" ]]; then
  echo "openspec/changes not found under $project_dir" >&2
  exit 1
fi

printed=0
if [[ "$target" != all || "$literal" == true ]]; then
  change_dir="$changes_root/$target"
  [[ -d "$change_dir" ]] || refuse "未找到活跃变更：$target"
  echo "📋 Active change tasks"
  print_change_tasks "$change_dir"
  if [[ "$printed" == 0 ]]; then printf '\n变更 %s 没有未完成任务。\n' "$target"; fi
  exit 0
fi

tmp_list="$(mktemp)"
trap 'rm -f "$tmp_list"' EXIT

for change_dir in "$changes_root"/*; do
  [[ -d "$change_dir" && "${change_dir##*/}" != "archive" ]] || continue
  check_link_target "$change_dir" || exit "$?"
  timestamp_source="$change_dir/.openspec.yaml"
  check_link_target "$timestamp_source" || exit "$?"
  [[ -f "$timestamp_source" ]] || timestamp_source="$change_dir"
  timestamp="$(stat_mtime "$timestamp_source")"
  printf '%s\t%s\n' "$timestamp" "$change_dir" >> "$tmp_list"
done

sorted="$(sort -n "$tmp_list")"
echo "📋 Active change tasks"
while IFS=$'\t' read -r _timestamp change_dir; do
  [[ -n "$change_dir" ]] || continue
  print_change_tasks "$change_dir"
done <<< "$sorted"

if [[ "$printed" -eq 0 ]]; then
  echo
  echo "✨ No unfinished tasks in active changes"
fi

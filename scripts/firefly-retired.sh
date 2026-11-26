#!/usr/bin/env bash
# firefly-retired.sh — remove the assets firefly 0.1.0 left behind.
#
# Two rules that never bend: only files whose sha256 matches the pinned
# 0.1.0 hashes are touched, and everything touched moves into a backup
# directory instead of being deleted. Symlinks themselves are never removed
# or replaced; targets resolve through them.

# process_retired_assets <mode> <manifest> <home_root> [sp_root]
#   mode: "apply" (installer / doctor --repair) or "report" (doctor).
#   Returns 1 in report mode when a matching leftover was flagged DRIFT.
process_retired_assets() {
  local mode="$1" manifest="$2" home_root="$3" sp_root="${4:-}"

  local listing
  listing="$(retired_listing "$manifest" "$sp_root")" || return 1

  # Group overlay-leftover lines by parent directory (all listed files of
  # one entry share one backup decision) without string concatenation:
  # GROUP_DIR_OF maps each file to its directory, UNIQUE_DIRS lists dirs.
  local handling target hashes parent
  local -A seen_dirs=()
  local -A RETIRED_LEFTOVER_HASHES=()
  local -A RETIRED_GROUP_DIR_OF=()
  local -a RETIRED_UNIQUE_DIRS=()
  RETIRED_SAW_DRIFT=0
  while IFS="$(printf '\t')" read -r handling target hashes; do
    [[ -n "$handling" ]] || continue
    if [[ "$handling" == "remove-with-backup" ]]; then
      parent="$(dirname "$target")"
      if [[ -z "${seen_dirs[$parent]:-}" ]]; then
        seen_dirs["$parent"]=1
        process_retired_directory "$mode" "$home_root" "$parent" "$hashes"
      fi
    else
      parent="$(dirname "$target")"
      RETIRED_GROUP_DIR_OF["$target"]="$parent"
      RETIRED_LEFTOVER_HASHES["$target"]="$hashes"
      if [[ -z "${seen_dirs[$parent]:-}" ]]; then
        seen_dirs["$parent"]=1
        RETIRED_UNIQUE_DIRS+=("$parent")
      fi
    fi
  done <<<"$listing"

  local dir
  for dir in "${RETIRED_UNIQUE_DIRS[@]}"; do
    process_leftover_group "$mode" "$home_root" "$dir"
  done

  [[ "$RETIRED_SAW_DRIFT" -eq 1 ]] && return 1
  return 0
}

retired_listing() {
  local manifest="$1" sp_root="$2"
  local helper="${FIREFLY_MANIFEST_HELPER:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/manifest-assets.mjs}"
  if [[ -n "$sp_root" ]]; then
    FIREFLY_SUPERPOWERS_ROOT="$sp_root" node "$helper" "$manifest" --retired
  else
    # A dummy root keeps placeholder expansion valid; nothing exists there,
    # so every overlay-leftover target is simply absent and skipped.
    FIREFLY_SUPERPOWERS_ROOT="${FIREFLY_SUPERPOWERS_ROOT:-/nonexistent-firefly-superpowers}" node "$helper" "$manifest" --retired
  fi
}

# Overlay-leftover files inside one upstream directory: every
# RETIRED_GROUP_DIR_OF entry whose value equals $3 belongs to this group.
process_leftover_group() {
  local mode="$1" home_root="$2" dir="$3"
  local any_present=0 any_mismatch=0
  local target resolved hashes actual
  for target in "${!RETIRED_GROUP_DIR_OF[@]}"; do
    [[ "${RETIRED_GROUP_DIR_OF[$target]}" == "$dir" ]] || continue
    [[ -e "$target" || -L "$target" ]] || continue
    any_present=1
    resolved="$(resolve_managed_target "$target")"
    hashes="${RETIRED_LEFTOVER_HASHES[$target]}"
    actual="$(firefly_sha256_file "$resolved" 2>/dev/null || true)"
    list_contains_hash "$hashes" "$actual" || any_mismatch=1
  done

  (( any_present )) || return 0
  if (( any_mismatch )); then
    emit_retired_status "$mode" KEPT "$dir" "mixed content"
    return 0
  fi
  if [[ "$mode" == "report" ]]; then
    emit_retired_status "$mode" DRIFT "$dir" "retired firefly asset; run firefly repair"
    RETIRED_SAW_DRIFT=1
    return 0
  fi

  local backup_dir rel
  backup_dir="$(retired_backup_dir "$home_root")/$(basename "$dir")"
  for target in "${!RETIRED_GROUP_DIR_OF[@]}"; do
    [[ "${RETIRED_GROUP_DIR_OF[$target]}" == "$dir" ]] || continue
    [[ -e "$target" || -L "$target" ]] || continue
    resolved="$(resolve_managed_target "$target")"
    rel="${target#"$dir"/}"
    mkdir -p "$backup_dir/$(dirname "$rel")"
    mv "$resolved" "$backup_dir/$rel"
    echo "RETIRED $target (firefly overlay leftover; reinstall or update superpowers to restore the upstream skill)"
  done
}

# Directory-shaped retired asset (firefly-owned skill directories).
process_retired_directory() {
  local mode="$1" home_root="$2" target="$3" hashes="$4"
  [[ -e "$target" || -L "$target" ]] || return 0

  local resolved
  resolved="$(resolve_managed_target "$target")"
  [[ -d "$resolved" ]] || return 0

  local marker="$resolved/SKILL.md"
  [[ -f "$marker" ]] || return 0

  local actual
  actual="$(firefly_sha256_file "$marker")"
  if ! list_contains_hash "$hashes" "$actual"; then
    emit_retired_status "$mode" KEPT "$target" "content differs from firefly 0.1.0"
    return 0
  fi

  if [[ "$mode" == "report" ]]; then
    emit_retired_status "$mode" DRIFT "$target" "retired firefly asset; run firefly repair"
    RETIRED_SAW_DRIFT=1
    return 0
  fi

  local backup_dir
  backup_dir="$(retired_backup_dir "$home_root")/${target##*/}"
  mkdir -p "$(dirname "$backup_dir")"
  mv "$resolved" "$backup_dir"
  echo "📦 RETIRED $target (firefly 0.1.0 asset)"
}

list_contains_hash() {
  local list="$1" want="$2"
  local h old_ifs="$IFS"
  IFS=','
  for h in $list; do
    [[ "$h" == "$want" ]] && { IFS="$old_ifs"; return 0; }
  done
  IFS="$old_ifs"
  return 1
}

# KEPT prints NOTE in report mode (not unhealthy) and KEPT otherwise;
# DRIFT prints in both modes and marks the report unhealthy upstream.
emit_retired_status() {
  local mode="$1" verb="$2" target="$3" reason="$4"
  if [[ "$verb" == "RETIRED" ]]; then
    echo "📦 RETIRED $target ($reason)"
  elif [[ "$verb" == "KEPT" ]]; then
    if [[ "$mode" == "report" ]]; then
      echo "📝 NOTE   $target (not firefly-managed; left untouched)"
    else
      echo "↩️  KEPT   $target ($reason)"
    fi
  else
    echo "❌ DRIFT  $target ($reason)"
  fi
}

retired_backup_dir() {
  local home_root="$1"
  printf '%s/firefly/retired/%s' "$home_root" "$(date +%Y%m%d-%H%M%S)"
}

#!/usr/bin/env bash
# firefly doctor library.
#
# Sourced by doctor-claude.sh and doctor-codex.sh to share the check flow and
# summary that are identical across platforms. This file only DEFINES
# functions; it must not execute work or set shell options when sourced.
#
# Sourced after firefly-common.sh, which provides the manifest, compare and
# global-command helpers used below.
#
# Globals the sourcing script must provide (exported):
#   PLATFORM_ROOT               platform root (~/.claude or ~/.codex)
#   PLATFORM_ROOT_SUFFIX        expected root suffix (".claude" or ".codex")
#   PLATFORM_NAME               display name ("Claude" or "Codex")
#   OPENSPEC_OVERRIDE_VERSION   upstream openspec version the overrides target
# Plus the firefly-common.sh globals (MANIFEST_PATH, FIREFLY_MANIFEST_HELPER,
# FIREFLY_BIN_DIR, GLOBAL_COMMAND_*).

# Shared doctor entry point. The platform script keeps only its variables,
# usage text and a thin main that forwards here.
doctor_main_flow() {
  local repair_requested="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --repair)
        repair_requested="true"
        shift
        ;;
      *)
        echo "unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  local unhealthy=0
  local healthy=0
  local repaired=0
  local openspec_root
  local kinds=""
  local -x FIREFLY_OPENSPEC_ROOT=""

  echo "🔎 firefly $PLATFORM_NAME doctor"
  validate_root "$PLATFORM_ROOT" "$PLATFORM_ROOT_SUFFIX"
  validate_root "$FIREFLY_BIN_DIR" ""
  require_command node
  firefly_require_sha256
  resolve_global_command
  if [[ "$repair_requested" == "true" ]]; then
    echo "🛠️ Repairing drifted or missing assets"
  fi
  openspec_root="$(resolve_openspec_root)"

  if ! is_valid_openspec_package "$openspec_root"; then
    print_status "MISS" "$openspec_root/package.json"
    log_info "OpenSpec package is missing or invalid at $openspec_root; install @fission-ai/openspec before repairing its overrides."
    unhealthy=1
  elif ! openspec_version_matches "$openspec_root"; then
    actual_version="$(read_openspec_version "$openspec_root")"
    print_status "DRIFT" "$openspec_root/package.json"
    log_info "OpenSpec $actual_version does not match override target $OPENSPEC_OVERRIDE_VERSION; its overrides remain unrepaired to avoid downgrading upstream."
    unhealthy=1
  else
    FIREFLY_OPENSPEC_ROOT="$openspec_root"
    kinds="openspec-override"
  fi

  kinds="${kinds:+$kinds,}skill-directory,command-directory,reference-directory,runtime-script,runtime-command"

  local manifest_lines
  local kind source_path target_path
  manifest_lines="$(firefly_manifest_assets "$kinds")"
  while IFS=$'\t' read -r kind source_path target_path; do
    [[ -n "$kind" ]] || continue

    if compare_path "$source_path" "$target_path"; then
      ((healthy+=1))
      continue
    fi

    if [[ "$repair_requested" == "true" ]]; then
      repair_path "$source_path" "$target_path"
      ((repaired+=1))
      continue
    fi

    unhealthy=1
  done <<< "$manifest_lines"

  if compare_global_command; then
    ((healthy+=1))
  elif [[ "$repair_requested" == "true" ]] && repair_global_command; then
    ((repaired+=1))
  else
    unhealthy=1
  fi

  # Retired 0.1.0 assets: report mode flags matching leftovers as DRIFT and
  # differing content as NOTE (not unhealthy); repair mode moves matching
  # leftovers into the backup directory.
  local sp_root=""
  if [[ "$PLATFORM_NAME" == "Claude" ]]; then
    sp_root="$(discover_superpowers_root)"
  else
    sp_root="${CODEX_HOME:-$HOME/.codex}/superpowers"
    [[ -d "$sp_root" ]] || sp_root=""
  fi
  local retired_mode="report"
  [[ "$repair_requested" == "true" ]] && retired_mode="apply"
  if [[ "$retired_mode" == "apply" ]]; then
    process_retired_assets apply "$MANIFEST_PATH" "$PLATFORM_ROOT" "$sp_root" || true
  else
    if ! process_retired_assets report "$MANIFEST_PATH" "$PLATFORM_ROOT" "$sp_root"; then
      unhealthy=1
    fi
  fi

  echo "📋 Summary"
  echo "💚 Healthy assets: $healthy"
  echo "🛠️ Repaired assets: $repaired"
  if [[ "$unhealthy" -ne 0 ]]; then
    echo "💥 Unhealthy assets detected"
  else
    echo "✨ No drift detected"
  fi

  if [[ "$unhealthy" -ne 0 ]]; then
    if [[ "$repair_requested" == "true" ]]; then
      echo "firefly $PLATFORM_NAME doctor repair incomplete; unresolved managed assets remain" >&2
    else
      echo "firefly $PLATFORM_NAME doctor found missing or drifted managed assets" >&2
    fi
    exit 1
  fi

  if [[ "$repair_requested" == "true" ]]; then
    echo "firefly $PLATFORM_NAME doctor repair complete"
    exit 0
  fi

  echo "firefly $PLATFORM_NAME doctor passed"
}

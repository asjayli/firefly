#!/usr/bin/env bash
# firefly installer library.
#
# Sourced by install-claude.sh and install-codex.sh to share the installer
# steps that are identical across platforms. This file only DEFINES
# functions; it must not execute work or set shell options when sourced.
#
# Sourced after firefly-common.sh, which provides the manifest, sync and
# global-command helpers used below.
#
# Globals the sourcing script must provide (exported):
#   PLATFORM_ROOT               platform root (~/.claude or ~/.codex)
#   PLATFORM_NAME               display name ("Claude" or "Codex")
#   OPENSPEC_OVERRIDE_VERSION   upstream openspec version the overrides target
# Plus the firefly-common.sh globals (MANIFEST_PATH, FIREFLY_MANIFEST_HELPER,
# FIREFLY_BIN_DIR, GLOBAL_COMMAND_*).

# Install the pinned OpenSpec release from npm on every run.
install_openspec() {
  log_step "Installing OpenSpec $OPENSPEC_OVERRIDE_VERSION with npm"
  npm install -g @fission-ai/openspec@1.6.0
  log_success "Installed OpenSpec $OPENSPEC_OVERRIDE_VERSION from npm"
}

# Sync every manifest entry of the comma-separated kinds in $1. Placeholder
# roots are forwarded by firefly_manifest_assets as needed.
sync_manifest_entries() {
  local kinds="$1"
  local manifest_lines
  local kind source_path target_path
  manifest_lines="$(firefly_manifest_assets "$kinds")"
  while IFS=$'\t' read -r kind source_path target_path; do
    [[ -n "$kind" ]] || continue
    sync_path "$source_path" "$target_path"
  done <<< "$manifest_lines"
}

overlay_assets() {
  log_step "Overlaying firefly-managed assets into $PLATFORM_ROOT"

  mkdir -p "$PLATFORM_ROOT/skills"
  sync_manifest_entries "skill-directory,command-directory,reference-directory"

  log_success "Applied firefly-managed $PLATFORM_NAME assets"
}

overlay_runtime_scripts() {
  local runtime_dir="$PLATFORM_ROOT/firefly/bin"
  log_step "Installing firefly runtime scripts into $runtime_dir"
  mkdir -p "$runtime_dir"

  sync_manifest_entries "runtime-script,runtime-command"

  log_success "Installed firefly runtime scripts and command from the manifest"
}

overlay_firefly_home() {
  local home_dir="$PLATFORM_ROOT/firefly"
  log_step "Mirroring firefly source into $home_dir (baseline for global doctor/repair)"

  sync_manifest_entries "source-mirror"

  log_success "Mirrored firefly source baseline"
}

overlay_openspec_assets() {
  local openspec_root
  openspec_root="$(resolve_openspec_root)"

  if [[ ! -d "$openspec_root" ]]; then
    echo "openspec install root not found: $openspec_root" >&2
    return 1
  fi

  if ! is_valid_openspec_package "$openspec_root"; then
    echo "OpenSpec package metadata is missing or invalid: $openspec_root/package.json" >&2
    return 1
  fi

  if ! openspec_version_matches "$openspec_root"; then
    local actual_version
    actual_version="$(read_openspec_version "$openspec_root")"
    log_info "openspec $actual_version detected; firefly openspec override targets $OPENSPEC_OVERRIDE_VERSION."
    log_info "Skipping openspec override to avoid downgrading upstream. Pin openspec to $OPENSPEC_OVERRIDE_VERSION or update firefly's override."
    return 1
  fi

  local -x FIREFLY_OPENSPEC_ROOT="$openspec_root"
  local manifest_lines
  local kind source_path target_path
  manifest_lines="$(firefly_manifest_assets "openspec-override")"
  while IFS=$'\t' read -r kind source_path target_path; do
    [[ -n "$kind" ]] || continue
    sync_path "$source_path" "$target_path"
    log_success "Applied openspec override: $target_path"
  done <<< "$manifest_lines"
}

# Shared installer entry point. The platform script keeps only its variables,
# usage text and a thin main that forwards here.
install_main_flow() {
  local install_incomplete="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      *)
        echo "unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  log_step "firefly $PLATFORM_NAME installer"
  validate_root "$PLATFORM_ROOT" "$PLATFORM_ROOT_SUFFIX"
  require_command cp
  require_command rm
  require_command mkdir
  require_command node
  require_command npm
  firefly_require_sha256
  resolve_global_command
  validate_global_command_target

  install_openspec

  if ! overlay_openspec_assets; then
    install_incomplete="true"
  fi

  overlay_assets
  overlay_firefly_home
  overlay_runtime_scripts
  install_global_command

  # Remove what firefly 0.1.0 left behind (hash-pinned, backed up, never
  # deleted). Claude overlays sat inside the superpowers plugin root; codex
  # inside ~/.codex/superpowers. Both roots are discovered, never required.
  local sp_root=""
  if [[ "$PLATFORM_NAME" == "Claude" ]]; then
    sp_root="$(discover_superpowers_root)"
  else
    sp_root="${CODEX_HOME:-$HOME/.codex}/superpowers"
    [[ -d "$sp_root" ]] || sp_root=""
  fi
  process_retired_assets apply "$MANIFEST_PATH" "$PLATFORM_ROOT" "$sp_root" || true

  if [[ "$install_incomplete" == "true" ]]; then
    echo "firefly $PLATFORM_NAME install incomplete: OpenSpec overrides were not applied" >&2
    exit 1
  fi

  echo "🎉 firefly $PLATFORM_NAME install complete"
}

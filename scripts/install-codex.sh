#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "${BASH_SOURCE[0]}")/firefly-common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/firefly-upstream.sh"
source "$(dirname "${BASH_SOURCE[0]}")/firefly-install.sh"
source "$(dirname "${BASH_SOURCE[0]}")/firefly-retired.sh"
MANIFEST_PATH="${FIREFLY_MANIFEST:-$ROOT_DIR/manifests/codex.json}"
export FIREFLY_MANIFEST_HELPER="$ROOT_DIR/scripts/manifest-assets.mjs"
# The manifest helper expands ~/.claude, ~/.codex and ~/.local/bin targets
# from $HOME when the matching override is unset; refuse early with a clear
# message instead of failing mid-install on an unbound variable.
if [[ -z "${HOME:-}" ]]; then
  echo "HOME is not set; set HOME (or CLAUDE_HOME, CODEX_HOME and FIREFLY_BIN_DIR together) before installing." >&2
  exit 1
fi
CODEX_ROOT="${CODEX_HOME:-$HOME/.codex}"
# Shared-library platform facts consumed by firefly-install.sh.
export PLATFORM_ROOT="$CODEX_ROOT"
export PLATFORM_ROOT_SUFFIX=".codex"
export PLATFORM_NAME="Codex"
FIREFLY_BIN_DIR="${FIREFLY_BIN_DIR:-$HOME/.local/bin}"
export GLOBAL_COMMAND_STATE_PATH="$FIREFLY_BIN_DIR/.firefly-global-command.sha256"
export GLOBAL_COMMAND_SOURCE=""
export GLOBAL_COMMAND_PATH=""
OPENSPEC_ROOT="${OPENSPEC_ROOT:-}"
# firefly's openspec override files are snapshots taken against this upstream
# openspec version. Never overlay them onto a different upstream version —
# that would silently downgrade upstream behavior.
export OPENSPEC_OVERRIDE_VERSION="1.6.0"

usage() {
  cat <<EOF
Install firefly Codex assets.

Usage:
  $(basename "$0") [--help]

Manifest:
  $MANIFEST_PATH

Behavior:
  - verifies the Codex root at $CODEX_ROOT
  - installs OpenSpec $OPENSPEC_OVERRIDE_VERSION on every run
  - overlays firefly-managed openspec customization
  - directly overlays firefly-managed assets into ~/.codex
  - installs firefly-managed reference files into ~/.codex/firefly/references
  - exposes the firefly command at ~/.local/bin/firefly

The managed-asset list comes from the manifest above via manifest-assets.mjs;
this script only adds behavior (version gating, checksum state, backups).
EOF
}

main() {
  install_main_flow "$@"
}

main "$@"

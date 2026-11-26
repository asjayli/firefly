#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$(dirname "${BASH_SOURCE[0]}")/firefly-common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/firefly-upstream.sh"
source "$(dirname "${BASH_SOURCE[0]}")/firefly-doctor.sh"
source "$(dirname "${BASH_SOURCE[0]}")/firefly-retired.sh"
MANIFEST_PATH="${FIREFLY_MANIFEST:-$ROOT_DIR/manifests/claude.json}"
export FIREFLY_MANIFEST_HELPER="$ROOT_DIR/scripts/manifest-assets.mjs"
CLAUDE_ROOT="${CLAUDE_HOME:-$HOME/.claude}"
# Shared-library platform facts consumed by firefly-doctor.sh.
export PLATFORM_ROOT="$CLAUDE_ROOT"
export PLATFORM_ROOT_SUFFIX=".claude"
export PLATFORM_NAME="Claude"
FIREFLY_BIN_DIR="${FIREFLY_BIN_DIR:-$HOME/.local/bin}"
export GLOBAL_COMMAND_STATE_PATH="$FIREFLY_BIN_DIR/.firefly-global-command.sha256"
export GLOBAL_COMMAND_SOURCE=""
export GLOBAL_COMMAND_PATH=""
OPENSPEC_ROOT="${OPENSPEC_ROOT:-}"
# firefly's openspec override files are snapshots taken against this upstream
# openspec version. Repair must not overlay them onto a different upstream
# version — that would silently downgrade upstream behavior.
export OPENSPEC_OVERRIDE_VERSION="1.6.0"

usage() {
  cat <<EOF
Check firefly Claude managed assets.

Usage:
  $(basename "$0") [--help] [--repair]

Manifest:
  $MANIFEST_PATH

Checks:
  - openspec config override
  - firefly-managed Claude skills and commands under ~/.claude
  - firefly-managed reference files under ~/.claude/firefly/references
  - firefly runtime command dispatcher under ~/.claude/firefly/bin
  - global firefly command at ~/.local/bin/firefly
  - content drift against firefly-owned copies

The managed-asset list comes from the manifest above via manifest-assets.mjs.
EOF
}

main() {
  doctor_main_flow "$@"
}

main "$@"

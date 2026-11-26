#!/usr/bin/env bash

set -euo pipefail

# Resolve the global command symlink so helper paths remain runtime-relative.
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_SOURCE" ]]; do
  SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  [[ "$SCRIPT_SOURCE" == /* ]] || SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"

usage() {
  cat <<'EOF'
Usage: firefly <command> [arguments]

Commands:
  validate [--root <project-root>]  Run Chinese-compatible OpenSpec strict validation
  init [arguments]                  Initialize OpenSpec project files
  tasks [arguments]                 List active change tasks
  diagram [arguments]               Generate a firefly design diagram
  doctor                            Check firefly managed assets
  repair                            Repair firefly managed assets
  snapshot                          Print the candidate snapshot of the worktree
  record <subcommand> [options]     Append a row to a handoff carrier (see: record --help)
EOF
}

run_doctor() {
  local claude_runtime_bin="${CLAUDE_HOME:-$HOME/.claude}/firefly/bin"
  local codex_runtime_bin="${CODEX_HOME:-$HOME/.codex}/firefly/bin"

  # Dispatch on the runtime the dispatcher itself lives in: the script
  # directory (after symlink resolution) identifies the platform.
  if [[ "$SCRIPT_DIR" == "$claude_runtime_bin" ]]; then
    if [[ ! -x "$SCRIPT_DIR/doctor-claude.sh" ]]; then
      echo "firefly doctor runtime helper is missing" >&2
      exit 1
    fi
    exec "$SCRIPT_DIR/doctor-claude.sh" "$@"
  fi
  if [[ "$SCRIPT_DIR" == "$codex_runtime_bin" ]]; then
    if [[ ! -x "$SCRIPT_DIR/doctor-codex.sh" ]]; then
      echo "firefly doctor runtime helper is missing" >&2
      exit 1
    fi
    exec "$SCRIPT_DIR/doctor-codex.sh" "$@"
  fi

  # Outside a runtime install (for example straight from the repo's scripts/
  # directory) the platform must be chosen explicitly.
  local platform=""
  local passthrough=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --platform)
        if [[ -z "${2:-}" ]]; then
          echo "--platform requires an argument: claude or codex" >&2
          exit 1
        fi
        platform="$2"
        shift 2
        ;;
      *)
        passthrough+=("$1")
        shift
        ;;
    esac
  done

  case "$platform" in
    claude)
      if [[ ! -x "$SCRIPT_DIR/doctor-claude.sh" ]]; then
        echo "firefly doctor runtime helper is missing" >&2
        exit 1
      fi
      exec "$SCRIPT_DIR/doctor-claude.sh" "${passthrough[@]}"
      ;;
    codex)
      if [[ ! -x "$SCRIPT_DIR/doctor-codex.sh" ]]; then
        echo "firefly doctor runtime helper is missing" >&2
        exit 1
      fi
      exec "$SCRIPT_DIR/doctor-codex.sh" "${passthrough[@]}"
      ;;
    "")
      echo "firefly doctor requires --platform claude or codex when run outside a firefly runtime" >&2
      usage >&2
      exit 1
      ;;
    *)
      echo "unknown platform: $platform (expected claude or codex)" >&2
      exit 1
      ;;
  esac
}

command_name="${1:-help}"
case "$command_name" in
  validate)
    shift
    exec node "$SCRIPT_DIR/validate-openspec-cn.mjs" "$@"
    ;;
  init)
    shift
    exec "$SCRIPT_DIR/bootstrap-project.sh" "$@"
    ;;
  tasks)
    shift
    exec "$SCRIPT_DIR/list-change-tasks.sh" "$@"
    ;;
  diagram)
    shift
    exec "$SCRIPT_DIR/firefly-diagram.sh" "$@"
    ;;
  # The renamed subcommand gets one line pointing at its successor, not the
  # whole usage.
  draw)
    echo "firefly draw is now firefly diagram" >&2
    exit 1
    ;;
  doctor)
    shift
    run_doctor "$@"
    ;;
  repair)
    shift
    run_doctor --repair "$@"
    ;;
  snapshot)
    shift
    exec "$SCRIPT_DIR/firefly-snapshot.sh" "$@"
    ;;
  record)
    shift
    exec "$SCRIPT_DIR/firefly-record.sh" "$@"
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

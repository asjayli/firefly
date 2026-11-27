#!/usr/bin/env bash

set -euo pipefail

# Resolve the global command symlink so helper paths remain runtime-relative.
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_SOURCE" ]]; do
  SCRIPT_DIR="$(cd -L "$(dirname "$SCRIPT_SOURCE")" && pwd -L)"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  [[ "$SCRIPT_SOURCE" == /* ]] || SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -L "$(dirname "$SCRIPT_SOURCE")" && pwd -L)"

usage() {
  cat <<'EOF'
Usage: firefly <command> [arguments]

Commands:
  validate [--root DIR] [--change ID]  Run Chinese-compatible OpenSpec strict validation
  init [arguments]                  Initialize OpenSpec project files
  tasks [arguments]                 List active change tasks
  diagram [arguments]               Generate a firefly design diagram
  doctor [--upstreams]              Check firefly assets or list upstream adaptations
  config [--root PROJECT]            Check project playbooks and resolve model preferences
  repair                            Repair firefly managed assets
  snapshot                          Print the candidate snapshot of the worktree
  record <subcommand> [options]     Append a row to a handoff carrier (see: record --help)
EOF
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
  config)
    shift
    exec node "$SCRIPT_DIR/project-config.mjs" "$SCRIPT_DIR/.." "$@"
    ;;
  doctor)
    shift
    if [[ $# == 1 && "$1" == --upstreams ]]; then
      PACKAGE_DIR="$(cd -L "$SCRIPT_DIR/.." && pwd -L)"
      exec cat "$PACKAGE_DIR/references/upstreams.json"
    fi
    bash "$SCRIPT_DIR/manage.sh" doctor "$@"
    if [[ -e .firefly || -L .firefly ]]; then
      node "$SCRIPT_DIR/project-config.mjs" "$SCRIPT_DIR/.." >/dev/null
    fi
    ;;
  repair)
    shift
    exec bash "$SCRIPT_DIR/manage.sh" "$command_name" "$@"
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

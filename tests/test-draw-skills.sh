#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_file_contains() {
  local path="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$path"; then
    echo "expected $path to contain: $needle" >&2
    exit 1
  fi
}

path="$ROOT_DIR/firefly/references/abilities/mermaid-diagram-specialist/guide.md"
  assert_file_contains "$path" "Write notes in Chinese so readers can understand each key"
  assert_file_contains "$path" "What to annotate**: key business actions, critical intermediate steps,"
  assert_file_contains "$path" "Keep the diagram readable: annotate enough to explain the"
  assert_file_contains "$path" "flow, but do not attach a note to every arrow."
  assert_file_contains "$path" "Key methods and critical steps annotated with concise Chinese \`Note\`"
  assert_file_contains "$path" "without making the diagram bloated"

# v2 firefly-draw settles behavior; rendering belongs to the controller command
# `firefly diagram` (phase 8 registers it). The skill text points there and
# carries none of the retired rendering machinery.
path="$ROOT_DIR/firefly/references/abilities/firefly-draw/guide.md"
  assert_file_contains "$path" "firefly diagram"
  for retired in "firefly-draw.sh" "mmdc" ".svg"; do
    if grep -Fq "$retired" "$path"; then
      echo "expected $path to no longer name the retired rendering token: $retired" >&2
      exit 1
    fi
  done

echo "draw skill docs test passed"

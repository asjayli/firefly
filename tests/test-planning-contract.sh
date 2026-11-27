#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Pins the planning contract introduced in task group 3 on both rendered
# platforms: the think skill must carry the greenfield completeness matrix,
# the read-only memory policy, and the Context Provenance section in its output
# template; the propose skill must carry forward provenance and the read-only
# memory policy.

assert_contains() {
  local path="$1"
  local needle="$2"
  [[ -f "$path" ]] || { echo "missing file: $path" >&2; exit 1; }
  grep -qF "$needle" "$path" || {
    echo "expected [$needle] in $path" >&2
    exit 1
  }
}

{
  think="$ROOT_DIR/firefly/references/abilities/firefly-think/guide.md"
  propose="$ROOT_DIR/firefly/references/abilities/firefly-propose/guide.md"

  # Requirement completeness matrix (greenfield).
  assert_contains "$think" "Check requirement completeness"
  assert_contains "$think" "Target platform"
  assert_contains "$think" "Data model"

  # Read-only memory policy (v2 states it platform-neutrally: the memory
  # directories the host keeps under the project root, never written back).
  assert_contains "$think" "Read project memory"
  assert_contains "$think" "Do not write memory back"
  assert_contains "$think" "memory directories the host keeps under the project root"

  # Context Provenance section in the think output template.
  assert_contains "$think" "Context Provenance"
  assert_contains "$think" "Why Applicable"

  # Propose carries forward provenance and the read-only policy.
  assert_contains "$propose" "Context Provenance"
  assert_contains "$propose" "Read project memory read-only"

  # Group 4: producer self-critique (7 items) before review.
  openspec_propose="$ROOT_DIR/firefly/references/abilities/openspec-propose/guide.md"

  # firefly-propose runs the 7-item producer self-critique before its reviewer.
  assert_contains "$propose" "producer self-critique"
  assert_contains "$propose" "falsifiable"
  assert_contains "$propose" "acyclic"
  assert_contains "$propose" "user-authorized scope"

  assert_contains "$openspec_propose" "Return after scaffolding so the caller can record the mandate"
  assert_contains "$openspec_propose" "The planning handoff owns `tasks.md`"

}

echo "planning contract test passed"

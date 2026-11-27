#!/usr/bin/env bash
# Shared helpers for the tests added with the 2.0 skill layout: skill
# contracts, runtime scripts, upgrades and acceptance cases.
#
# Source it after `set -euo pipefail`. It defines functions only and does not
# change shell options, so the sourcing test keeps control of `set -e` and of
# process exit behavior. The older tests keep their own inline helpers and do
# not source this file.

# Temporary directories created through new_tmp_dir, removed when the test exits.
_FIREFLY_TEST_TMP_DIRS=()

_firefly_test_cleanup() {
  local dir
  for dir in ${_FIREFLY_TEST_TMP_DIRS[@]+"${_FIREFLY_TEST_TMP_DIRS[@]}"}; do
    rm -rf "$dir"
  done
}

# Create a new unique temporary directory, named after the optional label,
# and store its path in FIREFLY_TMP_DIR. Every directory created this way is
# removed when the test exits. It sets a variable rather than printing, so it
# must be called in the test's own shell: called inside "$( ... )" the trap
# would be armed in a subshell and never run.
new_tmp_dir() {
  local label="${1:-tmp}"
  local dir
  dir="$(mktemp -d "${TMPDIR:-/tmp}/firefly-test-${label}.XXXXXX")"
  _FIREFLY_TEST_TMP_DIRS+=("$dir")
  trap '_firefly_test_cleanup' EXIT
  # Read by the calling test, which is why the linter cannot see a use here.
  # shellcheck disable=SC2034
  FIREFLY_TMP_DIR="$dir"
}

# Exit 1 when the file $1 does not contain the fixed string $2.
assert_contains() {
  local file="$1"
  local needle="$2"
  if [[ "$(cat "$file")" != *"$needle"* ]]; then
    echo "FAIL: expected $file to contain: $needle" >&2
    exit 1
  fi
}

# Exit 1 when the file $1 contains the fixed string $2.
assert_not_contains() {
  local file="$1"
  local needle="$2"
  if [[ "$(cat "$file")" == *"$needle"* ]]; then
    echo "FAIL: expected $file not to contain: $needle" >&2
    exit 1
  fi
}

# Exit 1 when the two strings differ.
assert_eq() {
  if [[ "$1" != "$2" ]]; then
    echo "FAIL: values differ" >&2
    echo "  expected: $1" >&2
    echo "  actual:   $2" >&2
    exit 1
  fi
}

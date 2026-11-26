#!/usr/bin/env bash
# manifest-assets.mjs path validation (phase 17, security item 3): every
# managed target must land inside a managed root after expansion, every
# source (and every source-mirror path) must stay inside the repository of
# its manifest, and a structurally broken manifest exits 1.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"
HELPER="$ROOT_DIR/scripts/manifest-assets.mjs"

new_tmp_dir manifest-assets
tmp_dir="$FIREFLY_TMP_DIR"

# run_helper <manifest> [args...] — captures stdout+stderr in HELPER_OUTPUT
# and the exit status in HELPER_STATUS.
run_helper() {
  local status=0
  # shellcheck disable=SC2034
  HELPER_OUTPUT="$(node "$HELPER" "$@" 2>&1)" || status=$?
  # shellcheck disable=SC2034
  HELPER_STATUS="$status"
}

expect_rejected() {
  local label="$1" message="$2"
  if [[ "$HELPER_STATUS" -ne 1 || "$HELPER_OUTPUT" != *"manifest-assets: $message"* ]]; then
    echo "FAIL: $label: exit $HELPER_STATUS, output: $HELPER_OUTPUT" >&2
    exit 1
  fi
  echo "negative: blocked ($label)"
}

fake_repo="$tmp_dir/repo"
mkdir -p "$fake_repo/manifests" "$fake_repo/scripts"

write_manifest() {
  printf '%s\n' "$2" > "$fake_repo/manifests/$1.json"
}

# 1. The real manifest still emits its global command (regression guard for
#    the validation itself).
run_helper "$ROOT_DIR/manifests/claude.json" --kinds global-command
assert_eq 0 "$HELPER_STATUS"
assert_eq 1 "$(printf '%s\n' "$HELPER_OUTPUT" | wc -l)"
if [[ "$HELPER_OUTPUT" != *"global-command"*"$ROOT_DIR/scripts/firefly-global.sh"* ]]; then
  echo "FAIL: global-command line malformed: $HELPER_OUTPUT" >&2
  exit 1
fi
echo "ok real manifest: the global-command entry is emitted as before"

# 2. A placeholder root target passes when the root is provided.
os_root="$tmp_dir/openspec-root"
write_manifest placeholder-ok '{"version":1,"managedAssets":[{"id":"po","kind":"openspec-override","source":"scripts/x.js","target":"<openspec-root>/dist/core/x.js"}]}'
placeholder_status=0
placeholder_output="$(FIREFLY_OPENSPEC_ROOT="$os_root" node "$HELPER" "$fake_repo/manifests/placeholder-ok.json" 2>&1)" || placeholder_status=$?
assert_eq 0 "$placeholder_status"
assert_eq "openspec-override	$fake_repo/scripts/x.js	$os_root/dist/core/x.js" "$placeholder_output"
echo "ok a <openspec-root> target expands and lands inside the provided managed root"

# 3. An absolute target outside every managed root is refused.
write_manifest evil-target '{"version":1,"managedAssets":[{"id":"evil-target","kind":"runtime-script","source":"scripts/x.sh","target":"/etc/firefly-evil"}]}'
run_helper "$fake_repo/manifests/evil-target.json"
expect_rejected "evil-target" "entry evil-target target is outside every managed root: /etc/firefly-evil"

# 4. A relative target is refused: no emit of an unresolved location.
write_manifest relative-target '{"version":1,"managedAssets":[{"id":"rel-target","kind":"runtime-script","source":"scripts/x.sh","target":"relative/x"}]}'
run_helper "$fake_repo/manifests/relative-target.json"
expect_rejected "relative-target" "entry rel-target target is not an absolute path after expansion: relative/x"

# 5. A source with a `..` segment is refused before emit.
write_manifest evil-source '{"version":1,"managedAssets":[{"id":"evil-source","kind":"runtime-script","source":"../outside.sh","target":"~/.claude/x"}]}'
run_helper "$fake_repo/manifests/evil-source.json"
expect_rejected "evil-source" "entry evil-source source escapes the repository root: $tmp_dir/outside.sh"

# 6. A source-mirror path that escapes the repository is refused.
write_manifest evil-mirror '{"version":1,"managedAssets":[{"id":"evil-mirror","kind":"source-mirror","source":"repo root","paths":["../escape"],"target":"~/.claude/firefly"}]}'
run_helper "$fake_repo/manifests/evil-mirror.json"
expect_rejected "evil-mirror" "entry evil-mirror source escapes the repository root: $tmp_dir/escape"

# 7. A structurally broken manifest is refused.
write_manifest broken-structure '{"version":1,"managedAssets":{"not":"an array"}}'
run_helper "$fake_repo/manifests/broken-structure.json"
expect_rejected "broken-structure" "manifest $fake_repo/manifests/broken-structure.json is missing an integer version or a managedAssets array"

# 8. HOME unset: the `~` expansion fails with the variable named.
write_manifest homeless '{"version":1,"managedAssets":[{"id":"t","kind":"runtime-script","source":"scripts/x.sh","target":"~/.claude/x"}]}'
homeless_status=0
homeless_output="$(env -u HOME node "$HELPER" "$fake_repo/manifests/homeless.json" 2>&1)" || homeless_status=$?
assert_eq 1 "$homeless_status"
if [[ "$homeless_output" != *"manifest-assets: HOME is not set"* ]]; then
  echo "FAIL: HOME-unset message unclear: $homeless_output" >&2
  exit 1
fi
echo "negative: blocked (HOME unset names the missing variable)"

echo "manifest assets test passed"

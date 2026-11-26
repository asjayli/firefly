#!/usr/bin/env bash
# Completeness assertions of scripts/sync-platform-assets.mjs --check.
#
# Rendering walks the `shared` array of manifests/platform-assets.json, so a
# hand-edited directory that nobody registered, or a registered entry whose
# source was removed, would otherwise pass unnoticed. This test pins that
# --check reports both, running against a copy of the tree so the real one is
# never touched:
#   1. an untouched copy passes --check;
#   2. an unregistered source directory under assets/shared/skills fails with
#      an UNREGISTERED line;
#   3. a registered entry whose source is gone fails with a MISSING-SOURCE line.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"

SYNC="$ROOT_DIR/scripts/sync-platform-assets.mjs"
MANIFEST="$ROOT_DIR/manifests/platform-assets.json"

[[ -f "$SYNC" ]] || { echo "missing $SYNC" >&2; exit 1; }
[[ -f "$MANIFEST" ]] || { echo "missing $MANIFEST" >&2; exit 1; }

new_tmp_dir shared-completeness
copy="$FIREFLY_TMP_DIR/tree"
out="$FIREFLY_TMP_DIR/out.txt"

# The copy keeps the repository layout so the script, which locates the root
# from its own path, reads the copied manifest and assets.
mkdir -p "$copy"
cp -R "$ROOT_DIR/scripts" "$copy/scripts"
cp -R "$ROOT_DIR/manifests" "$copy/manifests"
mkdir -p "$copy/assets"
cp -R "$ROOT_DIR/assets/shared" "$copy/assets/shared"

# --check also compares the rendered platform copies, so bring over exactly
# the directories that the `shared` array renders to.
for rel in $(node -e 'for (const rel of require(process.argv[1]).shared) console.log(rel)' "$MANIFEST"); do
  for platform in codex claude; do
    mkdir -p "$copy/assets/$platform/$(dirname "$rel")"
    cp -R "$ROOT_DIR/assets/$platform/$rel" "$copy/assets/$platform/$rel"
  done
done

run_check() {
  set +e
  node "$copy/scripts/sync-platform-assets.mjs" --check >"$out" 2>&1
  status=$?
  set -e
  return "$status"
}

# 1. An untouched copy passes.
run_check
assert_contains "$out" "Platform assets in sync"
echo "completeness: clean copy passes"

# 2. A source directory that the `shared` array does not list is reported.
mkdir -p "$copy/assets/shared/skills/zz-unregistered"
printf -- '---\nname: zz-unregistered\ndescription: never registered\n---\n' > "$copy/assets/shared/skills/zz-unregistered/SKILL.md"
if run_check; then
  echo "FAIL: --check accepted an unregistered shared directory" >&2
  exit 1
fi
assert_contains "$out" "UNREGISTERED assets/shared/skills/zz-unregistered"
assert_contains "$out" "Platform assets out of sync"
echo "negative: blocked (UNREGISTERED)"

# 3. A registered entry whose source directory is gone is reported.
rm -rf "$copy/assets/shared/skills/zz-unregistered"
mv "$copy/assets/shared/references" "$copy/assets/shared/references.moved"
if run_check; then
  echo "FAIL: --check accepted a registered entry without a source" >&2
  exit 1
fi
assert_contains "$out" "MISSING-SOURCE assets/shared/references"
echo "negative: blocked (MISSING-SOURCE)"

# 4. Restoring the source makes the copy clean again.
mv "$copy/assets/shared/references.moved" "$copy/assets/shared/references"
run_check
assert_contains "$out" "Platform assets in sync"
echo "completeness: restored copy passes"

echo "shared completeness test passed"

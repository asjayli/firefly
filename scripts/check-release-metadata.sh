#!/usr/bin/env bash

# Validates firefly release metadata consistency:
#   - VERSION is a well-formed semantic version.
#   - Both platform manifests expose the same fireflyVersion as VERSION.
#   - README.md / README_EN.md display the current version.
#   - CHANGELOG.md documents the current version.
#   - LICENSE is present and identifies MIT.
#   - THIRD_PARTY_NOTICES.md declares every vendored/override upstream
#     (playwright-interactive, OpenSpec, superpowers), and the vendored
#     playwright-interactive LICENSE.txt/NOTICE.txt are retained.
#   - The OpenSpec override target version still matches the pinned OpenSpec
#     version in each manifest.
#
# Dependency-light on purpose (bash + grep + sed): it runs in CI-like
# environments before any toolchain is guaranteed.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

failures=0

fail() {
  echo "FAIL: $1" >&2
  failures=$((failures + 1))
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: ${1#"$ROOT_DIR"/}"
}

require_contains() {
  local path="$1"
  local needle="$2"
  local label="$3"
  grep -Fq -- "$needle" "$path" || fail "expected $label to contain: $needle"
}

# Extracts the first JSON string value for a field name (no JSON parser needed).
json_string_field() {
  local path="$1"
  local field="$2"
  sed -n "s/.*\"$field\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$path" | head -n 1
}

# 1. Required metadata files exist.
require_file "$ROOT_DIR/VERSION"
require_file "$ROOT_DIR/CHANGELOG.md"
require_file "$ROOT_DIR/LICENSE"
require_file "$ROOT_DIR/THIRD_PARTY_NOTICES.md"
require_file "$ROOT_DIR/manifests/codex.json"
require_file "$ROOT_DIR/manifests/claude.json"
require_file "$ROOT_DIR/README.md"
require_file "$ROOT_DIR/README_EN.md"

if [[ "$failures" -gt 0 ]]; then
  echo "release metadata check failed: $failures problem(s)" >&2
  exit 1
fi

# 2. VERSION is a well-formed semantic version on a single line.
version="$(cat "$ROOT_DIR/VERSION")"
if [[ "$(wc -l < "$ROOT_DIR/VERSION")" -ne 1 ]]; then
  fail "VERSION must contain exactly one line"
fi
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$ ]]; then
  fail "VERSION is not a valid semantic version: $version"
fi

# 3. Both manifests expose fireflyVersion equal to VERSION.
codex_version="$(json_string_field "$ROOT_DIR/manifests/codex.json" fireflyVersion)"
claude_version="$(json_string_field "$ROOT_DIR/manifests/claude.json" fireflyVersion)"
[[ "$codex_version" == "$version" ]] \
  || fail "manifests/codex.json fireflyVersion is '$codex_version', expected '$version'"
[[ "$claude_version" == "$version" ]] \
  || fail "manifests/claude.json fireflyVersion is '$claude_version', expected '$version'"

# 4. READMEs display the current version.
require_contains "$ROOT_DIR/README.md" "$version" "README.md"
require_contains "$ROOT_DIR/README_EN.md" "$version" "README_EN.md"

# 5. CHANGELOG documents the current version.
require_contains "$ROOT_DIR/CHANGELOG.md" "[$version]" "CHANGELOG.md"

# 6. LICENSE identifies MIT.
require_contains "$ROOT_DIR/LICENSE" "MIT License" "LICENSE"
require_contains "$ROOT_DIR/LICENSE" "Permission is hereby granted" "LICENSE"

# 7. Every vendored/override third-party component is declared.
for component in "playwright-interactive" "OpenSpec" "superpowers" "Microsoft"; do
  require_contains "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$component" "THIRD_PARTY_NOTICES.md"
done

# 8. The vendored playwright-interactive license files are retained on every
#    platform. Platforms are whatever <name>.json lives in manifests/ besides
#    the asset-sync manifest, so a new platform joins without editing this
#    loop.
for manifest_path in "$ROOT_DIR"/manifests/*.json; do
  platform="$(basename "$manifest_path" .json)"
  [[ "$platform" == "platform-assets" ]] && continue
  require_file "$ROOT_DIR/assets/$platform/skills/playwright-interactive/LICENSE.txt"
  require_file "$ROOT_DIR/assets/$platform/skills/playwright-interactive/NOTICE.txt"
done

# 9. OpenSpec override target version still matches the pinned OpenSpec version.
for manifest_path in "$ROOT_DIR"/manifests/*.json; do
  platform="$(basename "$manifest_path" .json)"
  [[ "$platform" == "platform-assets" ]] && continue
  manifest="$ROOT_DIR/manifests/$platform.json"
  pinned="$(json_string_field "$manifest" version)"
  override="$(json_string_field "$manifest" overrideTargetVersion)"
  [[ -n "$pinned" && -n "$override" ]] \
    || fail "manifests/$platform.json is missing an OpenSpec version or overrideTargetVersion"
  [[ "$pinned" == "$override" ]] \
    || fail "manifests/$platform.json OpenSpec override targets '$override' but pins '$pinned'"
done

# 10. retiredAssets structure is valid and the entry ids match across manifests.
for manifest_path in "$ROOT_DIR"/manifests/*.json; do
  platform="$(basename "$manifest_path" .json)"
  [[ "$platform" == "platform-assets" ]] && continue
  node -e '
    const fs = require("fs");
    const m = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    const retired = m.retiredAssets || [];
    for (const e of retired) {
      const w = "retiredAssets entry " + JSON.stringify(e && e.id) + " in " + process.argv[1];
      if (!e || typeof e.id !== "string" || typeof e.since !== "string" || typeof e.handling !== "string" || typeof e.target !== "string") {
        console.error(w + " is missing a string id/since/handling/target"); process.exit(1); }
      if (e.handling !== "remove-with-backup" && e.handling !== "overlay-leftover") {
        console.error(w + " has an unknown handling: " + e.handling); process.exit(1); }
      if (!Array.isArray(e.files) || e.files.length === 0) {
        console.error(w + " needs a non-empty files array"); process.exit(1); }
      for (const f of e.files) {
        if (!f || typeof f.path !== "string" || !Array.isArray(f.sha256) || f.sha256.length === 0) {
          console.error(w + " has a file entry without a string path or a non-empty sha256 array"); process.exit(1); }
        for (const h of f.sha256) if (!/^[0-9a-f]{64}$/.test(h)) {
          console.error(w + " has a malformed sha256: " + h); process.exit(1); }
      }
    }
  ' "$manifest_path" || fail "manifests/$platform.json retiredAssets structure is invalid"
done

claude_ids="$(node -e 'const m=require(process.argv[1]); process.stdout.write((m.retiredAssets||[]).map(e=>e.id).sort().join(" "))' "$ROOT_DIR/manifests/claude.json")"
codex_ids="$(node -e 'const m=require(process.argv[1]); process.stdout.write((m.retiredAssets||[]).map(e=>e.id).sort().join(" "))' "$ROOT_DIR/manifests/codex.json")"
[[ "$claude_ids" == "$codex_ids" ]] || fail "retiredAssets entry ids differ between manifests/claude.json and manifests/codex.json"

if [[ "$failures" -gt 0 ]]; then
  echo "release metadata check failed: $failures problem(s)" >&2
  exit 1
fi

echo "release metadata check passed (version $version)"

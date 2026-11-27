#!/usr/bin/env bash
# Check the version and license files shipped with the standalone skill.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
version="$(<"$root/VERSION")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "invalid VERSION: $version" >&2; exit 1; }
grep -qF "[${version}]" "$root/CHANGELOG.md"
grep -qF "当前版本：${version}" "$root/README.md"
grep -qF "Current version: ${version}" "$root/README_EN.md"
grep -qF 'MIT License' "$root/LICENSE"
cmp "$root/LICENSE" "$root/firefly/LICENSE"
test -s "$root/THIRD_PARTY_NOTICES.md"
printf 'release metadata check passed (version %s)\n' "$version"

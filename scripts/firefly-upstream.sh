#!/usr/bin/env bash
# firefly-upstream.sh — upstream resolution shared by the platform scripts.
#
# OpenSpec root resolution and version checks moved here from
# firefly-common.sh (function names unchanged). The superpowers leftover
# root discovery only locates; it never fails when nothing is found.

resolve_openspec_root() {
  if [[ -n "$OPENSPEC_ROOT" ]]; then
    validate_root "$OPENSPEC_ROOT" ""
    echo "$OPENSPEC_ROOT"
    return
  fi

  local npm_global_root
  npm_global_root="$(npm root -g)"
  local resolved="$npm_global_root/@fission-ai/openspec"
  validate_root "$resolved" "@fission-ai/openspec"
  echo "$resolved"
}

read_openspec_version() {
  local openspec_root="$1"
  local pkg="$openspec_root/package.json"
  [[ -f "$pkg" ]] || return 0
  node -e 'const p=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); process.stdout.write(p.version||"")' "$pkg" 2>/dev/null
}

is_valid_openspec_package() {
  local openspec_root="$1"
  local pkg="$openspec_root/package.json"

  [[ -f "$pkg" ]] || return 1
  node -e 'const p=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")); process.exit(p.name === "@fission-ai/openspec" ? 0 : 1)' "$pkg" 2>/dev/null
}

openspec_version_matches() {
  local openspec_root="$1"
  local ver

  is_valid_openspec_package "$openspec_root" || return 1
  ver="$(read_openspec_version "$openspec_root")"
  [[ "$ver" == "$OPENSPEC_OVERRIDE_VERSION" ]]
}

# Discover the Claude superpowers plugin root a 0.1.0 installation would have
# overlaid into. Locate only: prints the root when found, prints nothing and
# returns 0 when not. Never fails.
discover_superpowers_root() {
  local plugins_file="$CLAUDE_HOME/plugins/installed_plugins.json"
  [[ -f "$plugins_file" ]] || return 0

  local install_path
  install_path="$(node -e '
    const fs = require("fs");
    try {
      const doc = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
      const entry = (doc.plugins && doc.plugins["superpowers@superpowers-marketplace"]) || [];
      const scoped = entry.find((e) => e && typeof e.installPath === "string");
      if (scoped) process.stdout.write(scoped.installPath);
    } catch (_) {}
  ' "$plugins_file" 2>/dev/null)"
  [[ -n "$install_path" ]] || return 0
  [[ -d "$install_path" ]] || return 0
  printf '%s\n' "$install_path"
}

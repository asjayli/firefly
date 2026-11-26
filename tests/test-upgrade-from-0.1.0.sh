#!/usr/bin/env bash
# Six scenarios for removing what firefly 0.1.0 left behind, on both
# platforms. Hashes in the test manifest are generated from the fixtures
# themselves, so the semantics under test are exactly the pinned-hash ones.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$ROOT_DIR/scripts"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# sha256 of a file, hex, via the same helper the runtime uses.
hash_of() {
  node -e 'const c=require("crypto"),f=require("fs");process.stdout.write(c.createHash("sha256").update(f.readFileSync(process.argv[1])).digest("hex"))' "$1"
}

# Build a test manifest from the real one: keep everything, replace the
# retiredAssets hashes with hashes of this test's own fixtures.
run_platform() {
  local platform="$1"
  local home="$tmp_dir/$platform-home"
  local home_dir="$home/.$platform"
  mkdir -p "$home_dir"

  # Fixtures: a 0.1.0 firefly-doctor directory and an upstream
  # superpowers directory carrying overlay leftovers.
  local sp_root="$home_dir/superpowers"
  mkdir -p "$home_dir/skills/firefly-doctor" "$sp_root/skills/subagent-driven-development/scripts"
  printf 'doctor-010\n' > "$home_dir/skills/firefly-doctor/SKILL.md"
  printf 'sdd-010\n' > "$sp_root/skills/subagent-driven-development/SKILL.md"
  printf 'prompt-010\n' > "$sp_root/skills/subagent-driven-development/implementer-prompt.md"
  printf 'unlisted-upstream\n' > "$sp_root/skills/subagent-driven-development/scripts/upstream-only.sh"

  # The test manifest pins this run's hashes.
  local manifest="$tmp_dir/$platform-manifest.json"
  node -e '
    const fs = require("fs"), crypto = require("crypto");
    const [platform, out, home, spRoot] = process.argv.slice(1);
    const sha = (p) => crypto.createHash("sha256").update(fs.readFileSync(p)).digest("hex");
    const m = JSON.parse(fs.readFileSync(`manifests/${platform}.json`, "utf8"));
    const homeDir = `${home}/.${platform}`;
    const find = (id) => m.retiredAssets.find((e) => e.id === id);
    find("firefly-doctor-dir").files[0].sha256 = [sha(`${homeDir}/skills/firefly-doctor/SKILL.md`)];
    const sdd = find("subagent-driven-development-overlay");
    sdd.files = sdd.files.filter((f) =>
      f.path === "SKILL.md" || f.path === "implementer-prompt.md");
    sdd.files.forEach((f) => {
      const p = `${spRoot}/skills/subagent-driven-development/${f.path}`;
      f.sha256 = [sha(p)];
    });
    m.retiredAssets = m.retiredAssets.filter((e) =>
      e.id === "firefly-doctor-dir" || e.id === "subagent-driven-development-overlay");
    fs.writeFileSync(out, JSON.stringify(m, null, 2));
  ' "$platform" "$manifest" "$home" "$sp_root"

  local -a run_env=(env CODEX_HOME="$home_dir" CLAUDE_HOME="$home_dir" FIREFLY_MANIFEST_HELPER="$SCRIPTS/manifest-assets.mjs" bash -c)
  local lib_setup='set -euo pipefail; cd "'$SCRIPTS'"; source ./firefly-common.sh; source ./firefly-upstream.sh; source ./firefly-retired.sh'
  # shellcheck disable=SC2016
  local apply_cmd='process_retired_assets apply "$1" "$2" "$3"'
  # shellcheck disable=SC2016
  local report_cmd='process_retired_assets report "$1" "$2" "$3" || exit 9'

  ### Scenario 1: matching firefly directory is retired into the backup.
  out="$("${run_env[@]}" "$lib_setup; $apply_cmd" x "$manifest" "$home_dir" "$sp_root")"
  grep -q "RETIRED .*firefly-doctor .firefly 0.1.0 asset" <<<"$out"
  [[ ! -e "$home_dir/skills/firefly-doctor" ]]
  local backup;
  backup="$(find "$home_dir/firefly/retired" -type d -name firefly-doctor)"
  cmp <(printf 'doctor-010\n') "$backup/SKILL.md"
  echo "ok $platform scenario 1: matching directory retired with identical backup"

  ### Scenario 2: differing content is kept; doctor reports NOTE, exit 0.
  mkdir -p "$home_dir/skills/firefly-doctor"
  printf 'user-modified\n' > "$home_dir/skills/firefly-doctor/SKILL.md"
  out="$("${run_env[@]}" "$lib_setup; $apply_cmd" x "$manifest" "$home_dir" "$sp_root")"
  grep -q "KEPT .*firefly-doctor .content differs" <<<"$out"
  [[ -f "$home_dir/skills/firefly-doctor/SKILL.md" ]]
  "${run_env[@]}" "$lib_setup; $report_cmd" x "$manifest" "$home_dir" "$sp_root" >/dev/null
  echo "ok $platform scenario 2: differing content kept, NOTE reported, report exits 0"

  ### Scenario 3: a user symlink survives; the resolved directory is retired.
  rm -rf "$home_dir/skills/firefly-doctor"
  mkdir -p "$home/elsewhere/firefly-doctor"
  printf 'doctor-010\n' > "$home/elsewhere/firefly-doctor/SKILL.md"
  ln -s "$home/elsewhere/firefly-doctor" "$home_dir/skills/firefly-doctor"
  local before_link
  before_link="$(readlink "$home_dir/skills/firefly-doctor")"
  out="$("${run_env[@]}" "$lib_setup; $apply_cmd" x "$manifest" "$home_dir" "$sp_root")"
  [[ -L "$home_dir/skills/firefly-doctor" ]]
  [[ "$(readlink "$home_dir/skills/firefly-doctor")" == "$before_link" ]]
  [[ ! -e "$home/elsewhere/firefly-doctor/SKILL.md" ]]
  echo "ok $platform scenario 3: symlink kept and points unchanged, resolved directory retired"
  rm "$home_dir/skills/firefly-doctor"

  ### Scenario 4a: overlay leftovers all matching are retired together;
  ### an unlisted upstream file is untouched.
  printf 'sdd-010\n' > "$sp_root/skills/subagent-driven-development/SKILL.md"
  printf 'prompt-010\n' > "$sp_root/skills/subagent-driven-development/implementer-prompt.md"
  out="$("${run_env[@]}" "$lib_setup; $apply_cmd" x "$manifest" "$home_dir" "$sp_root")"
  grep -q "RETIRED .*subagent-driven-development/SKILL.md .firefly overlay leftover" <<<"$out"
  [[ ! -e "$sp_root/skills/subagent-driven-development/SKILL.md" ]]
  [[ ! -e "$sp_root/skills/subagent-driven-development/implementer-prompt.md" ]]
  cmp <(printf 'unlisted-upstream\n') "$sp_root/skills/subagent-driven-development/scripts/upstream-only.sh"
  echo "ok $platform scenario 4a: matching leftovers retired together, unlisted file untouched"

  ### Scenario 4b: one matching, one differing -> everything kept.
  printf 'sdd-010\n' > "$sp_root/skills/subagent-driven-development/SKILL.md"
  printf 'user-rewrote-this\n' > "$sp_root/skills/subagent-driven-development/implementer-prompt.md"
  out="$("${run_env[@]}" "$lib_setup; $apply_cmd" x "$manifest" "$home_dir" "$sp_root")"
  grep -q "KEPT .*subagent-driven-development .mixed content" <<<"$out"
  [[ -f "$sp_root/skills/subagent-driven-development/SKILL.md" ]]
  [[ -f "$sp_root/skills/subagent-driven-development/implementer-prompt.md" ]]
  echo "ok $platform scenario 4b: mixed content keeps everything"

  ### Scenario 5: doctor flags a restored leftover as DRIFT (exit 9 mapping),
  ### repair moves it, doctor exits clean again.
  printf 'sdd-010\n' > "$sp_root/skills/subagent-driven-development/SKILL.md"
  printf 'prompt-010\n' > "$sp_root/skills/subagent-driven-development/implementer-prompt.md"
  set +e
  "${run_env[@]}" "$lib_setup; $report_cmd" x "$manifest" "$home_dir" "$sp_root" >"$tmp_dir/$platform-report.log" 2>&1
  local report_status=$?
  set -e
  [[ "$report_status" == "9" ]]
  grep -q "DRIFT .*subagent-driven-development .retired firefly asset; run firefly repair" "$tmp_dir/$platform-report.log"
  "${run_env[@]}" "$lib_setup; $apply_cmd" x "$manifest" "$home_dir" "$sp_root" >/dev/null
  [[ ! -e "$sp_root/skills/subagent-driven-development/SKILL.md" ]]
  "${run_env[@]}" "$lib_setup; $report_cmd" x "$manifest" "$home_dir" "$sp_root" >/dev/null
  echo "ok $platform scenario 5: DRIFT reported, repair retires, report clean"

  ### Scenario 6: the real manifest leaves random content untouched.
  printf 'random\n' > "$sp_root/skills/subagent-driven-development/SKILL.md"
  printf 'random\n' > "$sp_root/skills/subagent-driven-development/implementer-prompt.md"
  local real_manifest="$ROOT_DIR/manifests/$platform.json"
  out="$("${run_env[@]}" "$lib_setup; $apply_cmd" x "$real_manifest" "$home_dir" "$sp_root")"
  grep -q "KEPT .*subagent-driven-development .mixed content" <<<"$out"
  [[ -f "$sp_root/skills/subagent-driven-development/SKILL.md" ]]
  echo "ok $platform scenario 6: real manifest keeps random content"
}

for platform in codex claude; do
  run_platform "$platform"
done

echo "upgrade from 0.1.0 test passed"

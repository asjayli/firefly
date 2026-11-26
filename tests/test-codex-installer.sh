#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALLER="$ROOT_DIR/scripts/install-codex.sh"
DOCTOR="$ROOT_DIR/scripts/doctor-codex.sh"
MANIFEST="$ROOT_DIR/manifests/codex.json"

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    echo "expected output to contain: $needle" >&2
    exit 1
  fi
}

test_file_exists() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "expected file to exist: $path" >&2
    exit 1
  fi
}

test_file_executable() {
  local path="$1"
  if [[ ! -x "$path" ]]; then
    echo "expected file to be executable: $path" >&2
    exit 1
  fi
}

test_path_not_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    echo "expected path to not exist: $path" >&2
    exit 1
  fi
}

test_symbolic_link() {
  local path="$1"
  if [[ ! -L "$path" ]]; then
    echo "expected symbolic link to exist: $path" >&2
    exit 1
  fi
}

assert_link_target() {
  local path="$1"
  local expected="$2"
  local actual

  actual="$(readlink "$path")"
  if [[ "$actual" != "$expected" ]]; then
    echo "expected symbolic link target $expected but got $actual" >&2
    exit 1
  fi
}

assert_paths_equal() {
  local expected="$1"
  local actual="$2"

  if ! diff -qr "$expected" "$actual" >/dev/null; then
    echo "expected installed source mirror to match: $expected $actual" >&2
    diff -qr "$expected" "$actual" >&2 || true
    exit 1
  fi
}

assert_exit_code() {
  local actual="$1"
  local expected="$2"
  if [[ "$actual" != "$expected" ]]; then
    echo "expected exit code $expected but got $actual" >&2
    exit 1
  fi
}

test_file_exists "$MANIFEST"
test_file_exists "$INSTALLER"
test_file_exists "$DOCTOR"

manifest_skill_sources="$(node -e 'const m=require(process.argv[1]); console.log(m.managedAssets.filter(a => a.kind === "skill-directory" && a.source.startsWith("assets/codex/skills/")).map(a => a.source).sort().join("\n"))' "$MANIFEST")"
scanned_skill_sources="$(find "$ROOT_DIR/assets/codex/skills" -mindepth 1 -maxdepth 1 -type d -printf 'assets/codex/skills/%f\n' | sort)"
if [[ "$manifest_skill_sources" != "$scanned_skill_sources" ]]; then
  echo "Codex manifest skill assets do not match assets/codex/skills" >&2
  diff <(printf '%s\n' "$manifest_skill_sources") <(printf '%s\n' "$scanned_skill_sources") | head -20 >&2
  locale >&2 | head -5
  exit 1
fi

assert_contains "$(<"$MANIFEST")" '"version": "1.6.0"'
assert_contains "$(<"$MANIFEST")" '"overrideTargetVersion": "1.6.0"'
assert_contains "$(<"$MANIFEST")" '"source": "repo root (assets, scripts, manifests)"'
assert_contains "$(<"$ROOT_DIR/scripts/firefly-install.sh")" 'npm install -g @fission-ai/openspec@1.6.0'

installer_help="$("$INSTALLER" --help)"
doctor_help="$("$DOCTOR" --help)"

assert_contains "$installer_help" "Install firefly Codex assets"
assert_contains "$installer_help" "$MANIFEST"
assert_contains "$doctor_help" "Check firefly Codex managed assets"
assert_contains "$doctor_help" "$MANIFEST"
assert_contains "$doctor_help" "--repair"
assert_contains "$doctor_help" "firefly runtime command dispatcher"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

export CODEX_HOME="$tmp_dir/.codex"
export FIREFLY_BIN_DIR="$tmp_dir/.local/bin"
export OPENSPEC_ROOT="$tmp_dir/openspec"
bin_dir="$tmp_dir/bin"
npm_log="$tmp_dir/npm.log"
export FAKE_NPM_ROOT="$tmp_dir/npm-global"
export FAKE_NPM_LOG="$npm_log"
mkdir -p "$bin_dir"
cat > "$bin_dir/npm" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  install)
    printf '%s\n' "$*" >> "$FAKE_NPM_LOG"
    ;;
  root)
    printf '%s\n' "$FAKE_NPM_ROOT"
    ;;
  *)
    exit 1
    ;;
esac
EOF
chmod +x "$bin_dir/npm"
export PATH="$bin_dir:$PATH"

set +e
deprecated_flag_output="$("$INSTALLER" --install-openspec 2>&1)"
deprecated_flag_status=$?
set -e
assert_exit_code "$deprecated_flag_status" "1"
assert_contains "$deprecated_flag_output" "unknown argument: --install-openspec"

mkdir -p "$OPENSPEC_ROOT/dist/core"
mkdir -p "$OPENSPEC_ROOT/dist/core/templates/workflows"
printf '{"name":"@fission-ai/openspec","version":"1.6.0"}\n' > "$OPENSPEC_ROOT/package.json"
printf 'export function serializeConfig() { return \"wrong\"; }\n' > "$OPENSPEC_ROOT/dist/core/config-prompts.js"
printf 'export const propose = \"wrong\";\n' > "$OPENSPEC_ROOT/dist/core/templates/workflows/propose.js"

mkdir -p "$FIREFLY_BIN_DIR"
printf '#!/usr/bin/env bash\n# firefly global command shim\necho user-command\n' > "$FIREFLY_BIN_DIR/firefly"
chmod +x "$FIREFLY_BIN_DIR/firefly"

set +e
command_collision_output="$("$INSTALLER" 2>&1)"
command_collision_status=$?
set -e
assert_exit_code "$command_collision_status" "1"
assert_contains "$command_collision_output" "refusing to replace existing command: $FIREFLY_BIN_DIR/firefly"
rm "$FIREFLY_BIN_DIR/firefly"

# No upstream superpowers directory exists in this fake HOME; the install
# must still succeed and lay out the full managed asset set.
installer_output="$("$INSTALLER")"
assert_contains "$installer_output" "🧱 firefly Codex installer"
assert_contains "$installer_output" "✅ Applied openspec override"
assert_contains "$installer_output" "✅ Applied firefly-managed Codex assets"
assert_contains "$installer_output" "💾 Backed up"
assert_contains "$installer_output" "🎉 firefly Codex install complete"
assert_contains "$(cat "$npm_log")" "install -g @fission-ai/openspec@1.6.0"

for mirror_path in assets scripts manifests; do
  assert_paths_equal "$ROOT_DIR/$mirror_path" "$CODEX_HOME/firefly/$mirror_path"
done

test_path_not_exists "$OPENSPEC_ROOT/dist/core/config-prompts.js.firefly.bak"
test_path_not_exists "$OPENSPEC_ROOT/dist/core/templates/workflows/propose.js.firefly.bak"
test_file_exists "$CODEX_HOME/skills/mermaid-diagram-specialist/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-init/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-repair/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-implement/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-archive/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-tasks/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-think/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-propose/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-review/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-verify-web/SKILL.md"
test_file_exists "$CODEX_HOME/skills/firefly-draw/SKILL.md"
test_file_exists "$CODEX_HOME/skills/openspec-propose/SKILL.md"
test_file_exists "$CODEX_HOME/skills/openspec-apply-change/SKILL.md"
test_file_exists "$CODEX_HOME/skills/openspec-archive-change/SKILL.md"
test_file_exists "$CODEX_HOME/skills/openspec-explore/SKILL.md"

for skill_name in openspec-propose openspec-apply-change openspec-archive-change openspec-explore; do
  cmp "$ROOT_DIR/assets/codex/skills/$skill_name/SKILL.md" "$CODEX_HOME/skills/$skill_name/SKILL.md"
  assert_contains "$(<"$CODEX_HOME/skills/$skill_name/SKILL.md")" 'generatedBy: "1.6.0"'
done

# The handoff contract is installed from the rendered references directory.
test_file_exists "$CODEX_HOME/firefly/references/handoff-contract.md"
cmp "$ROOT_DIR/assets/codex/references/handoff-contract.md" "$CODEX_HOME/firefly/references/handoff-contract.md"


# Runtime scripts are installed to ~/.codex/firefly/bin and must stay executable.
test_file_executable "$CODEX_HOME/firefly/bin/bootstrap-project.sh"
test_file_executable "$CODEX_HOME/firefly/bin/list-change-tasks.sh"
# Runtime scripts are installed to ~/.codex/firefly/bin and must stay executable,
# the five added with the snapshot and record tools included; the renamed
# diagram script replaces the old one; the shared install/doctor libraries
# and their common helper ship alongside the platform scripts.
for runtime_script in bootstrap-project.sh list-change-tasks.sh firefly-diagram.sh firefly-snapshot.sh firefly-record.sh review-package task-brief sdd-workspace doctor-codex.sh validate-openspec-cn.mjs firefly-common.sh firefly-install.sh firefly-doctor.sh; do
  test_file_executable "$CODEX_HOME/firefly/bin/$runtime_script"
done
test_path_not_exists "$CODEX_HOME/firefly/bin/firefly-draw.sh"
for runtime_script in review-package task-brief sdd-workspace firefly-snapshot.sh firefly-record.sh firefly-diagram.sh firefly-common.sh firefly-install.sh firefly-doctor.sh; do
  cmp "$ROOT_DIR/scripts/$runtime_script" "$CODEX_HOME/firefly/bin/$runtime_script"
done
echo "ok codex installer: runtime scripts and shared libraries installed, executable and identical to the source"

# The installed skill set equals the manifest's skill set, so a skill that is
# registered is installed; firefly-context is checked by name as well.
manifest_skill_names="$(node -e 'const m=require(process.argv[1]); console.log(m.managedAssets.filter(a => a.kind === "skill-directory" && a.source.startsWith("assets/codex/skills/")).map(a => a.target.split("/").pop()).sort().join("\n"))' "$MANIFEST")"
installed_skill_names="$(find "$CODEX_HOME/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)"
if [[ "$manifest_skill_names" != "$installed_skill_names" ]]; then
  echo "installed skill set differs from the manifest" >&2
  exit 1
fi
# Without any superpowers present the install still lays out exactly the 31
# managed skill directories.
installed_skill_count="$(find "$CODEX_HOME/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)"
if [[ "$installed_skill_count" -ne 31 ]]; then
  echo "expected 31 installed skill directories but got $installed_skill_count" >&2
  exit 1
fi
test_file_exists "$CODEX_HOME/skills/firefly-context/SKILL.md"
for s in firefly-bounds firefly-source firefly-doubt firefly-arch firefly-docs \
         firefly-ui firefly-tdd firefly-debug firefly-guard firefly-perf firefly-trace \
         firefly-pr firefly-retro; do
  test_file_exists "$CODEX_HOME/skills/$s/SKILL.md"
done
echo "ok codex installer: 31 skill directories installed without any superpowers present"
test_file_executable "$CODEX_HOME/firefly/bin/doctor-codex.sh"
test_file_executable "$CODEX_HOME/firefly/bin/validate-openspec-cn.mjs"
cmp "$ROOT_DIR/scripts/validate-openspec-cn.mjs" "$CODEX_HOME/firefly/bin/validate-openspec-cn.mjs"
test_file_executable "$CODEX_HOME/firefly/bin/firefly"
cmp "$ROOT_DIR/scripts/firefly.sh" "$CODEX_HOME/firefly/bin/firefly"
test_file_executable "$FIREFLY_BIN_DIR/firefly"
cmp "$ROOT_DIR/scripts/firefly-global.sh" "$FIREFLY_BIN_DIR/firefly"
global_command_output="$(CLAUDE_HOME="$tmp_dir/.claude" "$FIREFLY_BIN_DIR/firefly" doctor)"
assert_contains "$global_command_output" "firefly Codex doctor passed"

doctor_output="$("$DOCTOR")"
assert_contains "$doctor_output" "🔎 firefly Codex doctor"
assert_contains "$doctor_output" "✅ OK"
assert_contains "$doctor_output" "📋 Summary"
assert_contains "$doctor_output" "firefly Codex doctor passed"
assert_contains "$doctor_output" "$OPENSPEC_ROOT/dist/core/config-prompts.js"
assert_contains "$doctor_output" "$OPENSPEC_ROOT/dist/core/templates/workflows/propose.js"
assert_contains "$doctor_output" "$CODEX_HOME/skills/openspec-propose"
assert_contains "$doctor_output" "$CODEX_HOME/skills/openspec-apply-change"
assert_contains "$doctor_output" "$CODEX_HOME/firefly/references"

rm "$FIREFLY_BIN_DIR/firefly"

set +e
global_command_drift_output="$("$DOCTOR" 2>&1)"
global_command_drift_status=$?
set -e
assert_exit_code "$global_command_drift_status" "1"
assert_contains "$global_command_drift_output" "$FIREFLY_BIN_DIR/firefly"

global_command_repair_output="$("$DOCTOR" --repair)"
assert_contains "$global_command_repair_output" "$FIREFLY_BIN_DIR/firefly"
test_file_executable "$FIREFLY_BIN_DIR/firefly"
cmp "$ROOT_DIR/scripts/firefly-global.sh" "$FIREFLY_BIN_DIR/firefly"

rm "$FIREFLY_BIN_DIR/firefly"
rm "$FIREFLY_BIN_DIR/.firefly-global-command.sha256"
ln -s "$CODEX_HOME/firefly/bin/firefly" "$FIREFLY_BIN_DIR/firefly"

legacy_command_repair_output="$("$DOCTOR" --repair)"
assert_contains "$legacy_command_repair_output" "$FIREFLY_BIN_DIR/firefly"
test_file_executable "$FIREFLY_BIN_DIR/firefly"
test_path_not_exists "$FIREFLY_BIN_DIR/firefly.firefly.bak"
cmp "$ROOT_DIR/scripts/firefly-global.sh" "$FIREFLY_BIN_DIR/firefly"

expected_openspec_config="$(cat "$ROOT_DIR/assets/openspec/dist/core/config-prompts.js")"
actual_openspec_config="$(cat "$OPENSPEC_ROOT/dist/core/config-prompts.js")"
assert_contains "$actual_openspec_config" "$expected_openspec_config"
assert_contains "$expected_openspec_config" "# Project context (optional)"
assert_contains "$expected_openspec_config" "# Per-artifact rules (optional)"
assert_contains "$expected_openspec_config" "所有产出物必须用简体中文撰写。"
expected_openspec_propose="$(cat "$ROOT_DIR/assets/openspec/dist/core/templates/workflows/propose.js")"
actual_openspec_propose="$(cat "$OPENSPEC_ROOT/dist/core/templates/workflows/propose.js")"
assert_contains "$actual_openspec_propose" "$expected_openspec_propose"
expected_openspec_propose_skill="$(cat "$ROOT_DIR/assets/codex/skills/openspec-propose/SKILL.md")"
actual_openspec_propose_skill="$(cat "$CODEX_HOME/skills/openspec-propose/SKILL.md")"
assert_contains "$actual_openspec_propose_skill" "$expected_openspec_propose_skill"
assert_contains "$actual_openspec_propose_skill" 'Next command: `firefly implement <name>`'
assert_contains "$actual_openspec_propose" 'Next command: \`firefly implement <name>\`'

echo "drift" >> "$OPENSPEC_ROOT/dist/core/config-prompts.js"

set +e
drift_output="$("$DOCTOR" 2>&1)"
drift_status=$?
set -e

assert_exit_code "$drift_status" "1"
assert_contains "$drift_output" "❌ DRIFT"
assert_contains "$drift_output" "📋 Summary"

repair_output="$("$DOCTOR" --repair)"
assert_contains "$repair_output" "🛠️ Repairing drifted or missing assets"
assert_contains "$repair_output" "💾 Backed up"
assert_contains "$repair_output" "✅ Repaired"

post_repair_output="$("$DOCTOR")"
assert_contains "$post_repair_output" "✨ No drift detected"
assert_contains "$post_repair_output" "firefly Codex doctor passed"

chmod -x "$CODEX_HOME/firefly/bin/firefly-diagram.sh"

set +e
mode_drift_output="$("$DOCTOR" 2>&1)"
mode_drift_status=$?
set -e

assert_exit_code "$mode_drift_status" "1"
assert_contains "$mode_drift_output" "❌ DRIFT"
assert_contains "$mode_drift_output" "$CODEX_HOME/firefly/bin/firefly-diagram.sh"

mode_repair_output="$("$DOCTOR" --repair)"
assert_contains "$mode_repair_output" "$CODEX_HOME/firefly/bin/firefly-diagram.sh"
test_file_executable "$CODEX_HOME/firefly/bin/firefly-diagram.sh"

rm "$CODEX_HOME/firefly/bin/validate-openspec-cn.mjs"

set +e
validator_drift_output="$("$DOCTOR" 2>&1)"
validator_drift_status=$?
set -e

assert_exit_code "$validator_drift_status" "1"
assert_contains "$validator_drift_output" "validate-openspec-cn.mjs"

validator_repair_output="$("$DOCTOR" --repair)"
assert_contains "$validator_repair_output" "validate-openspec-cn.mjs"
test_file_executable "$CODEX_HOME/firefly/bin/validate-openspec-cn.mjs"
cmp "$ROOT_DIR/scripts/validate-openspec-cn.mjs" "$CODEX_HOME/firefly/bin/validate-openspec-cn.mjs"

rm "$CODEX_HOME/firefly/bin/firefly"

set +e
command_drift_output="$($DOCTOR 2>&1)"
command_drift_status=$?
set -e

assert_exit_code "$command_drift_status" "1"
assert_contains "$command_drift_output" "$CODEX_HOME/firefly/bin/firefly"

command_repair_output="$($DOCTOR --repair)"
assert_contains "$command_repair_output" "$CODEX_HOME/firefly/bin/firefly"
test_file_executable "$CODEX_HOME/firefly/bin/firefly"
cmp "$ROOT_DIR/scripts/firefly.sh" "$CODEX_HOME/firefly/bin/firefly"

rm "$CODEX_HOME/firefly/bin/doctor-codex.sh"

set +e
doctor_script_drift_output="$($DOCTOR 2>&1)"
doctor_script_drift_status=$?
set -e

assert_exit_code "$doctor_script_drift_status" "1"
assert_contains "$doctor_script_drift_output" "$CODEX_HOME/firefly/bin/doctor-codex.sh"

doctor_script_repair_output="$($DOCTOR --repair)"
assert_contains "$doctor_script_repair_output" "$CODEX_HOME/firefly/bin/doctor-codex.sh"
test_file_executable "$CODEX_HOME/firefly/bin/doctor-codex.sh"
cmp "$ROOT_DIR/scripts/doctor-codex.sh" "$CODEX_HOME/firefly/bin/doctor-codex.sh"

missing_openspec_root="$tmp_dir/missing-openspec"
rm -rf "$missing_openspec_root"

set +e
missing_openspec_repair_output="$(OPENSPEC_ROOT="$missing_openspec_root" "$DOCTOR" --repair 2>&1)"
missing_openspec_repair_status=$?
set -e

assert_exit_code "$missing_openspec_repair_status" "1"
assert_contains "$missing_openspec_repair_output" "OpenSpec package is missing or invalid"
test_path_not_exists "$missing_openspec_root/dist/core/config-prompts.js"

mismatched_openspec_root="$tmp_dir/mismatched-openspec"
mkdir -p "$mismatched_openspec_root"
printf '{"name":"@fission-ai/openspec","version":"9.9.9"}\n' > "$mismatched_openspec_root/package.json"

set +e
mismatched_openspec_repair_output="$(OPENSPEC_ROOT="$mismatched_openspec_root" "$DOCTOR" --repair 2>&1)"
mismatched_openspec_repair_status=$?
set -e

assert_exit_code "$mismatched_openspec_repair_status" "1"
assert_contains "$mismatched_openspec_repair_output" "override target 1.6.0"
test_path_not_exists "$mismatched_openspec_root/dist/core/config-prompts.js"

set +e
mismatched_openspec_install_output="$(OPENSPEC_ROOT="$mismatched_openspec_root" "$INSTALLER" 2>&1)"
mismatched_openspec_install_status=$?
set -e

assert_exit_code "$mismatched_openspec_install_status" "1"
assert_contains "$mismatched_openspec_install_output" "firefly Codex install incomplete"
test_path_not_exists "$mismatched_openspec_root/dist/core/config-prompts.js"

invalid_openspec_root="$tmp_dir/invalid-openspec"
mkdir -p "$invalid_openspec_root"
rm -rf "$CODEX_HOME/skills/firefly"

set +e
invalid_openspec_install_output="$(OPENSPEC_ROOT="$invalid_openspec_root" "$INSTALLER" 2>&1)"
invalid_openspec_install_status=$?
set -e

assert_exit_code "$invalid_openspec_install_status" "1"
assert_contains "$invalid_openspec_install_output" "OpenSpec package metadata is missing or invalid"
test_path_not_exists "$invalid_openspec_root/dist/core/config-prompts.js"
test_file_exists "$CODEX_HOME/skills/firefly/SKILL.md"

# FIREFLY_MANIFEST overrides the default manifest path: a temporary manifest
# without one skill-directory installs everything but that skill.
manifest_override_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir" "$manifest_override_dir"' EXIT
mkdir -p "$manifest_override_dir/fake-root/manifests" "$manifest_override_dir/home"
ln -s "$ROOT_DIR/assets" "$manifest_override_dir/fake-root/assets"
ln -s "$ROOT_DIR/scripts" "$manifest_override_dir/fake-root/scripts"
node -e '
  const fs = require("fs");
  const m = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  m.managedAssets = m.managedAssets.filter(
    (a) => !(a.kind === "skill-directory" && a.source === "assets/codex/skills/firefly-doubt")
  );
  fs.writeFileSync(process.argv[2], JSON.stringify(m, null, 2) + "\n");
' "$MANIFEST" "$manifest_override_dir/fake-root/manifests/codex.json"

override_home="$manifest_override_dir/home/.codex"
manifest_override_output="$(CODEX_HOME="$override_home" FIREFLY_BIN_DIR="$manifest_override_dir/home/.local/bin" OPENSPEC_ROOT="$tmp_dir/openspec" FIREFLY_MANIFEST="$manifest_override_dir/fake-root/manifests/codex.json" "$INSTALLER")"
assert_contains "$manifest_override_output" "🎉 firefly Codex install complete"
test_path_not_exists "$override_home/skills/firefly-doubt"
test_file_exists "$override_home/skills/firefly/SKILL.md"
test_file_exists "$override_home/firefly/references/handoff-contract.md"
echo "ok codex installer: FIREFLY_MANIFEST drops the removed skill-directory entry"

bad_root_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir" "$manifest_override_dir" "$bad_root_dir"' EXIT

set +e
bad_root_output="$(CODEX_HOME="$bad_root_dir" "$INSTALLER" 2>&1)"
bad_root_status=$?
set -e
assert_exit_code "$bad_root_status" "1"
assert_contains "$bad_root_output" "must end with .codex"

set +e
bad_openspec_output="$(CODEX_HOME="$CODEX_HOME" OPENSPEC_ROOT=/ "$INSTALLER" 2>&1)"
bad_openspec_status=$?
set -e
assert_exit_code "$bad_openspec_status" "1"
assert_contains "$bad_openspec_output" "root path must not be /"

missing_openspec_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir" "$manifest_override_dir" "$bad_root_dir" "$missing_openspec_dir"' EXIT

set +e
missing_openspec_install_output="$(env -u OPENSPEC_ROOT CODEX_HOME="$missing_openspec_dir/.codex" FIREFLY_BIN_DIR="$missing_openspec_dir/.local/bin" PATH="$bin_dir:$PATH" "$INSTALLER" 2>&1)"
missing_openspec_install_status=$?
set -e

assert_exit_code "$missing_openspec_install_status" "1"
assert_contains "$missing_openspec_install_output" "openspec install root not found"
assert_contains "$missing_openspec_install_output" "firefly Codex install incomplete"

echo "codex installer smoke test passed"

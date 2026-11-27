#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/tests/lib.sh"
new_tmp_dir standalone

fixture="$FIREFLY_TMP_DIR"
source_package="$fixture/source/firefly"
skills="$fixture/available skills"
bin="$fixture/command dir"
installed="$fixture/storage/skill"
mkdir -p "$fixture/source" "$fixture/home" "$skills" "$bin" "$(dirname "$installed")"
cp -R "$root/firefly" "$source_package"
ln -s "$installed" "$skills/firefly"
export HOME="$fixture/home"
unset CODEX_HOME CLAUDE_HOME

"$source_package/scripts/manage.sh" install --skills-dir "$skills" --bin-dir "$bin"
test -L "$skills/firefly"
test -L "$bin/firefly"
test ! -e "$HOME/.codex"
test ! -e "$HOME/.claude"
assert_eq "$installed/SKILL.md" "$(find "$installed" -name SKILL.md)"
"$bin/firefly" doctor

printf 'changed\n' > "$installed/references/handoff-contract.md"
if "$bin/firefly" doctor; then
  echo 'doctor should detect changed content' >&2
  exit 1
fi
"$bin/firefly" repair
cmp "$source_package/references/handoff-contract.md" "$installed/references/handoff-contract.md"
backup="$(find "$installed" -type f -name handoff-contract.md -path '*/.firefly-backup.*/previous/*')"
assert_contains "$backup" changed

mv "$installed/.firefly-baseline/references/handoff-contract.md" "$fixture/removed-baseline.md"
printf 'preserve\n' > "$installed/references/handoff-contract.md"
if "$bin/firefly" repair; then
  echo 'repair should reject a damaged baseline' >&2
  exit 1
fi
assert_contains "$installed/references/handoff-contract.md" preserve
"$source_package/scripts/manage.sh" install --skills-dir "$skills" --bin-dir "$bin"
cmp "$fixture/removed-baseline.md" "$installed/.firefly-baseline/references/handoff-contract.md"
"$bin/firefly" doctor

mv "$installed/.firefly-baseline" "$fixture/saved-baseline"
if "$bin/firefly" doctor; then
  echo 'doctor should fail when the installation loses its baseline' >&2
  exit 1
fi
mv "$fixture/saved-baseline" "$installed/.firefly-baseline"

mv "$installed/scripts" "$fixture/missing-runtime"
"$source_package/scripts/manage.sh" repair --skills-dir "$skills"
"$bin/firefly" doctor

mkdir "$fixture/relocated"
mv "$installed" "$fixture/relocated/skill"
installed="$fixture/relocated/skill"
ln -sfn "$installed" "$skills/firefly"
"$bin/firefly" doctor

mv "$installed/references" "$fixture/linked-references"
mv "$installed/scripts" "$fixture/linked-scripts"
ln -s "$fixture/linked-references" "$installed/references"
ln -s "$fixture/linked-scripts" "$installed/scripts"
"$source_package/scripts/manage.sh" install --skills-dir "$skills" --bin-dir "$bin" \
  --references-dir "$fixture/linked-references" --scripts-dir "$fixture/linked-scripts"
test -L "$installed/references"
test -L "$installed/scripts"
backup_dirs="$(find "$fixture" -name '.firefly-backup.*' | sort)"
"$source_package/scripts/manage.sh" install --skills-dir "$skills" --bin-dir "$bin"
assert_eq "$backup_dirs" "$(find "$fixture" -name '.firefly-backup.*' | sort)"
printf 'repair through registered link\n' > "$fixture/linked-references/handoff-contract.md"
"$bin/firefly" repair
cmp "$source_package/references/handoff-contract.md" "$fixture/linked-references/handoff-contract.md"
"$bin/firefly" doctor

mv "$installed/references" "$fixture/saved-references-link"
mkdir "$fixture/unmanaged"
touch "$fixture/unmanaged/retained"
ln -s "$fixture/unmanaged" "$installed/references"
if "$bin/firefly" repair; then
  echo 'repair should reject a retargeted link' >&2
  exit 1
fi
test -f "$fixture/unmanaged/retained"
mv "$installed/references" "$fixture/unregistered-link"
mv "$fixture/saved-references-link" "$installed/references"
"$bin/firefly" doctor

mkdir "$fixture/conflict"
touch "$fixture/conflict/firefly"
if "$source_package/scripts/manage.sh" install --skills-dir "$fixture/refused" --bin-dir "$fixture/conflict"; then
  echo 'installer should reject an unrelated command' >&2
  exit 1
fi
test -f "$fixture/conflict/firefly"
test ! -e "$fixture/refused/firefly"

failure_fixture="$root/tests/fixtures/firefly-install-failure.mjs"
failure_path="$fixture/failed-bin/firefly"
if FIREFLY_FAIL_LINK="$failure_path" NODE_OPTIONS="--import=$failure_fixture" \
  "$source_package/scripts/manage.sh" install --skills-dir "$fixture/failed-skills" --bin-dir "$fixture/failed-bin"; then
  echo 'installer should fail when publishing the CLI fails' >&2
  exit 1
fi
test ! -e "$fixture/failed-skills/firefly"
test ! -L "$failure_path"

unreadable="$fixture/unreadable/firefly"
mkdir -p "$unreadable"
touch "$unreadable/retained"
if FIREFLY_FAIL_READ="$unreadable" NODE_OPTIONS="--import=$failure_fixture" \
  "$source_package/scripts/manage.sh" install --skills-dir "$fixture/unreadable"; then
  echo 'installer should reject an unreadable destination' >&2
  exit 1
fi
test -f "$unreadable/retained"
test ! -e "$unreadable/.firefly-install.json"

reference="$source_package/references/abilities/mermaid-diagram-specialist/diagram-types.md"
mv "$reference" "$fixture/removed-guide.md"
if "$source_package/scripts/manage.sh" install --skills-dir "$fixture/incomplete"; then
  echo 'installer should reject missing package documentation' >&2
  exit 1
fi
test ! -e "$fixture/incomplete/firefly"
mv "$fixture/removed-guide.md" "$reference"

cp "$reference" "$fixture/saved-guide.md"
printf '\n{{PLATFORM_SPAWN}}\n' >> "$reference"
if "$source_package/scripts/manage.sh" install --skills-dir "$fixture/platform-placeholder"; then
  echo 'installer should reject a host-specific placeholder' >&2
  exit 1
fi
test ! -e "$fixture/platform-placeholder/firefly"
mv "$fixture/saved-guide.md" "$reference"

"$source_package/scripts/manage.sh" install --skills-dir "$fixture/without-cli"
"$fixture/without-cli/firefly/scripts/firefly.sh" doctor
test ! -e "$HOME/.codex"
test ! -e "$HOME/.claude"
echo 'standalone install, doctor, and repair passed'

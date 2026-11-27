#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../lib.sh
source "$root/tests/lib.sh"

source_ref="${1:-$root}"
skills_version="${2:-1.9.0}"
new_tmp_dir skills-distribution
fixture="$FIREFLY_TMP_DIR"
mkdir "$fixture/project" "$fixture/data"
cd "$fixture/project"

export XDG_DATA_HOME="$fixture/data"
export DISABLE_TELEMETRY=1 SKILLS_NO_TELEMETRY=1
export npm_config_cache="${npm_config_cache:-$fixture/npm}"
installer=(npx --yes "skills@$skills_version" add "$source_ref" --agent universal)
"${installer[@]}" --list > "$fixture/discovery.log" 2>&1 || { cat "$fixture/discovery.log" >&2; exit 1; }
assert_contains "$fixture/discovery.log" 'Found 1 skill'
"${installer[@]}" --yes > "$fixture/install.log" 2>&1 || { cat "$fixture/install.log" >&2; exit 1; }

bundle="$PWD/.agents/skills/firefly"
test -f "$bundle/references/handoff-contract.md"
test -x "$bundle/scripts/firefly.sh"
cp -R "$bundle" "$fixture/distributed"
command="$(bash "$bundle/scripts/manage.sh" bootstrap --bin-dir "$fixture/bin")"
assert_eq "$fixture/bin/firefly" "$command"
test -f "$XDG_DATA_HOME/firefly/runtime/firefly/.firefly-baseline/entrypoint.md"
"$command" doctor
"$command" status --help > "$fixture/status-help.log"
assert_contains "$fixture/status-help.log" 'firefly list'
diff -qr "$bundle" "$fixture/distributed"
echo 'skills distribution and first-use bootstrap passed'

#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "$haystack" != *"$needle"* ]]; then
    echo "expected output to contain: $needle" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"

  if [[ "$haystack" == *"$needle"* ]]; then
    echo "expected output not to contain: $needle" >&2
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

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

runtime_dir="$tmp_dir/runtime"
mkdir -p "$runtime_dir"
cp "$ROOT_DIR/firefly/scripts/firefly.sh" "$runtime_dir/firefly"
cp "$ROOT_DIR/firefly/scripts/"{spec-commands,project-paths,bundle}.mjs "$runtime_dir/"

cat > "$runtime_dir/validate-openspec-cn.mjs" <<'EOF'
console.log(`validate ${process.argv.slice(2).join(' ')}`);
EOF

# A stub per runtime script, echoing its own name and the arguments it got.
for command in bootstrap-project.sh list-change-tasks.sh firefly-diagram.sh firefly-snapshot.sh firefly-record.sh manage.sh; do
  cat > "$runtime_dir/$command" <<EOF
#!/usr/bin/env bash
echo "${command%.sh} \$*"
EOF
  chmod +x "$runtime_dir/$command"
done

validate_output="$("$runtime_dir/firefly" validate all --root project)"
assert_contains "$validate_output" "validate all --root project"

init_output="$("$runtime_dir/firefly" init project)"
assert_contains "$init_output" "bootstrap-project project"

tasks_output="$("$runtime_dir/firefly" tasks all --root project)"
assert_contains "$tasks_output" "list-change-tasks all --root project"

diagram_output="$("$runtime_dir/firefly" diagram feature-name out-dir)"
assert_contains "$diagram_output" "firefly-diagram feature-name out-dir"

snapshot_output="$("$runtime_dir/firefly" snapshot worktree)"
assert_contains "$snapshot_output" "firefly-snapshot"

record_output="$("$runtime_dir/firefly" record observe --change c1 --scenario S-1)"
assert_contains "$record_output" "firefly-record observe --change c1 --scenario S-1"

assert_contains "$("$runtime_dir/firefly" doctor)" "manage doctor"
assert_contains "$("$runtime_dir/firefly" repair)" "manage repair"

mkdir "$tmp_dir/bin"
cat > "$tmp_dir/bin/openspec" <<'EOF'
#!/usr/bin/env bash
printf '<%s>\n' "$@"
printf 'upstream stderr\n' >&2
exit 42
EOF
chmod +x "$tmp_dir/bin/openspec"
status=0
wrapped_output="$(PATH="$tmp_dir/bin:$PATH" "$runtime_dir/firefly" spec raw schema validate 'path with spaces' '' -- --help 2> "$tmp_dir/stderr")" || status=$?
assert_exit_code "$status" 42
expected=$'<schema>\n<validate>\n<path with spaces>\n<>\n<-->\n<--help>'
if [[ "$wrapped_output" != "$expected" ]]; then
  echo "unexpected OpenSpec arguments: $wrapped_output" >&2
  exit 1
fi
assert_contains "$(cat "$tmp_dir/stderr")" 'upstream stderr'

export PATH="$tmp_dir/bin:$PATH"
mkdir -p "$tmp_dir/project/openspec/changes/archive" "$tmp_dir/project/src"
cd "$tmp_dir/project/src"
check_forwarding() {
  local expected="$1" status=0 output
  shift
  output="$("$runtime_dir/firefly" "$@" 2> "$tmp_dir/stderr")" || status=$?
  assert_exit_code "$status" 42
  if [[ "$output" != "$expected" ]]; then
    echo "unexpected specification arguments: $output" >&2
    exit 1
  fi
}
check_forwarding $'<new>\n<change>\n<report-export>' new report-export
check_forwarding $'<list>\n<--json>' list --json
check_forwarding $'<status>\n<--change>\n<report-export>\n<--json>' status report-export --json
check_forwarding $'<show>\n<report-export>\n<--type>\n<change>\n<--json>' show report-export --json

for command in status show; do
  status=0
  output="$("$runtime_dir/firefly" "$command" --json 2>&1)" || status=$?
  assert_exit_code "$status" 2
  assert_contains "$output" '当前没有活跃变更'
  status=0
  mkdir -p "$tmp_dir/project/openspec/changes/"{one,two}
  output="$("$runtime_dir/firefly" "$command" --json 2>&1)" || status=$?
  assert_exit_code "$status" 2
  assert_contains "$output" $'  one\n  two'
  status=0
  rmdir "$tmp_dir/project/openspec/changes/"{one,two}
  mkdir -p "$tmp_dir/project/openspec/changes/"{only-change,archive/old}
  output="$("$runtime_dir/firefly" "$command" 2>&1)" || status=$?
  assert_exit_code "$status" 42
  assert_contains "$output" '当前变更：only-change'
  assert_contains "$output" '<only-change>'
  rmdir "$tmp_dir/project/openspec/changes/only-change"
done

mkdir "$tmp_dir/no-openspec"
ln -s "$(command -v bash)" "$tmp_dir/no-openspec/bash"
ln -s "$(command -v dirname)" "$tmp_dir/no-openspec/dirname"
ln -s "$(command -v node)" "$tmp_dir/no-openspec/node"
status=0
missing_output="$(PATH="$tmp_dir/no-openspec" "$runtime_dir/firefly" spec raw --version 2>&1)" || status=$?
assert_exit_code "$status" 127
assert_contains "$missing_output" '未找到规格后端'

assert_exit_code "$(set +e; "$runtime_dir/firefly" unknown >/dev/null 2>&1; echo "$?")" 1
assert_exit_code "$(set +e; "$runtime_dir/firefly" openspec --help >/dev/null 2>&1; echo "$?")" 1
assert_exit_code "$(set +e; "$runtime_dir/firefly" sc --help >/dev/null 2>&1; echo "$?")" 1
for args in 'new all' 'spec validate' 'spec archive'; do
  read -r -a operands <<< "$args"
  assert_exit_code "$(set +e; "$runtime_dir/firefly" "${operands[@]}" >/dev/null 2>&1; echo "$?")" 2
done
mkdir -p "$tmp_dir/store-pointer/openspec"
printf 'schema: spec-driven\nstore: elsewhere\n' > "$tmp_dir/store-pointer/openspec/config.yaml"
assert_exit_code "$(set +e; "$runtime_dir/firefly" new outside --root "$tmp_dir/store-pointer" >/dev/null 2>&1; echo "$?")" 2
assert_contains "$("$runtime_dir/firefly" doctor --help)" '--skill-dir'
assert_contains "$("$runtime_dir/firefly" repair --help)" '--skills-dir'
assert_contains "$("$runtime_dir/firefly" --help)" 'spec --help'
assert_not_contains "$("$runtime_dir/firefly" --help)" "--platform"
for command in new list status show; do
  assert_contains "$("$runtime_dir/firefly" "$command" --help)" "firefly $command"
done
assert_contains "$("$runtime_dir/firefly" status --help)" 'firefly list'
assert_contains "$("$runtime_dir/firefly" status --help)" '示例变更 ID'
assert_contains "$("$ROOT_DIR/firefly/scripts/firefly.sh" validate --help)" '必须显式指定校验目标'
for command in validate tasks snapshot spec; do
  status=0
  output="$("$ROOT_DIR/firefly/scripts/firefly.sh" "$command" 2>&1)" || status=$?
  assert_exit_code "$status" 2
  assert_contains "$output" "firefly $command"
done
assert_exit_code "$(set +e; "$runtime_dir/firefly" help status >/dev/null 2>&1; echo "$?")" 2
echo "firefly command test passed"

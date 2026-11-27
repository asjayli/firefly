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

validate_output="$("$runtime_dir/firefly" validate --root project)"
assert_contains "$validate_output" "validate --root project"

init_output="$("$runtime_dir/firefly" init project)"
assert_contains "$init_output" "bootstrap-project project"

tasks_output="$("$runtime_dir/firefly" tasks project)"
assert_contains "$tasks_output" "list-change-tasks project"

diagram_output="$("$runtime_dir/firefly" diagram feature-name out-dir)"
assert_contains "$diagram_output" "firefly-diagram feature-name out-dir"

snapshot_output="$("$runtime_dir/firefly" snapshot)"
assert_contains "$snapshot_output" "firefly-snapshot"

record_output="$("$runtime_dir/firefly" record observe --change c1 --scenario S-1)"
assert_contains "$record_output" "firefly-record observe --change c1 --scenario S-1"

assert_contains "$("$runtime_dir/firefly" doctor)" "manage doctor"
assert_contains "$("$runtime_dir/firefly" repair)" "manage repair"
assert_exit_code "$(set +e; "$runtime_dir/firefly" unknown >/dev/null 2>&1; echo "$?")" 1
assert_not_contains "$("$runtime_dir/firefly" --help)" "--platform"
echo "firefly command test passed"

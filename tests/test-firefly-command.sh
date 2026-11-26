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
cp "$ROOT_DIR/scripts/firefly.sh" "$runtime_dir/firefly"

cat > "$runtime_dir/validate-openspec-cn.mjs" <<'EOF'
console.log(`validate ${process.argv.slice(2).join(' ')}`);
EOF

# A stub per runtime script, echoing its own name and the arguments it got.
for command in bootstrap-project.sh list-change-tasks.sh firefly-diagram.sh firefly-snapshot.sh firefly-record.sh doctor-codex.sh doctor-claude.sh firefly-common.sh firefly-install.sh firefly-doctor.sh; do
  cat > "$runtime_dir/$command" <<EOF
#!/usr/bin/env bash
echo "${command%.sh} \$*"
EOF
  chmod +x "$runtime_dir/$command"
done

validate_output="$("$runtime_dir/firefly" validate --root project)"
assert_contains "$validate_output" "validate --root project"

init_output="$("$runtime_dir/firefly" init --tools codex project)"
assert_contains "$init_output" "bootstrap-project --tools codex project"

tasks_output="$("$runtime_dir/firefly" tasks project)"
assert_contains "$tasks_output" "list-change-tasks project"

diagram_output="$("$runtime_dir/firefly" diagram feature-name out-dir)"
assert_contains "$diagram_output" "firefly-diagram feature-name out-dir"

snapshot_output="$("$runtime_dir/firefly" snapshot)"
assert_contains "$snapshot_output" "firefly-snapshot"

record_output="$("$runtime_dir/firefly" record observe --change c1 --scenario S-1)"
assert_contains "$record_output" "firefly-record observe --change c1 --scenario S-1"

# Doctor dispatch: the runtime location of the script itself decides which
# doctor runs; outside both runtimes --platform is required.
home_dir="$tmp_dir/home"
mkdir -p "$home_dir/.claude/firefly/bin" "$home_dir/.codex/firefly/bin"
for pl in claude codex; do
  cp "$runtime_dir/firefly" "$home_dir/.$pl/firefly/bin/firefly"
  cp "$runtime_dir/doctor-$pl.sh" "$home_dir/.$pl/firefly/bin/doctor-$pl.sh"
  cp "$runtime_dir/doctor-claude.sh" "$home_dir/.$pl/firefly/bin/doctor-claude.sh"
  cp "$runtime_dir/doctor-codex.sh" "$home_dir/.$pl/firefly/bin/doctor-codex.sh"
done

claude_doctor_output="$(CLAUDE_HOME="$home_dir/.claude" "$home_dir/.claude/firefly/bin/firefly" doctor)"
assert_contains "$claude_doctor_output" "doctor-claude"

codex_doctor_output="$(CODEX_HOME="$home_dir/.codex" "$home_dir/.codex/firefly/bin/firefly" doctor)"
assert_contains "$codex_doctor_output" "doctor-codex"

set +e
outside_output="$("$runtime_dir/firefly" doctor 2>&1)"
outside_status=$?
set -e
assert_exit_code "$outside_status" "1"
assert_contains "$outside_output" "requires --platform claude or codex"

platform_output="$(CLAUDE_HOME="$home_dir/.claude" CODEX_HOME="$home_dir/.codex" "$runtime_dir/firefly" doctor --platform codex)"
assert_contains "$platform_output" "doctor-codex"

repair_output="$(CODEX_HOME="$home_dir/.codex" "$home_dir/.codex/firefly/bin/firefly" repair)"
assert_contains "$repair_output" "doctor-codex --repair"

set +e
unsupported_output="$("$runtime_dir/firefly" archive 2>&1)"
unsupported_status=$?
set -e

assert_exit_code "$unsupported_status" "1"
assert_contains "$unsupported_output" "Usage: firefly <command>"

# The renamed subcommand points at its successor and fails instead of
# falling through to the generic usage.
set +e
draw_output="$("$runtime_dir/firefly" draw feature-name 2>&1)"
draw_status=$?
set -e

assert_exit_code "$draw_status" "1"
assert_contains "$draw_output" "firefly draw is now firefly diagram"
assert_not_contains "$draw_output" "Usage: firefly <command>"

# help is the final list of runtime subcommands; the renamed one is gone.
help_output="$("$runtime_dir/firefly" help)"
for command in validate init tasks diagram doctor repair snapshot record; do
  assert_contains "$help_output" "  $command "
done
assert_not_contains "$help_output" "draw"
assert_contains "$("$runtime_dir/firefly")" "  record "

echo "firefly command test passed"

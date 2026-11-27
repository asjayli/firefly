#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/tests/lib.sh"
decision="$root/firefly/scripts/continuation.mjs"

expect() {
  assert_eq "$1" "$(printf '%s\n' "$2" | node "$decision")"
}

# A wait timeout and a controller resumption both preserve the active slot.
expect wait '{"kind":"dispatch","host":"active","savedReturn":false}'
expect wait '{"kind":"dispatch","host":"active","savedReturn":false,"obsolete":false}'
expect reconcile '{"kind":"dispatch","host":"unknown","savedReturn":false}'
expect collect-return '{"kind":"dispatch","host":"unknown","savedReturn":true}'
expect record-failure '{"kind":"dispatch","host":"finished","savedReturn":false}'

# The first valid REVISE retires pending review work. An exit acknowledgement
# closes the dispatch without creating a new slot or applying its late return.
expect cancel-and-wait '{"kind":"dispatch","host":"active","obsolete":true,"cancelSupported":true}'
expect wait '{"kind":"dispatch","host":"active","obsolete":true,"cancelSupported":false}'
expect close-obsolete '{"kind":"dispatch","host":"finished","obsolete":true,"savedReturn":true}'

expect rerun '{"kind":"recheck","key":"A","attempts":[],"evidence":"missing"}'
expect decide-from-evidence '{"kind":"recheck","key":"A","attempts":["A"],"evidence":"answers"}'
expect escalate '{"kind":"recheck","key":"A","attempts":["A"],"evidence":"missing"}'
expect rerun '{"kind":"recheck","key":"B","attempts":["A"],"evidence":"missing"}'

expect continue-independent '{"kind":"blocked-path","independentReady":true,"alternativeReady":true}'
expect try-alternative '{"kind":"blocked-path","independentReady":false,"alternativeReady":true}'
expect escalate '{"kind":"blocked-path","independentReady":false,"alternativeReady":false}'

finish() {
  printf '{"kind":"finish","required":%s,"conditions":%s,"workReady":%s,"dispatches":%s}\n' \
    "$required" "$1" "${2:-false}" "${3:-$clear_dispatches}"
}

expect_finish() {
  local expected="$1"
  shift
  assert_eq "$expected" "$(finish "$@" | node "$decision")"
}

reject_finish() {
  local expected_error="$1" output
  shift
  if output="$(finish "$@" | node "$decision" 2>&1)"; then
    echo "expected finish input to be rejected, got: $output" >&2
    exit 1
  fi
  assert_eq "firefly continuation: $expected_error" "$output"
}

# A local suite passes before the required host recovery check is completed.
required='["local-tests","host-resume"]'
clear_dispatches='{"status":"clear"}'
local_pass='{"id":"local-tests","status":"verified","evidence":"evidence/local-suite.log"}'
host_ready='{"id":"host-resume","status":"ready"}'
host_blocked='{"id":"host-resume","status":"blocked","reason":"Authenticated isolated host unavailable","owner":"host administrator"}'
host_pass='{"id":"host-resume","status":"verified","evidence":"evidence/isolated-reconnect.log"}'
host_wait='{"id":"host-resume","status":"waiting","evidence":"pipeline run 42"}'

expect_finish reconcile-conditions "[$local_pass]"
expect_finish continue-work "[$local_pass,$host_ready]"
expect_finish continue-work "[$local_pass,$host_blocked]" true
expect_finish wait "[$local_pass,$host_wait]"
expect_finish wait "[$local_pass,$host_blocked]" false '{"status":"waiting","evidence":"dispatch worker-1"}'
expect_finish wait "[$local_pass,$host_pass]" false '{"status":"waiting","evidence":"dispatch worker-1"}'
expect_finish escalate "[$local_pass,$host_blocked]"
expect_finish escalate "[$local_pass,$host_pass]" false '{"status":"blocked","reason":"Host status lost and writer cannot be fenced","owner":"host administrator"}'
expect_finish complete "[$local_pass,$host_pass]"

reject_finish 'Duplicate condition ID: local-tests' "[$local_pass,$local_pass]"
reject_finish 'Unknown condition ID: unrelated' "[$local_pass,{\"id\":\"unrelated\",\"status\":\"ready\"}]"
reject_finish 'Invalid status for host-resume' "[$local_pass,{\"id\":\"host-resume\",\"status\":\"complete\"}]"
reject_finish 'Missing evidence reference for host-resume' "[$local_pass,{\"id\":\"host-resume\",\"status\":\"verified\",\"evidence\":\" \"}]"
reject_finish 'Missing blocker reason or owner for host-resume' "[$local_pass,{\"id\":\"host-resume\",\"status\":\"blocked\",\"reason\":\"Offline\"}]"
reject_finish 'Invalid status for dispatches' "[$local_pass,$host_pass]" false '{}'
reject_finish 'Missing evidence reference for dispatches' "[$local_pass,$host_pass]" false '{"status":"waiting"}'
reject_finish 'Missing blocker reason or owner for dispatches' "[$local_pass,$host_pass]" false '{"status":"blocked"}'
reject_finish 'Expected conditions and a workReady boolean' "[$local_pass,$host_pass]" null
required='["local-tests","local-tests"]' reject_finish 'Duplicate required condition ID' "[$local_pass]"
required='[]' reject_finish 'Expected nonempty required condition IDs' '[]'
required='["local tests"]' reject_finish 'Expected nonempty required condition IDs' '[]'

# Record the host handle and terminal disposition in the existing ledger.
new_tmp_dir continuation
mkdir -p "$FIREFLY_TMP_DIR/openspec/changes/sample"
git -C "$FIREFLY_TMP_DIR" init -q
(
  cd "$FIREFLY_TMP_DIR"
  record="$root/firefly/scripts/firefly-record.sh"
  dispatch=(dispatch --change sample --package sample@ready.abc.def --role reviewer --agent review-a)
  "$record" "${dispatch[@]}" --status sent
  "$record" "${dispatch[@]}" --status started --handle host-review-1
  "$record" "${dispatch[@]}" --status obsolete --reason 'generation blocked'
  ledger=.superpowers/sdd/progress.md
  assert_contains "$ledger" '| started | host handle: host-review-1 |'
  assert_contains "$ledger" '| obsolete | generation blocked |'
  assert_eq 1 "$(grep -cF '| sent |' "$ledger")"
  if "$record" "${dispatch[@]}" --status started; then
    echo 'started dispatch requires a host handle' >&2
    exit 1
  fi
  worker=(dispatch --change sample --package sample@task.1.abc --role implementer --agent worker-a)
  if "$record" "${worker[@]}" --status sent --work 'task 1' --worktree relative; then
    echo 'worker dispatch requires an absolute worktree' >&2
    exit 1
  fi
  if "$record" "${worker[@]}" --status started --handle host-worker-1 --work 'task 1' --worktree "$FIREFLY_TMP_DIR"; then
    echo 'worker location belongs on the sent row' >&2
    exit 1
  fi
  "$record" "${worker[@]}" --status sent --work 'task 1' --worktree "$FIREFLY_TMP_DIR"
  "$record" "${worker[@]}" --status started --handle host-worker-1
  "$record" "${worker[@]}" --status returned
  assert_contains "$ledger" "| implementer | worker-a | sent | work: task 1; worktree: $FIREFLY_TMP_DIR |"
  assert_contains "$ledger" '| implementer | worker-a | started | host handle: host-worker-1 |'
  assert_contains "$ledger" '| implementer | worker-a | returned |'

  candidate="$("$root/firefly/scripts/firefly-snapshot.sh")"
  pids=()
  for id in 1 2 3 4 5 6; do
    "$record" observe --change sample --scenario "S-$id" --check check --candidate "$candidate" \
      --spec abcdefabcdef --observer "verifier:worker-$id" --result unverified >/dev/null &
    pids+=("$!")
  done
  for pid in "${pids[@]}"; do wait "$pid"; done
  observations=openspec/changes/sample/verification.md
  for id in 1 2 3 4 5 6; do assert_contains "$observations" "| S-$id | check |"; done
)

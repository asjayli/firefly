#!/usr/bin/env bash
# Validates the shape of tests/acceptance/*.md: count, positions, skills,
# expected-block keys and value sets, must_not verbs.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACC="$ROOT_DIR/tests/acceptance"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"

TERMINALS="investigation-report proposal-ready ready-decision candidate-integrated verdict-returned findings-returned diagnosis-returned constraints-recorded contract-written adr-written pr-prepared archived readiness-assessed launched retro-recorded escalated"
VERDICTS="ACCEPT REVISE RECHECK INSUFFICIENT_EVIDENCE ESCALATE none"
OWNERS="requester requirement owner controller spec author planner implementer verifier reviewer none"
VERBS="read record dispatch-author dispatch-planner dispatch-implementer dispatch-verifier dispatch-reviewer fix-candidate write-spec write-tasks integrate push merge archive sync-specs release widen-scope edit-product-code ask-user"
in_set() { local want="$1" set="$2"; [[ " $set " == *" $want "* ]]; }

count="$(ls "$ACC"/*.md 2>/dev/null | wc -l)"
[[ "$count" -eq 26 ]] || { echo "expected 26 acceptance cases, got $count" >&2; exit 1; }

declare -A seen_pos=()
for f in "$ACC"/*.md; do
  base="$(basename "$f" .md)"
  pos="${base%%-*}"
  [[ "$pos" =~ ^[0-9]{2}$ ]] || { echo "bad position prefix: $base" >&2; exit 1; }
  [[ -z "${seen_pos[$pos]:-}" ]] || { echo "duplicate position: $pos" >&2; exit 1; }
  seen_pos[$pos]=1
  grep -q "^Position: $pos$" "$f" || { echo "$base: Position field mismatch" >&2; exit 1; }
  skill="$(sed -n 's/^Skill: //p' "$f")"
  [[ -d "$ROOT_DIR/assets/shared/skills/$skill" ]] || { echo "$base: unknown skill $skill" >&2; exit 1; }
  grep -q '^Design: DESIGN.md ' "$f" || { echo "$base: missing Design line" >&2; exit 1; }
  blocks="$(grep -c '^Expected:$' "$f")"
  [[ "$blocks" -eq 2 ]] || { echo "$base: expected 2 Expected blocks, got $blocks" >&2; exit 1; }
  for key in entry writes terminal verdict stops_for_user next_owner; do
    n="$(grep -c "^  $key: " "$f")"
    [[ "$n" -eq 2 ]] || { echo "$base: key $key appears $n times (want 2)" >&2; exit 1; }
  done
  for v in $(sed -n 's/^  terminal: //p' "$f"); do in_set "$v" "$TERMINALS" || { echo "$base: bad terminal $v" >&2; exit 1; }; done
  for v in $(sed -n 's/^  verdict: //p' "$f"); do in_set "$v" "$VERDICTS" || { echo "$base: bad verdict $v" >&2; exit 1; }; done
  for v in $(sed -n 's/^  stops_for_user: //p' "$f"); do [[ "$v" == yes || "$v" == no ]] || { echo "$base: bad stops_for_user $v" >&2; exit 1; }; done
  for v in $(sed -n 's/^  next_owner: //p' "$f"); do in_set "$v" "$OWNERS" || { echo "$base: bad next_owner $v" >&2; exit 1; }; done
  mn="$(sed -n 's/^  must_not: //p' "$f")"
  [[ -n "$mn" ]] || { echo "$base: missing must_not" >&2; exit 1; }
  IFS=';'
  for verb in $mn; do in_set "$(echo "$verb" | xargs)" "$VERBS" || { echo "$base: bad must_not verb $verb" >&2; exit 1; }; done
  unset IFS
  grep -q '^## Notes$' "$f" || { echo "$base: missing Notes" >&2; exit 1; }
done
for p in $(seq -w 1 26); do [[ -n "${seen_pos[$p]:-}" ]] || { echo "missing position $p" >&2; exit 1; }; done

echo "acceptance cases shape ok (26 files, positions 01-26)"

# Negative self-check in a temp copy: an APPROVE verdict must be rejected
# by the same value-set rule this test enforces.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp -r "$ACC" "$tmp/acceptance"
sed -i 's/^  verdict: ACCEPT$/  verdict: APPROVE/' "$tmp/acceptance/16-firefly-review.md"
bad=0
for v in $(sed -n 's/^  verdict: //p' "$tmp/acceptance/16-firefly-review.md"); do
  in_set "$v" "$VERDICTS" || bad=1
done
if [[ "$bad" -eq 0 ]]; then
  echo "negative: expected APPROVE verdict to be rejected" >&2
  exit 1
fi
echo "negative: blocked (APPROVE verdict)"

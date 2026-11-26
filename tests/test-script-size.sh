#!/usr/bin/env bash
# Line limit of the scripts under scripts/: 500 lines each, the limit the
# roadmap sets for every file. Lines are counted the way the skill lint counts
# them, so a last line without a trailing newline is a line too.
#
#   1. every scripts/*.sh and scripts/*.mjs is within the limit;
#   2. the check itself blocks a 501-line script (negative case).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"

LIMIT=500

# oversized <dir> <strip-prefix> — print "<file>: <n> lines (limit 500)" for
# every script in <dir> above the limit, with <strip-prefix> removed from the
# path; print the number of those scripts last.
oversized() {
  local file count=0
  local lines
  for file in "$1"/*.sh "$1"/*.mjs; do
    [[ -f "$file" ]] || continue
    lines="$(awk 'END { print NR }' "$file")"
    if [[ "$lines" -gt "$LIMIT" ]]; then
      echo "${file#"$2"}: $lines lines (limit $LIMIT)"
      count=$((count + 1))
    fi
  done
  echo "$count"
}

# 1. The real scripts.
result="$(oversized "$ROOT_DIR/scripts" "$ROOT_DIR/")"
assert_eq 0 "${result##*$'\n'}"
echo "ok scripts: every .sh and .mjs is within $LIMIT lines"

# 2. A 501-line script and a script whose 501st line has no newline are both
#    reported; 500 lines pass.
new_tmp_dir script-size
mkdir "$FIREFLY_TMP_DIR/scripts"
printf 'line\n%.0s' $(seq 1 501) > "$FIREFLY_TMP_DIR/scripts/over.sh"
{
  head -n 500 "$FIREFLY_TMP_DIR/scripts/over.sh"
  printf 'last line without newline'
} > "$FIREFLY_TMP_DIR/scripts/no-newline.mjs"
head -n 500 "$FIREFLY_TMP_DIR/scripts/over.sh" > "$FIREFLY_TMP_DIR/scripts/exact.sh"
result="$(oversized "$FIREFLY_TMP_DIR/scripts" "$FIREFLY_TMP_DIR/")"
assert_eq "scripts/over.sh: 501 lines (limit $LIMIT)
scripts/no-newline.mjs: 501 lines (limit $LIMIT)
2" "$result"
echo "negative: blocked (501-line script, and a 501st line without a newline)"

echo "script size test passed"

#!/usr/bin/env bash
# README workflow assertions for the 0.2.0 skill surface.
#
# lint_readme <path> <zh|en> checks one README:
#   skills      the skill subcommands are named
#   verdicts    the four verdict values and ESCALATE are documented
#   entries     the four commissioning entries each carry an example
#   runtime     firefly doctor, firefly next and the runtime subcommands
#   install     the install section never lists superpowers as a prerequisite
#               (a line naming it must state it is not needed)
#   wording     no "waits for your confirmation" phrasing
#   retired     the retired skill names are not presented as firefly skills
#
# The test then checks itself, in the negative pattern of
# tests/test-skill-contracts.sh: a temporary copy of README.md with one skill
# name removed must fail the lint.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"

SKILLS=(next think draw bounds source doubt arch docs ui tdd verify-web verify-formal debug guard perf trace propose tasks implement context review pr archive retro)
VERDICTS=(ACCEPT REVISE RECHECK INSUFFICIENT_EVIDENCE)
RUNTIME=(init doctor config repair validate tasks diagram snapshot record)
RETIRED=(firefly-doctor openspec-sync-specs)

FAILURES=0

fail() {
  echo "FAIL: $1" >&2
  FAILURES=$((FAILURES + 1))
}

# Print the install section (## 安装 / ## Installation) of $1.
install_section() {
  awk '/^## (安装|Installation)$/{flag=1;next} /^## /{flag=0} flag' "$1"
}

lint_readme() {
  local path="$1" lang="$2"
  local before=$FAILURES
  [[ -f "$path" ]] || { fail "missing README: $path"; return 1; }

  local skill token phrase line
  for skill in "${SKILLS[@]}"; do
    grep -Fq "\`firefly $skill\`" "$path" || fail "$path does not name \`firefly $skill\`"
  done
  for token in "${VERDICTS[@]}" ESCALATE; do
    grep -Fq "$token" "$path" || fail "$path does not document $token"
  done
  grep -Fq 'firefly next' "$path" || fail "$path does not mention firefly next"
  grep -Fq 'firefly doctor' "$path" || fail "$path does not mention firefly doctor"
  for token in "${RUNTIME[@]}"; do
    grep -Fq "firefly $token" "$path" || fail "$path does not document the runtime subcommand $token"
  done
  for retired in "${RETIRED[@]}"; do
    if grep -Fq "$retired" "$path"; then
      fail "$path presents the retired $retired as a firefly skill"
    fi
  done

  # Four commissioning entries, one example each.
  if [[ "$lang" == zh ]]; then
    grep -Fq '四个委托入口' "$path" || fail "$path lacks the four commissioning entries heading"
    for phrase in '查清为什么' '暂不实现' '已获准' '评审这个候选'; do
      grep -Fq "$phrase" "$path" || fail "$path lacks the commissioning entry example: $phrase"
    done
  else
    grep -Fq 'Four entries' "$path" || fail "$path lacks the four commissioning entries heading"
    for phrase in 'Find out why' 'do not implement' 'passed the ready decision' 'Review this candidate'; do
      grep -Fq "$phrase" "$path" || fail "$path lacks the commissioning entry example: $phrase"
    done
  fi

  # The install section may mention superpowers only to state it is not needed.
  while IFS= read -r line; do
    case "$line" in
      *superpowers*) ;;
      *) continue ;;
    esac
    if [[ "$lang" == zh ]]; then
      [[ "$line" == *不* ]] || fail "$path install section lists superpowers as a prerequisite: $line"
    else
      [[ "$line" == *"no longer"* || "$line" == *"not "* ]] \
        || fail "$path install section lists superpowers as a prerequisite: $line"
    fi
  done < <(install_section "$path")

  # No confirmation-gate wording that contradicts continuous execution.
  for phrase in '等你确认' '等待确认' '等待你的确认' 'waits for your confirmation' 'waiting for your confirmation'; do
    if grep -Fq "$phrase" "$path"; then
      fail "$path uses confirmation-gate wording: $phrase"
    fi
  done

  [[ "$FAILURES" -eq "$before" ]] || return 1
}

readme_failed=0
lint_readme "$ROOT_DIR/README.md" zh || readme_failed=1
lint_readme "$ROOT_DIR/README_EN.md" en || readme_failed=1
if [[ "$readme_failed" -ne 0 ]]; then
  echo "readme workflow test failed: $FAILURES problem(s)" >&2
  exit 1
fi

# Self-check: removing one skill name from a temporary copy must fail the lint.
new_tmp_dir readme-workflow
cp "$ROOT_DIR/README.md" "$FIREFLY_TMP_DIR/README.md"
sed -i 's/`firefly retro`/`firefly zz-removed`/g' "$FIREFLY_TMP_DIR/README.md"
if lint_readme "$FIREFLY_TMP_DIR/README.md" zh; then
  echo "FAIL: lint passed although a skill name was removed" >&2
  exit 1
fi
echo "negative: blocked (missing skill name)"

echo "readme workflow test passed"

#!/usr/bin/env bash
# Option values are assigned by need()/may() through `printf -v`, which the
# linter cannot follow.
# shellcheck disable=SC2154

# firefly record — append one row to a firefly handoff carrier.
#
# An append-only recorder, not a scheduler: each call validates its input in
# full, then appends exactly one table row to the carrier named in the
# handoff contract (firefly/references/handoff-contract.md). Existing
# lines are never rewritten; the first column is the local ISO-8601 time. A
# section or table header that does not exist yet is created.
#
# Usage: firefly record <subcommand> [options]. `firefly record --help` lists
# every option, the accepted values and the rejection rules. Skills call this
# recorder; they never hand-write these rows. Carrier written by each:
#   mandate   openspec/changes/<id>/proposal.md "## Mandate"; with --global,
#             .superpowers/sdd/progress.md "## Mandates"
#   observe   openspec/changes/<id>/verification.md "## Observations"; the
#             candidate and spec columns identify the inputs fixed before the check
#   ready     openspec/changes/<id>/tasks.md "## Ready decision"
#   verdict   .superpowers/sdd/progress.md "## Review verdicts"
#   dispatch  .superpowers/sdd/progress.md "## Review dispatches"
#   budget    .superpowers/sdd/progress.md "## Repair budget"
#
# Exit codes: 0 recorded; 2 invalid input, nothing written; 3 an ACCEPT that
# carries a reservation touching required behavior, nothing written.

set -euo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROG='firefly record'
EXIT_INVALID=2
EXIT_INVALID_ACCEPT=3

VERDICTS=(ACCEPT REVISE RECHECK INSUFFICIENT_EVIDENCE)
RESULTS=(pass fail unverified not-applicable)
REVIEW_ROLES=(verifier reviewer implementer)
RESERVATION_KINDS=(unverified-item uncovered-input non-blocking-finding)

# Options each subcommand accepts. Anything else is rejected.
ALLOWED='
mandate:change global id objective effects terminal
observe:change scenario check result observer candidate spec implemented-by-observer evidence rule note
ready:change spec tasks reviewer verdict note
verdict:change package reviewer role scenarios verdict reservation
dispatch:change package role agent status reason handle work worktree
budget:change round scenario progress implementer note
'

# Options given on the command line as "name=value"; --reservation repeats,
# so its values are collected apart.
OPTS=()
RESERVATIONS=()
scope=()

refuse() {
  echo "$PROG: $1" >&2
  exit "$EXIT_INVALID"
}

usage() {
  cat <<'EOF'
Usage: firefly record <subcommand> [options]

Append one row to the carrier of a handoff fact. The input is validated in
full first; a rejected call writes nothing.

Subcommands:
  mandate  (--change <id> | --global) --id <text> --objective <text>
           --effects <text> --terminal <text>
  observe  --change <id> --scenario <S-xxx> --check <name>
           --result <pass|fail|unverified|not-applicable> --observer <role:name>
           --candidate <tree-sha> --spec <version>
           [--implemented-by-observer] [--evidence <path>] [--rule <text>] [--note <text>]
  ready    --change <id> --spec <ver> --tasks <ver> --reviewer <name>
           --verdict <value> [--note <text>]
  verdict  --change <id> --package <package identity> --reviewer <name> --role <role>
           --scenarios <ids> --verdict <value>
           [--reservation "<kind>:<text>:touches-required=<yes|no>"]...
  dispatch --change <id> --package <package identity> --role <role> --agent <name>
           --status <sent|started|returned|failed|obsolete> [--handle <id>] [--reason <text>]
           [--work <task-or-check-id> --worktree <absolute-path>]
  budget   --change <id> --round <n> --scenario <S-xxx> --progress <yes|no>
           [--implementer <name>] --note <text>

Values:
  verdict                   ACCEPT | REVISE | RECHECK | INSUFFICIENT_EVIDENCE
  role (verdict, dispatch)  verifier | reviewer | implementer
  observer                  <role>:<name>, the role being verifier | implementer | reviewer
  reservation kind          unverified-item | uncovered-input | non-blocking-finding
  observe --note            never omitted, though not enforced here: the conditions
                            observed under (environment, inputs, viewport), the expected
                            outcome the scenario map row named, and the check it named

Rejected with exit 2:
  - a value outside its list; an observer of the wrong form
  - a required option missing or empty; an option the subcommand does not take;
    an option given twice (except --reservation)
  - observe: pass or fail without --evidence naming an existing path,
    relative to the repository root or absolute; not-applicable without --rule
  - a --change without a directory openspec/changes/<id>
  - not inside a Git repository
  - a --round that is not a positive integer
  - a --reservation not of the form <kind>:<text>:touches-required=<yes|no>
  - a package identity, reviewer, agent, implementer or observer name that
    cannot go into a file name (a letter or digit, then letters, digits,
    . _ : @ + -)

Rejected with exit 3:
  - verdict ACCEPT carrying a reservation with touches-required=yes

An ACCEPT records its reservation list even when the list is empty ("none").
EOF
}

# ---- options ---------------------------------------------------------------
# Plain arrays and `printf -v`: no associative arrays, no `declare -g`.

in_set() {
  local needle="$1"
  local item
  shift
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

# opt_set <name> <value> — store a value; a second --<name> is a misuse.
opt_set() {
  local entry
  for entry in ${OPTS[@]+"${OPTS[@]}"}; do
    [[ "${entry%%=*}" != "$1" ]] || refuse "invalid usage: --${1//_/-} given more than once"
  done
  OPTS+=("$1=$2")
}

# may <option> <variable> — copy an optional value (empty when absent).
may() {
  local value=''
  value="$(opt_get "$1")" || value=''
  printf -v "$2" '%s' "$value"
}

# need <option> <variable> — copy a required, non-empty value, or refuse.
need() {
  local value=''
  value="$(opt_get "$1")" || refuse "$1 is required for $subcommand"
  [[ -n "$value" ]] || refuse "$1 is required for $subcommand"
  printf -v "$2" '%s' "$value"
}

# opt_get <name> — print the value; status 1 when the option was not given.
opt_get() {
  local entry
  for entry in ${OPTS[@]+"${OPTS[@]}"}; do
    if [[ "${entry%%=*}" == "$1" ]]; then
      printf '%s' "${entry#*=}"
      return 0
    fi
  done
  return 1
}

# ---- validation and computed columns --------------------------------------

# enum <field> <value> <allowed words...>
enum() {
  local field="$1"
  local value="$2"
  shift 2
  in_set "$value" "$@" || refuse "invalid $field: $value"
}

# file_name <field> <value> — a value that becomes part of a file name (the
# reviewer return is stored as verdict-<role>-<reviewer>.md).
file_name() {
  [[ "$2" =~ ^[A-Za-z0-9][A-Za-z0-9._:@+-]*$ ]] || refuse "invalid $1: $2"
}

# use_change <id> — require the change directory and set CHANGE_DIR.
use_change() {
  local id="$1"
  [[ "$id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && "$id" != archive && -d "$repo_root/openspec/changes/$id" ]] \
    || refuse "invalid change: $id"
  CHANGE_DIR="$repo_root/openspec/changes/$id"
  [[ ! -L "$repo_root/openspec" && ! -L "$repo_root/openspec/changes" && ! -L "$CHANGE_DIR" ]] ||
    refuse "refusing symlinked change path: $CHANGE_DIR"
}

# use_workspace — locate the progress ledger directory and set LEDGER, its
# progress.md. Creating .superpowers/sdd is the only side effect that may
# precede a write, so this is called after validation has passed.
use_workspace() {
  WORKSPACE="$("$SELF_DIR/sdd-workspace" 2>&1)" && { LEDGER="$WORKSPACE/progress.md"; return 0; }
  refuse "cannot use the progress ledger: ${WORKSPACE//$'\n'/ }"
}

# ---- writing ---------------------------------------------------------------

# cell <text> — make text safe inside one Markdown table cell.
cell() {
  local text="$1"
  text="${text//$'\r'/}"
  text="${text//$'\n'/ }"
  text="${text//|/\\|}"
  printf '%s' "$text"
}

# shellcheck source=record-markdown.sh
source "$SELF_DIR/record-markdown.sh"

# ---- main ------------------------------------------------------------------

subcommand="${1:-}"
case "$subcommand" in
  help|--help|-h)
    usage
    exit 0
    ;;
  mandate|observe|ready|verdict|dispatch|budget)
    shift
    ;;
  *)
    [[ -n "$subcommand" ]] || usage >&2
    refuse "unknown subcommand: ${subcommand:-<none>}"
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global|--implemented-by-observer)
      opt_set "${1#--}" yes
      shift
      ;;
    --reservation)
      [[ $# -ge 2 ]] || refuse "invalid option: --reservation needs a value"
      RESERVATIONS+=("$2")
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    # Every other long option takes a value; this branch must come last
    # among the "--" patterns. Which subcommand takes which option is decided
    # once, against ALLOWED, after the loop.
    --*)
      [[ $# -ge 2 ]] || refuse "invalid option: $1 needs a value"
      opt_set "${1#--}" "$2"
      shift 2
      ;;
    *)
      refuse "invalid option for $subcommand: $1"
      ;;
  esac
done

# An option the subcommand does not take is a mistake even when the call
# could otherwise proceed; an unknown option is caught the same way.
read -r -a scope <<< "$(printf '%s\n' "$ALLOWED" | sed -n "s/^$subcommand://p")"
for entry in ${OPTS[@]+"${OPTS[@]}"}; do
  in_set "${entry%%=*}" ${scope[@]+"${scope[@]}"} || refuse "invalid option for $subcommand: --${entry%%=*}"
done
if [[ ${#RESERVATIONS[@]} -gt 0 ]]; then
  in_set reservation ${scope[@]+"${scope[@]}"} || refuse "invalid option for $subcommand: --reservation"
fi

# Everything below may refuse, so it runs before anything is written.
repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || refuse "not a git repository"
stamp="$(date '+%Y-%m-%dT%H:%M:%S%z')"
# target stays "ledger" until a subcommand names another carrier; the
# ledger's path is known once the workspace resolves.
target=ledger
reservations=''

case "$subcommand" in
  mandate)
    if [[ "$(opt_get global || true)" == yes ]]; then
      if opt_get change >/dev/null; then
        refuse "invalid usage: --change and --global are mutually exclusive"
      fi
      heading='## Mandates'
    else
      need change change
      use_change "$change"
      target="$CHANGE_DIR/proposal.md"
      heading='## Mandate'
    fi
    for option in id objective effects terminal; do need "$option" "$option"; done
    row="| $(cell "$stamp") | $(cell "$id") | $(cell "$objective") | $(cell "$effects") | $(cell "$terminal") |"
    ;;
  observe)
    need change change
    use_change "$change"
    for option in scenario check result observer; do need "$option" "$option"; done
    enum result "$result" "${RESULTS[@]}"
    [[ "$observer" == *:* && -n "${observer%%:*}" && -n "${observer#*:}" ]] || refuse "invalid observer: $observer"
    file_name "observer name" "${observer#*:}"
    enum "observer role" "${observer%%:*}" verifier implementer reviewer
    may evidence evidence
    may rule rule
    may note note
    if [[ "$result" == pass || "$result" == fail ]]; then
      [[ -n "$evidence" ]] || refuse "evidence is required for observe when result is $result"
      [[ "$evidence" == /* ]] || evidence="$repo_root/$evidence"
      [[ -e "$evidence" ]] || refuse "invalid evidence: $evidence (not found)"
    fi
    if [[ "$result" == not-applicable && -z "$rule" ]]; then
      refuse "rule is required for observe when result is not-applicable"
    fi
    need candidate candidate
    need spec spec
    [[ "$candidate" =~ ^([0-9a-f]{40}|[0-9a-f]{64})$ &&
      "$(git -C "$repo_root" cat-file -t "$candidate" 2>/dev/null)" == tree ]] ||
      refuse "invalid candidate tree: $candidate"
    [[ "$spec" =~ ^(wt:)?[0-9a-f]{12}$ ]] || refuse "invalid spec version: $spec"
    implemented=no
    if [[ "$(opt_get implemented-by-observer || true)" == yes ]]; then
      implemented=yes
    fi
    row="| $(cell "$stamp") | $(cell "$scenario") | $(cell "$check") | $(cell "$candidate") | $(cell "spec:$spec") | $(cell "$observer") | $implemented | $(cell "$note") | $result | $(cell "${evidence#"$repo_root"/}") | $(cell "$rule") |"
    target="$CHANGE_DIR/verification.md"
    heading='## Observations'
    ;;
  ready)
    need change change
    use_change "$change"
    for option in spec tasks reviewer verdict; do need "$option" "$option"; done
    enum verdict "$verdict" "${VERDICTS[@]}"
    file_name reviewer "$reviewer"
    may note note
    row="| $(cell "$stamp") | $(cell "$spec") | $(cell "$tasks") | $(cell "$reviewer") | $(cell "$verdict") | $(cell "$note") |"
    target="$CHANGE_DIR/tasks.md"
    heading='## Ready decision'
    ;;
  verdict)
    need change change
    use_change "$change"
    for option in package reviewer role scenarios verdict; do need "$option" "$option"; done
    enum role "$role" "${REVIEW_ROLES[@]}"
    enum verdict "$verdict" "${VERDICTS[@]}"
    file_name package "$package"
    file_name reviewer "$reviewer"
    for reservation in ${RESERVATIONS[@]+"${RESERVATIONS[@]}"}; do
      kind="${reservation%%:*}"
      rest="${reservation#*:}"
      touches="${rest##*:touches-required=}"
      text="${rest%:touches-required=*}"
      in_set "$kind" "${RESERVATION_KINDS[@]}" && [[ "$rest" == *:touches-required=* && -n "$text" ]] \
        && in_set "$touches" yes no || refuse "invalid reservation: $reservation"
      if [[ "$verdict" == ACCEPT && "$touches" == yes ]]; then
        echo "$PROG: ACCEPT cannot carry a reservation that touches required behavior" >&2
        exit "$EXIT_INVALID_ACCEPT"
      fi
      reservations="${reservations:+$reservations; }$kind: $text (touches-required: $touches)"
    done
    # The reservation list is part of every acceptance, empty or not.
    [[ "$verdict" != ACCEPT ]] || reservations="${reservations:-none}"
    row="| $(cell "$stamp") | $(cell "$package") | $(cell "$reviewer") | $(cell "$role") | $(cell "$scenarios") | $(cell "$verdict") | $(cell "$reservations") |"
    heading='## Review verdicts'
    ;;
  dispatch)
    need change change
    use_change "$change"
    for option in package role agent status; do need "$option" "$option"; done
    enum role "$role" "${REVIEW_ROLES[@]}"
    enum status "$status" sent started returned failed obsolete
    file_name package "$package"
    file_name agent "$agent"
    for option in reason handle work worktree; do may "$option" "$option"; done
    if [[ "$status" == started ]]; then
      [[ -n "$handle" ]] || refuse "handle is required for a started dispatch"
      reason="host handle: $handle${reason:+ ($reason)}"
    elif [[ -n "$handle" ]]; then
      refuse "handle is only valid for a started dispatch"
    fi
    if [[ -n "$work$worktree" ]]; then
      [[ "$status" == sent && -n "$work" && "$worktree" == /* ]] ||
        refuse "work and an absolute worktree are required together on a sent dispatch"
      reason="work: $work; worktree: $worktree${reason:+; $reason}"
    fi
    row="| $(cell "$stamp") | $(cell "$package") | $(cell "$role") | $(cell "$agent") | $(cell "$status") | $(cell "$reason") |"
    heading='## Review dispatches'
    ;;
  budget)
    need change change
    use_change "$change"
    for option in round scenario progress; do need "$option" "$option"; done
    [[ "$round" =~ ^[1-9][0-9]*$ ]] || refuse "invalid round: $round"
    enum progress "$progress" yes no
    may implementer implementer
    [[ -z "$implementer" ]] || file_name implementer "$implementer"
    need note note
    row="| $(cell "$stamp") | $(cell "$round") | $(cell "$scenario") | $(cell "$progress") | $(cell "$implementer") | $(cell "$note") |"
    heading='## Repair budget'
    ;;
esac

# The ledger lives in the workspace directory, which this may create.
if [[ "$target" == ledger ]]; then
  use_workspace
  target="$LEDGER"
fi

case "$heading" in
  '## Mandate'|'## Mandates') header='| Time | Mandate id | Objective | Permitted effects | Terminal condition |' ;;
  '## Observations') header='| Time | Scenario | Check | Candidate | Spec | Observer | Implemented by observer | Conditions | Status | Evidence | Rule |' ;;
  '## Ready decision') header='| Time | Spec version | Tasks version | Reviewer | Verdict | Note |' ;;
  '## Review verdicts') header='| Time | Package | Reviewer | Role | Scenarios | Verdict | Reservations |' ;;
  '## Review dispatches') header='| Time | Package | Role | Agent | Status | Reason |' ;;
  '## Repair budget') header='| Time | Round | Scenario | Progress | Implementer | Note |' ;;
esac

append_row "$target" "$heading" "$header" "$row"
printf 'recorded %s in %s\n' "$subcommand" "${target#"$repo_root"/}"

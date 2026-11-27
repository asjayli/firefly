#!/usr/bin/env bash
# Lint the standalone entry and the bundled capability guides.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SKILL_ROOT="$ROOT_DIR/firefly"
SKILLS_ROOT="$SKILL_ROOT/references/abilities"
CONTRACTS_ROOT="${FIREFLY_CONTRACTS_ROOT:-$ROOT_DIR/tests/contracts}"

V2_VERSION='2.0'
MAX_LINES=500
REQUIRED_SECTIONS=('When to use' 'When not to use' 'Mandate' 'Inputs' 'Procedure' 'Outputs' 'Handoffs' 'Stop and escalate')
RETIRED_SKILLS=(requesting-code-review subagent-driven-development executing-plans writing-plans brainstorming test-driven-development openspec-sync-specs firefly-doctor)
# The two ~ entries are literal text to search for, not paths to expand.
# shellcheck disable=SC2088
PLATFORM_LITERALS=('~/.claude' '~/.codex' '`Task`' spawn_agent wait_agent AskUserQuestion TodoWrite)
ANCHOR_TAGS=(trigger mandate input output verdict-or-state handoff stop)

FAILURES=()

fail() {
  local skill="$1"
  local rule="$2"
  local detail="$3"
  echo "FAIL $skill $rule: $detail" >&2
  FAILURES+=("$skill $rule")
}

trim() {
  local text="$1"
  text="${text#"${text%%[![:space:]]*}"}"
  text="${text%"${text##*[![:space:]]}"}"
  printf '%s\n' "$text"
}

# Print $1 without one pair of surrounding quotes.
strip_quotes() {
  local value="$1"
  case "$value" in
    \"*\"|\'*\') value="${value#?}"; value="${value%?}" ;;
  esac
  printf '%s\n' "$value"
}

# Print the frontmatter block of $1 (empty when the file has none). It reads
# the file directly, so stopping at the closing marker is safe here.
read_frontmatter() {
  awk 'NR == 1 { if ($0 == "---") inside = 1; next } inside && $0 == "---" { exit } inside { print }' "$1"
}

# fm_scalar <frontmatter> <key> — print the scalar value of a top-level or
# one-level nested ("metadata.version") key, quotes kept; empty when absent.
fm_scalar() {
  local block="$1"
  local key="$2"
  local parent=''
  local child="$key"
  if [[ "$key" == *.* ]]; then
    parent="${key%%.*}"
    child="${key#*.}"
  fi
  # The awk programs below read their whole input instead of exiting early:
  # a consumer that exits first can race the `printf` on the other side of
  # the pipe into SIGPIPE (exit 141), which `set -e -o pipefail` turns into a
  # random lint failure.
  printf '%s\n' "$block" | awk -v parent="$parent" -v child="$child" '
    found { next }
    parent != "" {
      if ($0 == parent ":") { in_parent = 1; next }
      if ($0 ~ /^[^[:space:]]/) in_parent = 0
      if (!in_parent) next
      if (match($0, "^  " child ":")) { value = substr($0, RSTART + RLENGTH); found = 1 }
      next
    }
    { if (match($0, "^" child ":")) { value = substr($0, RSTART + RLENGTH); found = 1 } }
    END {
      if (found) { sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); print value }
    }
  '
}

# fm_present <frontmatter> <key> — true when the key has a value on its own
# line or an indented block on the following lines.
fm_present() {
  printf '%s\n' "$1" | awk -v key="$2" '
    found { next }
    $0 == key ":" { block = 1; next }
    block && /^[[:space:]]+[^[:space:]]/ { found = 1; next }
    block && !/^[[:space:]]+[^[:space:]]/ { block = 0; next }
    index($0, key ":") == 1 {
      rest = substr($0, length(key) + 2)
      if (rest ~ /[^[:space:]]/) found = 1
    }
    END { exit found ? 0 : 1 }
  '
}

# Print the second-level headings of $1 in file order, without the marker.
h2_titles() {
  sed -n -E 's/^## (.*)$/\1/p' "$1"
}

# Print $1 with HTML comments removed, so a provenance note may name a
# retired skill without the skill text "referencing" it.
strip_html_comments() {
  awk '
    {
      if (in_comment) {
        e = index($0, "-->")
        if (e == 0) next
        $0 = substr($0, e + 3)
        in_comment = 0
      }
      while ((s = index($0, "<!--")) > 0) {
        e = index(substr($0, s), "-->")
        if (e == 0) { $0 = substr($0, 1, s - 1); in_comment = 1; break }
        $0 = substr($0, 1, s - 1) substr($0, s + e + 2)
      }
      print
    }
  ' "$1"
}

# skill_text <skill-dir> — print SKILL.md followed by every references/*.md.
skill_text() {
  local dir="$1"
  local ref guide="$2"
  [[ -f "$guide" ]] || return 1
  cat "$guide"
  for ref in "$dir"/references/*.md; do
    [[ -f "$ref" ]] && cat "$ref"
  done
  return 0
}

in_list() {
  local needle="$1"
  local item
  shift
  for item in "$@"; do
    [[ "$item" == "$needle" ]] && return 0
  done
  return 1
}

# lint_basic <skill> <dir>
lint_basic() {
  local skill="$1"
  local dir="$2"
  local fm name file="$3"
  [[ -f "$file" ]] || { fail "$skill" basic "missing SKILL.md"; return 0; }
  fm="$(read_frontmatter "$file")"
  [[ -n "$fm" ]] || { fail "$skill" basic "SKILL.md has no frontmatter"; return 0; }
  name="$(strip_quotes "$(fm_scalar "$fm" name)")"
  [[ -n "$name" ]] || fail "$skill" basic "frontmatter has no name"
  [[ "$name" == "$skill" ]] || fail "$skill" basic "name ($name) differs from the directory name"
  fm_present "$fm" description || fail "$skill" basic "frontmatter has no description"
}

# lint_v2 <skill> <dir> <frontmatter>
lint_v2() {
  local skill="$1"
  local dir="$2"
  local fm="$3"
  local file text listing want idx last license author design
  local guide="$4"
  local literal retired

  license="$(strip_quotes "$(fm_scalar "$fm" license)")"
  [[ "$license" == 'MIT' ]] || fail "$skill" frontmatter "license must be MIT, got: ${license:-<none>}"
  author="$(strip_quotes "$(fm_scalar "$fm" metadata.author)")"
  [[ "$author" == 'firefly' ]] || fail "$skill" frontmatter "metadata.author must be firefly, got: ${author:-<none>}"
  design="$(strip_quotes "$(fm_scalar "$fm" metadata.design)")"
  [[ "$design" =~ ^[0-9]{2}(,[0-9]{2})?$ ]] || fail "$skill" frontmatter "metadata.design must be NN or NN,MM, got: ${design:-<none>}"

  listing="$(h2_titles "$guide")"
  last=0
  for want in "${REQUIRED_SECTIONS[@]}"; do
    idx="$(printf '%s\n' "$listing" | awk -v title="$want" '$0 == title && !found { print NR; found = 1 }')"
    if [[ -z "$idx" ]]; then
      fail "$skill" sections "missing heading: ## $want"
      continue
    fi
    if [[ "$idx" -le "$last" ]]; then
      fail "$skill" sections "heading out of order: ## $want"
    fi
    last="$idx"
  done

  while IFS= read -r file; do
    [[ "$file" == *.md ]] || continue
    text="$(strip_html_comments "$file")"
    if [[ "$text" == *APPROVE* ]]; then
      fail "$skill" terms "retired verdict word in ${file#"$dir"/}"
    fi
    for retired in "${RETIRED_SKILLS[@]}"; do
      if [[ "$text" == *"$retired"* ]]; then
        fail "$skill" retired-names "references retired skill $retired in ${file#"$dir"/}"
      fi
    done
    for literal in "${PLATFORM_LITERALS[@]}"; do
      if [[ "$text" == *"$literal"* ]]; then
        fail "$skill" platform-neutral "platform literal $literal in ${file#"$dir"/}; use a platform token"
      fi
    done
  done < <(find "$dir" -type f | LC_ALL=C sort)

  while IFS= read -r file; do
    if [[ "$(awk 'END { print NR }' "$file")" -gt "$MAX_LINES" ]]; then
      fail "$skill" line-limit "${file#"$dir"/} exceeds $MAX_LINES lines"
    fi
  done < <(find "$dir" -type f | LC_ALL=C sort)
}

# lint_anchors <skill> <dir> <frontmatter>
lint_anchors() {
  local skill="$1"
  local fm="$3" guide="$4"
  local file="$CONTRACTS_ROOT/$skill.txt"
  [[ -f "$file" ]] || return 0
  local declared='' design line rest tag phrase text
  local plus=()
  local minus=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="$(trim "$line")"
    [[ -z "$line" || "$line" == '#'* ]] && continue
    if [[ "$line" == '@design '* ]]; then
      declared="${line#@design }"
    elif [[ "$line" == '+'* ]]; then
      rest="${line#+}"
      if [[ "$rest" != *': '* ]]; then
        fail "$skill" anchors "malformed line: $line"
        continue
      fi
      tag="${rest%%: *}"
      phrase="${rest#*: }"
      if ! in_list "$tag" "${ANCHOR_TAGS[@]}"; then
        fail "$skill" anchors "unknown tag in: $line"
        continue
      fi
      [[ -n "$phrase" ]] || { fail "$skill" anchors "empty phrase in: $line"; continue; }
      plus+=("$tag"$'\t'"$phrase")
    elif [[ "$line" == '-: '* ]]; then
      minus+=("${line#-: }")
    else
      fail "$skill" anchors "malformed line: $line"
    fi
  done < "$file"

  design="$(strip_quotes "$(fm_scalar "$fm" metadata.design)")"
  if [[ -n "$declared" && -n "$design" && "$declared" != "$design" ]]; then
    fail "$skill" anchors "@design $declared differs from metadata.design $design"
  fi

  text="$(skill_text "$2" "$guide")"
    for phrase in ${minus[@]+"${minus[@]}"}; do
      if [[ "$text" == *"$phrase"* ]]; then
        fail "$skill" anchors "forbidden phrase present: $phrase"
      fi
    done
    for line in ${plus[@]+"${plus[@]}"}; do
      phrase="${line#*$'\t'}"
      if [[ "$text" != *"$phrase"* ]]; then
        fail "$skill" anchors "required phrase missing: $phrase"
      fi
    done
}

# lint_skill <dir>
lint_skill() {
  local dir="$1"
  local skill fm version before file="$2"
  skill="$(basename "$dir")"
  before=${#FAILURES[@]}
  lint_basic "$skill" "$dir" "$file"
  [[ -f "$file" ]] || return 0
  fm="$(read_frontmatter "$file")"
  version="$(strip_quotes "$(fm_scalar "$fm" metadata.version)")"
  if [[ "$version" == "$V2_VERSION" ]]; then
    lint_v2 "$skill" "$dir" "$fm" "$file"
  fi
  lint_anchors "$skill" "$dir" "$fm" "$file"
  if [[ ${#FAILURES[@]} -eq "$before" ]]; then
    echo "ok $skill"
  fi
}

# Every firefly-* skill under shared is migrated to v2.
# Every anchor file covers all seven tags.
lint_pins_complete() {
  local dir skill file tag
  for dir in "$SKILLS_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    skill="$(basename "$dir")"
    [[ "$skill" == firefly* ]] || continue
    file="$CONTRACTS_ROOT/$skill.txt"
    [[ -f "$file" ]] || { fail "$skill" pins-complete "no anchor file at $file"; continue; }
    for tag in "${ANCHOR_TAGS[@]}"; do
      grep -qE "^\+$tag: " "$file" || fail "$skill" pins "pins incomplete: $skill missing $tag"
    done
  done
}

# Route coverage: every firefly-* skill directory must be named as
# `firefly <name>` in the controller's ## Commands section, and every
# skill-like reference there must correspond to a directory.
lint_route_coverage() {
  local controller="$SKILL_ROOT/SKILL.md"
  [[ -f "$controller" ]] || return 0
  local dir name
  local -a dirs=()
  for dir in "$SKILLS_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    [[ "$name" == firefly-* ]] && dirs+=("${name#firefly-}")
  done
  # Restrict to the ## Commands section.
  local commands
  commands="$(awk '/^## Commands$/{flag=1;next} /^## /{flag=0} flag' "$controller")"
  local ref
  local -A named=()
  while IFS= read -r ref; do
    named["$ref"]=1
  done < <(grep -oE '`firefly [a-z][a-z0-9-]+' <<<"$commands" | sed 's/^`firefly //' | sort -u)
  local -A dirset=()
  for name in "${dirs[@]}"; do dirset["$name"]=1; done
  for name in "${dirs[@]}"; do
    [[ "${named[$name]:-}" == 1 ]] || fail firefly route-coverage "skill directory firefly-$name is not named in ## Commands"
  done
  local runtime=' next init doctor config repair validate tasks diagram snapshot record new list show status spec '
  for ref in "${!named[@]}"; do
    [[ "${dirset[$ref]:-}" == 1 ]] && continue
    [[ "$runtime" == *" $ref "* ]] && continue
    fail firefly route-coverage "## Commands names 'firefly $ref' but the guide firefly-$ref does not exist"
  done
}

lint_all() {
  local dir
  lint_skill "$SKILL_ROOT" "$SKILL_ROOT/SKILL.md"
  for dir in "$SKILLS_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    case "$(basename "$dir")" in
      firefly-*) lint_skill "$dir" "$dir/guide.md" ;;
    esac
  done
  lint_route_coverage
  lint_pins_complete
  if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo "skill contracts: ${#FAILURES[@]} failed rule(s)" >&2
    return 1
  fi
  echo "skill contracts: all skills pass"
}

lint_all

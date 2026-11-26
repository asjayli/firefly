#!/usr/bin/env bash
# Skill structure lint and contract anchors.
#
# Lints every firefly-* skill under assets/shared/skills/ and applies the
# anchor file tests/contracts/<skill>.txt, when present, to both rendered
# platform copies (format: tests/contracts/README.md).
#
#   basic     every skill: frontmatter with name and description; name equals
#             the directory name.
#   v2        skills whose frontmatter has metadata.version "2.0":
#             frontmatter fields, fixed section order, vocabulary, retired
#             skill names, platform neutrality, line limit.
#   anchors   + / - entries of the anchor file against the rendered copies.
#
# A skill that passes every rule prints "ok <skill>". A failed rule prints
# "FAIL <skill> <rule>: <detail>" on stderr and the script exits 1.
#
# FIREFLY_SKILLS_ROOT, FIREFLY_RENDERED_ROOT and FIREFLY_CONTRACTS_ROOT point
# the lint at a temporary tree, which is how this test checks its own rules:
# each rule gets a bad skill that it must block (FIREFLY_LINT_ONLY=1 runs the
# lint alone, without that self-check).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"

SKILLS_ROOT="${FIREFLY_SKILLS_ROOT:-$ROOT_DIR/assets/shared/skills}"
RENDERED_ROOT="${FIREFLY_RENDERED_ROOT:-$ROOT_DIR/assets}"
CONTRACTS_ROOT="${FIREFLY_CONTRACTS_ROOT:-$ROOT_DIR/tests/contracts}"
PLATFORMS=(codex claude)

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
  local ref
  [[ -f "$dir/SKILL.md" ]] || return 1
  cat "$dir/SKILL.md"
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
  local fm name
  [[ -f "$dir/SKILL.md" ]] || { fail "$skill" basic "missing SKILL.md"; return 0; }
  fm="$(read_frontmatter "$dir/SKILL.md")"
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
  local literal retired

  license="$(strip_quotes "$(fm_scalar "$fm" license)")"
  [[ "$license" == 'MIT' ]] || fail "$skill" frontmatter "license must be MIT, got: ${license:-<none>}"
  author="$(strip_quotes "$(fm_scalar "$fm" metadata.author)")"
  [[ "$author" == 'firefly' ]] || fail "$skill" frontmatter "metadata.author must be firefly, got: ${author:-<none>}"
  design="$(strip_quotes "$(fm_scalar "$fm" metadata.design)")"
  [[ "$design" =~ ^[0-9]{2}(,[0-9]{2})?$ ]] || fail "$skill" frontmatter "metadata.design must be NN or NN,MM, got: ${design:-<none>}"

  listing="$(h2_titles "$dir/SKILL.md")"
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
  local fm="$3"
  local file="$CONTRACTS_ROOT/$skill.txt"
  [[ -f "$file" ]] || return 0
  local declared='' design line rest tag phrase platform platform_dir text
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

  for platform in "${PLATFORMS[@]}"; do
    platform_dir="$RENDERED_ROOT/$platform/skills/$skill"
    if ! text="$(skill_text "$platform_dir")"; then
      fail "$skill" "anchor-$platform" "missing rendered copy: $platform_dir"
      continue
    fi
    for phrase in ${minus[@]+"${minus[@]}"}; do
      if [[ "$text" == *"$phrase"* ]]; then
        fail "$skill" "anchor-$platform" "forbidden phrase present: $phrase"
      fi
    done
    for line in ${plus[@]+"${plus[@]}"}; do
      phrase="${line#*$'\t'}"
      if [[ "$text" != *"$phrase"* ]]; then
        fail "$skill" "anchor-$platform" "required phrase missing: $phrase"
      fi
    done
  done
}

# lint_skill <dir>
lint_skill() {
  local dir="$1"
  local skill fm version before
  skill="$(basename "$dir")"
  before=${#FAILURES[@]}
  lint_basic "$skill" "$dir"
  [[ -f "$dir/SKILL.md" ]] || return 0
  fm="$(read_frontmatter "$dir/SKILL.md")"
  version="$(strip_quotes "$(fm_scalar "$fm" metadata.version)")"
  if [[ "$version" == "$V2_VERSION" ]]; then
    lint_v2 "$skill" "$dir" "$fm"
  fi
  # FIREFLY_SKIP_ANCHORS=1 leaves out the anchor file and the rendered copies,
  # so a skill can be checked on its source alone before it is rendered.
  if [[ "${FIREFLY_SKIP_ANCHORS:-}" != 1 ]]; then
    lint_anchors "$skill" "$dir" "$fm"
  fi
  if [[ ${#FAILURES[@]} -eq "$before" ]]; then
    echo "ok $skill"
  fi
}

# Every firefly-* skill under shared is migrated to v2.
# Every anchor file covers all seven tags.
lint_pins_complete() {
  local skill file tag
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

# references/<file>.md cited by a skill must exist beside it.
lint_references_resolve() {
  local dir file ref full
  for dir in "$SKILLS_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    [[ -f "$dir/SKILL.md" ]] || continue
    while IFS= read -r full; do
    # firefly/references/<file>.md is the shared contract installed
    # under the runtime firefly home, not a skill-local reference.
    case "$full" in
      firefly/references/*) continue ;;
      *) ref="$full" ;;
    esac
      [[ -f "$dir/$ref" ]] || fail "$(basename "$dir")" references "$ref is cited but does not exist"
    done < <(grep -oE "(firefly/)?references/[A-Za-z0-9._-]+\.md" "$dir/SKILL.md" | sort -u)
  done
}
lint_no_unmigrated() {
  local dir version fm
  for dir in "$SKILLS_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    case "$(basename "$dir")" in
      firefly-*) ;;
      *) continue ;;
    esac
    fm="$(read_frontmatter "$dir/SKILL.md" 2>/dev/null || true)"
    version="$(strip_quotes "$(fm_scalar "$fm" metadata.version)")"
    [[ "$version" == "$V2_VERSION" ]] || fail "$(basename "$dir")" unmigrated "metadata.version is not \"$V2_VERSION\""
  done
}

# The whole shared tree stays platform-neutral: no platform literal may
# appear outside a token placeholder.
lint_shared_neutral() {
  local file text
  while IFS= read -r file; do
    text="$(strip_html_comments "$file")"
    local lit
    # shellcheck disable=SC2088  # the tildes are literal platform strings to find
    for lit in '~/.claude' '~/.codex' 'AskUserQuestion' 'TodoWrite' 'spawn_agent' 'wait_agent' 'list_agents'; do
      if [[ "$text" == *"$lit"* ]]; then
        fail shared shared-neutral "platform literal $lit in ${file#"$ROOT_DIR"/}"
      fi
    done
  done < <(find "$ROOT_DIR/assets/shared" -type f | LC_ALL=C sort)
}

# Every rendered skill directory must be registered: shared (rendered copy) or
# platformSpecific (hand-kept per platform).
lint_no_stale_copies() {
  local platform dir name config
  config="$(cat "$ROOT_DIR/manifests/platform-assets.json")"
  for platform in claude codex; do
    for dir in "$ROOT_DIR/assets/$platform/skills"/*/; do
      [[ -d "$dir" ]] || continue
      name="$(basename "$dir")"
      if [[ "$config" != *"\"skills/$name\""* ]]; then
        fail "$name" stale-copies "assets/$platform/skills/$name is registered in neither shared nor platformSpecific"
      fi
    done
  done
}

# Route coverage: every firefly-* skill directory must be named as
# `firefly <name>` in the controller's ## Commands section, and every
# skill-like reference there must correspond to a directory.
lint_route_coverage() {
  local controller="$SKILLS_ROOT/firefly/SKILL.md"
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
  local runtime=' next init doctor repair validate tasks diagram snapshot record '
  for ref in "${!named[@]}"; do
    [[ "${dirset[$ref]:-}" == 1 ]] && continue
    [[ "$runtime" == *" $ref "* ]] && continue
    fail firefly route-coverage "## Commands names 'firefly $ref' but assets/shared/skills/firefly-$ref does not exist"
  done
}

lint_all() {
  local dir
  for dir in "$SKILLS_ROOT"/*/; do
    [[ -d "$dir" ]] || continue
    case "$(basename "$dir")" in
      firefly | firefly-*) lint_skill "$dir" ;;
    esac
  done
  lint_route_coverage
  lint_shared_neutral
  lint_no_stale_copies
  lint_no_unmigrated
  lint_pins_complete
  lint_references_resolve
  if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo "skill contracts: ${#FAILURES[@]} failed rule(s)" >&2
    return 1
  fi
  echo "skill contracts: all skills pass"
  echo "rules: frontmatter sections line-limit terms retired-names platform-neutral anchors route-coverage shared-neutral stale-copies unmigrated pins references-resolve"
}

if [[ "${FIREFLY_LINT_ONLY:-}" == '1' ]]; then
  lint_all
  exit $?
fi

# 1. The real tree.
lint_all

# 2. Self-check: each v2 and anchor rule must block a bad skill. Every bad
#    skill is linted alone in its own temporary tree.
# write_skill <tree> <skill-name> <missing-section>
# Writes one otherwise valid v2 skill, with all eight sections except the
# missing one, to the tree's shared source and both rendered copies.
write_skill() {
  local tree="$1"
  local name="$2"
  local skip="$3"
  local dir="$tree/shared/skills/$name"
  local section platform
  mkdir -p "$dir"
  {
    echo '---'
    echo "name: $name"
    echo 'description: Self-check skill for the structure lint.'
    echo 'license: MIT'
    echo 'metadata:'
    echo '  author: firefly'
    echo "  version: \"$V2_VERSION\""
    echo '  design: "01"'
    echo '---'
    echo
    for section in "${REQUIRED_SECTIONS[@]}"; do
      if [[ "$section" != "$skip" ]]; then
        echo "## $section"
        echo
        echo "Body of $section."
        echo
      fi
    done
  } > "$dir/SKILL.md"
  for platform in "${PLATFORMS[@]}"; do
    mkdir -p "$tree/render/$platform/skills/$name"
    cp "$dir/SKILL.md" "$tree/render/$platform/skills/$name/SKILL.md"
  done
}

# expect_blocked <tree> <skill-name> <rule> — lint the tree and require a
# "FAIL <skill-name> <rule>:" line and a non-zero exit.
expect_blocked() {
  local tree="$1"
  local skill="$2"
  local rule="$3"
  local out status
  out="$tree/out.txt"
  set +e
  FIREFLY_LINT_ONLY=1 FIREFLY_SKILLS_ROOT="$tree/shared/skills" FIREFLY_RENDERED_ROOT="$tree/render" \
    FIREFLY_CONTRACTS_ROOT="$tree/contracts" bash "$ROOT_DIR/tests/test-skill-contracts.sh" >"$out" 2>&1
  status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    echo "FAIL: rule '$rule' did not block the bad skill '$skill'" >&2
    cat "$out" >&2
    exit 1
  fi
  if ! grep -Fq -- "FAIL $skill $rule: " "$out"; then
    echo "FAIL: rule '$rule' did not report '$skill' (exit $status); lint output follows" >&2
    cat "$out" >&2
    exit 1
  fi
  echo "negative: blocked ($rule)"
}

# pins complete: removing the only +stop anchor of a skill must fail.
new_tmp_dir skill-contracts
tree="$FIREFLY_TMP_DIR"
cp -r "$ROOT_DIR/tests/contracts" "$tree/contracts"
sed -i '/^\+stop: /d' "$tree/contracts/firefly-retro.txt"
out="$tree/out.txt"
set +e
FIREFLY_LINT_ONLY=1 FIREFLY_CONTRACTS_ROOT="$tree/contracts" bash "$ROOT_DIR/tests/test-skill-contracts.sh" >"$out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]] || ! grep -Fq "pins incomplete: firefly-retro missing stop" "$out"; then
  echo "FAIL: rule 'pins' did not block (exit $status)" >&2; cat "$out" >&2; exit 1
fi
echo "negative: blocked (pins)"

# references resolve: citing a missing references/x.md must fail.
new_tmp_dir skill-contracts
tree="$FIREFLY_TMP_DIR"
mkdir -p "$tree/shared/skills/firefly-zz-badref" "$tree/contracts" "$tree/render/claude/skills/firefly-zz-badref" "$tree/render/codex/skills/firefly-zz-badref"
cat > "$tree/shared/skills/firefly-zz-badref/SKILL.md" <<'ZZ'
---
name: firefly-zz-badref
description: placeholder
license: MIT
metadata:
  author: firefly
  version: "2.0"
  design: "99"
---

## When to use
## When not to use
## Mandate
## Inputs
## Procedure
See references/x.md.
## Outputs
## Handoffs
## Stop and escalate
ZZ
for pl in claude codex; do cp "$tree/shared/skills/firefly-zz-badref/SKILL.md" "$tree/render/$pl/skills/firefly-zz-badref/SKILL.md"; done
printf '%s\n' '@design 99' '+trigger: placeholder' > "$tree/contracts/firefly-zz-badref.txt"
out="$tree/out.txt"
set +e
FIREFLY_LINT_ONLY=1 FIREFLY_SKILLS_ROOT="$tree/shared/skills" FIREFLY_RENDERED_ROOT="$tree/render" FIREFLY_CONTRACTS_ROOT="$tree/contracts" bash "$ROOT_DIR/tests/test-skill-contracts.sh" >"$out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]] || ! grep -Fq "references/x.md is cited but does not exist" "$out"; then
  echo "FAIL: rule 'references' did not block (exit $status)" >&2; cat "$out" >&2; exit 1
fi
echo "negative: blocked (references)"
# no unmigrated skill: a firefly-zz directory without metadata.version fails.
new_tmp_dir skill-contracts
tree="$FIREFLY_TMP_DIR"
mkdir -p "$tree/shared/skills/firefly-zz-unmigrated" "$tree/contracts" \
  "$tree/render/claude/skills/firefly-zz-unmigrated" "$tree/render/codex/skills/firefly-zz-unmigrated"
cat > "$tree/shared/skills/firefly-zz-unmigrated/SKILL.md" <<'ZZ'
---
name: firefly-zz-unmigrated
description: placeholder
---

## When to use
## When not to use
## Mandate
## Inputs
## Procedure
## Outputs
## Handoffs
## Stop and escalate
ZZ
for pl in claude codex; do cp "$tree/shared/skills/firefly-zz-unmigrated/SKILL.md" "$tree/render/$pl/skills/firefly-zz-unmigrated/SKILL.md"; done
cat > "$tree/contracts/firefly-zz-unmigrated.txt" <<'ZZ'
@design 99
+trigger: placeholder
ZZ
out="$tree/out.txt"
set +e
FIREFLY_LINT_ONLY=1 FIREFLY_SKILLS_ROOT="$tree/shared/skills" FIREFLY_RENDERED_ROOT="$tree/render" FIREFLY_CONTRACTS_ROOT="$tree/contracts" bash "$ROOT_DIR/tests/test-skill-contracts.sh" >"$out" 2>&1
status=$?
set -e
if [[ "$status" -eq 0 ]] || ! grep -Eq 'FAIL firefly-zz-unmigrated unmigrated: ' "$out"; then
  echo "FAIL: rule 'unmigrated' did not block (exit $status)" >&2; cat "$out" >&2; exit 1
fi
echo "negative: blocked (unmigrated)"

# shared is platform-neutral: a literal AskUserQuestion in a shared file must fail.
new_tmp_dir skill-contracts
tree="$FIREFLY_TMP_DIR"
expect_tree_blocked() {
  local tree="$1" rule="$2" out status
  out="$tree/out.txt"
  set +e
  FIREFLY_LINT_ONLY=1 bash "$ROOT_DIR/tests/test-skill-contracts.sh" >"$out" 2>&1
  status=$?
  set -e
  if [[ "$status" -eq 0 ]] || ! grep -Eq "FAIL [a-z-]+ $rule: " "$out"; then
    echo "FAIL: rule '$rule' did not block (exit $status); lint output follows" >&2
    cat "$out" >&2
    exit 1
  fi
  echo "negative: blocked ($rule)"
}
printf 'Use the AskUserQuestion tool here.\n' >> "$ROOT_DIR/assets/shared/skills/firefly-retro/SKILL.md"
expect_tree_blocked "$tree" shared-neutral
python3 - "$ROOT_DIR/assets/shared/skills/firefly-retro/SKILL.md" <<'PY'
import sys
path = sys.argv[1]
lines = [l for l in open(path).read().split('\n') if 'AskUserQuestion tool here' not in l]
open(path, 'w').write('\n'.join(lines))
PY

# no stale platform copies: an unregistered directory under rendered skills fails.
mkdir -p "$ROOT_DIR/assets/claude/skills/firefly-zz-stale" "$ROOT_DIR/assets/codex/skills/firefly-zz-stale"
expect_tree_blocked "$tree" stale-copies
rmdir "$ROOT_DIR/assets/claude/skills/firefly-zz-stale" "$ROOT_DIR/assets/codex/skills/firefly-zz-stale"

# Route coverage: the controller's ## Commands must name every skill.
new_tmp_dir skill-contracts
tree="$FIREFLY_TMP_DIR"
mkdir -p "$tree/shared/skills" "$tree/contracts" "$tree/render/claude/skills/firefly" "$tree/render/codex/skills/firefly"
cp -r "$ROOT_DIR/assets/shared/skills/firefly" "$tree/shared/skills/firefly"
cp -r "$ROOT_DIR/assets/shared/skills/firefly-retro" "$tree/shared/skills/"
cp -r "$ROOT_DIR/assets/shared/skills/firefly-trace" "$tree/shared/skills/"
sed -i '/^- `firefly retro`/d' "$tree/shared/skills/firefly/SKILL.md"
cp "$tree/shared/skills/firefly/SKILL.md" "$tree/render/claude/skills/firefly/SKILL.md"
cp "$tree/shared/skills/firefly/SKILL.md" "$tree/render/codex/skills/firefly/SKILL.md"
expect_blocked "$tree" firefly route-coverage

# A v2 skill without the Mandate section.
new_tmp_dir skill-contracts
tree="$FIREFLY_TMP_DIR"
write_skill "$tree" firefly-zz-no-mandate 'Mandate'
expect_blocked "$tree" firefly-zz-no-mandate sections

# A v2 skill with a 501-line reference file.
new_tmp_dir skill-contracts
tree="$FIREFLY_TMP_DIR"
write_skill "$tree" firefly-zz-long-file ''
mkdir -p "$tree/shared/skills/firefly-zz-long-file/references" \
  "$tree/render/claude/skills/firefly-zz-long-file/references" "$tree/render/codex/skills/firefly-zz-long-file/references"
for ((i = 1; i <= 501; i += 1)); do
  echo "line $i"
done > "$tree/shared/skills/firefly-zz-long-file/references/long.md"
cp "$tree/shared/skills/firefly-zz-long-file/references/long.md" "$tree/render/claude/skills/firefly-zz-long-file/references/long.md"
cp "$tree/shared/skills/firefly-zz-long-file/references/long.md" "$tree/render/codex/skills/firefly-zz-long-file/references/long.md"
expect_blocked "$tree" firefly-zz-long-file line-limit

# A v2 skill whose text uses the retired verdict word.
new_tmp_dir skill-contracts
tree="$FIREFLY_TMP_DIR"
write_skill "$tree" firefly-zz-approve ''
printf '\nReturn APPROVE when green.\n' >> "$tree/shared/skills/firefly-zz-approve/SKILL.md"
expect_blocked "$tree" firefly-zz-approve terms

# A clean v2 skill whose rendered Claude copy was edited to carry the retired
# verdict word: only the anchor file can catch that.
new_tmp_dir skill-contracts
tree="$FIREFLY_TMP_DIR"
write_skill "$tree" firefly-zz-anchor-approve ''
mkdir -p "$tree/contracts"
{
  echo '@design 01'
  echo '+trigger: Self-check skill'
  echo '-: APPROVE'
} > "$tree/contracts/firefly-zz-anchor-approve.txt"
printf '\nReturn APPROVE when green.\n' >> "$tree/render/claude/skills/firefly-zz-anchor-approve/SKILL.md"
expect_blocked "$tree" firefly-zz-anchor-approve anchor-claude

echo "skill contracts test passed"

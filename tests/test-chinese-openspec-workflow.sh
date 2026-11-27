#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT_DIR/tests/lib.sh"

assert_file_contains() {
  local path="$1"
  local needle="$2"

  if [[ ! -f "$path" ]]; then
    echo "expected file to exist: $path" >&2
    exit 1
  fi
  if [[ "$(cat "$path")" != *"$needle"* ]]; then
    echo "expected $path to contain: $needle" >&2
    exit 1
  fi
}

assert_file_not_contains() {
  local path="$1"
  local needle="$2"

  if [[ "$(cat "$path")" == *"$needle"* ]]; then
    echo "expected $path to not contain: $needle" >&2
    exit 1
  fi
}

guide_root="$ROOT_DIR/firefly/references/abilities"
assert_file_contains "$guide_root/firefly-propose/guide.md" "必须、不得、禁止、应当"
assert_file_contains "$guide_root/firefly-propose/guide.md" "### Requirement:"
for name in firefly-propose firefly-review firefly-archive; do
  assert_file_contains "$guide_root/$name/guide.md" 'firefly.sh" validate'
done

assert_file_contains "$ROOT_DIR/README.md" "firefly validate"
assert_file_contains "$ROOT_DIR/README.md" "不支持中文章节或标题"
assert_file_contains "$ROOT_DIR/README_EN.md" "firefly validate"
assert_file_contains "$ROOT_DIR/README_EN.md" "does not support Chinese section or heading keywords"

assert_file_contains "$ROOT_DIR/firefly/references/abilities/firefly-implement/guide.md" "changeRoot"
assert_file_contains "$ROOT_DIR/firefly/references/abilities/firefly-propose/guide.md" "OpenSpec proposal guide"
assert_file_not_contains "$guide_root/openspec-propose/guide.md" "openspec validate"
assert_file_not_contains "$guide_root/openspec-propose/guide.md" "all apply-required artifacts"
if grep -REn '(^[[:space:]]*|`)openspec (new|status|instructions|list|show|validate|archive)([[:space:]]|`|$)' "$guide_root"; then
  echo 'Run OpenSpec operations through Firefly in agent guides' >&2
  exit 1
fi

if command -v openspec >/dev/null 2>&1; then
  new_tmp_dir chinese-openspec
  project="$FIREFLY_TMP_DIR/project"
  mkdir -p "$project" "$FIREFLY_TMP_DIR/home"
  (
    cd "$project"
    export HOME="$FIREFLY_TMP_DIR/home" OPENSPEC_TELEMETRY=0
    runtime="$ROOT_DIR/firefly/scripts/firefly.sh"
    "$runtime" init .
    (cd openspec && "$runtime" new chinese-export)
    change=openspec/changes/chinese-export
    "$runtime" status --json > status.json
    assert_file_contains status.json '"schemaName": "spec-driven"'
    assert_file_contains status.json '"changeRoot":'
    assert_file_contains status.json '"planningHome":'
    "$runtime" spec instructions proposal --change chinese-export --json > instructions.json
    assert_file_contains instructions.json '"outputPath": "proposal.md"'
    (cd openspec && "$runtime" list --json) > changes.json
    assert_file_contains changes.json '"chinese-export"'
    test ! -e "$change/tasks.md"
    if unready="$("$runtime" validate all 2>&1)"; then
      echo 'full validation must report an unfinished scaffold' >&2
      exit 1
    fi
    printf '%s\n' "$unready" > unready.log
    assert_file_contains unready.log 'chinese-export'
    mkdir -p "$change/specs/export"
    printf '## Why\n\n验证中文需求。\n\n## What Changes\n\n- 增加导出。\n' > "$change/proposal.md"
    "$runtime" show --json > show.json
    assert_file_contains show.json '"chinese-export"'
    purpose='该能力为需要离线核对数据的用户提供导出文件。用户完成查询后可以保留当次结果，以便在后续对账时复核相同的数据范围和内容。'
    printf '## Purpose\n\n%s\n\n## ADDED Requirements\n\n### Requirement: 导出\n系统必须支持导出。\n\n#### Scenario: 导出成功\n- **WHEN** 用户发起导出\n- **THEN** 系统返回文件\n' "$purpose" > "$change/specs/export/spec.md"
    mv openspec/config.yaml openspec/config.yml
    (cd openspec && "$runtime" tasks chinese-export) > tasks.log
    assert_file_contains tasks.log '尚未生成任务表'
    (cd openspec && "$runtime" validate chinese-export)
    "$runtime" validate all --root "$project"
    "$runtime" validate chinese-export --root "$project"
    "$runtime" spec raw new change all
    cp -R "$change/specs" openspec/changes/all/specs
    cp "$change/proposal.md" openspec/changes/all/proposal.md
    "$runtime" validate --root "$project" -- all
    mv openspec/changes/all "$FIREFLY_TMP_DIR/literal-all-change"
    assert_file_not_contains "$change/specs/export/spec.md" MUST
    test ! -e "$change/tasks.md"
    if [[ "$("$runtime" spec raw --version)" == 2.* ]]; then
      # The adapter above already validated the Chinese delta. The native
      # archive command otherwise validates it again using English modals.
      "$runtime" spec raw archive chinese-export --yes --no-validate
      assert_file_contains openspec/specs/export/spec.md "$purpose"
      "$runtime" validate all --root "$project"
    fi
  )
fi
echo "Chinese OpenSpec workflow test passed"

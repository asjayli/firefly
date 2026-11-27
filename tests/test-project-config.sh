#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$root/tests/lib.sh"
new_tmp_dir project-config
project="$FIREFLY_TMP_DIR/project"
runtime="$root/firefly/scripts/firefly.sh"
mkdir -p "$project/.firefly/playbooks"
printf '{"implementer":"top"}\n' > "$project/.firefly/models.json"
playbook="$project/.firefly/playbooks/review.md"
cat > "$playbook" <<'EOF'
---
extends: firefly-review
anchor: 8. Resolve several returns
---
Check the focused project fixture.
EOF
"$runtime" config --root "$project" > "$FIREFLY_TMP_DIR/config.json"
assert_contains "$FIREFLY_TMP_DIR/config.json" '"implementer": "top"'
assert_contains "$FIREFLY_TMP_DIR/config.json" "$playbook"
(cd "$project" && "$runtime" doctor)
"$runtime" doctor --upstreams > "$FIREFLY_TMP_DIR/upstreams.json"
assert_contains "$FIREFLY_TMP_DIR/upstreams.json" '"ref": "v2.2.0"'
assert_contains "$FIREFLY_TMP_DIR/upstreams.json" '"ref": "v7.0.2"'

sed -i 's/8\. Resolve several returns/Nonexistent anchor/' "$playbook"
if (cd "$project" && "$runtime" doctor) > "$FIREFLY_TMP_DIR/errors" 2>&1; then
  echo "doctor accepted an unknown anchor" >&2
  exit 1
fi
assert_contains "$FIREFLY_TMP_DIR/errors" 'Unknown playbook anchor'
sed -i 's/Nonexistent anchor/8. Resolve several returns/' "$playbook"
printf '{"implementer":"unknown"}\n' > "$project/.firefly/models.json"
if "$runtime" config --root "$project" > "$FIREFLY_TMP_DIR/errors" 2>&1; then
  echo "config accepted an unknown tier" >&2
  exit 1
fi
assert_contains "$FIREFLY_TMP_DIR/errors" 'Unsupported model policy'

echo 'project configuration checks passed'

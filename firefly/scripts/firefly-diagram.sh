#!/usr/bin/env bash
# Runtime of the `firefly diagram` command: write timestamped Mermaid
# sequence diagram outputs (a .mmd source and a rendered .svg).

set -euo pipefail

MMDC_BIN="${MMDC_BIN:-mmdc}"
usage() {
  cat <<EOF
Generate timestamped Mermaid sequence diagram outputs.

Usage:
  firefly diagram <feature-name> <output-dir>
  firefly diagram --help

Behavior:
  - reads Mermaid content from stdin
  - requires an explicit output directory
  - publishes a timestamped .mmd and matching .svg after rendering
  - refuses to overwrite an existing output
  - prefers a local Chrome/Chromium executable when available
  - names outputs as <date-time>-<feature>
EOF
}

timestamp() {
  if [[ -n "${FIREFLY_DRAW_TIMESTAMP:-}" ]]; then
    printf '%s\n' "$FIREFLY_DRAW_TIMESTAMP"
    return
  fi

  date '+%Y%m%d-%H%M%S'
}

validate_timestamp() {
  local value="$1"

  if [[ ! "$value" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
    echo "invalid firefly diagram timestamp: $value (expected YYYYMMDD-HHMMSS)" >&2
    exit 1
  fi
}

sanitize_feature_name() {
  printf '%s' "$1" | tr '/[:space:]' '--' | tr -s '-'
}

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

detect_chrome_path() {
  local candidate

  for candidate in \
    "${FIREFLY_DRAW_CHROME_PATH:-}" \
    "${PUPPETEER_EXECUTABLE_PATH:-}" \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary" \
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
  do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  for candidate in google-chrome chrome chromium chromium-browser; do
    if command -v "$candidate" >/dev/null 2>&1; then
      command -v "$candidate"
      return 0
    fi
  done

  return 1
}

write_puppeteer_config() {
  local chrome_path="$1"
  local config_path="$2"

  cat > "$config_path" <<EOF
{
  "executablePath": "$(json_escape "$chrome_path")"
}
EOF
}

main() (
  if [[ $# == 1 && ( "$1" == --help || "$1" == -h ) ]]; then
    usage
    exit 0
  fi

  if [[ $# != 2 || -z "$1" || -z "$2" || "$1" == -* || "$2" == -* ]]; then
    usage >&2
    exit 2
  fi

  local feature_name="$1"
  local output_dir="$2"
  local ts
  local safe_feature
  local base_name
  local mmd_path
  local svg_path
  local chrome_path=""
  local puppeteer_config=""
  local -a mmdc_cmd

  ts="$(timestamp)"
  validate_timestamp "$ts"
  safe_feature="$(sanitize_feature_name "$feature_name")"
  base_name="${ts}-${safe_feature}"

  mkdir -p -- "$output_dir"
  stage="$(mktemp -d "$output_dir/.firefly-diagram.XXXXXX")"
  trap 'rm -rf -- "$stage"' EXIT

  mmd_path="$output_dir/${base_name}.mmd"
  svg_path="$output_dir/${base_name}.svg"

  cat > "$stage/$base_name.mmd"
  mmdc_cmd=("$MMDC_BIN" -i "$stage/$base_name.mmd" -o "$stage/$base_name.svg")

  if chrome_path="$(detect_chrome_path)"; then
    puppeteer_config="$stage/puppeteer.json"
    write_puppeteer_config "$chrome_path" "$puppeteer_config"
    mmdc_cmd+=(-p "$puppeteer_config")
  fi

  "${mmdc_cmd[@]}"
  node --input-type=module - "$stage/$base_name.mmd" "$mmd_path" "$stage/$base_name.svg" "$svg_path" <<'EOF'
import fs from 'node:fs';
const [source, destination, rendered, svg] = process.argv.slice(2);
let publishedSource = false;
try {
  fs.linkSync(source, destination);
  publishedSource = true;
  fs.linkSync(rendered, svg);
} catch (error) {
  if (publishedSource) fs.unlinkSync(destination);
  console.error(`firefly diagram: ${error.message}`);
  process.exitCode = 1;
}
EOF

  echo "🖊️  Wrote Mermaid source: $mmd_path"
  echo "🖼️  Rendered SVG: $svg_path"
)

main "$@"

#!/usr/bin/env bash
set -euo pipefail

scripts_dir="$(dirname "${BASH_SOURCE[0]}")"
package_dir="$(cd -L "$scripts_dir/.." && pwd -P)"
exec node "$scripts_dir/manage.mjs" "$package_dir" "$@"

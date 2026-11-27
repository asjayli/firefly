#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<EOF
Bootstrap OpenSpec in the current project.

Usage:
  $(basename "$0") [--help] [project_dir]

Behavior:
  - checks whether OpenSpec is already initialized in the target directory
  - runs openspec init only when initialization is missing
  - rejects an explicitly empty project_dir
  - rejects project_dir values containing newline characters
  - rejects symbolic links in project_dir path components before any write
  - preflight checks the OpenSpec output tree for symlinks
  - runs openspec init --tools none in an isolated directory
  - imports only the OpenSpec config and creates specs/ and changes/
EOF
}

# Resolve project_dir to an absolute path, reject newlines, and refuse to
# traverse any existing component that is a symbolic link. Newlines are rejected
# before the line-oriented read below so Bash 3.2 cannot mis-split the path.
assert_project_path_safe() {
  local path="$1"
  local current="/"
  local part
  local -a path_parts

  if [[ "$path" != /* ]]; then
    path="$PWD/$path"
  fi

  if [[ "$path" == *$'\n'* ]]; then
    echo "project_dir must not contain newline characters" >&2
    return 1
  fi

  IFS='/' read -r -a path_parts <<< "$path"
  for part in "${path_parts[@]}"; do
    case "$part" in
      ""|.)
        continue
        ;;
      ..)
        if [[ "$current" != "/" ]]; then
          current="${current%/*}"
          [[ -n "$current" ]] || current="/"
        fi
        continue
        ;;
    esac

    if [[ "$current" == "/" ]]; then
      current="/$part"
    else
      current="$current/$part"
    fi
    if [[ -L "$current" ]]; then
      echo "refusing symlinked project path component: $current" >&2
      return 1
    fi
  done
}

# Refuse a single symlinked initializer output path (e.g. project_dir/openspec).
assert_initializer_root_safe() {
  local path="$1"

  if [[ -L "$path" ]]; then
    echo "refusing symlinked initializer output: $path" >&2
    return 1
  fi
  if [[ -e "$path" && ! -d "$path" ]]; then
    echo "initializer output must be a directory: $path" >&2
    return 1
  fi
}

# Refuse existing symbolic links beneath the initializer output root.
# The find scan must succeed; on failure the tree is unsafe.
assert_initializer_tree_safe() {
  local root="$1"
  local scan_file
  local link

  assert_initializer_root_safe "$root"
  if [[ ! -d "$root" ]]; then
    return 0
  fi

  scan_file="$(mktemp "${TMPDIR:-/tmp}/firefly-bootstrap-scan.XXXXXX")"
  if ! find "$root" -type l -print0 > "$scan_file"; then
    rm -f -- "$scan_file"
    echo "unable to scan initializer output safely: $root" >&2
    return 1
  fi
  if IFS= read -r -d '' link < "$scan_file"; then
    rm -f -- "$scan_file"
    echo "refusing symlinked initializer output: $link" >&2
    return 1
  fi
  rm -f -- "$scan_file"
}

main() (
  local project_dir="."
  local project_dir_set="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        usage
        exit 0
        ;;
      --*)
        echo "unsupported option: $1" >&2
        exit 1
        ;;
      *)
        if [[ "$project_dir_set" == "true" ]]; then
          echo "only one project_dir may be provided" >&2
          exit 1
        fi
        if [[ -z "$1" ]]; then
          echo "project_dir must not be empty" >&2
          exit 1
        fi
        if [[ "$1" == *$'\n'* ]]; then
          echo "project_dir must not contain newline characters" >&2
          exit 1
        fi
        project_dir="$1"
        project_dir_set="true"
        shift
        ;;
    esac
  done

  if ! command -v openspec >/dev/null 2>&1; then
    echo "openspec is not installed or not on PATH" >&2
    exit 1
  fi

  assert_project_path_safe "$project_dir"
  assert_initializer_root_safe "$project_dir/openspec"

  if [[ -f "$project_dir/openspec/config.yaml" || -f "$project_dir/openspec/config.yml" ]]; then
    echo "OpenSpec already initialized in $project_dir"
    exit 0
  fi
  assert_initializer_tree_safe "$project_dir/openspec"

  local stage config
  stage="$(mktemp -d "${TMPDIR:-/tmp}/firefly-bootstrap.XXXXXX")"
  trap 'rm -rf -- "$stage"' EXIT
  mkdir "$stage/project" "$stage/home"
  # OpenSpec can clean legacy assets before honoring --tools none.
  echo "Running openspec init --tools none in an isolated directory"
  (
    cd "$stage/project"
    HOME="$stage/home" XDG_CONFIG_HOME="$stage/home/config" OPENSPEC_TELEMETRY=0 openspec init --tools none .
  )
  config="$stage/project/openspec/config.yaml"
  [[ -f "$config" && ! -L "$config" ]] || { echo "OpenSpec did not create a regular config.yaml" >&2; return 1; }
  assert_initializer_tree_safe "$project_dir/openspec"
  mkdir -p -- "$project_dir/openspec/specs" "$project_dir/openspec/changes"
  (set -o noclobber; cat -- "$config" > "$project_dir/openspec/config.yaml")
  echo "Project bootstrap complete"
)

main "$@"

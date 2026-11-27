#!/usr/bin/env bash

set -euo pipefail

# Resolve the global command symlink so helper paths remain runtime-relative.
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_SOURCE" ]]; do
  SCRIPT_DIR="$(cd -L "$(dirname "$SCRIPT_SOURCE")" && pwd -L)"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  [[ "$SCRIPT_SOURCE" == /* ]] || SCRIPT_SOURCE="$SCRIPT_DIR/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -L "$(dirname "$SCRIPT_SOURCE")" && pwd -L)"

usage() {
  cat <<'EOF'
用法：firefly <命令> [参数]

日常命令
  init [目录]                      初始化项目规格目录
  new <变更ID>                    创建变更骨架
  list [--json]                   列出活跃变更及其 ID
  status [变更ID] [--json]        查看变更的制品进度
  show [变更ID] [--json]          查看变更内容
  validate [变更ID] [--root 目录]  严格校验整个项目或指定变更
  tasks [目录]                    列出未完成任务
  doctor [--upstreams]            检查安装或显示上游版本

其他入口
  config、repair、diagram、snapshot、record
  spec --help                     查看规格后端的完整命令

用 firefly <命令> --help 查看参数和示例。
EOF
}

command_name="${1:-help}"
if [[ $# == 2 && ( "$2" == --help || "$2" == -h ) ]]; then
  case "$command_name" in
    doctor)
      printf '%s\n' '用法：firefly doctor [--upstreams]' '  --upstreams  可选。展示上游依赖版本。省略则检查当前安装。'
      exit 0
      ;;
    config)
      printf '%s\n' '用法：firefly config [--root 目录]' '  --root  可选。项目目录，默认当前目录。显示模型偏好和工作流配置。'
      exit 0
      ;;
    repair)
      printf '%s\n' '用法：firefly repair' '  从安装基线修复受管文件，并保留替换前的备份。'
      exit 0
      ;;
  esac
fi
case "$command_name" in
  validate)
    shift
    exec node "$SCRIPT_DIR/validate-openspec-cn.mjs" "$@"
    ;;
  init)
    shift
    exec "$SCRIPT_DIR/bootstrap-project.sh" "$@"
    ;;
  new|list|show|status)
    exec node "$SCRIPT_DIR/spec-commands.mjs" "$@"
    ;;
  spec)
    shift
    if ! command -v openspec >/dev/null 2>&1; then
      printf '%s\n' 'firefly: openspec is not installed or not on PATH' >&2
      exit 127
    fi
    exec openspec "$@"
    ;;
  tasks)
    shift
    exec "$SCRIPT_DIR/list-change-tasks.sh" "$@"
    ;;
  diagram)
    shift
    exec "$SCRIPT_DIR/firefly-diagram.sh" "$@"
    ;;
  config)
    shift
    exec node "$SCRIPT_DIR/project-config.mjs" "$SCRIPT_DIR/.." "$@"
    ;;
  doctor)
    shift
    if [[ $# == 1 && "$1" == --upstreams ]]; then
      PACKAGE_DIR="$(cd -L "$SCRIPT_DIR/.." && pwd -L)"
      exec cat "$PACKAGE_DIR/references/upstreams.json"
    fi
    bash "$SCRIPT_DIR/manage.sh" doctor "$@"
    if [[ -e .firefly || -L .firefly ]]; then
      node "$SCRIPT_DIR/project-config.mjs" "$SCRIPT_DIR/.." >/dev/null
    fi
    ;;
  repair)
    shift
    exec bash "$SCRIPT_DIR/manage.sh" "$command_name" "$@"
    ;;
  snapshot)
    shift
    exec "$SCRIPT_DIR/firefly-snapshot.sh" "$@"
    ;;
  record)
    shift
    exec "$SCRIPT_DIR/firefly-record.sh" "$@"
    ;;
  help|--help|-h)
    if [[ $# -gt 1 ]]; then
      printf '%s\n' '用 firefly <命令> --help 查看命令帮助。' >&2
      exit 2
    fi
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

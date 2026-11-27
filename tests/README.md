# tests

每个 `test-*.sh` 一行：守什么、需要什么桩、大约耗时。全部可直接 `bash tests/<name>.sh` 运行。

| 文件 | 守什么 | 外部桩 | 耗时 |
|---|---|---|---|
| `test-autonomous-workflow.sh` | 主控与各技能的自治契约（总控 v2、think/verify-web/archive 段） | 无桩 | ~4s |
| `test-bootstrap-project.sh` | bootstrap-project.sh 行为 | 假 OpenSpec | ~1s |
| `test-chinese-openspec-workflow.sh` | 中文 OpenSpec 流程 | 无桩 | ~1s |
| `test-draw-helper.sh` | firefly diagram 脚本行为 | 无桩 | ~1s |
| `test-draw-skills.sh` | firefly-draw/mermaid 技能文本契约 | 无桩 | ~1s |
| `test-firefly-command.sh` | firefly CLI 子命令与 doctor 分发 | 桩 doctor | ~1s |
| `test-handoff-contract.sh` | 共享交接契约 144 项 | 无桩 | ~1s |
| `test-list-change-tasks.sh` | list-change-tasks.sh | 无桩 | ~1s |
| `test-planning-contract.sh` | think/propose/openspec-propose 规划契约 | 无桩 | ~1s |
| `test-portable-shell-scripts.sh` | 安装器/库禁用非可移植 find | 无桩 | ~1s |
| `test-preflight-contract.sh` | 实现能力的 Preflight 契约 | 无桩 | ~1s |
| `test-project-config.sh` | 模型档位、playbook 锚点和上游适配清单 | 无桩 | ~2s |
| `test-readme-workflow.sh` | README 工作流描述 | 无桩 | ~1s |
| `test-release-metadata.sh` | 发布版本与技能包许可 | 无桩 | ~1s |
| `test-runtime-scripts.sh` | snapshot/record/task-brief/review-package 行为 | 临时 git 仓库 | ~8s |
| `test-script-size.sh` | 脚本行数上限 | 无桩 | ~1s |
| `test-skill-contracts.sh` | 独立入口、能力文档结构与契约锚点 | 无桩 | ~6s |
| `test-standalone-install.sh` | 无宿主安装、符号链接、诊断、修复和基线损坏 | 无桩 | ~2s |
| `test-validate-openspec-cn.sh` | 中文严格校验适配器 | 临时项目 | ~2s |

- 锚点格式见 `tests/contracts/README.md`；`tests/cases/` 下是被 source 的用例体（`moved-scripts.sh`、`snapshot-retention.sh`、`boundary-cases.sh`），不单独运行。
- `tests/acceptance/`（阶段 14 建）：52 条桌面重放用例。
- `tests/lib.sh`：共享断言与临时目录清理。

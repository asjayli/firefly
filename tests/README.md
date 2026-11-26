# tests

每个 `test-*.sh` 一行：守什么、需要什么桩、大约耗时。全部可直接 `bash tests/<name>.sh` 运行；串行全套约 90 秒。

| 文件 | 守什么 | 外部桩 | 耗时 |
|---|---|---|---|
| `test-autonomous-workflow.sh` | 主控与各技能的自治契约（总控 v2、think/verify-web/archive 段） | 无桩 | ~4s |
| `test-bootstrap-project.sh` | bootstrap-project.sh 行为 | 假 npm | ~1s |
| `test-chinese-openspec-workflow.sh` | 中文 OpenSpec 流程与渲染一致 | 无桩 | ~1s |
| `test-claude-installer.sh` | Claude 安装器（31 技能、FIREFLY_MANIFEST、doctor/repair、symlink） | 假 npm | ~37s |
| `test-codex-installer.sh` | Codex 安装器（同上） | 假 npm | ~2s |
| `test-draw-helper.sh` | firefly diagram 脚本行为 | 无桩 | ~1s |
| `test-draw-skills.sh` | firefly-draw/mermaid 技能文本契约 | 无桩 | ~1s |
| `test-firefly-command.sh` | firefly CLI 子命令与 doctor 分发 | 桩 doctor | ~1s |
| `test-handoff-contract.sh` | 共享交接契约 144 项 | 无桩 | ~1s |
| `test-hash-portability.sh` | 哈希脚本的跨平台行为 | 无桩 | ~1s |
| `test-list-change-tasks.sh` | list-change-tasks.sh | 无桩 | ~1s |
| `test-manifest-assets.sh` | manifest-assets.mjs 路径校验（受管根/仓内七负向） | 无桩 | ~1s |
| `test-managed-symlinks.sh` | 受管符号链接（含 references 链接） | 假 npm | ~11s |
| `test-planning-contract.sh` | think/propose/openspec-propose 规划契约 | 无桩 | ~1s |
| `test-platform-asset-parity.sh` | 渲染防漂移（篡改后 --check 拦截） | 无桩 | ~1s |
| `test-portable-shell-scripts.sh` | 安装器/库禁用非可移植 find | 无桩 | ~1s |
| `test-preflight-contract.sh` | implement/apply 的 Preflight 契约 | 无桩 | ~1s |
| `test-readme-workflow.sh` | README 工作流描述 | 无桩 | ~1s |
| `test-release-metadata.sh` | 发布元数据（含 retiredAssets 两负向） | 无桩 | ~1s |
| `test-runtime-scripts.sh` | snapshot/record/task-brief/review-package 行为 | 临时 git 仓库 | ~8s |
| `test-script-size.sh` | 脚本行数上限 | 无桩 | ~1s |
| `test-shared-completeness.sh` | shared 渲染完备性 | 无桩 | ~1s |
| `test-skill-contracts.sh` | 25 技能结构 lint（14 规则 + 11 负例） | 无桩 | ~6s |
| `test-upgrade-from-0.1.0.sh` | 0.1.0 残留退役六情形×两平台 | 无桩（库级直调） | ~2s |
| `test-validate-openspec-cn.sh` | 中文严格校验适配器 | 临时项目 | ~2s |

- 锚点格式见 `tests/contracts/README.md`；`tests/cases/` 下是被 source 的用例体（`moved-scripts.sh`、`snapshot-retention.sh`、`boundary-cases.sh`），不单独运行。
- `tests/acceptance/`（阶段 14 建）：52 条桌面重放用例。
- `tests/lib.sh`：共享断言与临时目录清理。

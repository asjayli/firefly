# Firefly 0.2.0 实现逻辑审查

审查基线为 `4ac1b93`。按问题对开工、验收、安装和恢复的影响排序。

## 发现

### 1. P1 · 旧验证证据可以被记作新候选通过

`record observe` 对 `pass` 只检查证据路径存在，然后在写入时重新计算候选和规格版本。探针先为候选 A 保存证据，再修改实现得到候选 B，最后引用 A 的证据调用记录命令。命令成功，新行把 A 的证据记为 B 的 `pass`。代码或规格在验证后、记录前变化时，只比较当前快照与记录行无法识别这类错配。

验证开始时固定候选和规格。记录接口接收验证实际使用的标识，并以它们归档观察。若当前版本已变化，旧证据只能作为历史记录使用。评审包也应直接从已固定的候选树生成，避免第二次采集可变工作树。 [记录实现](../scripts/firefly-record.sh#L385) · [交接契约](../assets/shared/references/handoff-contract.md#L184) · [评审构包规则](../assets/shared/skills/firefly-review/SKILL.md#L87)

### 2. P1 · 基线缺失时，修复会移除仍可用的安装文件

清单检查确认源目录类型，但普通文件条目可以指向缺失的基线。修复先备份，再删除安装目标，最后复制基线。用临时清单模拟 OpenSpec 覆盖文件的基线丢失，`doctor --repair` 退出 1，原安装路径已经消失，只剩备份。另一个探针验证了成功路径会立即删除备份，和 README 承诺的「替换前保留备份」不一致。

先验证源文件并在目标同目录准备完整替换件，再替换目标。失败时保留或恢复原安装，成功后按文档保留可恢复的备份。 [清单检查](../scripts/manifest-assets.mjs#L238) · [替换顺序](../scripts/firefly-common.sh#L161) · [备份承诺](../README.md#L65)

### 3. P1 · 合法的符号链接拓扑会阻断全局诊断和修复

运行时用 `cd -P` 得到脚本的物理目录，分发 `doctor` 时却把它与按环境变量拼接的逻辑路径比较。令 `.codex` 指向另一目录，从全局命令执行 `doctor`，实际退出 1，并要求手动传入 `--platform`。同样的分发也用于 `repair`。现有符号链接测试覆盖技能和引用目录，平台根目录仍是实体目录。

分发时统一解析两侧路径。回归测试应分别覆盖 Codex 与 Claude 的平台根、运行时目录链接，并经全局入口检查 `doctor` 与 `repair`。 [分发逻辑](../scripts/firefly.sh#L30) · [现有符号链接用例](../tests/test-managed-symlinks.sh#L64)

### 4. P2 · 将评审报告写到普通仓内目录会污染候选

在临时 Git 仓库执行 `review-package HEAD WORKTREE <仓根>/report.diff`，实际差异包含 `.review-package.*`，执行前后候选 SHA 也发生变化。脚本先在输出目录创建临时文件，随后才采集工作树，过滤时只排除了最终输出名。标准 `openspec/changes/…` 输出路径已有目录级排除，本问题影响 CLI 支持的其他普通仓内路径。

在创建输出临时文件前固定输入，并约束报告产物的位置，或通过一致的候选排除规则处理报告。回归测试应比较前后快照以及差异文件清单。 [输出和采集顺序](../scripts/review-package#L120)

### 5. P2 · 规格版本受 Git 忽略规则影响，已跟踪的规格也可能无法开工

`snapshot --spec` 从空索引执行 `git add -A`。探针在临时仓库忽略 `openspec/changes/`，同时保留一个已跟踪的规格文件。命令仍因 Git 忽略规则退出 1。因为空索引缺少真实索引中的跟踪信息，规格实际存在也无法生成开工裁决所需的版本。

按实际规格目录内容生成摘要，并明确文件收集规则，覆盖已跟踪、未跟踪和本地忽略的项目布局。 [规格版本计算](../scripts/firefly-snapshot.sh#L160) · [开工前检查](../assets/shared/skills/firefly-implement/SKILL.md#L81)

### 6. P2 · 两个平台的安装指引在克隆和进入目录之间断开

两份指引都从 `asjayli/Forgevia.git` 克隆，随后执行 `cd firefly`。该命令未指定本地目录，Git 会根据 URL 选择 `Forgevia`，所以在干净目录照步骤运行时，切换目录会失败。中英文 README 也仍从 `Forgevia` 拉取安装指引，当前仓库的 `origin` 为 `asjayli/firefly.git`。

统一安装指引、克隆地址与本地目录，并从空目录验证文档命令。 [Codex 安装](../INSTALL.codex.md#L27) · [Claude 安装](../INSTALL.claude.md#L58) · [中文入口](../README.md#L38) · [英文入口](../README_EN.md#L38)

## 验证依据

- 顶层行为核对了命令入口、发布清单、共享技能、交接契约、CI 和实际使用的 Git 状态。重点检查候选身份、状态转换、部分失败和用户已有安装。
- CI 对应的 26 个测试脚本、ShellCheck 和设计投影校验全部通过。另在仓内临时目录用真实 Git、Bash 和文件系统复现前五项，并确认本机 OpenSpec 1.6.0 的 `status --json` 返回 `changeRoot`。安装指引的问题由命令和远端配置直接确认。
- Codex 与 Claude Code 的完整代理会话未实跑，技能层判断依据为分发指令、共享契约和运行时探针。

## 实施对象清单

| 对象绝对路径 | 边界 |
|---|---|
| `/code/asjayli/firefly/scripts/firefly-record.sh` | 仓内 |
| `/code/asjayli/firefly/scripts/review-package` | 仓内 |
| `/code/asjayli/firefly/scripts/firefly-snapshot.sh` | 仓内 |
| `/code/asjayli/firefly/scripts/firefly-common.sh` | 仓内 |
| `/code/asjayli/firefly/scripts/manifest-assets.mjs` | 仓内 |
| `/code/asjayli/firefly/scripts/firefly.sh` | 仓内 |
| `/code/asjayli/firefly/assets/shared/references/handoff-contract.md` | 仓内 |
| `/code/asjayli/firefly/assets/shared/skills/` | 仓内 |
| `/code/asjayli/firefly/assets/codex/` | 仓内 |
| `/code/asjayli/firefly/assets/claude/` | 仓内 |
| `/code/asjayli/firefly/tests/` | 仓内 |
| `/code/asjayli/firefly/INSTALL.codex.md` | 仓内 |
| `/code/asjayli/firefly/INSTALL.claude.md` | 仓内 |
| `/code/asjayli/firefly/README.md` | 仓内 |
| `/code/asjayli/firefly/README_EN.md` | 仓内 |

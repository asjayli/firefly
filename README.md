<div align="center">

# firefly

### 面向 Codex、Claude 的 Agent Coding 工作流

中文 | [English](README_EN.md)

</div>

**当前版本：0.2.0**（[CHANGELOG](CHANGELOG.md)）· 许可证：[MIT](LICENSE) · [第三方声明](THIRD_PARTY_NOTICES.md)

firefly 把用户的委托转成可验收的交付物：调查给出有依据的解释，提案说明准备实现什么，实现交付经过验证的改动，评审给出独立判断。并非每项委托都以修改代码结束。

## 职责范围

### firefly 做什么

- 把一次委托转成可验收的交付物：四个委托入口（查清原因 / 给出方案暂不实现 / 实现已获准方案 / 评审这个候选）各有明确的终点与证据要求。
- 以子命令为授权边界：`firefly think`、`firefly implement <change>` 这类命名入口直接进入对应技能；命令名固定终点，不附带无关效果，调查不会升级成改代码。
- 提供 23 个技能与一组运行时子命令（`init` / `doctor` / `repair` / `validate` / `tasks` / `diagram` / `snapshot` / `record`），并管理全局受管资源的安装、检查与修复。

### firefly 不做什么

- 不接管你的项目源文件：只在命令边界内写入规格、任务与验证记录，不静默覆盖项目内文件。
- 不替人做取舍：后果不同的选项交回用户与负责人；执行者不能扩大委托，也不能批准自己的候选。
- 不建第二个调度器：从中断恢复复用既有规格、`tasks.md`、Git 与验证记录，不新增状态内核或跨进程调度。
- 不自动触发：仅在用户显式要求使用 firefly 或点名某个子命令时工作，编码请求本身不构成触发。

## 安装

### 前提

- Node 与 npm：安装器会固定安装经验证的 OpenSpec `1.6.0`（`npm install -g @fission-ai/openspec@1.6.0`），替换本地已有版本。
- ripgrep（`rg`）可选：`firefly tasks` 用它加速任务扫描，缺失时自动回退 grep。
- 0.2.0 起 firefly 自带全部工作流技能，不再需要 superpowers，也不安装、不覆盖任何 superpowers 技能。

### Codex 安装方式

直接对 Codex 说：

```text
帮我安装，交互过程请使用中文：Fetch and follow instructions from https://raw.githubusercontent.com/asjayli/Forgevia/refs/heads/main/INSTALL.codex.md
```

### Claude 安装方式

直接对 Claude 说：

```text
帮我安装，交互过程请使用中文：Fetch and follow instructions from https://raw.githubusercontent.com/asjayli/Forgevia/refs/heads/main/INSTALL.claude.md
```

### 安装后检查

安装器把平台无关的 `firefly` 命令装到 `~/.local/bin/firefly`，并镜像一份 firefly 源基线到平台目录，供检查与修复比对。确保 `~/.local/bin` 在 PATH 中后运行：

```bash
firefly doctor
```

`doctor` 检查当前平台（Codex 或 Claude）的 firefly 受管资产是否齐全、是否与基线一致，逐项报告 `OK` / `MISS` / `DRIFT`，不修改任何文件。发现问题后用 `firefly repair` 从 firefly 自有副本恢复，替换前保留备份。

## 技能能力

下表是 firefly 的 23 个技能子命令，与总控技能注册表一一对应。「设计位置」是设计稿 26 个工程判断中的编号（17 简化并入 `firefly review`，21 流水线门禁并入 `firefly guard`，22 旧系统退役并入 `firefly archive`）。

| 子命令 | 设计位置 | 一句话职责 | 进入条件 |
|---|---|---|---|
| `firefly next` | 01 总控 | 只读提出接下来 3–5 步建议，各带证据来源与完成标准 | 想知道下一步做什么时 |
| `firefly think` | 02 澄清 | 开发前一次一问澄清需求，纪要落在 `openspec/think/` | 用户须在后果不同的方案间取舍 |
| `firefly draw` | 03 概念 | 用一页对照、时序图或可丢弃原型选定首个用户行为 | 提问说不清，或请求/任务/文件生命周期不明 |
| `firefly propose` | 04 规格 | 把需求转成 OpenSpec 变更并带两包过联合开工裁决 | 完整交付路径的一环 |
| `firefly bounds` | 05 质量线 | 实现前约定场景之外的质量约束，评审派发时运行受影响检查 | 变更触及服务目标、兼容或数据边界 |
| `firefly tasks` | 06 任务 | 把就绪规格拆成可独立验证的任务并写双向场景映射；查询入口只读列未完成任务 | 完整交付路径的一环 |
| `firefly implement` | 07 实现 | 交付已过开工裁决的一个变更：每组一执行者、候选快照固定、集成后交付 | 完整交付路径的一环 |
| `firefly source` | 08 来源 | 把第三方依赖在已装版本下的承诺与环境实际记成两项结论 | 不确定依赖在所用版本与配置下承诺什么 |
| `firefly doubt` | 09 反证 | 在全新上下文对一项要紧假设做一次独立反证调查 | 高代价决定依赖未经验证的假设 |
| `firefly context` | 10 上下文 | 按需重建工作上下文、为继任者压缩交接 | 中断恢复或会话交接时 |
| `firefly ui` | 11 界面 | 实现前规定 UI 状态并在真实页面观察 | 改动涉及页面状态与交互 |
| `firefly arch` | 12 契约 | 公共接口变更前定契约并回写规格场景 | 场景改公共接口，或两方需独立开发 |
| `firefly tdd` | 13 测试 | 承担测试纪律：值得先写的测试须在未改基线上看它失败 | 实现中每个派遣测试组 |
| `firefly verify-web` | 14 浏览器 | 在全新隔离会话验证浏览器可见行为，每条检查一行观察 | 改动涉及页面、交互或视觉效果 |
| `firefly debug` | 15 调试 | 先取得能区分故障与正常的反馈，再定位一次失败 | 失败不可稳定复现，或一轮修复未改变症状 |
| `firefly review` | 16 裁决 | 未参与生成的评审者裁决固定候选，返回四种裁决之一 | 完整交付路径的一环；可单独委托 |
| `firefly guard` | 18 安全 | 只读检查指定范围的信任边界，并可把门禁挂载进 CI | 权限边界变化，或要把质量线挂成流水线检查 |
| `firefly perf` | 19 性能 | 对照记录条件下的基线，测量变更是否缩短用户实际等待 | 需要性能证据支撑决定 |
| `firefly pr` | 20 交付 | 把已接受候选写成面向合入决策者的 PR 描述并执行获准动作 | 候选已接受且需要 PR |
| `firefly docs` | 23 记录 | 维护团队词汇、决策记录与主规格这类维护者载体 | 需要保留下一位维护者无法从代码还原的信息 |
| `firefly trace` | 24 信号 | 与规格约定运行信号要求，并在发布前于测试环境演练 | 场景承诺用户取得结果，或服务有值班承诺 |
| `firefly archive` | 25 归档 | ACCEPT 后的三个独立端点：只读就绪评估、本地归档、另行委托的上线 | 交付被接受之后 |
| `firefly retro` | 26 复盘 | 复盘一次实际失败或反复返工，把原因定位到一层并提出可撤回的改进 | 交付后发生失败或重复返工 |

## 如何使用

### 四个委托入口

用户决定交付什么、允许改变什么；firefly 据此选择入口和下一步。同一个「月末导出刷新后要重来」的问题，四种委托各走各的终点：

- **「查清为什么刷新后导出又要重来。」** 进入调查：区分请求断开终止计算，还是页面丢失了仍在运行的任务标识。交回观察、原因或仍缺的证据；即使已经知道怎么修，也不改产品。
- **「给出恢复方案，暂不实现。」** 进入规格与规划：只有目标含混时才澄清，只有关键事实不明时才做概念验证。交付能区分正确与错误实现的场景、任务依赖与验证方法；方案可开工即停。
- **「实现已获准开工的恢复方案。」** 从第一个依赖已满足的任务开始，不重走访谈。执行者提交候选，验证者检查受影响行为，独立评审裁决集成候选；交付经验证的改动或有依据的阻塞说明，不包含推送、归档或上线。
- **「评审这个候选。」** 把固定候选、规格和证据直接交独立评审。终点是四种裁决之一，不是修复。

### 常用运行时子命令

```bash
firefly init                  # 检查全局环境；项目缺 OpenSpec 初始化时才执行 openspec init
firefly tasks                 # 只读列出所有活跃变更的未完成任务
firefly validate --root <目录> # 中文 OpenSpec 严格校验（见下节）
firefly diagram <功能> <目录>   # 生成带时间戳的 .mmd 与渲染 .svg
firefly doctor                # 检查当前平台受管资产（OK/MISS/DRIFT），不改文件
firefly repair                # 修复缺失或漂移的受管资产，替换前保留备份
firefly snapshot              # 打印工作树候选快照；--spec/--tasks 查两包版本
firefly record <子命令>        # 向交接载体追加一条经校验的记录行
```

`firefly next` 是技能侧的只读入口：从会话与项目中提取已完成、未兑现与待展开的信号，按风险清障、兑现承诺、续作、推进、清债的次序提出 3–5 项建议，每项带证据来源、完成标准与对应的 firefly 入口；无信号时如实报告，不编造条目。

### 裁决与升级

独立评审的裁决取值只有四种：

- `ACCEPT`（接受）：包不变且全部必需角色有效接受，可附保留项清单。
- `REVISE`（退修）：实现或测试本身有缺陷，候选必须修改，计入修复预算。
- `RECHECK`（待复验）：约定的检查可在当前候选上补跑，候选不变，不计修复轮次。
- `INSUFFICIENT_EVIDENCE`（证据不足）：所需证据在现有授权、工具或环境下取不到，直接升级。

需要新授权、证据不可得、重复修复无进展或承诺必须改变时，`ESCALATE` 返回三件套：当前结论、缺失的证据或授权、能补齐它的负责人。升级后自动执行停止，不代 owner 作出裁决或批准。

### 候选状态

候选从在制到上线按同一张状态表交接与恢复：**在制 → 待集成 → 待裁决 → 已接受 → 发布中 → 已上线**（获归档授权后转 **已归档**）。验证通过转待集成；集成并固定评审包后转待裁决；接受转已接受；发布授权后按预案推进；末段按原场景复验通过转已上线。规格、标准或候选变化会使受影响的观察与裁决降为历史，不能用旧裁决放行新候选。

## 从 0.1.0 升级

- 重新安装即可：安装器会完成全部迁移。
- 安装与 `firefly repair` 会把 firefly 0.1.0 留下的旧资产（旧技能目录与六个 superpowers 覆盖层）按哈希校验后移入 `~/.codex/firefly/retired/<时间戳>/` 或 `~/.claude/firefly/retired/<时间戳>/` 备份，绝不删除。
- 旧覆盖层被移走后，如需恢复上游 superpowers 技能，请重装或更新 superpowers。
- CLI 的 `firefly draw` 改名为 `firefly diagram`。

## 中文 OpenSpec 严格校验

firefly 通过 `firefly validate` 提供中文 OpenSpec 严格校验，用于在不修改源规格的前提下支持需求正文中的“必须、不得、禁止、应当”。它先校验中文强制词，再在临时副本中注入 `MUST` 并运行原生严格校验：

```bash
firefly validate --root <项目根目录>
```

安装器将平台无关的命令安装到 `~/.local/bin/firefly`；确保该目录在 PATH 中后，可直接运行 `firefly validate --root <项目根目录>`。命令分发器支持的运行时子命令：`init`、`tasks`、`validate`、`diagram`、`doctor`、`repair`、`snapshot`、`record`。适配器同时校验主规格和活跃变更，且只支持 `spec-driven` schema；不支持中文章节或标题，必须继续使用 `## Requirements`、`### Requirement:` 和 `#### Scenario:` 等 OpenSpec 结构关键字。

## 第三方资产与许可

- `playwright-interactive`：来源上游，Apache License 2.0（© Microsoft Corporation）。firefly 重新分发时保留其 `LICENSE.txt` 与 `NOTICE.txt`。
- OpenSpec（`@fission-ai/openspec`，MIT）：安装器固定安装 `1.6.0`，并把受管覆盖文件叠加上上游安装（版本不匹配时保护性跳过）。
- 派生自 superpowers（MIT）的六个技能：`firefly-draw`、`firefly-tasks`、`firefly-implement`、`firefly-context`、`firefly-tdd`、`firefly-review` 从对应 superpowers 技能演化而来，文字为 firefly 自写。firefly 0.2.0 不再安装或维护任何 superpowers 覆盖。
- `mermaid-diagram-specialist`：firefly 原创技能。

详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 上游依赖

需要从上游安装并在其上叠加受管覆盖的依赖只剩 OpenSpec；其余为运行时工具或已随 firefly 分发的技能。

| 上游 | 用途 | firefly 基准 | 地址 |
|------|------|---------------|------|
| OpenSpec (`@fission-ai/openspec`) | spec-driven 变更工作流 CLI | 覆盖针对并固定为 `1.6.0` | https://www.npmjs.com/package/@fission-ai/openspec |
| playwright-interactive | 浏览器交互验证技能 | vendored（随仓库分发） | 见技能内 `LICENSE.txt` / `NOTICE.txt`（Apache-2.0，© Microsoft Corporation） |
| mermaid-cli (`mmdc`) | `firefly diagram` 渲染 SVG 的运行时依赖 | 运行时工具 | https://github.com/mermaid-js/mermaid-cli |
| ripgrep (`rg`) | `firefly tasks` 扫描任务（可选，缺失回退 grep） | 运行时工具 | https://github.com/BurntSushi/ripgrep |

> 说明：firefly 对 OpenSpec 的覆盖是针对 `1.6.0` 的内容快照，安装器固定安装此版本。当本地 OpenSpec 版本与快照不一致时，安装器与 doctor 会保护性跳过覆盖，避免降级上游；升级时必须同步更新覆盖快照、安装版本和 `manifests/*.json` 中的 `overrideTargetVersion`。

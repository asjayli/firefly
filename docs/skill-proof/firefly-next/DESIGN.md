# firefly-next 设计稿：26 维度的目标态（v1.2）

> 状态：**设计稿，待用户正式确认**。确认前不实施任何技能改动。
> 方法：26 个维度逐点吸收 Matt / Addy / Pstack 三套的优点，叠加 2025-2026 互联网最新实践，为 firefly 设计下一版理想形态。
> **v1.2 修订（2026-11-20，第二轮 mar 六维复审，17 主题全修）**：①§0.5 改为「扩展现有 shared 渲染」而非「取消 shared」——仓库已有单源 + token 管线，实测 16 项有差异、8 项超 2 处、2 处能力性差异；②§3 实施清单改为「资产面 × 动作 × 路径」全表，覆盖 codex/manifests/scripts/tests/shared/commands；③回退 doubt/guard 的残留清除（01 契约、§1 表、bounds 定位）；④依据失真 12 处逐条修正（08 改 docs-first、16/09 换真实裁决机制、04 constitution 归 spec-kit、01 模式宣告标 own design）；⑤强制门闭环 6 处补齐（16 输入含红绿证据、14 四元组、18 审批条目、§4.5 产物路径契约）；⑥P0 路线去外部依赖（DoD 门禁改用仓库 `tests/`）；⑦机制补收（07 前沿派发 + 指针通信、26 换 reflect 骨架、23 的 why 归位、三个并入统一 references 落点）；⑧合并判据换成三条可判定条件。
> **v1.1 修订（2026-11-20）**：吸收首轮 mar 五维审查的设计层发现 + 裁定——①「不分叉」= 资产单套化；② mar/nextup 机制提炼吸收（16 独立性协议、01 `firefly next`）；③ doubt/guard 合并经用户裁定**回退**（23 技能）；④ 裁定复述条款确认纳入（02④）。
> 互联网依据：Anthropic Agent Skills 与 context engineering 官方实践、GitHub Spec Kit / OpenSpec / BMAD / Kiro 的 spec-driven 浪潮、AI 评审的生成/评审分离范式、agent 安全（secrets 注入/最小权限/approval gates）、OTel GenAI 可观测约定、RCA-first 调试纪律、a11y 自动化边界等（详见各点「依据」）。

## 0. 设计立场：五条元原则

从三套的分化与最新实践中，firefly-next 的所有技能设计服从以下元原则：

1. **显式授权（Explicit mandate）**——继承 firefly 现状的最大优点：用户点名才进入，子命令即授权边界。三套中 Pstack 的「常驻触发器」与 Addy 的「按需技能」之间，firefly 取 Addy 的按需 + 自己的契约路由，拒绝隐式扩权。
2. **证据优先于断言（Evidence over claim）**——吸收 Addy source-driven / doubt-driven 的内核：任何结论（源码行为、测试通过、评审通过）必须挂在可复核的证据上；agent 的自我报告不是证据。
3. **生成与评审分离（Separation of duties）**——**原则 2 的组织化执行形态**（评审独立是取证手段，不是独立目标）：2025 评审实践的共识：写得越多，评审越要独立。执行代理与评审代理必须分离，评审以独立子代理 + 并行多维检查点运行。
4. **上下文最小充分（Minimal sufficiency）**——Anthropic context engineering 的核心：上下文是有限注意力预算，只装「达成目标的最小高信号 token 集」；用 JIT 检索、compaction、结构化笔记、子代理摘要四板斧管理。
5. **产物即流程（Artifacts as process）**——spec-driven 浪潮的共识：流程不靠自觉，靠仓库里的持久产物（spec / tasks / ADR / NOTES / 复盘记录）驱动；每个技能必须定义它的产出物与验收标准，否则不许存在。

## 0.5 资产单套化（「不分叉」裁定的落地设计，v1.2 重写）

**裁定**：firefly 的目标是「一份手工编辑源服务所有平台」。**仓库现状已具备该机制的雏形**——本设计不再新建布局，而是把已有机制扩展到位。

**现状依据（2026-11-20 实测，v1.2 修正）**：

- `manifests/platform-assets.json` 已声明：`shared/ is the single hand-edited source rendered to assets/codex and assets/claude by scripts/sync-platform-assets.mjs`；`{{PLATFORM_SPAWN}}` / `{{PLATFORM_HOME_ENV}}` token 在用；`node scripts/sync-platform-assets.mjs --check` 现为 exit 0；`tests/test-platform-asset-parity.sh` 与 CI 均调用该守卫。
- `assets/shared/skills/` 已承载 10 个技能的单源，`assets/shared/superpowers/` 承载 4 个；两侧 `assets/{claude,codex}/skills/` 目录集合完全一致（各 19），4 个技能逐字节相同。
- **实测差异口径**（`diff -U0` 逐 hunk）：**16 个 SKILL.md 有差异**（v1.1 写的「15 个」不准）；**8 个超过 2 处**（playwright-interactive 10 hunk / firefly 6 / subagent-driven-development 6 / openspec-explore 4 / doctor 3 / repair 3 / archive-change 3 / openspec-propose 3）；其中 **2 处是能力性差异**——`subagent-driven-development` 在 Codex 侧多一段「仅在子代理接口暴露 model selection 时适用」的降级分支、并把「Always specify the model」改为「When the platform supports model selection」；`playwright-interactive` 在 Codex 侧增 `config.toml`、`--sandbox danger-full-access`、`codex.emitImage()`。
- `manifests/platform-assets.json` 已把 11 项登记为 `platformSpecific` 并给出功能性理由（`AskUserQuestion` 句级改写、`config.toml` + sandbox flag、`codex.emitImage()` 等）。

**结论（v1.2 改判）**：差异不是「措辞可以一比一消除」，而是「**11 项受控的能力性/接口性差异 + 5 项纯措辞差异**」。单套化的目标是**把手工双份降到 11 项受控差异**，不是追求「零分支的单文件」。据此，`shared` 保留为唯一编辑源并扩展，`platformSpecific` 分类继续使用。

**目标布局（在现有布局上扩展，不新建树）**：

```
assets/shared/skills/<skill-id>/SKILL.md      唯一手工编辑源（现 10 项 → 目标 18 项）
assets/shared/superpowers/skills/...           受管覆盖同规则单套化（现 4 项 → 目标 6 项）
assets/{claude,codex}/                         渲染产物，不手工编辑
assets/claude/commands/opsx/                     claudeOnly（Codex 无 slash-command 机制），继续登记
manifests/platform-assets.json                 shared / platformSpecific / claudeOnly 分类 + token 定义（保留）
manifests/{claude,codex}.json                  既有两份 manifest 保留，新增/更名/删除技能时逐条同步
scripts/sync-platform-assets.mjs               渲染器（保留并扩展 token）
scripts/install-{claude,codex}.sh / doctor-*   平台后缀保留，公共逻辑下沉 firefly-common.sh
```

**11 项 platformSpecific 的逐条处置（实施时按此表执行）**：

| 技能 | 差异性质 | 处置 |
|---|---|---|
| firefly（6 hunk） | Codex 60 秒等待环 vs Claude 原生回调 | 新增 token `{{PLATFORM_WAIT_LOOP}}`，正文平台中立 |
| subagent-driven-development（6 hunk） | Codex 侧 model selection 降级分支 | 新增 token `{{PLATFORM_MODEL_SELECTION}}` |
| playwright-interactive（10 hunk） | `config.toml` + sandbox flag + `emitImage` | 保留 platformSpecific（工具接口差异，无法 token 化）+ 平台注记小节 |
| openspec-explore（4 hunk） | `AskUserQuestion` 句级改写 | 新增 token `{{PLATFORM_ASK}}` |
| firefly-doctor（3 hunk）/ repair（3 hunk） | 路径与命令名 | `{{PLATFORM_HOME_ENV}}` 已覆盖，余下并入 doctor→firefly 合并改造 |
| archive-change（3 hunk）/ openspec-propose（3 hunk） | 命令名差异 | token 覆盖 |
| 其余 4 项 | 纯措辞 | 直接并入 shared |

**写法约定**：
- 正文平台中立：机制语义统一表述（如「经原生子代理机制派发」），平台特定工具名并列标注（`Task`/`spawn_agent`）
- 平台路径（`~/.claude`、`~/.codex`）不出现在 SKILL.md 正文，归渲染 token
- 差异不能 token 化的（Codex 等待环、playwright 的 sandbox flag），以「平台注记」小节集中并列，并在 `platform-assets.json` 登记为 platformSpecific

**全量资产处置表（v1.2 补齐受管面，19 claude 技能 + 6 superpowers 覆盖 + 5 个 claudeOnly 命令 + 3 份 manifest + 14 个脚本 + 21 个测试）**：

| 资产 | 处置 | 对应设计点 |
|---|---|---|
| firefly | 演进（next 子命令 + 静态注册表 + 契约内挂载） | 01 |
| firefly-think / draw / propose / tasks / implement / verify-web / review / archive | 演进 | 02/03/04/06/07/14/16/25 |
| **playwright-interactive** | 演进（保留 platformSpecific，挂 14） | 14 |
| firefly-doctor | **并入 firefly**（01 注册表的承载，退役独立技能） | 01 |
| firefly-init / firefly-repair | 保留为运维技能（安装/修复流程，不进 26 点） | — |
| openspec-propose / explore / apply-change / archive-change | 保留为 openspec 底层路由目标（propose/archive 演进依赖） | 04/25 |
| openspec-sync-specs | 更名演进 firefly-docs（过渡期保留旧名别名） | 23 |
| mermaid-diagram-specialist + scripts/firefly-draw.sh | Mermaid 职责独立保留（`firefly diagram` 子命令，不再挂 draw） | 03 |
| superpowers 六覆盖 | test-driven-development 更名演进 firefly-tdd（过渡别名）；其余五项按 03/06/07/16 并入对应技能后**删除目录** | 03/06/07/13/16 |
| **assets/claude/commands/opsx（5 文件）** | **保留**为 claudeOnly；不要求迁入 shared（Codex 无对应机制） | — |
| **assets/shared/（10 技能 + 4 superpowers）** | **保留并扩展**为唯一编辑源；不取消 | — |
| **assets/{claude,codex}/** | 由 shared 渲染；迁移期后删除两侧手工副本，仅保留渲染产物 | — |
| **manifests/platform-assets.json** | 保留；扩展 token 定义；新增条目与技能同批提交 | — |
| **manifests/{claude,codex}.json** | 保留；51 条 source 指向 shared 或平台树，改名/删除时逐条同步 | — |
| **scripts/install-{claude,codex}.sh** | 平台后缀保留，公共逻辑下沉 `firefly-common.sh`（diff 由 156 行收敛） | — |
| **scripts/doctor-{claude,codex}.sh** | 同上（diff 由 116 行收敛）；`firefly doctor` 按平台名分发，取消 codex 优先探测 | 01 |
| **scripts/firefly.sh** | 增 `next`、`diagram` 子命令分发 | 01/03 |
| **scripts/check-release-metadata.sh** | 去掉 `for platform in codex claude` 硬循环，改读 platform-assets 分类 | — |
| **scripts/sync-platform-assets.mjs** | 保留并扩展（新增 token + completeness 断言） | — |
| **tests/*（21 个）** | 10 个绑定三树布局的改路径；新增 completeness 断言（`assets/shared/` 每个目录必须出现在 platform-assets.json） | — |

## 1. 技能总览：新增 / 演进 / 合并

firefly-next 目标态共 **23 个技能**：11 个演进 + 12 个新建。
三个维度并入相邻技能：**17 简化→review 维度、21 CI→guard、22 废弃→archive**。doubt/guard 曾按 mar 建议合并，经用户裁定回退为独立技能。

**合并判据（v1.2 改为三条可判定条件，替代原「维护成本大于收益」一句话）**——一个维度独立成技能，须同时满足：
1. **独立触发时机**：不被其他技能的触发条件覆盖（有自己点名进入的场合）；
2. **独立产物类型**：产出物不是其他技能报告中的一节，而是可被单独引用的文件；
3. **产物被消费**：至少一个其他技能把它作为必附输入或必跑检查。

三条缺一即并入相邻技能（缺哪条并到承接该条的技能）。按此判据复核现状 26 点：17/21/22 三条全缺 → 并入；09 doubt（独立触发 + 独立报告 + 被 04/16 消费）→ 独立；24 trace（独立 `firefly trace` 触发 + 运行记录与埋点规范 + 被 25 消费）→ 独立；10 context（独立触发 + NOTES/交接纪要 + 被 07/15/25 消费）→ 独立。

| 组 | 技能 | 动作 | 一句话定位 |
|---|---|---|---|
| meta | firefly | 演进 | 总控路由 + 技能注册表健康检查 |
| define | firefly-think | 演进 | 需求追问：可判定问题清单 |
| define | firefly-draw | 演进 | 想法对垒：多方案强制竞争 |
| define | firefly-propose | 演进 | 规格成形：constitution + delta spec |
| define | firefly-bounds | **新增**（吸收 security 的定义面） | 质量契约：约束清单 + 安全红线定义 + 待挂载项提报 |
| plan | firefly-tasks | 演进 | 任务拆解：验证附着于任务 |
| build | firefly-implement | 演进 | 增量实现：小步 + 前沿派发 + 指针通信 |
| build | firefly-source | **新增** | 证据化依据：官方文档优先 + 引用溯源 |
| build | firefly-doubt | **新增** | 反证轮：独立子代理红队自己的方案 |
| build | firefly-context | **新增** | 上下文工程：最小充分与会话续航 |
| build | firefly-ui | **新增** | 前端工程：a11y 与组件质量门禁 |
| build | firefly-arch | **新增** | 接口与架构：契约先行 |
| verify | firefly-tdd | 演进（吸收 test-driven-development） | 测试先行：锁测试防自通过 |
| verify | firefly-verify-web | 演进 | 运行时验证：沙箱浏览器取证 |
| verify | firefly-debug | **新增** | 调试：RCA-first 证据链 |
| review | firefly-review | 演进 | 评审裁决：独立子代理 + 并行多维 + `--deep`/spec 档 |
| review | firefly-guard | **新增**（吸收 CI） | 安全与门禁：secrets/权限/供应链/CI |
| review | firefly-perf | **新增** | 性能：基准先行，数字说话 |
| ship | firefly-pr | **新增** | 交付：为评审者而写的 PR |
| ship | firefly-docs | 演进（吸收 openspec-sync-specs） | 文档与 ADR：决策即记录 |
| ship | firefly-trace | **新增** | 可观测：轻量运行记录 + 问题驱动埋点（OTel 仅作字段命名参考） |
| ship | firefly-archive | 演进（吸收 deprecation/shipping） | 收尾：definition-of-done + 废弃迁移 |
| extra | firefly-retro | **新增** | 复盘：transcript 取证 + 三透镜评审 + 结构化优先分流 |

合并说明：`simplification` 并入 review 的常设维度 + `--deep` 档；`ci` 并入 guard 的门禁挂载；`deprecation` 并入 archive。三个并入统一采用**「原文迁入宿主技能的 `references/<topic>.md`，正文只留一行指针」**——不重写摘要，避免细节随目录消失（v1.2）。

---

## 2. 逐点设计（26 维度）

### 01 总控与路由 / Meta & Routing

**现状**：firefly（显式编排、写死的子命令契约）——四套中唯一把「授权边界」写进路由层的。
**吸收（v1.2 修正归因）**：
- Addy `using-agent-skills`：**按开发阶段的固定决策树**（"什么阶段用什么技能"），不是检索/搜索式发现——本设计取其"单一入口 + 阶段路由"形态，不引入技能检索。
- Pstack `poteto-mode`：**目标→playbook 总路由 + 非协商项强制路由**（任意代码改动、跨边界改动、争议设计、提交前，各自动路由到对应 playbook）；「模式宣告」是本设计在其上的外推，标 **own design**。
- Matt `ask-matt`：单一入口——用户永远知道从哪个门进。
**依据**：Anthropic Agent Skills 官方实践——progressive disclosure：SKILL.md 正文保持 <500 行高信号，重资料放 references/ 按需加载；技能元数据（name/description）是路由的依据，必须可被检索。
**目标态（firefly 演进，吸收 doctor 并入 + nextup 技能）**：
- 触发：用户点名 `firefly` 或其子命令；「存在编码任务」不是触发条件。
- 职责：①**路由契约表**（v1.2 改为穷举登记，不是举例）：每条 =「子命令 → 技能 → 授权范围 → 阶段挂载 → 可用档」，**登记表见 §4.6**；契约内挂载不算隐式扩权，须模式宣告；②**技能注册表**（静态，firefly-doctor 并入后承载）：列出全部受管资产（23 设计技能 + 8 保留技能）、触发词与健康状态（description 是否漂移、references 是否在、SKILL.md 与注册表是否一致、**记录目录的过期/待迁移项**）——健康检查基于 baseline diff（复用 `doctor-claude.sh` 模型），不做使用频率追踪（静态资产无此数据源）；③**模式宣告**（own design）：进入/退出子命令时输出一行模式标记；④**`firefly next` 子命令**（吸收 nextup）：回答「下一步干啥」——盘点证据（git 状态 / TODO / 计划文档 / **NOTES.md 与 tasks.md 中未兑现的承诺**）→ 五类归类（风险排除/承诺兑现/断点续作/计划推进/债务清理）→ 优先级排序 → 3-5 项带证据、带完成标准、带第一步的提案，**只提案不执行**。
- 产出：路由决策一行；`next` 产出带证据的优先级提案表。
- 验收：触发不在 §4.6 登记表内的请求被拒绝并提示正确入口；登记表内的阶段挂载经模式宣告放行；注册表健康检查可对任一受管资产重跑。
- v1.2 注记：原「拒绝任何非点名触发」与「契约内挂载」字面互斥已由 §4.6 登记表消解；「会话承诺」改为可落盘的 NOTES/tasks 引用；注册表检查项新增记录有效期一项，与 §4.5 对齐。

### 02 需求追问 / Requirements

**现状**：firefly-think（结构化提问，收集背景与目标）。
**吸收（v1.2 修正归因）**：
- Matt `grill-with-docs`：**它是 `grilling` + `domain-modeling` 的组合调度入口**（原文仅 50 字符），真正的价值在盘问过程中同时产出 **ADR 与术语表**；「不问自己能查到的」这条纪律来自 `grilling`（"派一个子代理去查；不要问用户任何你自己能查到的东西"），不是来自本技能。
- Addy `interview-me`：一次只问一件事 + 每问附最佳猜测；本设计再补「2-4 个候选答案 + 都不是出口」，标 **own design**。
- Pstack `sharpen`：把模糊诉求磨成可判定命题（先复述、能观察的不问人）。
**依据**：context engineering 的「right altitude」——追问既不能碎成二十个Yes/No（脆），也不能泛泛「多告诉我一些」（空）；每轮追问应是「具体到能引导行为，开放到保留判断」。
**目标态（firefly-think 演进）**：
- 触发：`firefly think`；新任务进入 define 阶段时。
- 机制：①**先读后问**：提问前列出已读文件清单，禁止问其中已有答案的问题；②**可判定问题清单**：每轮 ≤5 问，每问附 2-4 个候选答案 +「都不是」出口；③**停机条件**：剩余问题全部「不影响方案分叉」时停止；④**裁定复述**（v1.1 新增，防误解与扩大解释）：用户的自由文本回答被映射为决策时，必须先复述为具体动作（「『X』= 做 Y，对吗？」）确认后才落文档，文档保留原话 + 解释链；项目语境的歧义词（如「分叉」「合并」）触发澄清而非最近选项硬套。
- 产出：需求纪要：目标 / 非目标 / 约束 / 已知未知，附「未决问题=空」显式声明。
- 验收：纪要中每个需求可判定——能写出「满足/不满足」的检验式。

### 03 想法打磨 / Idea

**现状**：firefly-draw 是 Mermaid 出图技能（23 行，description 为「generate a Mermaid interaction sequence diagram」，路由 mermaid-diagram-specialist + `scripts/firefly-draw.sh`）+ brainstorming（方案发散）。
**吸收（v1.2 修正归因）**：
- Pstack `arena`：**强制多方案对垒**——真实机制是 Frame（3-6 条可评分 rubric）→ Fan out（每候选独立 worktree）→ Cross-judge（交叉打分）→ Pick → **Graft（把落选者的强项移植进胜者）** → Verify。本设计取其「多案竞争 + 交叉裁决 + 移植强项」，不保留 worktree 细节。
- **「各自列出杀死自己的条件」出自 Addy `idea-refine`**（"什么可能杀死这个想法"），不是 arena——归因修正。
- Matt `prototype`：可丢弃原型——用最便宜的方式验证最贵的假设。
- Addy `idea-refine`：迭代收敛而非一次性定稿 + 杀死条件。
**依据**：AI 生成成本低导致「第一方案偏差」——agent 倾向接受第一个成形方案；对垒机制是对这种偏差的制度化纠偏（structured disagreement 的设计思想同样用于 16 评审）。
**目标态（firefly-draw 演进）**：
- 机制：①**双案下限**：非平凡决策（影响 >3 文件或含架构选择）必须 ≥2 个竞争方案 + 各自反例条件 + 交叉裁决 + **graft 移植落选强项**；**平凡变更**（≤3 文件且无架构选择）不强制对垒，但须在 spec 里写一句「为何判为平凡」（由 04 与 16 spec 档复核，v1.2）；②**假设分级**：假设按「验证成本」排序，最贵的先用原型/检索杀；③用户裁决点：对垒结果交用户选，agent 只推荐不拍板；④**Mermaid 职责迁出**（v1.1）：现 draw 的出图职责（mermaid-diagram-specialist + firefly-draw.sh）独立为 `firefly diagram` 子命令，draw 专注意法对垒——修「演进实为职责替换」与 01「路由表现状保留」的矛盾。
- 产出：方案对垒表（`changes/<id>/duel.md`）：方案 / 代价 / 风险 / 杀死条件 / 推荐理由 / graft 项。
- 验收：无对垒表的非平凡方案进入 spec 时，propose 必须打回；平凡变更须附判定句。

### 04 规格成形 / Spec

**现状**：firefly-propose（OpenSpec delta spec 流程）。
**吸收（v1.2 修正归因）**：
- Addy `spec-driven-development`：**四阶段门 SPECIFY → PLAN → TASKS → IMPLEMENT**（每阶段有出口检查），**不含 constitution 层**；constitution 层来自 GitHub Spec Kit（见「依据」）。
- Matt `to-spec`：把对话散落的决议收拢成结构文档的收束能力（不重新访谈，只综合已讨论内容）。
- Pstack：无对应（本点 Pstack 缺位，其哲学是 spec 即任务列表）。
**依据**：GitHub Spec Kit / OpenSpec / BMAD / Kiro 在 2025 共同验证的 spec-first 范式：constitution → spec → plan → tasks 分层；争议点「spec 放哪」的社区答案趋向 **spec 入仓库**（与代码同生命周期、可评审、可回滚）——firefly 的 OpenSpec 资产结构正是这个答案。反面教训（**定性描述，原始报告未核到，标【未验证】**）：spec 质量不受控时产出大段可疑代码——所以 spec 必须带验收标准，且验收标准必须可转测试。
**目标态（firefly-propose 演进）**：
- 机制：①**三层分离**：constitution（项目原则，长期，来自 spec-kit 范式）/ delta spec（本次变更，短命）/ tasks（执行清单）；②**验收标准即测试草案**：每条 Requirement 映射为 Scenario（Given/When/Then），语言可直接抄进测试文件；③**spec 完整性检查**：无验收标准的 spec 不许进入 tasks 阶段；**定稿的三个强制输入**（v1.2 由两个增为三个）——03 的方案对垒表 + 09 doubt 的反证报告 + 05 bounds 的约束清单，缺一不放行（定稿验收由 review 的 spec 档执行）；**平凡变更豁免**——改动 ≤3 文件且不含架构选择时对垒表可省，但 spec 里必须写一句「为何判为平凡」，由 review spec 档复核该判断。
- 产出：`openspec/changes/<id>/`：proposal.md / specs/*.md / design.md（可选）/ **duel.md（对垒表）/ doubt.md（反证报告）/ trace.md（运行记录）**——后三项路径固定，供 16 spec 档按路径读取（见 §4.5）。
- 验收：spec 评审通过；每条 Scenario 有 Given/When/Then；非平凡定稿必附对垒表与反证报告；平凡定稿附「为何平凡」判定句。

### 05 质量底线 / Constraints（新增 firefly-bounds）

**现状**：gap——约束散落在各技能的注意事项里，无一致执行。
**吸收（v1.2 补收）**：
- Addy `constraint-driven-development`（本点唯一对应）：**非功能约束先行**——性能/安全/兼容性预算在写第一行业务代码前定死，违反即停；其**执行核心是 diff 削弱检测**——盯住 diff 中质量线被下调的迹象（新增 `@ts-ignore`/`eslint-disable`/`# noqa`、被跳过或删除的测试、被剥掉的断言、未实现的 stub、被调低的阈值）。
- Pstack 的四原则（结构编码领域 / 边界校验 / 非法状态不可表示 / 幂等）——**归属 poteto-mode 的架构原则段**，本点借用为约束模板候选条目（v1.2 修正归属）。
**依据**：agent 安全实践的一致结论——约束写在 prompt 里会被长上下文稀释（context rot），必须落成**可执行检查**（lint 规则/CI 门禁/测试）才能常驻；「写下来」不等于「被遵守」。
**目标态（firefly-bounds，新增）**：
- 触发：`firefly bounds`；spec 阶段（契约内挂载，见 §4.6）。
- 职责：①**约束清单**（性能预算/内存上限/兼容矩阵/安全红线/数据边界/测试分层与速度预算/**PR 尺寸阈值**——**清单开放式**，retro 回流可扩展），每条绑定可执行验证；**无数字时走 Ratchet 棘轮**（记录当前实测值，只许变好不许变差——「编出来的数字会被忽略，测出来的数字会被守住」）+ 合理默认值表；②**diff 削弱检测清单**（v1.2 补收）：新增抑制注释 / 跳过或删除的测试 / 被剥的断言 / 未实现 stub / 被调低的阈值，逐项挂检查命令，**执行由 18 guard 承接**；③约束与任务挂钩——完成声明必须引用检查结果；④项目级 `bounds.md`（constitution 的一部分）；⑤安全红线类约束的**执行**由 firefly-guard 承接（见 18），bounds 管**定义**。
- 产出：约束清单 + 每条验证命令 + **待挂载项清单（供 guard 在 18⑤ 挂 CI；bounds 不直接写 CI 配置，避免与 guard 双主）**。
- 验收：抽检任意一条约束，能立即运行其验证命令并得到通过/失败；diff 削弱检测项在任一 diff 上可重跑。

### 06 任务拆解 / Tickets

**现状**：firefly-tasks + writing-plans（tasks.md 流程）。
**吸收（v1.2 补收）**：
- Matt `to-tickets`：任务的**原子性**——每个任务一个可独立验证的交付物；**垂直切片（tracer bullet）**——第一刀打穿全链路而不是先把某一层做完（v1.2 补收）。
- Addy `planning-and-task-breakdown`：依赖图——任务间阻塞关系显式化。
- Pstack：任务即 spec 的执行投影，不另造体系。
**依据**：sub-agent 架构实践——任务粒度决定可并行度与上下文隔离度；每个任务应能被一个「干净上下文」的子代理独立完成并返回摘要（1-2k token），这是任务拆解的客观标尺。
**目标态（firefly-tasks 演进）**：
- 机制：①**一任务一验证**：每个任务必须写「完成=什么测试/命令通过」，无验证的任务不许进列表；②**依赖显式**：tasks.md 中标注 blocked-by，**阻塞图即派发依据**（07 按前沿取任务，见下）；③**子代理标尺（v1.2 改写）**：任务描述必须做到「**指针足够**」——一个没有本次对话上下文的执行者，凭任务书里给出的路径（spec 节 / 任务书 / 相关文件 / 验收命令）就能接活；**不要求把 spec 抄进任务书**（那违反元原则 4 最小充分）；④进度即事实：勾选状态只能由验证结果驱动，不许手勾。
- 产出：`tasks.md`（现有格式演进：任务/验证/依赖/状态/指针）。
- 验收：任取一个完成任务，其验证命令可独立重跑通过；任取一个未开始任务，其指针足以让无上下文执行者开工。

### 07 增量实现 / Implementation

**现状**：firefly-implement + executing-plans + subagent-driven-development。
**吸收（v1.2 修正归因 + 补收）**：
- Addy `incremental-implementation`：小步提交——每步保持系统可运行（绿色台阶）。
- Matt `implement`：**722 字符的存根技能**（原文无「按 spec 逐条销账」），本设计不引用其表述。
- **Matt `implement-spec`（v1.2 补收，v1.1 整条遗漏）**：tasks 是**带阻塞关系的前沿图**而不是步骤列表；按前沿派发（可并行处并行）；**票级独立 worktree + merger 子代理**；子代理之间**只交换上下文指针**（spec 节 / 任务书 / commit / 笔记路径），不复制信息；探查子代理的笔记落仓库外目录。
- Pstack：无直接对应（实现纪律藏在四原则里）。
**依据**：上下文工程——执行代理上下文越短越准；长任务用 compaction + 结构化笔记续航，而不是无限堆历史。子代理执行范式：主代理持有计划，子代理持有任务，双方只交换任务书与结果摘要。任务粒度决定可并行度与上下文隔离度（与 06 的 blocked-by 图同源）。
**目标态（firefly-implement 演进）**：
- 机制：①**绿色台阶**：每完成一个任务，系统必须回到可运行状态（编译过/既有测试不红）；②**前沿派发（v1.2）**：按 tasks.md 的 blocked-by 图取「前沿」任务（无未完成前置者）派发，可并行处并行，写清每个子代理的 worktree 与合并责任；③**指针通信（v1.2）**：任务书只给指针（spec 节 / 任务文件 / 相关源码路径 / 验收命令），不复制正文；子代理回传摘要 + 证据链接；④**越界即停**：实现中发现 spec 未覆盖的分叉，停下走 think/propose，不许现场发挥；⑤**变更最小**：只动任务书声明的范围，顺手重构算越界（交 review 档位处理）。
- 产出：代码变更 + 每任务的执行摘要（做了什么/偏离什么/证据链接）。
- 验收：diff 可逐任务回放；无任务书外文件被改动（除锁文件等声明的副作用）；并行派发时各分支互不改同一文件。

### 08 证据化依据 / Evidence-Grounded（新增 firefly-source）

**现状（v1.2 修正）**：**完全缺位**——全仓库检索无任何技能主张「源码优先」；v1.1 写的「散见于各技能」不成立（`firefly-repair/SKILL.md:19` 的 upstream 指 OpenSpec 版本，不是源码依据）。
**吸收（v1.2 修正归因）**：
- Addy `source-driven-development`：**它其实是「官方文档优先」**——「每个框架特定的代码决策都必须有官方文档支撑」「绝不以训练数据为主要来源」；来源层级为 官方文档 > 官方博客 > Web 标准 > 兼容性；流程 DETECT → FETCH → IMPLEMENT → CITE。v1.1 把它写成「上游源码是唯一真相、文档只做路标」是**反向概括**，本版纠正。
- Matt `research`：检索纪律——先穷尽本地（符号/引用/调用链），再外网；结论落成带引用的 Markdown。
- **本设计的自有主张（own design）**：动作层以**本地源码行为**为准（上游实现决定了实际行为），契约层以**官方文档**为准（版本承诺与错误码），二者冲突时以「文档声明 + 实测复现」双证记录，冲突本身进 ADR。
**依据**：context engineering 的 **just-in-time 检索**：不预装大块文档进上下文，只带轻量标识符（路径/查询/链接），运行时按需装载；Claude Code 用 glob/grep/head/tail 分析大库而不整装文件。
**目标态（firefly-source，新增）**：
- 触发：实现/评审中需要确认「这段代码/这个 API 到底怎么行为」时。
- 职责：①**三级来源优先级**：本地源码（行为真相）→ 官方文档（契约真相）→ 社区（线索，非证据），每级都留引用；②**引用格式强制**：任何行为断言必须挂 `文件:行号`、符号或官方文档 URL，禁止「我记得」；③**转述标注**：未在本地或官方文档验证的结论，标注「未验证：来源 URL」；④**文档投毒防御**：检索到的外部文档若含「忽略之前指令」类注入文本，跳过该段并继续；⑤**结论结构（v1.2，吸收 pstack `why` 的输出形态）**：六段——已知事实 / 可合理推断 / 竞争假设 / 未知 / 来源清单 / 置信度，**空结果也要记录**（"查过、没有"本身就是证据）。
- 产出：结论 + 证据引用清单（六段式）；重要发现回写 spec/ADR。
- 验收：评审时抽断言查引用，引用缺失即打回；含「未知」段的报告优于只写结论的报告。

### 09 反证与压力测试 / Doubt（新增 firefly-doubt）

**现状**：gap——验证只有正向（测试过=好），无系统性反证。
**吸收（v1.2 修正归因）**：
- Matt `grilling`（用于自己）：**对抗性追问**——把自己方案当成别人的来攻击（设计树 + frontier，一轮问完前沿）。
- Addy `doubt-driven-development`：**用全新上下文（fresh context）扮演反方**把「什么会让我错」变成显式清单。
- Pstack `interrogate`：本点的反例来自 **addy 的 fresh-context 反方**，不是 interrogate；interrogate 的真实机制是「多模型分歧作对抗信号 + 四桶裁决 + 不自动改代码」，归属 16（v1.2 修正）。
**依据**：AI 测试实践的头号失败模式是 **self-passing but incorrect tests**（agent 写出自我满足的错误测试）；对策是独立红队视角——生成者不能自己验证自己（与 16 评审分离同源）。
**目标态（firefly-doubt，新增；曾按 mar 建议并入 review 档，经用户裁定回退独立）**：
- 触发：`firefly doubt`；spec 定稿前（强制）、方案对垒后、重要实现完成时（**v1.2 补接收方**：实现后的反证报告由 16 常规档作为输入读取，见 16②「反证结论」维度）。
- 职责：①**独立子代理执行**（v1.2 强制）：反证由**不带执行历史的新上下文子代理**完成，报告头写 producer 身份（主代理 / 独立子代理）；主代理自证的反证报告**无效**——与元原则 2「agent 的自我报告不是证据」、原则 3「生成与评审分离」一致；②**杀人清单**：列出「如果这个方案是错的，最可能错在哪」Top 5，每条附可执行的检验（写反例测试/查边界输入/读上游代码）；③**反例测试**：为最可能的两条写实际的反向测试并运行，贴运行输出；④**结论分级**：反证存活 / 带伤存活（列伤）/ 阵亡。
- 产出：`changes/<id>/doubt.md`（攻击点 / 检验 / 结果 / 存活判定 / producer），作为 04 定稿门与 16 spec 档的必附输入。
- 验收：spec 定稿无反证报告不放行（P0 流程点，放行检查由 review 的 spec 档执行）；review spec 档**复跑任一 killing test** 作为实证（v1.2，防格式检查化）。

### 10 上下文工程 / Context（新增 firefly-context）

**现状（v1.2 修正）**：**协议已有、技能缺位**——`superpowers/skills/subagent-driven-development/SKILL.md:302-311` 已有 Durable Progress 协议（"Track progress in a ledger file…after context compaction, rebuild the recovery view from tasks.md, Git history, .superpowers/sdd/progress.md"），`executing-plans/SKILL.md:94` 同源；缺的是**统一承载与验收**，不是从零发明。本技能是「合并既有两处协议 + 补齐交接物标准」。
**吸收**：
- Addy `context-engineering`（本点最强）：系统化的上下文观。
- Matt `handoff`：会话/代理间交接的结构化（交接物是给人也是给下一个 agent 的）。
**依据**：Anthropic context engineering 全文，四板斧落地：①**最小充分**——只装达成目标的最小高信号集；②**JIT 检索**——带标识符不带大块数据；③**compaction**——接近窗口上限时高保真压缩（保留架构决策/未解 bug/关键约束，清工具原始输出）；④**结构化笔记**——NOTES.md/todo 落盘，跨 compaction 续航；子代理只回传 1-2k token 摘要。
**目标态（firefly-context，新增）**：
- 触发：`firefly context`；长任务（预计 >30 分钟/多阶段）；会话交接；**接近上下文上限或收到压缩摘要时**（v1.2：compaction 事件对静态资产不可观测，改用可观测的前兆）。
- 职责：①**任务开卷**：启动时产出最小上下文装载清单（要什么/为什么/去哪取）；②**续航协议**：每阶段末把「决策/未决/下一步」写入 `NOTES.md`（或 tasks.md），使 compaction/换会话可无损恢复；③**交接物标准**：跨代理交接必须含（目标/已完成/未完成/证据/风险），缺一项不算交接完成；④**上下文卫生**：提醒清理已完成工具输出、过期检索结果。
- 产出：NOTES.md / 交接纪要。
- 验收：compaction 后代理能仅凭 NOTES.md + tasks.md 恢复并继续，不问用户已答过的问题。

### 11 前端工程 / Frontend（新增 firefly-ui）

**现状**：gap——浏览器侧只有验证（verify-web），无构建侧前端工程。
**吸收**：
- Addy `frontend-ui-engineering`（本点唯一完整对应）：组件质量、可访问性、UI 产线规范三合一。
- Pstack 的领域结构化思想移植：UI 状态也用「非法状态不可表示」约束。
**依据**：2025 a11y 实践共识——自动化（axe/Lighthouse 类）只覆盖约 30-40% 的 WCAG 检查点，趋势是从静态规则检查走向 IDE/CI 内 agent 化解释，但**手动键盘走查不可替代**；另外 agent 自己也是 a11y 的消费者（正确标签帮 agent 浏览）。
**目标态（firefly-ui，新增）**：
- 触发：`firefly ui`；任务涉及 UI 组件/页面时自动挂载。
- 职责：①**组件门禁**：新组件必须过（语义化标签/键盘可达/焦点管理/对比度/ARIA 正确使用）检查清单；②**状态约束**：UI 状态机显式化（loading/error/empty/success 全枚举，禁止非法组合）；③**双轨 a11y**：自动扫描 + 键盘手动走查（Tab 序/焦点陷阱/Esc 退出）；**工具基线（v1.2 补齐）**：自动轨用 `npx @axe-core/cli <url>` 或项目已有 axe/Lighthouse 配置，无扫描器时**只跑手动清单并在报告标注「自动轨未执行：无扫描器」**，不得以「无工具」为由跳过整轨；④**交给 verify-web 的接口（v1.2 双向）**：产出「视觉断言清单」（选择器 + 期望状态），由 14 在运行时验证中接收，14 的验证报告回填本清单的执行结果。
- 产出：组件检查清单结果 + a11y 双轨报告 + 视觉断言清单。
- 验收：新 UI 无「自动扫描通过但键盘不可达」的组件；视觉断言清单在 14 有对应执行记录。

### 12 接口与架构 / Architecture（新增 firefly-arch）

**现状**：gap——架构决策无技能承载，散在 think/implement 里。
**吸收（v1.2 修正归因）**：
- Matt `codebase-design` + `improve-codebase-architecture`：结构演进观——架构是持续重构出来的；其 **depth / interface / seam** 三个词汇是本点的主要借用（v1.2 补回，v1.1 丢失）。
- Addy `api-and-interface-design`：**接口先行**——先定契约（签名/错误码/版本），再写实现；含 Hyrum's Law 与单版本规则。
- Pstack `architect`：**空实现体 sketch（签名 + 类型 + 模块边界）→ 多模型 agree → implement → scrap**，这是本点「契约先行」最贴合的机制（v1.2 修正：v1.1 把四原则记在 architect 名下，实际四原则在 `poteto-mode` 的架构原则段）。
**依据**：SDD 分层实践——接口契约是 spec 的一部分（可评审、可生成 mock、可写契约测试）；上下文工程的工具设计原则同样适用于 API：无重叠、自包含、语义清晰——「如果人不能一眼说出该用哪个接口，agent 也做不到」。
**目标态（firefly-arch，新增）**：
- 触发：新模块/新公共 API/跨模块数据流变更时。
- 职责：①**契约先行**：公共接口先出 **sketch**（签名 + 类型 + 错误 + 版本策略 + 兼容承诺，实现体留空），挂进 spec，再填实现；②**结构决策记录**：架构选择走 ADR（与 firefly-docs 联动）；③**边界纪律**：模块间只经显式契约通信，禁止深层 import；④**演进式重构**：大改分台阶（每步可运行），拒绝一次推倒；⑤**四原则借用（v1.2 归位）**：结构编码领域 / 边界一次校验 / 非法状态不可表示 / 幂等，来自 `poteto-mode` 架构原则段，作为契约评审的检查项。
- 产出：接口契约文档 + ADR。
- 验收：契约测试存在且与实现同步；无未记录的跨边界依赖。

---

### 13 测试驱动 / TDD

**现状**：test-driven-development（受管覆盖）——红绿重构循环。
**吸收（v1.2 修正归因）**：
- matt `tdd` 与 addy `test-driven-development` 主张**先写失败测试**（matt 另限"只在预先约定的接缝处测试"）。
- **Pstack `tdd` 有显式例外**（v1.2 补回，v1.1 的「三套罕见共识」把它抹平了）：「只在用户明确要求 TDD、存在失败测试/回归测试，或 bug 有便宜的本地测试目标时使用；测试路径不清楚、昂贵、集成很重或未被要求时**跳过**」「**不要为了满足流程而强行写测试**」。
- **「基线先行」在 addy 版零命中**（其首步是"先发现技术栈"）；本设计的「基线先行」标 **own design**。
**依据**：2025 AI-TDD 实践的两个硬结论：①**锁测试**——agent 不得修改已有测试来达成通过（改测试=改需求，须显式走 spec 流程）；②**防自通过**——agent 生成「自我满足的错误测试」是头号失败模式，对策是测试与实现分代理写、或测试先经人/独立代理评审。
**目标态（firefly-tdd，演进吸收现有 test-driven-development）**：
- 机制：①**基线先行**（own design）：动代码前跑全量测试，红的先修或显式记录豁免；②**红→绿→重构**，**红必须有证据**：新测试的失败输出贴进任务摘要（16 读取，见 16 输入清单）；③**锁测试条款**：需要改测试时停下走变更流程，禁止顺手改（改测试=改需求）；**批准主体（v1.2 补全）**——走 04 的 delta spec 变更，由 16 spec 档裁决；④**测试分层**：单元/集成比例与速度预算进 bounds；⑤**TDD 豁免（v1.2，pstack 条款）**：测试路径昂贵/集成过重/未被要求时可显式跳过 TDD，但须在任务摘要写「跳过理由 + 替代验证方式」；⑥**接缝纪律**（吸收 matt）：只在预先约定的接缝处测试——写测试前列出接缝并与用户确认（旧接缝优先、高杠杆接缝优先，实在没有才开新的），未经确认的接缝不写测试；⑦**更名迁移**：superpowers 的 test-driven-development 更名演进为本技能，过渡期保留旧名别名触发，按 22 点废弃纪律出显式迁移通知。
- 产出：测试代码 + 每任务的「红证据→绿证据」对（写入 `changes/<id>/tasks.md` 的任务条目下）。
- 验收：新增测试的首次失败输出可查；无「实现与测试同提交且测试从未红过」的可疑对。

### 14 运行时验证 / Browser

**现状**：firefly-verify-web + playwright-interactive（受管）——浏览器实证。
**吸收**：
- Addy `browser-testing-with-devtools`：**独立浏览器 profile**——默认 profile 带着登录态/邮箱/银行会话，agent 驱动浏览器等于把这些交给它；必须用隔离 profile。
- Pstack `create-verification-skill`：**为项目生成一个本地 `verify` 技能**（一项目一份，供所有 playbook 复用）——v1.2 修正：v1.1 写成"每个功能一份"，与原文相反且与 23 技能上限冲突。
**依据**：agent 安全实践（隔离执行环境）+ E2E 验证实践（人类可见工作区 vs 自动化环境的取舍）；「截图即证据」——验证结论必须挂可复核的产物（截图/trace/网络记录），口头「页面正常」不算。
**目标态（firefly-verify-web 演进）**：
- 机制：①**隔离 profile 强制**：任何浏览器验证必须在独立/一次性 profile 中进行（`--isolated`），**profile 标识（创建时间 / 临时目录）写入归档**；②**证据四元组（v1.2 由三元组扩充）**：验证结论 = 操作序列 + 截图/录屏 + 关键 DOM/网络断言 + **profile 标识**，四者齐才算验证；③**验证技能沉淀**：同一功能的验证脚本**第二次被重写时**（文件即状态，不依赖跨任务计数）提炼成可重放脚本（吸收 Pstack）；④**作用域声明**：验证前声明「将访问的域名/触发的动作」，超域即停；⑤**接收 11 的视觉断言清单**（v1.2 双向）：按清单逐条执行并在报告回填结果。
- 产出：验证报告（四元组归档路径 + 视觉断言清单执行结果）。
- 验收：任一「已验证」结论可打开其证据归档复核，且归档含 profile 标识。

### 15 调试修复 / Debugging（新增 firefly-debug）

**现状**：gap——调试靠通用能力，无纪律约束，易滑向试错式补丁。
**吸收**：
- Matt `diagnosing-bugs`：核心是「**构建一条会对这个 bug 变红的反馈循环**」（原文自称"这才是这个技能本身"）；「先诊断后动手」是本设计的提炼（v1.2 修正）。
- Addy `debugging-and-error-recovery`：错误恢复的结构化（分类→策略→动作）。
**依据**：2025 调试实践的聚合共识：①**RCA-first**——改代码前必须先给出根因假设及证据，防止 trial-and-error 式「vibe debugging」；②**证据链**——每步结论挂证据（日志/断点/最小复现）；③**二分隔离**——从 O(N²) 的怀疑面收缩到单变量（deterministic replay 是理想形态，最小复现是平替）；④ Debug2Fix 等研究证明「调试子代理 + 交互式调试工具」显著优于主代理顺带调试。
**目标态（firefly-debug，新增）**：
- 触发：`firefly debug`；同一测试的修复尝试**未生效**（v1.2：改为可观测事实，不依赖「两次」这类跨任务计数）/ 非预期行为 / 线上问题排查。
- 职责：⓪**停线保存现场**（v1.1 第 0 步，吸收 addy Stop-the-line）：进入调试即停止叠加功能改动，先保存原始失败证据（错误输出/日志/复现步骤）；①**最小复现优先**：先造最小复现，复现不了先解决「为什么复现不了」；②**假设登记**：根因假设显式列出（≥1 条），每条绑一个检验实验；③**单变量改动**：每轮只动一个变量，改动前后都跑复现；④**根因≠症状**：修复必须能解释「为什么治的是根因」；⑤修完把根因与修法写入任务摘要（供 retro 沉淀）。
- 产出：调试记录（复现 / 假设 / 实验 / 根因 / 修复 / 回归测试）。
- 验收：回归测试锁死原 bug；无「改了三处不知道哪处治好」的合并。

### 16 评审裁决 / Review

**现状**：firefly-review + requesting-code-review（受管）。
**吸收（v1.2 修正归因，三条全部改写）**：
- Pstack `interrogate`：**每个已配置模型派一个评审者，对抗信号来自模型多样性而不是分配人设**；结论落**四桶**（Act on / Consider / Noted / Dismissed）；**不自动改代码**。（v1.1 写成"审讯式密度/假设逐条过堂"与原文不符。）
- Addy `code-review-and-quality`：**五轴检查清单**（正确性 / 可读性 / 架构 / 安全 / 性能）。
- Matt `code-review`：**规范 + 规格双轴**（仓库编码规范 / 是否忠实实现 issue 或 spec），两条线作为**并行子代理**运行、**互不污染上下文**、由本技能汇总。（原文无「必须改/建议/可接受」三档，该分档是本设计 own design。）
**依据**：**生成与评审分离**：AI 写得越多，评审越要独立；范式是独立评审子代理（与执行代理不同上下文）+ 并行多维检查 + 反馈环（主代理修复→评审子代理复审直到清零）。子代理对抗的实证文献为 *Adversarial Review: Structured Disagreement for Grounded Agentic Code Review*（arXiv 2608.18167）。
**目标态（firefly-review 演进，v1.1 吸收 mar 技能为独立性协议）**：
- **输入清单（v1.2 明确，防"有写入无读取"）**：diff + spec + 任务书 + **13 的红证据→绿证据对** + **09 的反证报告（doubt.md）** + **18 的安全检查报告** + 11 的视觉断言清单（当次涉及 UI 时）。路径统一按 §4.5 的产物契约读取。
- 机制：①**独立评审代理**：评审者不持有执行历史，只看输入清单（防锚定）；②**并行维度**：正确性（对 spec）/ 简化（17 点）/ 风险（边界与异常）/ 测试（覆盖与质量）/ **安全（v1.2 补，挂 18 的清单）** / **反证结论（v1.2 补：对 09 反证报告逐条裁决，实现后反证的唯一读取方）** / **标准一致性**（审查判据是否被一致应用，专抓「判据不对称」）；③**裁决式意见（own design，注明）**：每条 = [必须改|建议|可接受] + 理由 + 位置——该三档为本设计定义，不冠以 matt 出处；④**清零环**：必须改项不归零不通过，复审**由同一评审包 + 一个新评审代理**增量做（v1.2：平台子代理是一次性回调，"同一代理"不可保证）；⑤**thermo 档位**：`--deep` 整模块深度简化审查；⑥**spec 档**：输入=spec+对垒表+反证报告+bounds 约束清单（无 diff），维度=Scenario 完整性 / 验收可测性 / 与 constitution 冲突 / **复跑任一 killing test**，04 的定稿验收由本档执行。
- **独立性协议**（吸收 mar）：一 agent 一维度（单维深挖胜过全面浅扫）；reviewer 互不见彼此结论；同一问题 ≥2 维度独立命中才高置信，单维度无旁证降置信；冲突结论保留双方证据标「待人工」不和稀泥；汇总者必须去重/裁决/定级复核，禁止粘贴拼盘。
- **档位谱**：轻量档（小 diff 只跑正确性+测试，阈值进 bounds）← 常规维度 → `--deep` / spec 档。
- 产出：评审报告（分维度裁决清单）；spec 档产出定稿裁决 + 反证报告归档。
- 验收：无未裁决的必须改项；评审/执行上下文隔离可查；spec 定稿必附反证报告（P0 流程点）且 killing test 有复跑记录；输入清单中每一项都能在报告里找到对应的裁决行。

### 17 代码简化 / Simplification（并入 16）

**现状**：gap（独立技能缺位）。
**吸收**：
- Addy `code-simplification`：简化是独立工序，不是顺手做。
- Pstack `thermo-nuclear-code-quality-review`：**深度清理档位**——极端简化审查作为可选重炮。
**依据**：评审分离原则——简化判断交给独立评审维度比执行代理自查有效；「最小充分」原则同样适用于代码：能删的分支/抽象/防御都是认知负担。
**目标态（16 的一个评审维度 + 一个档位）**：
- 机制：①review 的常设维度「简化」：每 diff 问三题——能删吗？能并吗？这层抽象有第二个使用者吗（YAGNI）？②**thermo 档位**：`firefly review --deep` 触发深度简化审查（整模块视角，吸收 Pstack 重炮语义），作为可选档而非常驻；③**原文落点（v1.2）**：addy `code-simplification` 全文迁入 `assets/shared/skills/firefly-review/references/simplification.md`，正文只留一行指针——不重写摘要，避免细节丢失。
- 产出：简化维度结论（常规档）/ 独立简化清单（`--deep` 档）。
- 验收：常规 review 必含简化维度结论；thermo 档位产出独立的简化清单；references 文件存在且被 SKILL.md 引用。

### 18 安全加固 / Security（新增 firefly-guard，吸收 CI）

**现状**：gap——安全靠通用常识，无专门防线。
**吸收**：
- Addy `security-and-hardening`：**参数化/最小权限/输入不信任**三件套，清单化；**威胁建模优先**（trust boundary + STRIDE）——v1.2 补回，v1.1 丢失。
- Pstack `thermo-nuclear-review`：安全作为重炮审查档。
**依据**：2025 agent 安全实践的一致清单：①**secrets 注入而非环境**——密钥经注入进入进程，不落上下文/日志/文件；②**最小权限 token**——过度授权（over-scoped token）是泄密主通道；③**approval gates**——不可逆动作（外发/删除/force push/发布）必须人工门禁；④**供应链**——依赖变更（新增/升级）单列审查；⑤提示注入与数据外泄的常规化防御（对齐 08 的文档投毒防御）。
**目标态（firefly-guard，新增，吸收 CI/CD 门禁；曾并入 bounds，经用户裁定回退独立）**：
- 触发：`firefly guard`；依赖变更时；发布前；16 的安全维度自动挂载（契约内挂载，登记于 §4.6）。
- 职责：①**安全清单执行**：参数化查询/输入校验/权限最小化/密钥不落盘 + **diff 削弱检测**（05② 的执行者），逐条通过/不通过（bounds 安全红线的执行视图）；②**secrets 注入**：密钥经注入进入进程，不落上下文/日志/文件；③**供应链单列**：依赖变更独立评审（版本差异/已知 CVE/维护状态）；④**不可逆动作门禁**：以可逆性判据为主规则（不可逆即停待批），外发/删除/发布为示例枚举而非穷举；**审批条目落盘（v1.2 补）**——每次"停待批"写一条 `{动作 / 可逆性判据 / 批准人 / 时间 / 决定}` 到 `changes/<id>/approvals.md`；⑤**CI 门禁挂载**（并入原 CI 点）：接收 05 的**待挂载项清单**、13 的测试、11 的 a11y 扫描，统一挂 CI，门禁红=不许合；**本技能是 CI 配置的唯一作者**（避免与 bounds 双主）。
- 产出：安全检查报告 + `approvals.md` + CI 门禁配置。
- 验收：抽任一门禁可重跑；**secrets 零出现**的扫描口径（v1.2 补齐）——命令 `git grep -nIE '(sk-[A-Za-z0-9]{16,}|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36}|-----BEGIN (RSA|EC|OPENSSH) PRIVATE KEY-----)'` 覆盖 `changes/`、报告目录与提交 diff，命中即失败；不可逆动作抽检其 `approvals.md` 条目存在。

### 19 性能优化 / Performance（新增 firefly-perf）

**现状**：gap。
**吸收**：
- Addy `performance-optimization`：先测量后优化，拒绝猜。
- Pstack `benchmark-checklist`：**基准清单**——优化前后同基准对比，数字说话。
**依据**：性能工程通识在 agent 时代的强化——agent 极易「顺手优化」制造复杂度而不解决瓶颈；对策是把「测量→定位→改动→复测」锁成流程，性能预算进 bounds（05）。
**目标态（firefly-perf，新增）**：
- 触发：`firefly perf`；bounds 声明性能预算且变更可能触碰时（契约内挂载，见 §4.6）；用户报性能问题。
- 职责：①**基准先行**：无基准不优化——先建立可重复测量（脚本/命令+环境说明），**复测取中位数/趋势对比，先审测量方法本身再信数字**（v1.1，防单次抖动误报触发假收益/假回滚）；②**单点归因**：瓶颈定位挂 profile/计时证据，不接受「应该是这里」；③**改动对赌**：优化前预测收益，改后复测对照，不达标回滚；④复杂度代价申报：以复杂度换性能时显式记录（进 ADR）。
- 产出：基准脚本 + 前后对比数据 + 优化记录。
- 验收：每个性能声明的 PR 附带可重跑的基准对比。

### 20 版本与 PR / Delivery（新增 firefly-pr）

**现状**：gap——git/PR 操作散在全局规则里，无技能化。
**吸收**：
- Pstack `make-pr-easy-to-review`：**为评审者而写**——PR 的第一读者是评审者（人或代理），标题/描述/大小都服务评审效率。
- Matt `pr`：PR 的结构与惯例。
- Addy `git-workflow-and-versioning`：小步提交、消息即历史。
**依据**：评审分离原则的延伸——PR 是评审的输入接口，接口质量直接决定评审质量；小 PR + 清晰消息 = 评审代理的上下文最小充分。
**目标态（firefly-pr，新增）**：
- 触发：`firefly pr`；任务组完成进入交付时。
- 职责：①**PR 体检**：单 PR 单主题、diff 尺寸阈值（**阈值取自 05 的 bounds 清单**，超限拆分）、提交消息逐条能独立解释；②**评审者导语**：PR 描述必含（为什么/做了什么/怎么验证/风险），验证部分挂 14 的证据链接；③**拆分指引**：大变更按任务书自动建议拆分点；④与 16 联动：PR 就绪 = 评审报告清零。
- 产出：合规 PR（描述/证据/尺寸达标）。
- 验收：PR 清单全过；评审代理对 PR 的首次理解不需要额外提问。

### 21 CI/CD 门禁（并入 18 firefly-guard）

**现状**：gap。
**吸收**：Addy `ci-cd-and-automation`（本点唯一对应）：自动化门禁是约束的执行者。
**依据**：约束驱动（05）的结论——约束必须可执行才常驻；CI 是约束的自动执行处；agent 时代新增：CI 里跑的不只是测试，还有 a11y 扫描、安全扫描、基准回归（bounds 统一挂载）。
**目标态**：并入 firefly-guard 的「CI 门禁挂载」职责（见 18⑤），不再单列技能——门禁的「定义」在 bounds，门禁的「执行」在 CI，guard 负责挂载与红绿裁决。**原文落点（v1.2）**：addy `ci-cd-and-automation` 全文迁入 `assets/shared/skills/firefly-guard/references/ci-cd.md`（门禁分层流水线 / CI 失败回流给 agent / Dependabot / Build Cop / CI 优化），正文只留一行指针。

### 22 废弃与迁移 / Deprecation（并入 firefly-archive）

**现状**：gap。
**吸收**：Addy `deprecation-and-migration`（本点唯一对应）：废弃是显式流程——标记→通知→迁移路径→时间表→移除。
**依据**：SDD 的产物观——废弃决策是需要记录的变更（影响使用者的契约变更），应走 delta spec 而非顺手删除；与「先读后改、先查后删」的全局纪律一致。
**目标态（并入 firefly-archive 的「收尾」职责，v1.1 补全机制）**：
- ①废弃清单（API/配置/文件），每项带迁移路径与时间表；②移除动作走 delta spec（破坏性变更显式化），**additive 先行、destructive 单独部署（expand-contract）**；③迁移脚本作为产物沉淀，**每个迁移必须有 down path**（没有回退路径的迁移就是不可逆部署）；④粒度=一次迁移一个消费者；⑤默认 advisory 建议弃用，强制移除须单独批准（审批条目写 `changes/<id>/approvals.md`，与 18④ 同格式）；**原文落点（v1.2）**：addy `deprecation-and-migration` 全文迁入 `assets/shared/skills/firefly-archive/references/deprecation.md`。
- **产出（v1.2 补，原缺）**：废弃清单 + 迁移脚本（含 down path）+ `approvals.md` 条目。
- **验收（v1.2 补，原缺）**：抽任一已废弃项，能执行其 down path 回到废弃前状态；强制移除项有批准条目。

### 23 文档与 ADR / Docs

**现状**：openspec-sync-specs（受管覆盖）——spec 与实现同步。
**吸收**：
- Addy `documentation-and-adrs`：**ADR 记录为什么**——决策的上下文（备选/理由/后果）比结论更值钱。
- Pstack `why`：**带引用的证据化重建**——`git blame` / PR 元数据的代码锚点、七类证据并行查、**已知与推断分离**、**空结果也要记录**（"查过、没有"是结论）、置信度汇总；原文明确**不默认产出 ADR**，v1.1 写成"落成文档"与其立场相反（v1.2 修正）。本点只借其**取证形态**，ADR 的强制触发来自 addy。
- Matt `domain-modeling`：领域模型是文档的核心章节。
**依据**：产物即流程原则——文档不是事后补的装饰，是流程的承重结构；context engineering 的 structured note-taking 把文档当成 agent 的外部记忆：文档写给「下一个上下文」（人或 agent），可检索、可增量。
**目标态（firefly-docs，演进吸收 openspec-sync-specs）**：
- 触发：spec 变更、架构决策、任务完成归档时。
- 职责：①**spec 同步**（现有职责保留）：实现与 spec 漂移即报；②**ADR 强制触发**：架构/接口/依赖/性能复杂度等不可逆选择时建 ADR（背景/备选/决定/后果四段式）；③**文档面向检索**：标题即查询词，章节自包含，不写「如前所述」；④**过期即删**：与代码矛盾的文档比没有文档更危险，发现矛盾当场修或删。
- 产出：spec 同步报告 / ADR / 更新的模块文档。
- 验收：抽任一 ADR，其「备选方案」段非空；任一 spec 条目能指到对应实现/测试。

### 24 可观测性 / Observability（新增 firefly-trace）

**现状**：gap。
**吸收**：Addy `observability-and-instrumentation`（本点唯一对应）：结构化日志/指标/追踪三支柱。
**依据**：2025 的标准化进展——**OpenTelemetry GenAI 语义约定**成为 agent 遥测的事实标准（LLM 调用/工具使用/子代理交接都有 span 约定）；实践共识是 **tracing + evals 结合**：不只记录做了什么，还要能回答「为什么这样行为」「失败在哪一步」；对 firefly 这种编排型工作流，可观测的首要对象是**工作流自身**（每个子命令的进出/授权/产物）。
**目标态（firefly-trace，新增，v1.1 调整机制取向）**：
- 触发：`firefly trace`；**归档时由 25 显式调用**（v1.2：P0 阶段 01 的契约挂载尚未落地，"自动生成"没有挂载者；改为显式调用，待 01 落地后再开自动）。
- 职责：①**运行留痕**：每次任务产出结构化运行记录（时间线/进入的技能/关键决策/证据链接），字段用轻量 JSON/Markdown 约定，**OTel GenAI 语义约定仅作字段命名参考、不作合规要求**（v1.1 降级：本地落盘摘要无采集管线消费）；②**应用侧埋点**（问题驱动，v1.1 补收 addy）：添加任何埋点前先写下 on-call 工程师会问的 2-4 个问题，每个信号必须回答其一；日志结构化/级别语义/敏感字段脱敏/**标签基数控制**（标签只能来自小而固定的集合）；③**失败可回放**：记录足以让第三方理解「失败在哪一步、当时输入是什么」。
- 产出：`changes/<id>/trace.md`（五字段运行记录，与 §4.5 的「任务运行记录」同构）+ 埋点规范。
- 验收：任一历史任务的运行记录能独立回答「做了什么 / 依据什么 / 结果如何」——**保留期限内**（见 §4.5）。

### 25 发布与完成 / Shipping

**现状**：firefly-archive（归档收尾）。
**吸收（v1.2 修正归因）**：
- Addy `shipping-and-launch` + `definition-of-done`：**完成有定义**——发布不是「代码写完」，是清单销项。
- Pstack：无直接对应——v1.1 的「完成定义藏在阻断关系里」是自造理由；`poteto-mode` 有 Shipping playbook，但其重点是部署控制面（见下「范围声明」）。
**依据**：产物即流程——DoD 清单使「完成」可判定，杜绝「90% 完成度」的永远差一步；agent 场景特有：agent 声称完成 ≠ 完成，DoD 每项都要证据。
**目标态（firefly-archive 演进，吸收 deprecation）**：
- 机制：①**DoD 清单**：完成 = 清单逐项证据（测试绿 / **门禁绿** / 评审清零 / spec 同步 / 文档更新 / 临时产物清理），缺证据即未完成；**门禁载体（v1.2 去外部依赖）**——P0 阶段用仓库现成的 `tests/test-*.sh` 全绿 + `shellcheck` 通过作为「门禁绿」的判据，18 guard 在 P1 只补「新增检查如何写成 test 脚本 + 哪些进门禁」的规范；**spec 同步**在 23 落地前用「spec 与实现逐条比对」的手工记录顶替，并在销项表标注「23 未落地，手动核对」；②**归档**：任务资产进 openspec archive（现有流程），附 24 的 `trace.md`；③**废弃管理**（吸收 22）：废弃清单与迁移路径随归档维护。
- **范围声明（v1.2 补，防"漏了还是不做"的歧义）**：发布控制面（feature flag / 分批灰度 / 错误预算 / 回滚预案）**不在本技能范围**，归项目自有发布流程；本技能只管「完成判定 + 归档 + 废弃」三件事。
- 产出：DoD 清单（销项表）+ 归档记录。
- 验收：无「声称完成但销项表有空洞」的任务进入归档；销项表每行的证据都能打开（命令输出/报告路径/commit）。

### 26 复盘与学习 / Retro（新增 firefly-retro）

**现状**：gap——教训不回流，同类错误重复出现。
**吸收（v1.2 换骨架）**：
- **Pstack `reflect`（本点主骨架）**：①**定位并摘录当前 transcript**（只记用户提示与纠正、工具调用与结果、改动的文件；**不含诊断、结论、成因**——防止复盘被既有判断锚定）；②**并行派三个评审者**（Judgment / Tooling / Divergent 三个透镜）；③裁决为 **Accepted / Rejected / Backlog** 三档；④**结构化优先检查**——凡是能被 lint 规则、脚本、元数据标记或运行时检查更可靠执行的条目，一律移入 Backlog 走自动化，不写成文档条款。
- Matt `retro`（辅助）：其真实机制是「为编码 agent 的**环境**提改进」，7 类候选（导航 / 自动化检查 / 编码规范 / 全局 AGENTS.md / 工具经济性 / 空操作 / 信息访问）+ 按严重度呈报 + 机械性违规→lint/CI 分流。v1.1 写的「四问（什么成了/什么败了/学到什么/改什么）」在原文中**零命中**（v1.2 修正）。
- Pstack `why`：调查工具，归属 08/23；v1.1 把它当"固化成常驻触发器"的来源是角色错位（v1.2 修正）。
**依据**：context engineering 的外部记忆观——跨任务学习必须落盘成可检索产物；教训的可执行形态是技能 / 清单 / 门禁里的具体条款，不是一段感想文字。
**目标态（firefly-retro，新增，v1.2 换骨架）**：
- 触发：`firefly retro`；任务归档时（轻量）；**同一类返工在同一变更内出现第二次时**（强制，改为可观测事实，不依赖跨任务计数）。
- 职责：①**transcript 摘要**：按 reflect 的四项摘录（提示与纠正 / 工具调用与结果 / 改动文件 / **不含判断**）；②**三透镜评审**：Judgment（判断类教训）/ Tooling（工具与流程）/ Divergent（偏离与意外）各一路，并行；③**三档裁决**：Accepted（写回条款）/ Rejected（记理由）/ Backlog（转自动化）；④**结构化优先**：能被 lint/脚本/门禁执行的，**不进文档**，进 05 的开放清单或 18 的门禁配置；⑤**回流三通道**：技能条款（改 SKILL.md 须**以提案形式走 OpenSpec 变更**）、约束（进 bounds）、门禁（进 18 的 CI 挂载清单）；**「已批准待同步」的状态载体（v1.2 补）**——写进受管资产之外的 `.firefly/retro-approved.json`（记录 change id、目标技能、批准时间），01 注册表健康检查读取该文件作为 baseline diff 的已知清单，不再依赖已退役的 doctor；⑥**条款自查**：每次 retro 复查既有条款清单的长度与相关性，逐条裁决删留。
- 产出：复盘记录（`changes/<id>/retro.md`）+ 条款回流 diff 或 Backlog 条目。
- 验收：任何复盘至少产生一条可执行条款、一条 Backlog 自动化项，或显式的「不采纳理由」。

## 3. 实施对象清单（v1.2 重写：资产面 × 动作 × 路径）

根目录：`/code/ai/asjayli/firefly`。下表全部为**仓内**对象；`/tmp/slim-index/*` 的生成器脚本为仓外，本轮只读，处理方式见 §4.7。

### 3.1 技能面（31 项受管资产，逐行）

**A. 11 个演进技能**

| # | 技能 | 源路径 | 目标路径 | 动作 | 设计点 | manifest/脚本 |
|---|---|---|---|---|---|---|
| 1 | firefly | `assets/claude/skills/firefly/SKILL.md` | `assets/shared/skills/firefly/SKILL.md` | 演进 + 迁入 shared | 01 | 双 manifest source 改写 |
| 2 | firefly-think | `assets/shared/skills/firefly-think/SKILL.md` | 同路径 | 演进 | 02 | 无 |
| 3 | firefly-draw | `assets/shared/skills/firefly-draw/SKILL.md` | 同路径 | 演进（Mermaid 职责迁出） | 03 | 无 |
| 4 | firefly-propose | `assets/shared/skills/firefly-propose/SKILL.md` | 同路径 | 演进 | 04 | 无 |
| 5 | firefly-tasks | `assets/shared/skills/firefly-tasks/SKILL.md` | 同路径 | 演进 | 06 | 无 |
| 6 | firefly-implement | `assets/shared/skills/firefly-implement/SKILL.md` | 同路径 | 演进 | 07 | 无 |
| 7 | openspec-sync-specs → firefly-docs | `assets/shared/skills/openspec-sync-specs/SKILL.md` | `assets/shared/skills/firefly-docs/SKILL.md` | **更名**（旧名保留 alias 触发） | 23 | manifest id 改名 + 4 处引用同步 |
| 8 | firefly-verify-web | `assets/shared/skills/firefly-verify-web/SKILL.md` | 同路径 | 演进 | 14 | 无 |
| 9 | firefly-review | `assets/shared/skills/firefly-review/SKILL.md` | 同路径 + `references/simplification.md` | 演进（并入 17 原文） | 16/17 | references 需登记 |
| 10 | firefly-archive | `assets/shared/skills/firefly-archive/SKILL.md` | 同路径 + `references/deprecation.md` | 演进（并入 22 原文） | 22/25 | references 需登记 |
| 11 | test-driven-development → firefly-tdd | `assets/claude/superpowers/skills/test-driven-development/SKILL.md` | `assets/shared/skills/firefly-tdd/SKILL.md` | **更名 + 迁入 shared** | 13 | 旧名 alias + 双 platform-assets 登记 |

**B. 12 个新建技能**

| # | 技能 | 目标路径 | 设计点 | manifest 条目 |
|---|---|---|---|---|
| 12 | firefly-bounds | `assets/shared/skills/firefly-bounds/SKILL.md` | 05 | 新增 skill-directory |
| 13 | firefly-source | `assets/shared/skills/firefly-source/SKILL.md` | 08 | 新增 |
| 14 | firefly-doubt | `assets/shared/skills/firefly-doubt/SKILL.md` | 09 | 新增 |
| 15 | firefly-context | `assets/shared/skills/firefly-context/SKILL.md` | 10 | 新增 |
| 16 | firefly-ui | `assets/shared/skills/firefly-ui/SKILL.md` | 11 | 新增 |
| 17 | firefly-arch | `assets/shared/skills/firefly-arch/SKILL.md` | 12 | 新增 |
| 18 | firefly-debug | `assets/shared/skills/firefly-debug/SKILL.md` | 15 | 新增 |
| 19 | firefly-guard | `assets/shared/skills/firefly-guard/SKILL.md` + `references/ci-cd.md` | 18/21 | 新增 |
| 20 | firefly-perf | `assets/shared/skills/firefly-perf/SKILL.md` | 19 | 新增 |
| 21 | firefly-pr | `assets/shared/skills/firefly-pr/SKILL.md` | 20 | 新增 |
| 22 | firefly-trace | `assets/shared/skills/firefly-trace/SKILL.md` | 24 | 新增 |
| 23 | firefly-retro | `assets/shared/skills/firefly-retro/SKILL.md` | 26 | 新增 |

**C. 8 个保留资产（不改造，仅口径登记）**

| 资产 | 路径 | 动作 | 说明 |
|---|---|---|---|
| mermaid-diagram-specialist | `assets/shared/skills/mermaid-diagram-specialist/SKILL.md` | 职责迁出到 `firefly diagram` | 03 |
| playwright-interactive | `assets/claude/skills/playwright-interactive/SKILL.md` | 保留 platformSpecific | 14；双侧 10 hunk 差异按 §0.5 表处理 |
| firefly-init | `assets/claude/skills/firefly-init/SKILL.md` | 保留 | 运维，不进 26 点 |
| firefly-repair | `assets/claude/skills/firefly-repair/SKILL.md` | 保留 | 运维 |
| openspec-propose | `assets/claude/skills/openspec-propose/SKILL.md` | 保留 | 04 的底层路由目标 |
| openspec-explore | `assets/claude/skills/openspec-explore/SKILL.md` | 保留 | 04/25 的探查入口 |
| openspec-apply-change | `assets/claude/skills/openspec-apply-change/SKILL.md` | 保留 | 07 的底层执行 |
| openspec-archive-change | `assets/claude/skills/openspec-archive-change/SKILL.md` | 保留 | 25 的归档执行 |

**D. 删除 / 退役（v1.2 补齐，原清单无删除动作）**

| 对象 | 路径 | 动作 | 前置条件 |
|---|---|---|---|
| firefly-doctor | `assets/{claude,codex}/skills/firefly-doctor/` | **删除目录** + 双 manifest 移除条目 | 01 注册表承载其职责后 |
| brainstorming | `assets/{claude,codex}/superpowers/skills/brainstorming/` | 并入 03 后**删除** | 03 落地 |
| writing-plans | 同上路径 | 并入 06 后**删除** | 06 落地 |
| executing-plans | 同上路径 | 并入 07 后**删除** | 07 落地 |
| subagent-driven-development | 同上路径 | 并入 07 后**删除**（其 Durable Progress 协议并入 10） | 07/10 落地 |
| requesting-code-review | 同上路径 | 并入 16 后**删除** | 16 落地 |
| test-driven-development（旧目录） | `assets/{claude,codex}/superpowers/skills/test-driven-development/` | 更名迁移后**删除** | 13 落地 + 别名生效 |
| 两侧手工副本 | `assets/{claude,codex}/skills/`（除 platformSpecific） | 渲染产物化，不再手工编辑；手工副本随迁移清除 | §0.5 token 扩展完成 |

### 3.2 脚本面（v1.2 补齐，原清单零行）

| 脚本 | 动作 | 设计点 |
|---|---|---|
| `scripts/install-claude.sh` / `install-codex.sh` | 公共逻辑下沉 `firefly-common.sh`，diff 由 156 行收敛；平台后缀保留 | — |
| `scripts/doctor-claude.sh` / `doctor-codex.sh` | 同上（diff 116 行收敛）；`firefly doctor` 取消 codex 优先探测，改按平台名分发 | 01 |
| `scripts/firefly.sh` | 增 `next`、`diagram` 子命令分发（现仅 validate/init/tasks/draw/doctor/repair） | 01/03 |
| `scripts/check-release-metadata.sh` | 去掉 `for platform in codex claude` 硬循环（`:96-98`），改读 `platform-assets.json` 分类 | — |
| `scripts/sync-platform-assets.mjs` | 保留并扩展：新增 `{{PLATFORM_WAIT_LOOP}}` / `{{PLATFORM_MODEL_SELECTION}}` / `{{PLATFORM_ASK}}` token；新增 completeness 断言（shared 下每个目录必须登记） | §0.5 |
| `scripts/manifest-assets.mjs` | 跟随 manifest 结构变更（新增/改名条目） | — |
| `scripts/firefly-draw.sh` | 随 Mermaid 职责迁到 `firefly diagram`，改名 `firefly-diagram.sh` | 03 |

### 3.3 账本面（v1.2 补齐）

| 文件 | 动作 |
|---|---|
| `manifests/platform-assets.json` | 新增 token 定义；`shared` 由 14 项扩到 20 项；`platformSpecific` 由 11 项减到 3 项（playwright / subagent 的 model selection / firefly 的等待环按 §0.5 表裁定） |
| `manifests/claude.json` | 19 → 27 条 skill-directory（+12 新建 −1 doctor −5 superpowers +1 tdd 更名 +1 docs 更名）；51 条 source 中指向 `assets/claude/` 的改指 `assets/shared/`（经渲染） |
| `manifests/codex.json` | 同上，条目数与 claude 对齐 |

### 3.4 测试面（v1.2 补齐，原清单零行）

| 测试 | 影响 |
|---|---|
| `tests/test-autonomous-workflow.sh`（37 处引用） | 跟随技能改名与路径 |
| `tests/test-chinese-openspec-workflow.sh`（21 处） | 同上 |
| `tests/test-sdd-workflow-scripts.sh`（17 处） | 同上 |
| `tests/test-claude-installer.sh`（11 处）/ `test-codex-installer.sh`（6 处） | 跟随 install 脚本合并 |
| `tests/test-managed-symlinks.sh`（4 处） | 跟随 manifest 条目变更 |
| `tests/test-release-metadata.sh`（4 处）/ `test-platform-asset-parity.sh`（2 处）/ `test-draw-skills.sh`（4 处）/ `test-planning-contract.sh`（1 处） | 跟随路径与 `--check` 替代 |
| 新增 `tests/test-shared-completeness.sh` | 断言：`assets/shared/` 每个目录都出现在 `platform-assets.json`；替代对单一 `--check` 的依赖 |

## 4. 实施路线（v1.2 去外部依赖 + 加金标准试点）

- **P0（流程闭环）**：16 review 演进（含 spec 档）/ 09 doubt / 15 debug / 25 archive 演进 + **03/04 最小演进**（对垒表 + 三个强制输入）+ **24 trace 最小运行记录（由 25 显式调用）** + **09 金标准试点**——先拿一条**真实的历史 OpenSpec 变更**跑一遍 09，用其实际产物检验 `doubt.md` 的格式与 04/16 的挂点，通过后再批量落其它技能（v1.2；替代「七项一次批」）。**DoD 的「门禁绿」在 P0 用仓库现成的 `tests/test-*.sh` + `shellcheck`，不依赖 P1 的 18**。
- **P1（工程纵深）**：05 bounds / 08 source / 10 context / 13 tdd 演进 / 14 verify-web 演进 / 01 firefly 演进 / 18 guard（含 CI 门禁）——约束、依据、上下文、验证四梁 + 总控；18 落地后把 P0 的临时门禁收编为正式门禁规范。
- **P2（领域扩展与收尾）**：11 ui / 12 arch / 19 perf / 20 pr / 23 docs 演进 / 26 retro / 02 收尾（裁定复述）/ **§0.5 token 扩展与 11 项 platformSpecific 收敛**（此批与技能改造同批判定，不单独排末位）。

### 4.5 横切公共约定、产物契约与记录生命周期（v1.2 扩充）

**三个横切 schema**（各技能引用不复制）：

- **证据条目**：`[类型] 断言 + 来源（文件:行号 / 符号 / 命令输出 / 截图归档路径）+ 时间`——08、13 红绿对、14 四元组、15 调试记录、24 运行记录统一
- **可执行清单**：`条目 + 验证命令 + 最近一次结果（通过/失败 + 时间）`——05 约束、09 检验、18 安全项、16 裁决、25 DoD 统一（中文统一「清单」，英文 checklist）
- **任务运行记录**：`目标 / 已完成 / 未完成 / 证据链接 / 风险` 五字段——10 的 NOTES、24 的 trace、25 的归档摘要统一

**载体与机械强制（v1.2）**：三份 schema 落在 `assets/shared/references/schemas.md`（渲染器自动出双平台副本），各 SKILL.md 正文只留一行指针；`tests/test-shared-completeness.sh` 断言引用存在。

**产物契约（v1.2 新增，修「有写入无读取」）**——所有技能产出一律落在 `openspec/changes/<id>/` 下，路径固定、写入方唯一、读取方显式：

| 产物 | 路径 | 写入方 | 读取方 |
|---|---|---|---|
| 对垒表 | `changes/<id>/duel.md` | 03 | 04（定稿输入）、16 spec 档 |
| 反证报告 | `changes/<id>/doubt.md` | 09（独立子代理） | 04（定稿输入）、16 spec 档、16 常规档（反证结论维度） |
| 运行记录 | `changes/<id>/trace.md` | 24（由 25 调用） | 25（归档）、26（复盘 transcript） |
| 审批条目 | `changes/<id>/approvals.md` | 18④、22⑤ | 25（DoD 抽检） |
| 任务与红绿证据 | `changes/<id>/tasks.md`（含每任务的「红证据→绿证据」） | 06、13、07 | 16（输入清单）、25 |
| 复盘记录 | `changes/<id>/retro.md` | 26 | 05（约束回流）、18（门禁回流） |
| 安全报告 | `changes/<id>/security.md` | 18 | 16（安全维度）、25 |
| 证据归档 | `changes/<id>/evidence/` | 14 | 16、25 |
| 交接纪要 | `.firefly/NOTES.md` | 10 | 07、15、25 |

**记录生命周期（v1.2 分类）**——易腐证据与长期资产分开：

- **易腐证据**（`evidence/`、`trace.md`、运行日志）：带 `schemaVersion`，保留 90 天，由 01 注册表健康检查**第四条检查项**报告过期项（01② 已列）；
- **长期资产**（spec、ADR、duel/doubt/retro、approvals、DoD 销项表）：随仓库生命周期，不设过期——它们是审计链与决策记录，删除即失效；
- 「任一历史任务」类追溯义务以**易腐证据的保留期限**为界，长期资产不受此限。

### 4.6 路由登记表（v1.2 新增，穷举；01 的授权契约以本表为唯一真源）

| 子命令 | 技能 | 授权范围 | 阶段挂载 | 可用档 |
|---|---|---|---|---|
| `firefly` | 01 | 路由 + 注册表健康检查 + 模式宣告 | — | — |
| `firefly next` | 01 | 提案（只提案不执行） | — | — |
| `firefly think` | 02 | 需求追问 | — | — |
| `firefly draw` | 03 | 方案对垒 | — | — |
| `firefly diagram` | mermaid-diagram-specialist | 出图 | — | — |
| `firefly propose` | 04 | 规格成形 | **bounds 约束检查（05）** | — |
| `firefly bounds` | 05 | 约束定义 | — | — |
| `firefly tasks` | 06 | 任务拆解 | — | — |
| `firefly implement` | 07 | 增量实现 | — | — |
| `firefly doubt` | 09 | 反证 | — | — |
| `firefly context` | 10 | 上下文管理 | — | — |
| `firefly ui` | 11 | 前端质量门禁 | — | — |
| `firefly tdd` | 13 | 测试先行 | — | — |
| `firefly verify-web` | 14 | 运行时验证 | — | — |
| `firefly debug` | 15 | 调试 | — | — |
| `firefly review` | 16 | 评审裁决 | **安全维度挂 18；反证输入挂 09** | 轻量 / 常规 / `--deep` / spec |
| `firefly guard` | 18 | 安全与门禁 | review 安全维度自动挂载 | — |
| `firefly perf` | 19 | 性能 | bounds 预算触碰时 | — |
| `firefly pr` | 20 | 交付 | review 清零 | — |
| `firefly trace` | 24 | 运行记录 | 25 归档时显式调用 | — |
| `firefly archive` | 25 | 收尾 | 调用 24 | — |
| `firefly retro` | 26 | 复盘 | 归档时轻量 | — |

**隐式挂载（无独立子命令，由持有技能的阶段触发，同样受本表授权）**：08 source（08 在 07/16 内部按需调用）→ 授权范围 `07/16` 内；12 arch（新模块/新公共 API/跨模块数据流变更时，由 01 判定后挂 04/07）；23 docs（spec 变更、架构决策、归档时由 04/25 调用）；13/14/15 的互相引用同此。

**未列入本表的触发一律拒绝**——这是元原则 1 的可执行形态。

### 4.7 生成器与投影（v1.2 新增）

- **现状**：`/tmp/slim-index/build-flynext.py` 是**仓外**一次性脚本，全文不打开 DESIGN.md，23 卡中英文是手写常量；产物 `docs/skill-proof/data/sets/firefly-next.js` 因此可能偏离真源（英文三卡已实际偏离）。
- **处置**：把生成器**纳入仓库** `docs/skill-proof/tools/build-flynext.py`（仓内新增文件），并新增 `docs/skill-proof/tools/verify-flynext.py` 校验器，检查四项：①卡数 == DESIGN 技能数；②每卡机制条目数 == 对应小节的 ①②③ 条目数；③禁用词表（`--doubt`、`Merged with security`、`OTel GenAI semantic conventions` 等已撤表述）零命中；④`source.sha` == `git log -1 --format=%H -- DESIGN.md`。校验失败即非零退出，生成前必跑。
- 仓外脚本本体本轮只读，不修改；新仓内文件从零编写。

### 裁定结果

**v1.1 裁定（2026-11-20）**

1. **doubt / guard 合并**：**回退**——firefly-doubt、firefly-guard 恢复独立技能（23 技能）。
2. **mar / nextup 吸收**：**机制提炼**（mar→16 独立性协议 + 标准一致性维度；nextup→01 `firefly next` 子命令），不原文收编。
3. **裁定复述条款**（02 think ④）：**确认纳入**。

**v1.2 裁定（2026-11-20，第二轮 mar 六维复审后，按"设计问题全修"执行）**

4. **§0.5 路线**：采 **A 方案**——保留 `assets/shared/` 为唯一编辑源、扩展现有 token 渲染；不新建 `assets/skills/` 树、不合并三份 manifest。理由：仓库已有单源 + 守卫，A 的改动面远小于 B，且不动 `--check` 与 parity 测试。
5. **技能数**：维持 **23**。按 §1 的合并三条件复核，24 trace 与 10 context 均满足三条（独立触发 / 独立产物 / 被消费），不并入；该判据同时解释了 17/21/22 的并入。
6. **依据处理**：查无此物的 12 处按「改写归因 / 标 own design / 标【未验证】」三种方式处理，不删除设计条款本身。
7. **P0 试点**：先以一条真实历史变更跑通 09，再批量落其它技能。

## 5. 参考来源（主要）

> 标注约定：**[已核]** = 可直接检索到原文；**[未验证]** = 无法定位原始出处，仅作定性表述；**[own design]** = 本设计自有主张，不冠以外部出处。

- **[已核]** Anthropic: *Equipping agents for the real world with Agent Skills*（2025-10）https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- **[已核]** Anthropic: *Effective context engineering for AI agents*（2025-09）https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents；Skill authoring best practices（官方文档，含 <500 行建议）
- **[已核]** GitHub: *Spec-driven development with AI*（spec-kit，2025-09）https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/
- **[已核]** *Adversarial Review: Structured Disagreement for Grounded Agentic Code Review*（arXiv 2608.18167，ICML 2026）
- **[已核]** Debug2Fix（arXiv 2602.18571）：调试子代理 + 交互式调试工具
- **[已核]** OpenTelemetry GenAI semantic conventions（仅作字段命名参考，不作合规要求）
- **[未验证]** 「2025-11 实测 689 行可疑代码」——无法定位到机构/标题/链接，04 点已降为定性表述
- **[未验证]** 锁测试基线与 self-passing 风险的「多家实践」（skyramp/bunnyshell/matrix-os 等机构名，无可定位文章）
- **[未验证]** 「a11y 自动化只覆盖 30-40% WCAG」——数字在 GOV.UK service standard 与 TestParty 等处出现过，但原始出处未统一
- **[已核]** StackToHeap（2025-08-10）*Code reviews with Claude Code subagents*——个人博客，非机构共识
- **[own design]** 裁决三档 [必须改|建议|可接受]、模式宣告、基线先行、双案下限的阈值（>3 文件）、轻量档阈值

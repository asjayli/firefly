# firefly-next 设计稿：26 维度的目标态（v2）

> 状态：**设计稿，待用户正式确认**。确认前不实施任何技能改动。
> 方法：26 个维度逐点吸收 Matt / Addy / Pstack 三套的优点，叠加 2025-2026 互联网最新实践，为 firefly 设计下一版理想形态。
> **v1.1 修订（2026-11-20）**：吸收 mar 五维审查的设计层发现 + 裁定——①「不分叉」= 资产单套化布局（见 §0.5）；② mar/nextup 机制提炼吸收（16 独立性协议、01 `firefly next`）；③ doubt/guard 合并经用户裁定**回退**（23 技能）；④ 裁定复述条款确认纳入（02④）。裁定详情见文末「裁定结果」。
> 互联网依据：Anthropic Agent Skills 与 context engineering 官方实践、GitHub Spec Kit / OpenSpec / BMAD / Kiro 的 spec-driven 浪潮、AI 评审的生成/评审分离范式、agent 安全（secrets 注入/最小权限/approval gates）、OTel GenAI 可观测约定、RCA-first 调试纪律、a11y 自动化边界等（详见各点「依据」）。

## 0. 设计立场：五条元原则

从三套的分化与最新实践中，firefly-next 的所有技能设计服从以下元原则：

1. **显式授权（Explicit mandate）**——继承 firefly 现状的最大优点：用户点名才进入，子命令即授权边界。三套中 Pstack 的「常驻触发器」与 Addy 的「按需技能」之间，firefly 取 Addy 的按需 + 自己的契约路由，拒绝隐式扩权。
2. **证据优先于断言（Evidence over claim）**——吸收 Addy source-driven / doubt-driven 的内核：任何结论（源码行为、测试通过、评审通过）必须挂在可复核的证据上；agent 的自我报告不是证据。
3. **生成与评审分离（Separation of duties）**——2025 评审实践的共识：写得越多，评审越要独立。执行代理与评审代理必须分离，评审以独立子代理 + 并行多维检查点运行。
4. **上下文最小充分（Minimal sufficiency）**——Anthropic context engineering 的核心：上下文是有限注意力预算，只装「达成目标的最小高信号 token 集」；用 JIT 检索、compaction、结构化笔记、子代理摘要四板斧管理。
5. **产物即流程（Artifacts as process）**——spec-driven 浪潮的共识：流程不靠自觉，靠仓库里的持久产物（spec / tasks / ADR / NOTES / 复盘记录）驱动；每个技能必须定义它的产出物与验收标准，否则不许存在。

## 0.5 资产单套化（「不分叉」裁定的落地设计）

**裁定**：firefly 不再按 claude / codex 维护两份资产，`shared`（为分叉抽公共的机制）随之取消——**一套 SKILL.md 服务所有平台**。

现状依据（2026-11-20 探查）：两侧技能集合完全一致（19 目录无单侧独有）；15 个技能有差异但每技能仅 1-2 处，差异实质是**同一机制的两平台措辞**（`Task` vs `spawn_agent/wait_agent`、`~/.claude` vs `~/.codex` 路径、连续控制器表述），不是能力差异——仓库 AGENTS.md 的「能力交集基线」本来就是单套化的合法性依据。

目标布局：

```
assets/skills/<skill-id>/SKILL.md      唯一一份，平台中立表述
assets/superpowers/skills/...           受管覆盖同规则单套化
manifests/firefly.json                  单一 manifest（平台目标路径作为字段而非目录分叉）
scripts/install / doctor / repair       单套适配：路径差异在安装器层解析
```

写法约定：
- 正文平台中立：机制语义统一表述（如「经原生子代理机制派发」），平台特定工具名并列标注（`Task`/`spawn_agent`）
- 平台路径（`~/.claude`、`~/.codex`）不出现在 SKILL.md 正文，归安装器模板变量
- 差异不能中立化的（如 Codex 60 秒等待环 vs Claude 原生回调），以「平台注记」小节集中并列，不散落正文

**全量资产处置表**（单套口径，19 claude 技能 + 6 superpowers 覆盖 = 25 项；codex 侧随单套化自动消失）：

| 资产 | 处置 | 对应设计点 |
|---|---|---|
| firefly | 演进（next 子命令 + 静态注册表 + 契约内挂载） | 01 |
| firefly-think / draw / propose / tasks / implement / verify-web / review / archive | 演进 | 02/03/04/06/07/14/16/25 |
| firefly-doctor | **并入 firefly**（01 注册表的承载，退役独立技能） | 01 |
| firefly-init / firefly-repair | 保留为运维技能（安装/修复流程，不进 26 点） | — |
| openspec-propose / explore / apply-change / archive-change | 保留为 openspec 底层路由目标（propose/archive 演进依赖） | 04/25 |
| openspec-sync-specs | 更名演进 firefly-docs（过渡期保留旧名别名） | 23 |
| mermaid-diagram-specialist + scripts/firefly-draw.sh | Mermaid 职责独立保留（`firefly diagram` 子命令，不再挂 draw） | 03 |
| superpowers 六覆盖 | test-driven-development 更名演进 firefly-tdd（过渡别名）；其余五项按 03/06/07/16 并入对应技能后退役 | 03/06/07/13/16 |

## 1. 技能总览：新增 / 演进 / 合并

firefly-next 目标态共 **23 个技能**：11 个演进 + 12 个新建。
三个维度并入相邻技能：**17 简化→review 维度、21 CI→guard、22 废弃→archive**（判据：独立技能的维护成本大于收益，YAGNI）。doubt/guard 曾按 mar 建议合并，经用户裁定回退为独立技能。

| 组 | 技能 | 动作 | 一句话定位 |
|---|---|---|---|
| meta | firefly | 演进 | 总控路由 + 技能注册表健康检查 |
| define | firefly-think | 演进 | 需求追问：可判定问题清单 |
| define | firefly-draw | 演进 | 想法对垒：多方案强制竞争 |
| define | firefly-propose | 演进 | 规格成形：constitution + delta spec |
| define | firefly-bounds | **新增**（吸收 security+CI） | 质量契约与门禁：约束清单 + 安全加固 + CI 挂载 |
| plan | firefly-tasks | 演进 | 任务拆解：验证附着于任务 |
| build | firefly-implement | 演进 | 增量实现：小步 + 独立执行子代理 |
| build | firefly-source | **新增** | 源码依据：上游真相 + JIT 检索 |
| build | firefly-context | **新增** | 上下文工程：最小充分与会话续航 |
| build | firefly-ui | **新增** | 前端工程：a11y 与组件质量门禁 |
| build | firefly-arch | **新增** | 接口与架构：契约先行 |
| verify | firefly-tdd | 演进（吸收 test-driven-development） | 测试先行：锁测试防自通过 |
| verify | firefly-verify-web | 演进 | 运行时验证：沙箱浏览器取证 |
| verify | firefly-debug | **新增** | 调试：RCA-first 证据链 |
| build | firefly-doubt | **新增** | 反证轮：红队自己的方案 |
| review | firefly-guard | **新增**（吸收 CI） | 安全与门禁：secrets/权限/供应链/CI |
| review | firefly-review | 演进 | 评审裁决：独立子代理 + 并行多维 + `--doubt`/`--deep`/spec 档 |
| review | firefly-perf | **新增** | 性能：基准先行，数字说话 |
| ship | firefly-pr | **新增** | 交付：为评审者而写的 PR |
| ship | firefly-docs | 演进（吸收 openspec-sync-specs） | 文档与 ADR：决策即记录 |
| ship | firefly-trace | **新增** | 可观测：OTel 约定的结构化遥测 |
| ship | firefly-archive | 演进（吸收 deprecation/shipping） | 收尾：definition-of-done + 废弃迁移 |
| extra | firefly-retro | **新增** | 复盘：教训入库成触发器 |

合并说明：`simplification` 并入 review 的常设维度 + `--deep` 档；`ci` 并入 guard 的门禁挂载；`deprecation` 并入 archive。判据统一：独立技能的维护成本大于收益（YAGNI）。

---

## 2. 逐点设计（26 维度）

### 01 总控与路由 / Meta & Routing

**现状**：firefly（显式编排、写死的子命令契约）——四套中唯一把「授权边界」写进路由层的。
**吸收**：
- Addy `using-agent-skills`：技能发现机制——agent 能自己列出/检索可用技能而不是靠人记。
- Pstack `poteto-mode`：身份声明——进入时明确宣告当前模式，退出时显式交还控制权。
- Matt `ask-matt`：单一入口——用户永远知道从哪个门进。
**依据**：Anthropic Agent Skills 官方实践——progressive disclosure：SKILL.md 正文保持 <500 行高信号，重资料放 references/ 按需加载；技能元数据（name/description）是路由的依据，必须可被检索。
**目标态（firefly 演进，吸收 doctor 并入 + nextup 技能）**：
- 触发：用户点名 `firefly` 或其子命令；「存在编码任务」不是触发条件。
- 职责：①**路由表**：子命令→技能→授权范围的静态契约，**契约显式登记各子命令的阶段挂载**（如 `propose` 的授权范围含 bounds 约束检查、spec 定稿门含 review 的 `--doubt` 档）——契约内挂载不算隐式扩权，须模式宣告；②**技能注册表**（静态，firefly-doctor 并入后承载）：列出全部技能、触发词与健康状态（description 是否漂移、references 是否在、SKILL.md 与注册表是否一致）；健康检查基于 baseline diff（复用 doctor-claude.sh 模型），**不做使用频率追踪**（静态资产无此数据源）；③**模式宣告**：进入/退出子命令时输出一行模式标记；④**`firefly next` 子命令**（吸收 nextup）：回答「下一步干啥」——盘点证据（git 状态/TODO/计划文档/会话承诺）→ 五类归类（风险排除/承诺兑现/断点续作/计划推进/债务清理）→ 优先级排序 → 3-5 项带证据、带完成标准、带第一步的提案，**只提案不执行**。
- 产出：路由决策一行；`next` 产出带证据的优先级提案表。
- 验收：拒绝**契约外**触发并提示正确入口（契约内阶段挂载经模式宣告放行）；注册表健康检查可对任一技能重跑。
- v1.1 注记：原「上次使用」追踪删除（无数据源且与 doctor baseline-diff 模型冲突）；验收由「拒绝任何非点名触发」改写（原表述与阶段挂载字面互斥）。

### 02 需求追问 / Requirements

**现状**：firefly-think（结构化提问，收集背景与目标）。
**吸收**：
- Matt `grill-with-docs`：追问前先读文档——问题建立在已读材料上，不问文档里已有答案的问题。
- Addy `interview-me`：一次只问一件事 + 提供候选答案（把开放题降为选择题）。
- Pstack `sharpen`：把模糊诉求磨成可判定命题。
**依据**：context engineering 的「right altitude」——追问既不能碎成二十个Yes/No（脆），也不能泛泛「多告诉我一些」（空）；每轮追问应是「具体到能引导行为，开放到保留判断」。
**目标态（firefly-think 演进）**：
- 触发：`firefly think`；新任务进入 define 阶段时。
- 机制：①**先读后问**：提问前列出已读文件清单，禁止问其中已有答案的问题；②**可判定问题清单**：每轮 ≤5 问，每问附 2-4 个候选答案 +「都不是」出口；③**停机条件**：剩余问题全部「不影响方案分叉」时停止；④**裁定复述**（v1.1 新增，防误解与扩大解释）：用户的自由文本回答被映射为决策时，必须先复述为具体动作（「『X』= 做 Y，对吗？」）确认后才落文档，文档保留原话 + 解释链；项目语境的歧义词（如「分叉」「合并」）触发澄清而非最近选项硬套。
- 产出：需求纪要：目标 / 非目标 / 约束 / 已知未知，附「未决问题=空」显式声明。
- 验收：纪要中每个需求可判定——能写出「满足/不满足」的检验式。

### 03 想法打磨 / Idea

**现状**：firefly-draw + brainstorming（方案发散）。
**吸收**：
- Pstack `arena`：**强制多方案对垒**——至少两个方案正面竞争，各自列出杀死自己的条件。
- Matt `prototype`：可丢弃原型——用最便宜的方式验证最贵的假设。
- Addy `idea-refine`：迭代收敛而非一次性定稿。
**依据**：AI 生成成本低导致「第一方案偏差」——agent 倾向接受第一个成形方案；对垒机制是对这种偏差的制度化纠偏（structured disagreement 的设计思想同样用于 16 评审）。
**目标态（firefly-draw 演进）**：
- 机制：①**双案下限**：非平凡决策（影响 >3 文件或含架构选择）必须 ≥2 个竞争方案 + 各自反例条件；②**假设分级**：假设按「验证成本」排序，最贵的先用原型/检索杀；③用户裁决点：对垒结果交用户选，agent 只推荐不拍板；④**Mermaid 职责迁出**（v1.1）：现 draw 的出图职责（mermaid-diagram-specialist + firefly-draw.sh）独立为 `firefly diagram` 子命令，draw 专注意法对垒——修「演进实为职责替换」与 01「路由表现状保留」的矛盾。
- 产出：方案对垒表：方案 / 代价 / 风险 / 杀死条件 / 推荐理由。
- 验收：无对垒表的方案进入 spec 时，propose 必须打回。

### 04 规格成形 / Spec

**现状**：firefly-propose（OpenSpec delta spec 流程）。
**吸收**：
- Addy `spec-driven-development`：constitution 层——项目级原则与单次 spec 分离，原则只写一次。
- Matt `to-spec`：把对话散落的决议收拢成结构文档的收束能力。
- Pstack：无对应（本点 Pstack 缺位，其哲学是 spec 即任务列表）。
**依据**：GitHub Spec Kit / OpenSpec / BMAD / Kiro 在 2025 共同验证的 spec-first 范式：constitution → spec → plan → tasks 分层；争议点「spec 放哪」的社区答案趋向 **spec 入仓库**（与代码同生命周期、可评审、可回滚）——firefly 的 OpenSpec 资产结构正是这个答案。反面教训：spec 质量不受控时产出 689 行可疑代码（Nov 2025 实测报告）——所以 spec 必须带验收标准，且验收标准必须可转测试。
**目标态（firefly-propose 演进）**：
- 机制：①**三层分离**：constitution（项目原则，长期）/ delta spec（本次变更，短命）/ tasks（执行清单）；②**验收标准即测试草案**：每条 Requirement 映射为 Scenario（Given/When/Then），语言可直接抄进测试文件；③**spec 完整性检查**：无验收标准的 spec 不许进入 tasks 阶段；**定稿的两个强制输入**（v1.1）——03 的方案对垒表 + 09 doubt 的反证报告，缺一不放行（定稿验收由 review 的 spec 档执行）。
- 产出：`openspec/changes/<id>/`：proposal.md / specs/*.md / design.md（可选）。
- 验收：spec 评审通过；每条 Scenario 有 Given/When/Then；定稿必附对垒表与反证报告。

### 05 质量底线 / Constraints（新增 firefly-bounds）

**现状**：gap——约束散落在各技能的注意事项里，无一致执行。
**吸收**：
- Addy `constraint-driven-development`（本点唯一对应）：**非功能约束先行**——性能/安全/兼容性预算在写第一行业务代码前定死，违反即停。
- Pstack 的四原则（结构编码领域/边界校验/非法状态不可表示/幂等）作为约束模板的候选条目。
**依据**：agent 安全实践的一致结论——约束写在 prompt 里会被长上下文稀释（context rot），必须落成**可执行检查**（lint 规则/CI 门禁/测试）才能常驻；「写下来」不等于「被遵守」。
**目标态（firefly-bounds，新增）**：
- 触发：`firefly bounds`；spec 阶段。
- 职责：①**约束清单**（性能预算/内存上限/兼容矩阵/安全红线/数据边界/测试分层与速度预算——**清单开放式**，retro 回流可扩展），每条绑定可执行验证；**无数字时走 Ratchet 棘轮**（v1.1，吸收 addy：记录当前实测值，只许变好不许变差——「编出来的数字会被忽略，测出来的数字会被守住」）+ 合理默认值表；②约束与任务挂钩——完成声明必须引用检查结果；③项目级 `bounds.md`（constitution 的一部分）；④安全红线类约束的**执行**由 firefly-guard 承接（见 18），bounds 管定义。
- 产出：约束清单 + 每条验证命令 + CI 侧的检查挂载点。
- 验收：抽检任意一条约束，能立即运行其验证命令并得到通过/失败。

### 06 任务拆解 / Tickets

**现状**：firefly-tasks + writing-plans（tasks.md 流程）。
**吸收**：
- Matt `to-tickets`：任务的**原子性**——每个任务一个可独立验证的交付物。
- Addy `planning-and-task-breakdown`：依赖图——任务间阻塞关系显式化。
- Pstack：任务即 spec 的执行投影，不另造体系。
**依据**：sub-agent 架构实践——任务粒度决定可并行度与上下文隔离度；每个任务应能被一个「干净上下文」的子代理独立完成并返回摘要（1-2k token），这是任务拆解的客观标尺。
**目标态（firefly-tasks 演进）**：
- 机制：①**一任务一验证**：每个任务必须写「完成=什么测试/命令通过」，无验证的任务不许进列表；②**依赖显式**：tasks.md 中标注 blocked-by；③**子代理标尺**：任务描述必须自包含——一个没有本次对话上下文的执行者也能做（这是对描述完备性的可操作定义）；④进度即事实：勾选状态只能由验证结果驱动，不许手勾。
- 产出：`tasks.md`（现有格式演进：任务/验证/依赖/状态）。
- 验收：任取一个完成任务，其验证命令可独立重跑通过。

### 07 增量实现 / Implementation

**现状**：firefly-implement + executing-plans + subagent-driven-development。
**吸收**：
- Addy `incremental-implementation`：小步提交——每步保持系统可运行（绿色台阶）。
- Matt `implement` 的「按 spec 逐条销账」纪律。
- Pstack：无直接对应（实现纪律藏在四原则里）。
**依据**：上下文工程——执行代理上下文越短越准；长任务用 compaction + 结构化笔记续航，而不是无限堆历史。子代理执行范式：主代理持有计划，子代理持有任务，双方只交换任务书与结果摘要。
**目标态（firefly-implement 演进）**：
- 机制：①**绿色台阶**：每完成一个任务，系统必须回到可运行状态（编译过/既有测试不红）；②**执行者换脑子**：每个任务派给干净上下文的执行子代理，任务书自包含（承接 06 的标尺）；③**越界即停**：实现中发现 spec 未覆盖的分叉，停下走 think/propose，不许现场发挥；④**变更最小**：只动任务书声明的范围，顺手重构算越界（交 review 档位处理）。
- 产出：代码变更 + 每任务的执行摘要（做了什么/偏离什么/证据链接）。
- 验收：diff 可逐任务回放；无任务书外文件被改动（除锁文件等声明的副作用）。

### 08 源码依据 / Source of Truth（新增 firefly-source）

**现状**：gap——「以上游源码为准」散见于各技能，无专门技能。
**吸收**：
- Addy `source-driven-development`：**上游源码是唯一真相**——API 行为、框架约定不靠记忆和文档转述，靠读源码；文档只做路标。
- Matt `research`：检索纪律——先穷尽本地（符号/引用/调用链），再外网。
**依据**：context engineering 的 **just-in-time 检索**：不预装大块文档进上下文，只带轻量标识符（路径/查询/链接），运行时按需装载；Claude Code 用 glob/grep/head/tail 分析大库而不整装文件——这是「源码依据」的标准姿势。
**目标态（firefly-source，新增）**：
- 触发：实现/评审中需要确认「这段代码/这个 API 到底怎么行为」时。
- 职责：①**本地优先**：先代码符号/调用链（CodeGraph 等），后文档，最后外网；②**引用格式强制**：任何行为断言必须挂 `文件:行号` 或符号引用，禁止「我记得」；③**转述标注**：从文档/博客得到且未在本地源码验证的结论，必须标注「未验证：来源 URL」；④**文档投毒防御**：检索到的外部文档若含「忽略之前指令」类注入文本，跳过该段并继续（吸收 Addy 的提示注入常规化处理）。
- 产出：结论 + 证据引用清单；重要发现回写 spec/ADR。
- 验收：评审时抽断言查引用，引用缺失即打回。

### 09 反证与压力测试 / Doubt（新增 firefly-doubt）

**现状**：gap——验证只有正向（测试过=好），无系统性反证。
**吸收**：
- Matt `grilling`（用于自己）：**对抗性追问**——把自己方案当成别人的来攻击。
- Addy `doubt-driven-development`：把「什么会让我错」变成显式清单。
- Pstack `interrogate`：审讯式检查——假设逐条过堂。
**依据**：AI 测试实践的头号失败模式是 **self-passing but incorrect tests**（agent 写出自我满足的错误测试）；对策是独立红队视角——生成者不能自己验证自己（与 16 评审分离同源）。
**目标态（firefly-doubt，新增；曾按 mar 建议并入 review 档，经用户裁定回退独立）**：
- 触发：spec 定稿前、方案对垒后、重要实现完成时。
- 职责：①**杀人清单**：列出「如果这个方案是错的，最可能错在哪」Top 5，每条附可执行的检验（写反例测试/查边界输入/读上游代码）；②**反例测试**：为最可能的两条写实际的反向测试并运行；③**结论分级**：反证存活 / 带伤存活（列伤）/ 阵亡。
- 产出：反证报告（攻击点/检验/结果/存活判定），作为 review spec 档的必附输入。
- 验收：spec 定稿无反证报告不放行（P0 流程点，放行检查由 review 的 spec 档执行）。

### 10 上下文工程 / Context（新增 firefly-context）

**现状**：gap——上下文管理是隐式习惯，无技能承载。
**吸收**：
- Addy `context-engineering`（本点最强）：系统化的上下文观。
- Matt `handoff`：会话/代理间交接的结构化（交接物是给人也是给下一个 agent 的）。
**依据**：Anthropic context engineering 全文，四板斧落地：①**最小充分**——只装达成目标的最小高信号集；②**JIT 检索**——带标识符不带大块数据；③**compaction**——接近窗口上限时高保真压缩（保留架构决策/未解 bug/关键约束，清工具原始输出）；④**结构化笔记**——NOTES.md/todo 落盘，跨 compaction 续航；子代理只回传 1-2k token 摘要。
**目标态（firefly-context，新增）**：
- 触发：长任务（预计 >30 分钟/多阶段）；会话交接；compaction 发生时。
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
- 职责：①**组件门禁**：新组件必须过（语义化标签/键盘可达/焦点管理/对比度/ARIA 正确使用）检查单；②**状态约束**：UI 状态机显式化（loading/error/empty/success 全枚举，禁止非法组合）；③**双轨 a11y**：自动扫描（axe 类）+ 键盘手动走查清单（Tab 序/焦点陷阱/Esc 退出）；④与 verify-web 联动：视觉断言进运行时验证。
- 产出：组件检查单结果 + a11y 双轨报告。
- 验收：新 UI 无「自动扫描通过但键盘不可达」的组件。

### 12 接口与架构 / Architecture（新增 firefly-arch）

**现状**：gap——架构决策无技能承载，散在 think/implement 里。
**吸收**：
- Matt `codebase-design` + `improve-codebase-architecture`：结构演进观——架构是持续重构出来的，不是一次画好的。
- Addy `api-and-interface-design`：**接口先行**——先定契约（签名/错误码/版本），再写实现。
- Pstack `architect`：四原则做架构底线（结构编码领域/边界一次校验/非法状态不可表示/幂等）。
**依据**：SDD 分层实践——接口契约是 spec 的一部分（可评审、可生成 mock、可写契约测试）；上下文工程的工具设计原则同样适用于 API：无重叠、自包含、语义清晰——「如果人不能一眼说出该用哪个接口，agent 也做不到」。
**目标态（firefly-arch，新增）**：
- 触发：新模块/新公共 API/跨模块数据流变更时。
- 职责：①**契约先行**：公共接口先出契约描述（签名/错误/版本策略/兼容承诺），挂进 spec；②**结构决策记录**：架构选择走 ADR（与 firefly-docs 联动）；③**边界纪律**：模块间只经显式契约通信，禁止深层 import；④**演进式重构**：大改分台阶（每步可运行），拒绝一次推倒。
- 产出：接口契约文档 + ADR。
- 验收：契约测试存在且与实现同步；无未记录的跨边界依赖。

---

### 13 测试驱动 / TDD

**现状**：test-driven-development（受管覆盖）——红绿重构循环。
**吸收**：
- 三套同题（matt `tdd` / addy `test-driven-development` / pstack `tdd`）罕见共识，取交集：**先写失败测试**是纪律本身。
- Addy 版独有：测试基线（baseline）先行——动代码前先确认旧测试全绿。
**依据**：2025 AI-TDD 实践的两个硬结论：①**锁测试**——agent 不得修改已有测试来达成通过（改测试=改需求，须显式走 spec 流程）；②**防自通过**——agent 生成「自我满足的错误测试」是头号失败模式，对策是测试与实现分代理写、或测试先经人/独立代理评审。
**目标态（firefly-tdd，演进吸收现有 test-driven-development）**：
- 机制：①**基线先行**：动代码前跑全量测试，红的先修或显式记录豁免；②**红→绿→重构**，**红必须有证据**：新测试的失败输出贴进任务摘要；③**锁测试条款**：需要改测试时停下走变更流程，禁止顺手改（改测试=改需求）；④**测试分层**：单元/集成比例与速度预算进 bounds；⑤**接缝纪律**（v1.1，吸收 matt）：只在预先约定的接缝处测试——写测试前列出接缝并与用户确认（旧接缝优先、高杠杆接缝优先，实在没有才开新的），未经确认的接缝不写测试，控制测试面数量防重构误报；⑥**更名迁移**（v1.1）：superpowers 的 test-driven-development 更名演进为本技能，过渡期保留旧名别名触发，按 22 点废弃纪律出显式迁移通知。
- 产出：测试代码 + 每任务的「红证据→绿证据」对。
- 验收：新增测试的首次失败输出可查；无「实现与测试同提交且测试从未红过」的可疑对。

### 14 运行时验证 / Browser

**现状**：firefly-verify-web + playwright-interactive（受管）——浏览器实证。
**吸收**：
- Addy `browser-testing-with-devtools`：**独立浏览器 profile**——默认 profile 带着登录态/邮箱/银行会话，agent 驱动浏览器等于把这些交给它；必须用隔离 profile。
- Pstack `create-verification-skill`：**为每个功能生成专属验证技能**——验证知识沉淀复用。
**依据**：agent 安全实践（隔离执行环境）+ E2E 验证实践（人类可见工作区 vs 自动化环境的取舍）；「截图即证据」——验证结论必须挂可复核的产物（截图/trace/网络记录），口头「页面正常」不算。
**目标态（firefly-verify-web 演进）**：
- 机制：①**隔离 profile 强制**：任何浏览器验证必须在独立/一次性 profile 中进行（吸收 Addy 红线）；②**证据三元组**：验证结论 = 操作序列 + 截图/录屏 + 关键 DOM/网络断言，三者齐才算验证；③**验证技能沉淀**：重复验证同一功能第三次时，把它提炼成可重放的验证脚本（吸收 Pstack）；④**作用域声明**：验证前声明「将访问的域名/触发的动作」，超域即停。
- 产出：验证报告（三元组归档路径）。
- 验收：任一「已验证」结论可打开其证据归档复核。

### 15 调试修复 / Debugging（新增 firefly-debug）

**现状**：gap——调试靠通用能力，无纪律约束，易滑向试错式补丁。
**吸收**：
- Matt `diagnosing-bugs`：**先诊断后动手**——假设-检验循环。
- Addy `debugging-and-error-recovery`：错误恢复的结构化（分类→策略→动作）。
**依据**：2025 调试实践的聚合共识：①**RCA-first**——改代码前必须先给出根因假设及证据，防止 trial-and-error 式「vibe debugging」；②**证据链**——每步结论挂证据（日志/断点/最小复现）；③**二分隔离**——从 O(N²) 的怀疑面收缩到单变量（deterministic replay 是理想形态，最小复现是平替）；④ Debug2Fix 等研究证明「调试子代理 + 交互式调试工具」显著优于主代理顺带调试。
**目标态（firefly-debug，新增）**：
- 触发：测试红了两次仍没修好 / 非预期行为 / 线上问题排查。
- 职责：⓪**停线保存现场**（v1.1 第 0 步，吸收 addy Stop-the-line）：进入调试即停止叠加功能改动，先保存原始失败证据（错误输出/日志/复现步骤）；①**最小复现优先**：先造最小复现，复现不了先解决「为什么复现不了」；②**假设登记**：根因假设显式列出（≥1 条），每条绑一个检验实验；③**单变量改动**：每轮只动一个变量，改动前后都跑复现；④**根因≠症状**：修复必须能解释「为什么治的是根因」；⑤修完把根因与修法写入任务摘要（供 retro 沉淀）。
- 产出：调试记录（复现 / 假设 / 实验 / 根因 / 修复 / 回归测试）。
- 验收：回归测试锁死原 bug；无「改了三处不知道哪处治好」的合并。

### 16 评审裁决 / Review

**现状**：firefly-review + requesting-code-review（受管）。
**吸收**：
- Pstack `interrogate`：**审讯式密度**——问题逐条过堂，不许「整体看起来不错」。
- Addy `code-review-and-quality`：检查维度清单化。
- Matt `code-review`：评审是裁决不是聊天——每条意见给裁决（必须改/建议/可接受）。
**依据**：2025 评审实践的核心共识——**生成与评审分离**：AI 写得越多，评审越要独立；范式是独立评审子代理（与执行代理不同上下文、不同人格设定）+ 并行多维检查（安全/性能/可测性/简化各一个检查点）+ 反馈环（主代理修复→评审子代理复审直到清零）；structured disagreement 研究证明子代理对抗能落地「最小协作开销的高质量评审」。
**目标态（firefly-review 演进，v1.1 吸收 mar 技能为独立性协议）**：
- 机制：①**独立评审代理**：评审者不持有执行历史，只看 diff+spec+任务书（防锚定）；②**并行维度**：正确性（对 spec）/ 简化（吸收 17 点）/ 风险（边界与异常）/ 测试（覆盖与质量）+ **标准一致性**（v1.1 新增：审查设计/实现宣称的判据是否被一致应用，专抓「判据不对称」）；③**裁决式意见**：每条 = [必须改|建议|可接受] + 理由 + 位置；④**清零环**：必须改项不归零不通过，复审由同一评审代理增量做；⑤**thermo 档位**：`--deep` 整模块深度简化审查；⑥**spec 档**：输入=spec+对垒表+反证报告（无 diff），维度=Scenario 完整性 / 验收可测性 / 与 constitution 冲突，04 的定稿验收由本档执行。
- **独立性协议**（吸收 mar，v1.1）：一 agent 一维度（单维深挖胜过全面浅扫）；reviewer 互不见彼此结论；同一问题 ≥2 维度独立命中才高置信，单维度无旁证降置信；冲突结论保留双方证据标「待人工」不和稀泥；汇总者必须去重/裁决/定级复核，禁止粘贴拼盘。
- **档位谱**（v1.1）：轻量档（小 diff 只跑正确性+测试，阈值进 bounds）← 常规四维+标准一致性 → `--deep` / spec 档（spec 档的必附输入含 09 doubt 的反证报告）。
- 产出：评审报告（分维度裁决清单）；spec 档产出定稿裁决 + 反证报告归档。
- 验收：无未裁决的必须改项；评审/执行上下文隔离可查；spec 定稿必附反证报告（P0 流程点）。

### 17 代码简化 / Simplification（并入 16）

**现状**：gap（独立技能缺位）。
**吸收**：
- Addy `code-simplification`：简化是独立工序，不是顺手做。
- Pstack `thermo-nuclear-code-quality-review`：**深度清理档位**——极端简化审查作为可选重炮。
**依据**：评审分离原则——简化判断交给独立评审维度比执行代理自查有效；「最小充分」原则同样适用于代码：能删的分支/抽象/防御都是认知负担。
**目标态（16 的一个评审维度 + 一个档位）**：
- 机制：①review 的常设维度「简化」：每 diff 问三题——能删吗？能并吗？这层抽象有第二个使用者吗（YAGNI）？②**thermo 档位**：`firefly review --deep` 触发深度简化审查（整模块视角，吸收 Pstack 重炮语义），作为可选档而非常驻。
- 验收：常规 review 必含简化维度结论；thermo 档位产出独立的简化清单。

### 18 安全加固 / Security（新增 firefly-guard，吸收 CI）

**现状**：gap——安全靠通用常识，无专门防线。
**吸收**：
- Addy `security-and-hardening`：**参数化/最小权限/输入不信任**三件套，清单化。
- Pstack `thermo-nuclear-review`：安全作为重炮审查档。
**依据**：2025 agent 安全实践的一致清单：①**secrets 注入而非环境**——密钥经注入进入进程，不落上下文/日志/文件；②**最小权限 token**——过度授权（over-scoped token）是泄密主通道；③**approval gates**——不可逆动作（外发/删除/force push/发布）必须人工门禁；④**供应链**——依赖变更（新增/升级）单列审查；⑤提示注入与数据外泄的常规化防御（对齐 08 的文档投毒防御）。
**目标态（firefly-guard，新增，吸收 CI/CD 门禁；曾并入 bounds，经用户裁定回退独立）**：
- 触发：`firefly guard`；依赖变更时；发布前；review 的安全维度自动挂载（契约内挂载，经 01 路由表登记）。
- 职责：①**安全清单执行**：参数化查询/输入校验/权限最小化/密钥不落盘，逐条通过/不通过（bounds 安全红线的执行视图）；②**secrets 注入**：密钥经注入进入进程，不落上下文/日志/文件；③**供应链单列**：依赖变更独立评审（版本差异/已知 CVE/维护状态）；④**不可逆动作门禁**（v1.1 改判据式）：以可逆性判据为主规则（不可逆即停待批），外发/删除/发布为示例枚举而非穷举；⑤**CI 门禁挂载**（并入原 CI 点）：bounds 的约束检查、tdd 测试、a11y 扫描全部挂 CI，门禁红=不许合。
- 产出：安全检查报告 + CI 门禁配置。
- 验收：抽任一门禁可重跑；secrets 在全部产物中零出现。

### 19 性能优化 / Performance（新增 firefly-perf）

**现状**：gap。
**吸收**：
- Addy `performance-optimization`：先测量后优化，拒绝猜。
- Pstack `benchmark-checklist`：**基准清单**——优化前后同基准对比，数字说话。
**依据**：性能工程通识在 agent 时代的强化——agent 极易「顺手优化」制造复杂度而不解决瓶颈；对策是把「测量→定位→改动→复测」锁成流程，性能预算进 bounds（05）。
**目标态（firefly-perf，新增）**：
- 触发：`firefly perf`；bounds 声明性能预算且变更可能触碰时；用户报性能问题。
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
- 职责：①**PR 体检**：单 PR 单主题、diff 尺寸阈值（超限拆分）、提交消息逐条能独立解释；②**评审者导语**：PR 描述必含（为什么/做了什么/怎么验证/风险），验证部分挂 14 的证据链接；③**拆分指引**：大变更按任务书自动建议拆分点；④与 16 联动：PR 就绪 = 评审报告清零。
- 产出：合规 PR（描述/证据/尺寸达标）。
- 验收：PR 清单全过；评审代理对 PR 的首次理解不需要额外提问。

### 21 CI/CD 门禁（并入 18 firefly-guard）

**现状**：gap。
**吸收**：Addy `ci-cd-and-automation`（本点唯一对应）：自动化门禁是约束的执行者。
**依据**：约束驱动（05）的结论——约束必须可执行才常驻；CI 是约束的自动执行处；agent 时代新增：CI 里跑的不只是测试，还有 a11y 扫描、安全扫描、基准回归（bounds 统一挂载）。
**目标态**：并入 firefly-guard 的「CI 门禁挂载」职责（见 18⑤），不再单列技能——门禁的「定义」在 bounds，门禁的「执行」在 CI，guard 负责挂载与红绿裁决。

### 22 废弃与迁移 / Deprecation（并入 firefly-archive）

**现状**：gap。
**吸收**：Addy `deprecation-and-migration`（本点唯一对应）：废弃是显式流程——标记→通知→迁移路径→时间表→移除。
**依据**：SDD 的产物观——废弃决策是需要记录的变更（影响使用者的契约变更），应走 delta spec 而非顺手删除；与「先读后改、先查后删」的全局纪律一致。
**目标态（并入 firefly-archive 的「收尾」职责，v1.1 补全机制）**：
- ①废弃清单（API/配置/文件），每项带迁移路径与时间表；②移除动作走 delta spec（破坏性变更显式化），**additive 先行、destructive 单独部署（expand-contract，v1.1 补收）**；③迁移脚本作为产物沉淀，**每个迁移必须有 down path**（没有回退路径的迁移就是不可逆部署）；④粒度=一次迁移一个消费者；⑤默认 advisory 建议弃用，强制移除须单独批准。

### 23 文档与 ADR / Docs

**现状**：openspec-sync-specs（受管覆盖）——spec 与实现同步。
**吸收**：
- Addy `documentation-and-adrs`：**ADR 记录为什么**——决策的上下文（备选/理由/后果）比结论更值钱。
- Pstack `why`：对「为什么」的持续追问，落成文档。
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
- 触发：`firefly trace`；任务归档时自动生成运行摘要。
- 职责：①**运行留痕**：每次任务产出结构化运行记录（时间线/进入的技能/关键决策/证据链接），字段用轻量 JSON/Markdown 约定，**OTel GenAI 语义约定仅作字段命名参考、不作合规要求**（v1.1 降级：本地落盘摘要无采集管线消费）；②**应用侧埋点**（问题驱动，v1.1 补收 addy）：添加任何埋点前先写下 on-call 工程师会问的 2-4 个问题，每个信号必须回答其一；日志结构化/级别语义/敏感字段脱敏/**标签基数控制**（标签只能来自小而固定的集合）；③**失败可回放**：记录足以让第三方理解「失败在哪一步、当时输入是什么」。
- 产出：运行记录（machine-readable 摘要）+ 埋点规范。
- 验收：任一历史任务的运行记录能独立回答「做了什么 / 依据什么 / 结果如何」——**保留期限内**（见 §4.5）。

### 25 发布与完成 / Shipping

**现状**：firefly-archive（归档收尾）。
**吸收**：
- Addy `shipping-and-launch` + `definition-of-done`：**完成有定义**——发布不是「代码写完」，是清单销项。
- Pstack：无直接对应（完成定义藏在阻断关系里）。
**依据**：产物即流程——DoD 清单使「完成」可判定，杜绝「90% 完成度」的永远差一步；agent 场景特有：agent 声称完成 ≠ 完成，DoD 每项都要证据。
**目标态（firefly-archive 演进，吸收 deprecation）**：
- 机制：①**DoD 销项**：完成 = 清单逐项证据（测试绿/门禁绿/评审清零/spec 同步/文档更新/临时产物清理），缺证据即未完成；②**归档**：任务资产进 openspec archive（现有流程），附 24 的运行记录；③**废弃管理**（吸收 22）：废弃清单与迁移路径随归档维护。
- 产出：DoD 销项表 + 归档记录。
- 验收：无「声称完成但销项表有空洞」的任务进入归档。

### 26 复盘与学习 / Retro（新增 firefly-retro）

**现状**：gap——教训不回流，同类错误重复出现。
**吸收**：
- Matt `retro`：**复盘四问**（什么成了/什么败了/学到什么/改什么）。
- Pstack `reflect` + `why`：把教训固化成**常驻触发器**——复盘的终点是新规则，不是感想。
**依据**：context engineering 的外部记忆观——跨任务学习必须落盘成可检索产物；Pstack 的「原则即触发器」+ Anthropic 技能机制（SKILL.md description 即路由依据）共同指向：**教训的可执行形态是技能/清单/门禁里的具体条款**，不是一段感想文字。
**目标态（firefly-retro，新增，v1.1 反刍降级）**：
- 触发：`firefly retro`；任务归档时（轻量）；连续失败/返工 ≥2 次时（强制）。
- 职责：①**四问结构**：成了什么 / 败在哪 / 根因（联动 15 调试记录）/ 改什么；②**回流三通道**：教训必须落到——技能条款（改 SKILL.md，**以提案形式走 OpenSpec 变更**，安装态待同步，doctor 对「已批准待同步」不报 DRIFT，v1.1 修对撞）/ 约束（进 bounds）/ 门禁（进 bounds 的 CI 挂载清单，开放式）；无落点记「未采纳」并说明为什么；③**条款自查**（v1.1，替代原「反刍检查」——跨任务命中追踪需要状态存储与调度器，超出静态资产表达力，降级）：每次 retro 运行时复查既有条款清单的长度与相关性，逐条裁决删留，防清单腐化。
- 产出：复盘记录 + 条款回流 diff。
- 验收：任何复盘至少产生一条可执行条款或显式的「不采纳理由」。

## 3. 与现状的映射（实施对象清单，待批准后执行）

| 现有资产 | 动作 | 对应设计点 |
|---|---|---|
| assets/claude/skills/firefly/SKILL.md | 演进 | 01 |
| firefly-think | 演进 | 02 |
| firefly-draw + brainstorming | 演进/合并 | 03 |
| firefly-propose | 演进 | 04 |
| firefly-tasks + writing-plans | 演进/合并 | 06 |
| firefly-implement + executing-plans + subagent-driven-development | 演进/合并 | 07 |
| firefly-verify-web + playwright-interactive | 演进 | 14 |
| firefly-review + requesting-code-review | 演进/合并 | 16/17 |
| openspec-sync-specs | 更名演进 firefly-docs | 23 |
| firefly-archive | 演进（吸收 deprecation/DoD） | 22/25 |
| test-driven-development | 更名演进 firefly-tdd | 13 |
| firefly-bounds / firefly-doubt / firefly-source / firefly-context / firefly-ui / firefly-arch / firefly-debug / firefly-guard（含 CI）/ firefly-perf / firefly-pr / firefly-trace / firefly-retro | **新建** | 05/09/08/10/11/12/15/18(+21)/19/20/24/26 |

（以上为仓库内资产路径，均在本仓库 `assets/claude/` 下；实施时逐项走 OpenSpec 变更流程。）

## 4. 实施路线（建议，待批准）

- **P0（流程闭环，v1.1 重排修依赖倒置）**：16 review 演进（含 spec 档）/ 09 doubt / 15 debug / 25 archive 演进 + **03/04 最小演进**（对垒表产物 + spec 定稿挂反证点——doubt 闸门的两个挂点）+ **24 trace 最小运行记录**（archive 归档要附的载体）——「反证-调试-评审-完成定义」闭环补齐且不悬空。
- **P1（工程纵深）**：05 bounds / 08 source / 10 context / 13 tdd 演进 / 14 verify-web 演进 / 01 firefly 演进 / 18 guard（含 CI 门禁）（next 子命令 + 注册表静态化，承载契约内挂载）——约束、依据、上下文、验证四梁 + 总控。
- **P2（领域扩展与收尾）**：11 ui / 12 arch / 19 perf / 20 pr / 23 docs 演进 / 26 retro / 02 演进收尾（裁定复述）/ 资产单套化重整（§0.5 布局迁移，建议此时机一并执行）。

### 4.5 横切公共约定与记录生命周期（v1.1 新增，修 mar P1 横切散定义与无限期追溯）

**三个横切 schema**（各技能引用不复制，改动只改一处）：
- **证据条目**：`[类型] 断言 + 来源（文件:行号 / 符号 / 命令输出 / 截图归档路径）+ 时间`——08 引用、13 红绿对、14 三元组、15 调试记录、24 运行记录统一此格式
- **可执行清单**：`条目 + 验证命令 + 最近一次结果（通过/失败 + 时间）`——bounds 约束、doubt 检验、安全清单项、review 裁决、25 DoD 销项统一此结构（中文统一「清单」，英文 checklist）
- **任务运行记录**：`目标 / 已完成 / 未完成 / 证据链接 / 风险` 五字段——context 的 NOTES、trace 的运行留痕、archive 的归档摘要统一此结构

**记录生命周期**：运行记录/证据归档带 `schemaVersion` 字段；保留期限默认 90 天（bounds 可覆写）；过期迁移/清理由 01 注册表健康检查顺带报告；「任一历史任务」类追溯义务以保留期限为界。

### 裁定结果（2026-11-20，用户逐项裁定）

1. **doubt / guard 合并**：**回退**——firefly-doubt、firefly-guard 恢复独立技能（23 技能，本次修订已执行）。
2. **mar / nextup 吸收**：**机制提炼**（mar→16 独立性协议 + 标准一致性维度；nextup→01 `firefly next` 子命令），不原文收编。
3. **裁定复述条款**（02 think ④）：**确认纳入**。

## 5. 参考来源（主要）

- Anthropic: Equipping agents with Agent Skills（2025-10）；Skill authoring best practices（官方文档）
- Anthropic: Effective context engineering for AI agents（2025-09，含 compaction/note-taking/sub-agents/JIT）
- GitHub: Spec-driven development with AI — spec-kit（2025-09）；OpenSpec / BMAD / Kiro 对比综述
- 评审分离：Supercharged code reviews with subagents（2025-08）；Structured Disagreement for Grounded Agentic Code Review（研究）
- 安全：AI coding agents security（secrets 注入/最小权限/approval gates/沙箱逃逸研究）
- 可观测：OpenTelemetry AI Agent Observability（2025-03，GenAI 语义约定）
- 调试：AgentRx（Microsoft Research）；Systematic Debugging skill 范式；Debug2Fix（arXiv 2026）
- TDD/验证：锁测试基线与 self-passing 风险的多篇实践（skyramp/bunnyshell/matrix-os 等）
- a11y：2025 自动化 a11y 工具与「自动化只覆盖部分 WCAG」的社区共识

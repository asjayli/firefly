# firefly-next 设计稿：26 维度的目标态（v2）

> 状态：**设计稿，待用户正式确认**。确认前不实施任何技能改动。
> 方法：26 个维度逐点吸收 Matt / Addy / Pstack 三套的优点，叠加 2025-2026 互联网最新实践，为 firefly 设计下一版理想形态。
> 互联网依据：Anthropic Agent Skills 与 context engineering 官方实践、GitHub Spec Kit / OpenSpec / BMAD / Kiro 的 spec-driven 浪潮、AI 评审的生成/评审分离范式、agent 安全（secrets 注入/最小权限/approval gates）、OTel GenAI 可观测约定、RCA-first 调试纪律、a11y 自动化边界等（详见各点「依据」）。

## 0. 设计立场：五条元原则

从三套的分化与最新实践中，firefly-next 的所有技能设计服从以下元原则：

1. **显式授权（Explicit mandate）**——继承 firefly 现状的最大优点：用户点名才进入，子命令即授权边界。三套中 Pstack 的「常驻触发器」与 Addy 的「按需技能」之间，firefly 取 Addy 的按需 + 自己的契约路由，拒绝隐式扩权。
2. **证据优先于断言（Evidence over claim）**——吸收 Addy source-driven / doubt-driven 的内核：任何结论（源码行为、测试通过、评审通过）必须挂在可复核的证据上；agent 的自我报告不是证据。
3. **生成与评审分离（Separation of duties）**——2025 评审实践的共识：写得越多，评审越要独立。执行代理与评审代理必须分离，评审以独立子代理 + 并行多维检查点运行。
4. **上下文最小充分（Minimal sufficiency）**——Anthropic context engineering 的核心：上下文是有限注意力预算，只装「达成目标的最小高信号 token 集」；用 JIT 检索、compaction、结构化笔记、子代理摘要四板斧管理。
5. **产物即流程（Artifacts as process）**——spec-driven 浪潮的共识：流程不靠自觉，靠仓库里的持久产物（spec / tasks / ADR / NOTES / 复盘记录）驱动；每个技能必须定义它的产出物与验收标准，否则不许存在。

## 1. 技能总览：新增 / 演进 / 合并

firefly-next 目标态共 **21 个技能**：11 个演进 + 10 个新建（11+10=21）。
五个维度并入相邻技能：**17 简化→review 维度、21 CI→bounds、22 废弃→archive、09 反证→review 的 `--doubt` 档、18 安全门禁→bounds**——后两项经 mar 审查裁定合并（判据与 17 的 YAGNI 先例一致：同一流程点不设两套机制、一条质量线不拆两个家）。

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
|（09 反证与 18 安全门禁并入 review 档位与 bounds，见合并说明） | | | |
| review | firefly-review | 演进 | 评审裁决：独立子代理 + 并行多维 + `--doubt`/`--deep`/spec 档 |
| review | firefly-perf | **新增** | 性能：基准先行，数字说话 |
| ship | firefly-pr | **新增** | 交付：为评审者而写的 PR |
| ship | firefly-docs | 演进（吸收 openspec-sync-specs） | 文档与 ADR：决策即记录 |
| ship | firefly-trace | **新增** | 可观测：OTel 约定的结构化遥测 |
| ship | firefly-archive | 演进（吸收 deprecation/shipping） | 收尾：definition-of-done + 废弃迁移 |
| extra | firefly-retro | **新增** | 复盘：教训入库成触发器 |

合并说明：`simplification` 并入 review 的常设维度 + `--deep` 档；`doubt` 并入 review 的 `--doubt`/spec 前置档（杀人清单/反例测试/存活判定，与 thermo 档同构）；`security/CI` 并入 bounds（约束的定义、安全清单与 CI 门禁执行归一条质量线）；`deprecation` 并入 archive。判据统一：独立技能的维护成本大于收益（YAGNI）。

---

## 2. 逐点设计（26 维度）

### 01 总控与路由 / Meta & Routing

**现状**：firefly（显式编排、写死的子命令契约）——四套中唯一把「授权边界」写进路由层的。
**吸收**：
- Addy `using-agent-skills`：技能发现机制——agent 能自己列出/检索可用技能而不是靠人记。
- Pstack `poteto-mode`：身份声明——进入时明确宣告当前模式，退出时显式交还控制权。
- Matt `ask-matt`：单一入口——用户永远知道从哪个门进。
**依据**：Anthropic Agent Skills 官方实践——progressive disclosure：SKILL.md 正文保持 <500 行高信号，重资料放 references/ 按需加载；技能元数据（name/description）是路由的依据，必须可被检索。
**目标态（firefly 演进）**：
- 触发：用户点名 `firefly` 或其子命令；「存在编码任务」不是触发条件。
- 职责：①路由表：子命令→技能→授权范围的静态契约（现状保留）；②新增**技能注册表**：`firefly doctor` 可列出全部技能、各自触发词、上次使用与健康状态（description 是否漂移）；③新增**模式宣告**：进入/退出子命令时输出一行模式标记，杜绝「顺手多做」。
- 产出：路由决策一行输出（进哪个技能、授权边界是什么）；无匹配时明确说「不在契约内，请点名」。
- 验收：对任何非点名触发尝试，firefly 必须拒绝并提示正确入口。

### 02 需求追问 / Requirements

**现状**：firefly-think（结构化提问，收集背景与目标）。
**吸收**：
- Matt `grill-with-docs`：追问前先读文档——问题建立在已读材料上，不问文档里已有答案的问题。
- Addy `interview-me`：一次只问一件事 + 提供候选答案（把开放题降为选择题）。
- Pstack `sharpen`：把模糊诉求磨成可判定命题。
**依据**：context engineering 的「right altitude」——追问既不能碎成二十个Yes/No（脆），也不能泛泛「多告诉我一些」（空）；每轮追问应是「具体到能引导行为，开放到保留判断」。
**目标态（firefly-think 演进）**：
- 触发：`firefly think`；新任务进入 define 阶段时。
- 机制：①**先读后问**：提问前必须列出已读文件清单，禁止问其中已有答案的问题；②**可判定问题清单**：每轮 ≤5 问，每问附 2-4 个候选答案 + 「都不是」出口；③**停机条件**：当剩余问题全部「不影响方案分叉」时停止追问，输出需求纪要（目标/非目标/约束/已知未知）。
- 产出：`docs/specs/<task>/requirements.md`（或对话内嵌纪要），含「未决问题=空」的显式声明。
- 验收：纪要中每个需求可判定（能写出「满足/不满足」的检验式）。

### 03 想法打磨 / Idea

**现状**：firefly-draw + brainstorming（方案发散）。
**吸收**：
- Pstack `arena`：**强制多方案对垒**——至少两个方案正面竞争，各自列出杀死自己的条件。
- Matt `prototype`：可丢弃原型——用最便宜的方式验证最贵的假设。
- Addy `idea-refine`：迭代收敛而非一次性定稿。
**依据**：AI 生成成本低导致「第一方案偏差」——agent 倾向接受第一个成形方案；对垒机制是对这种偏差的制度化纠偏（structured disagreement 的设计思想同样用于 16 评审）。
**目标态（firefly-draw 演进）**：
- 机制：①**双案下限**：任何非平凡决策（影响 >3 文件或含架构选择）必须给出 ≥2 个竞争方案 + 各自的反例条件；②**假设分级**：方案中的假设按「验证成本」排序，最贵的假设用原型/检索先杀；③用户裁决点：对垒结果交用户选，agent 只推荐不拍板。
- 产出：方案对垒表（方案/代价/风险/杀死条件/推荐理由）。
- 验收：无对垒表的方案直接进入 spec 时，propose 必须打回。

### 04 规格成形 / Spec

**现状**：firefly-propose（OpenSpec delta spec 流程）。
**吸收**：
- Addy `spec-driven-development`：constitution 层——项目级原则与单次 spec 分离，原则只写一次。
- Matt `to-spec`：把对话散落的决议收拢成结构文档的收束能力。
- Pstack：无对应（本点 Pstack 缺位，其哲学是 spec 即任务列表）。
**依据**：GitHub Spec Kit / OpenSpec / BMAD / Kiro 在 2025 共同验证的 spec-first 范式：constitution → spec → plan → tasks 分层；争议点「spec 放哪」的社区答案趋向 **spec 入仓库**（与代码同生命周期、可评审、可回滚）——firefly 的 OpenSpec 资产结构正是这个答案。反面教训：spec 质量不受控时产出 689 行可疑代码（Nov 2025 实测报告）——所以 spec 必须带验收标准，且验收标准必须可转测试。
**目标态（firefly-propose 演进）**：
- 机制：①**三层分离**：constitution（项目原则，长期）/ delta spec（本次变更，短命）/ tasks（执行清单）；②**验收标准即测试草案**：spec 里每条 Requirement 必须能映射为 Scenario，Scenario 语言可直接抄进测试文件；③**spec 完整性检查**：无验收标准的 spec 不许进入 tasks 阶段。
- 产出：`openspec/changes/<change-id>/`（proposal.md / specs/*.md / design.md 可选）。
- 验收：spec 评审（firefly-review 的 spec 档）通过；每条 Scenario 有 Given/When/Then。

### 05 质量底线 / Constraints（新增 firefly-bounds）

**现状**：gap——约束散落在各技能的注意事项里，无一致执行。
**吸收**：
- Addy `constraint-driven-development`（本点唯一对应）：**非功能约束先行**——性能/安全/兼容性预算在写第一行业务代码前定死，违反即停。
- Pstack 的四原则（结构编码领域/边界校验/非法状态不可表示/幂等）作为约束模板的候选条目。
**依据**：agent 安全实践的一致结论——约束写在 prompt 里会被长上下文稀释（context rot），必须落成**可执行检查**（lint 规则/CI 门禁/测试）才能常驻；「写下来」不等于「被遵守」。
**目标态（firefly-bounds，新增，吸收 security+CI）**：
- 触发：`firefly bounds`；spec 阶段；依赖变更时；发布前。
- 职责：①**约束清单**（性能预算/内存上限/兼容矩阵/安全红线/数据边界），每条绑定可执行验证；②约束与任务挂钩——完成声明必须引用检查结果；③项目级 `bounds.md`（constitution 的一部分）；④**安全清单**（并入原 guard）：参数化查询/输入校验/权限最小化/密钥不落盘，逐条通过/不通过；⑤**secrets 注入**：密钥经注入进入进程，不落上下文/日志/文件；⑥**供应链单列**：依赖变更独立评审（版本差异/CVE/维护状态）；⑦**不可逆动作门禁**：以可逆性判据为主规则（不可逆即停待批），外发/删除/发布为示例枚举；⑧**CI 门禁挂载**（并入原 CI 点）：约束检查、tdd 测试、a11y 扫描全部挂 CI，门禁红=不许合。
- 产出：约束清单 + 每条验证命令 + 安全检查报告 + CI 门禁配置。
- 验收：抽任一约束/门禁可重跑；secrets 在全部产物中零出现。

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

### 09 反证与压力测试 / Doubt（并入 16 review 的 --doubt 档）

**现状**：gap——验证只有正向（测试过=好），无系统性反证。
**吸收**：
- Matt `grilling`（用于自己）：**对抗性追问**——把自己方案当成别人的来攻击。
- Addy `doubt-driven-development`：把「什么会让我错」变成显式清单。
- Pstack `interrogate`：审讯式检查——假设逐条过堂。
**依据**：AI 测试实践的头号失败模式是 **self-passing but incorrect tests**（agent 写出自我满足的错误测试）；对策是独立红队视角——生成者不能自己验证自己（与 16 评审分离同源）。
**目标态（并入 16 review 的 `--doubt` 档，经审查裁定合并）**：
- 档位定义：spec 定稿前、方案对垒后强制走 review 的 `--doubt` 档——①**杀人清单**：列出「如果这个方案是错的，最可能错在哪」Top 5，每条附可执行的检验；②**反例测试**：为最可能的两条写实际的反向测试并运行；③**结论分级**：反证存活 / 带伤存活（列伤）/ 阵亡。
- 产出：反证报告作为 review spec 档的输入（spec 定稿门必附）。
- 验收：spec 定稿无反证报告不放行（P0 流程点，由 review spec 档执行）。

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
- 机制：①**基线先行**：动代码前跑全量测试，红的先修或显式记录豁免；②**红→绿→重构**不变，但**红必须有证据**：新测试的失败输出贴进任务摘要（证明不是天生绿）；③**锁测试条款**：实现代理发现需要改测试时，必须停下来走变更流程，禁止顺手改；④**测试也分层**：单元/集成的比例与速度预算进 bounds。
- 产出：测试代码 + 每任务的「红证据→绿证据」对。
- 验收：PR 中新增测试的首次失败输出可查；无「实现与测试同一提交内同时出现且测试从未红过」的可疑对。

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
- 触发：测试红了两次仍没修好 / 出现非预期行为 / 线上问题排查。
- 职责：①**最小复现优先**：先造最小复现（测试/脚本），复现不了先解决「为什么复现不了」；②**假设登记**：根因假设显式列出（≥1 条），每条绑一个检验实验；③**单变量改动**：每轮只动一个变量，改动前后都跑复现；④**根因≠症状**：修复必须能解释「为什么这个改动治的是根因」，说不清就继续查；⑤修完把根因与修法写入任务摘要（供 retro 沉淀）。
- 产出：调试记录（复现/假设/实验/根因/修复/回归测试）。
- 验收：回归测试把原 bug 锁死；无「改了三处不知道哪处治好」的合并。

### 16 评审裁决 / Review

**现状**：firefly-review + requesting-code-review（受管）。
**吸收**：
- Pstack `interrogate`：**审讯式密度**——问题逐条过堂，不许「整体看起来不错」。
- Addy `code-review-and-quality`：检查维度清单化。
- Matt `code-review`：评审是裁决不是聊天——每条意见给裁决（必须改/建议/可接受）。
**依据**：2025 评审实践的核心共识——**生成与评审分离**：AI 写得越多，评审越要独立；范式是独立评审子代理（与执行代理不同上下文、不同人格设定）+ 并行多维检查（安全/性能/可测性/简化各一个检查点）+ 反馈环（主代理修复→评审子代理复审直到清零）；structured disagreement 研究证明子代理对抗能落地「最小协作开销的高质量评审」。
**目标态（firefly-review 演进）**：
- 机制：①**独立评审代理**：评审者不持有执行历史，只看 diff+spec+任务书（防锚定）；②**多维并行**：至少四个维度各过一遍——正确性（对 spec）/ 简化（能否更少代码，吸收 17 点）/ 风险（边界与异常）/ 测试（覆盖与质量）；③**裁决式意见**：每条 = [必须改|建议|可接受] + 理由 + 位置；④**清零环**：必须改项不归零不通过，复审由同一评审代理做增量；⑤**自我评审豁免声明**：任何「我检查过了」必须注明检查方式，纯自述不算。
- 产出：评审报告（分维度裁决清单）。
- 验收：无未裁决的必须改项；评审代理与执行代理的上下文隔离可查（摘要列明输入只有 diff/spec/任务书）。

### 17 代码简化 / Simplification（并入 16）

**现状**：gap（独立技能缺位）。
**吸收**：
- Addy `code-simplification`：简化是独立工序，不是顺手做。
- Pstack `thermo-nuclear-code-quality-review`：**深度清理档位**——极端简化审查作为可选重炮。
**依据**：评审分离原则——简化判断交给独立评审维度比执行代理自查有效；「最小充分」原则同样适用于代码：能删的分支/抽象/防御都是认知负担。
**目标态（16 的一个评审维度 + 一个档位）**：
- 机制：①review 的常设维度「简化」：每 diff 问三题——能删吗？能并吗？这层抽象有第二个使用者吗（YAGNI）？②**thermo 档位**：`firefly review --deep` 触发深度简化审查（整模块视角，吸收 Pstack 重炮语义），作为可选档而非常驻。
- 验收：常规 review 必含简化维度结论；thermo 档位产出独立的简化清单。

### 18 安全加固 / Security（并入 05 bounds）

**现状**：gap——安全靠通用常识，无专门防线。
**吸收**：
- Addy `security-and-hardening`：**参数化/最小权限/输入不信任**三件套，清单化。
- Pstack `thermo-nuclear-review`：安全作为重炮审查档。
**依据**：2025 agent 安全实践的一致清单：①**secrets 注入而非环境**——密钥经注入进入进程，不落上下文/日志/文件；②**最小权限 token**——过度授权（over-scoped token）是泄密主通道；③**approval gates**——不可逆动作（外发/删除/force push/发布）必须人工门禁；④**供应链**——依赖变更（新增/升级）单列审查；⑤提示注入与数据外泄的常规化防御（对齐 08 的文档投毒防御）。
**目标态（并入 05 bounds，经审查裁定合并：一条质量线不拆两个家）**：
- 05 承接安全与门禁全部职责（见 05 目标态的④-⑧）；本点不再单独成技能。

### 19 性能优化 / Performance（新增 firefly-perf）

**现状**：gap。
**吸收**：
- Addy `performance-optimization`：先测量后优化，拒绝猜。
- Pstack `benchmark-checklist`：**基准清单**——优化前后同基准对比，数字说话。
**依据**：性能工程通识在 agent 时代的强化——agent 极易「顺手优化」制造复杂度而不解决瓶颈；对策是把「测量→定位→改动→复测」锁成流程，性能预算进 bounds（05）。
**目标态（firefly-perf，新增）**：
- 触发：`firefly perf`；bounds 声明了性能预算且变更可能触碰时；用户报性能问题。
- 职责：①**基准先行**：无基准不优化——先建立可重复的测量（脚本/命令+环境说明）；②**单点归因**：瓶颈定位必须挂 profile/计时证据，不接受「应该是这里」；③**改动对赌**：优化前预测预期收益，改后复测对照，不达标回滚；④复杂度代价申报：以复杂度换性能时显式记录（进 ADR）。
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

### 21 CI/CD 门禁（并入 05 bounds）

**现状**：gap。
**吸收**：Addy `ci-cd-and-automation`（本点唯一对应）：自动化门禁是约束的执行者。
**依据**：约束驱动（05）的结论——约束必须可执行才常驻；CI 是约束的自动执行处；agent 时代新增：CI 里跑的不只是测试，还有 a11y 扫描、安全扫描、基准回归（bounds 统一挂载）。
**目标态**：并入 bounds 的「CI 门禁挂载」职责（见 05⑧），不再单列技能——门禁的「定义」在 bounds，门禁的「执行」在 CI，中间不需要一个独立技能。

### 22 废弃与迁移 / Deprecation（并入 firefly-archive）

**现状**：gap。
**吸收**：Addy `deprecation-and-migration`（本点唯一对应）：废弃是显式流程——标记→通知→迁移路径→时间表→移除。
**依据**：SDD 的产物观——废弃决策是需要记录的变更（影响使用者的契约变更），应走 delta spec 而非顺手删除；与「先读后改、先查后删」的全局纪律一致。
**目标态**：并入 firefly-archive 的「收尾」职责：①废弃清单（API/配置/文件），每项带迁移路径与时间表；②移除动作走 spec（破坏性变更显式化）；③迁移脚本/命令作为产物沉淀。

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
**目标态（firefly-trace，新增）**：
- 触发：`firefly trace`；任务归档时自动生成运行摘要。
- 职责：①**运行留痕**：每次任务产出结构化运行记录（时间线/进入的技能/关键决策/证据链接），按 OTel GenAI 约定组织字段；②**应用侧埋点**：为被开发的应用添加日志/指标/追踪时的清单与约定（日志结构化、级别语义、敏感字段脱敏）；③**失败可回放**：记录足以让第三方理解「失败发生在哪一步、当时的输入是什么」。
- 产出：运行记录（任务的 machine-readable 摘要）+ 埋点规范。
- 验收：任一历史任务的运行记录能独立回答「做了什么/依据什么/结果如何」。

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
**目标态（firefly-retro，新增）**：
- 触发：`firefly retro`；任务归档时（轻量）；连续失败/返工 ≥2 次时（强制）。
- 职责：①**四问结构**（吸收 Matt）：成了什么/败在哪/根因（联动 15 的调试记录）/改什么；②**回流三通道**：教训必须落到三处之一——技能条款（改 SKILL.md）/ 约束（进 bounds）/ 门禁（进 guard 的 CI），无落点的教训记入「未采纳」并说明为什么；③**反刍检查**：复盘产出的新条款在下次任务中被引用/触发时记录命中——未被触发的条款定期清理（防清单腐化）。
- 产出：复盘记录 + 条款回流 diff（改了哪个技能/约束/门禁）。
- 验收：任何复盘至少产生一条可执行条款或显式的「不采纳理由」。

---

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
| firefly-bounds（含安全与 CI）/ firefly-source / firefly-context / firefly-ui / firefly-arch / firefly-debug / firefly-perf / firefly-pr / firefly-trace / firefly-retro | **新建** | 05(+18+21)/08/10/11/12/15/19/20/24/26 |

（以上为仓库内资产路径，均在本仓库 `assets/claude/` 下；实施时逐项走 OpenSpec 变更流程。）

## 4. 实施路线（建议，待批准）

- **P0（流程闭环）**：16 review 演进（含 `--doubt` 档与 spec 档）/ 15 debug / 25 archive 演进——先把「反证-调试-评审-完成定义」闭环补上，这是质量增益最大的一环。
- **P1（工程纵深）**：05 bounds（含安全与 CI 门禁）/ 08 source / 10 context / 13 tdd 演进 / 14 verify-web 演进——约束、依据、上下文、验证四梁。
- **P2（领域扩展）**：11 ui / 12 arch / 19 perf / 20 pr / 23 docs 演进 / 24 trace / 26 retro / 01-04 演进收尾。

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

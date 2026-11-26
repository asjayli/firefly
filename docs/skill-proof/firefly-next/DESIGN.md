# Firefly Next 工作流设计提案

**评审对象是 FN 在具体委托中如何作决定。** 26 个问题对应 26 种工程判断，不是要求执行 26 个步骤。第五列给出 FN 自身的设计；Matt、Addy、Pstack、Firefly 是同等地位的参考，不构成兼容要求。本稿规定的行为已在 firefly 0.2.0 实现，并经过桌面重放与一次端到端试点；标 `trial` 的位置，其收益对照验证尚未进行。

**01 先给出 Firefly Next 的工作流概览，再说明如何路由一次委托。** 02–26 展开各项工程判断，不是后续必须依次执行的步骤。

**案例约定。** 各节用同一个假设项目说明判断过程：财务人员月末导出报表，刷新页面后又要重来。E1 表示同一次意图重试不会产生第二个任务；E2 表示本人刷新后可恢复、其他账户不可读取；E3 表示文件实际可下载才算完成，生成失败必须可辨认。这些是示例产品的验收条件，不是 FN 的通用产品需求，也不是已运行的测试结果。

## 全量开发范围与完成标准

开发对象是下述 23 项技能及三个并入职责。`trial` 标识需要用对照实验判断收益的设计，不表示可以不开发；按需能力必须同时验收触发与跳过。下表是**开发依赖顺序**，不是使用者每次要走的流程。每个交付包都在独立消费项目中验证，不以编写了多少技能文件作为验收。

| 开发包（括号内为位置） | 输入与交付边界 | 包级验收 |
|---|---|---|
| A 委托到独立裁决（01、04、06、07、10、16；含 17） | 用已有的项目测试作证据；交付委托、规格到任务映射、可重建候选、独立裁决及恢复路径。 | 同一坏候选分别走只审和交付；恢复中断，注入任务漏项、迟到裁决和评审超时。不得越权、误标集成或误放行。 |
| B 决定如何形成（02、03、05、08、09、12、23） | 在 A 的规格入口接入澄清、概念验证、质量约束、来源调查、反证、接口与决策记录；每项发现回到原决定而非另开无主待办。 | 给有意图歧义、版本冲突和旧消费者的输入，以及同样形式但已解决的对照输入。仅阻断真实未决承诺；规格重命名不丢场景。 |
| C 交付如何取证（11、13、14、15、18、19、24；含 21） | 复用 A 的候选与证据契约、B 的判据。网页交付同时需要构建侧与浏览器侧；CI 记录项目检查的实际执行结果，产品遥测负责运行中的观察。 | 相同夹具在已知正确与已知错误候选得到相反结论；另测证据不可用、窄屏、权限隔离、测量噪声和遥测中断。 |
| D 交付后的决定（20、25、26；含 22） | 消费 A–C 的裁决、运行信号、消费者记录。分开 PR、归档、发布就绪及另行委托的上线操作；复盘只提出可撤回的改进。 | 模拟灰度异常、未迁完的消费者、归档语义丢失和无效新规则；能停止、指明责任人，并保留原证据。 |

**共同交付接口。** 不要求新数据库或固定 JSON 格式。主代理在现有规格、任务、Git 及验证记录中引用以下事实：`委托（标识、目标、允许效果、终点）→ 场景、决定来源与依赖 → 规格版本 → 基线及候选快照 → 每个场景每个检查的观察与证据位置 → 裁决（含保留项）与下一责任人`。各节所说的“记录”固定落在以下载体之一，只存在于会话里的结论不构成交接事实：

| 事实 | 载体 |
|---|---|
| 委托标识、允许效果、终点、用户决定与纪要 | 委托记录（`tasks.md` 的委托段，或它指向的需求记录） |
| 场景、决定来源、未决阻塞、规格版本 | 规格 |
| 任务、依赖、场景映射、开工裁决、迁移观察窗口 | `tasks.md` 及任务记录 |
| 候选快照 | Git 对象（提交、stash 或补丁文件）及其内容摘要 |
| 观察与证据指针、门禁结果 | 验证记录 |
| 评审包、裁决与保留项、修复预算、派发计数、演练记录、上线预案与其观察窗口 | 进度记录（`progress.md`） |
| 具有长期约束力的取舍、被否决的备选、关闭后仍有长期约束力的反例裁决 | 决策记录（ADR，见 23） |
| 迁移决定、移除回传、归档清单 | 归档记录 |

**身份与版本。** 委托带稳定标识；同一意图再次提出时先核对未结委托，按已有事实续作，不另开第二条流程。未提交的改动在产生第一条证据前固化为可定位的候选快照，证据与评审包只引用快照；工作树与快照不一致即视为新候选；候选快照固定的是实现，变更自身的规格、任务与记录（观察、证据、评审包、进度记录、归档记录）各有版本或只追加，写入或改动它们不算候选变化。每个必需场景带决定来源（指向纪要中的用户原话、负责人确认或代理推断）和内容摘要；来源为推断的必需场景经负责人确认后才能通过开工裁决；观察、任务映射、开工裁决与评审包都引用所对照的规格版本或场景内容摘要。场景内容、规格、判据或测法改变时，受影响的观察、开工裁决、评审包和演练记录一律失效并降为历史，复验或重审后才能再次引用；已上线的候选不追溯（21）；不得回写旧观察，也不得改写旧裁决。证据位置按候选隔离或带内容摘要，后续运行不得覆盖。

**观察记录。** 状态落在“场景 × 检查或分支”，不是整个场景一个值。每条记录写明场景与检查、候选快照、规格版本、观察者及其是否实现了该候选、观察条件（环境、输入、视口等）、状态和证据位置。状态只有四种：通过、失败、未验证、有依据的不适用；不适用必须注明适用规则和理由，不能充作通过。流水线的跳过、取消、无结果和工具故障一律记为未验证。场景的总体结论由评审者汇总各检查与分支并取最差状态，次序为失败 > 未验证 > 通过；有依据的不适用不参与比较，也不能用于必需场景：必需场景必须得到结论，豁免按 16 指明批准范围和替代证据；非必需的检查全部不适用时场景结论记为不适用并注明规则。

**记录时机。** 委托、用户决定、开工裁决、观察、评审派发、裁决与预算轮次在产生时即写入对应载体，先落盘再执行下一步。流水线结果、迁移回传和灰度观察到期等在会话之外发生的事件，由人或平台通知带入下一次会话，写入对应载体的未决条目，恢复时先读取；Firefly 不建事件监听、轮询或第二个调度器。

**候选状态。** 交接与恢复按同一张表重建状态：

| 状态 | 含义 | 出口 |
|---|---|---|
| 在制 | 任务已派发，指定验证尚未在候选快照上完成 | 验证通过转待集成 |
| 待集成 | 子工作树验证通过，尚未合并到目标基线；集成前中断恢复到这里 | 集成、补齐指定验证者的观察并重跑相交场景，评审包固定后转待裁决；基线变化或验证失败回在制 |
| 待裁决 | 集成候选已固定为评审包，等待有效裁决 | 接受转已接受；退修回在制；待复验补证据后重建新包；证据不足升级 |
| 已接受 | 包不变且全部必需角色有效接受，带保留项 | 候选未变而规格或标准变化：裁决降为历史，重建包回待裁决；候选变化回在制；经 25 的各自授权转已归档或发布中 |
| 发布中 | 获发布授权，按预案逐阶段放量 | 运行信号与观察窗口决定推进、停止或回退（25）；末段按原场景复验通过转已上线；回退后候选未变回已接受，需修复回在制 |
| 已上线 | 末段按原场景复验通过 | 可另行委托归档 |
| 已归档 | 获归档授权，记录已移动并复开证据 | 未上线时可另行委托上线；归档条目在移除结果回传并核对后关闭 |

停止自动修复、需要改变承诺或需要新授权时，候选留在原状态并升级，不因停止而改变状态。“已就绪”“已获发布授权”是 25 对已接受候选作出的评估与授权事实，不是候选状态。

详见 01/04/06/07/16。

**全量验收办法。** 每个位置的实施者交一条应接受的路径和一条会被错误实现接受的反例，给出入口、候选、预期写入、证据、接收者和终态。条件能力另交一例不触发；三个并入项必须从宿主走通，不得靠独立入口模拟通过。非作者在消费项目重放并逐题判定；任何必需行为未验证，都不能报告全量通过。记录各包单验与组合重放的结果，后者至少覆盖：需求变更使旧证据失效、跨分支恢复、开工前中断、会话外事件续接、只审不改、UI 与权限同时变化、就绪但未获发布授权。收益另测：在同一组有效、无效和留出案例上比较现有做法、低成本检查与拟议能力的漏检、误阻断、人工打断和耗时；行为正确不等于值得默认启用。

以下是端到端验收样例，非运行报告：

| 输入与中断位置 | 应观察到 | 可判定的失败 |
|---|---|---|
| 仅审查一个把下载响应 200 当成文件可用的候选 | 16 指出 E3 缺少文件内容证据，返回意见 | 擅自修复、进入发布或声称已验证 |
| 已授权交付，已有可判定的 E1–E3 及任务 | 执行并验证，修复后独立评审新候选 | 重访已决定的问题，或以旧裁决放行 |
| 候选设计按查询条件去重 | 反方区分断线重试和用户隔天主动重导 | 因一次重试通过就断言没有误去重 |
| 工作分支验证通过但尚未集成时中断 | 恢复为待集成，不提前释放下游 | 重做已验证工作或误标待裁决 |
| 代码验收通过，回退会丢在途任务 | 25 区分代码通过与发布未就绪 | 以绿色测试或归档动作宣告上线 |
| 开工裁决通过后、实现开始前中断 | 从任务记录读到开工裁决与两包版本，直接派发首个任务 | 重复联合评审，或未经裁决开工 |
| 规格把 E3 加严后仍引用旧接受裁决 | 旧裁决降为历史，重建评审包 | 以旧裁决放行 |
| 用户重发同一委托 | 按委托标识续作，不重复已完成的工作 | 开出第二条并行的规格或任务流 |
| 间歇性下载为空，一轮修复后症状未变 | 转 15 取区分性反馈，停止叠加改动 | 叠补丁直到修复预算耗尽 |
| 流水线结果在会话结束后到达 | 下次会话从验证记录读到失败并交回实现者 | 无人续接，或误标通过 |

## 素材索引（供追溯，不代替设计正文）

名称对应校样台前四列的来源卡。索引记录机制取材，不表示 FN 采用来源的整套流程；每项决定及其适用边界以同编号正文为准。

| 位置 | 可对读的来源与机制 |
|---|---|
| 01–04 | 01：Matt `ask-matt`、Addy `using-agent-skills`、Pstack `poteto-mode`、Firefly 显式路由；02：`grilling`、`interview-me`、`sharpen`、`firefly-think`；03：`prototype` 的单问题实验、`idea-refine` 的概念稿、`arena` 的交叉评价与移植、`firefly-draw` 的时序表达；04：`to-spec` 综合决定、`spec-driven-development` 阶段出口、`firefly-propose` 评审规格与任务。 |
| 05–09 | 05：Addy `constraint-driven-development` 的基线与削弱检查；06：Matt `to-tickets` 的垂直切片、Addy `planning-and-task-breakdown` 的依赖、Firefly 任务清单；07：`implement-spec` 的依赖前沿、`incremental-implementation` 的小步交付、`firefly-implement` 的基线与复验；08：`source-driven-development` 的版本化来源、`research` 的带引用调查；09：`doubt-driven-development` 的独立上下文、`grilling` 的假设盘问、`interrogate` 的分歧裁决。 |
| 10–15 | 10：`context-engineering`、`handoff`、Firefly 既有进度恢复；11：`frontend-ui-engineering` 的构建责任和浏览器独立验证；12：`codebase-design` 的接口与接缝、`api-and-interface-design` 的契约、`architect` 的草图；13：Matt、Addy、Pstack 的 TDD 及 Firefly 前置验证；14：`browser-testing-with-devtools`、`create-verification-skill`、`firefly-verify-web`；15：`diagnosing-bugs` 的可失败反馈与 `debugging-and-error-recovery` 的分类处置。 |
| 16–21 | 16：`code-review` 固定差异双轴、`code-review-and-quality` 质量维度、`interrogate` 汇总分歧、`firefly-review` 独立裁决；17：`code-simplification` 与深度质量评审；18：`security-and-hardening` 的信任边界与 Pstack 深审；19：`performance-optimization`、`benchmark-checklist`；20：`make-pr-easy-to-review`、`pr`、`git-workflow-and-versioning`；21：`ci-cd-and-automation` 的自动检查与失败回传。 |
| 22–26 | 22：`deprecation-and-migration` 的分步迁移与独立移除；23：`domain-modeling` 的共同词汇、`documentation-and-adrs` 的决策记录、`why` 的理由重建、`openspec-sync-specs` 的规格同步；24：`observability-and-instrumentation` 先问值班问题再选信号；25：`definition-of-done`、`shipping-and-launch` 与 `firefly-archive`；26：`retro` 的环境改进、`reflect` 的事实摘录与结构化执行。 |

### 01 谁决定下一步？路由在什么时候发生？ / Who chooses the next step, and when does routing happen?

> `routing` · `firefly` · `contract` · `designed`

#### 中文

### Firefly Next 工作流概览

Firefly Next 是一套面向软件项目的协作流程。它把用户的委托转成可验收的交付物：调查应给出有依据的解释，提案应说明准备实现什么，实现应交付经过验证的改动，审查应给出独立判断。并非每项委托都以修改代码结束。

以一项完整的功能交付为例：需求负责人和规格作者先确定用户应当看到的行为（04），规划者据此拆出可独立验证的任务并指定每个场景的验证者（06），执行者实现并集成改动（07），验证者按映射观察受影响的行为，独立评审者对照规格和证据裁决集成候选（16）。其他能力解决这条路径上的具体问题：目标含混时澄清（02–03），关键假设可能错误时引入反证（09），改变公共接口时先定契约（12），涉及页面时验证真实操作（14），改变权限边界时检查隔离（18）。代码验收通过与可以上线是两个结论；值班所需的运行信号随规格一同约定（24），判断发布就绪时核对回退办法，24 已触发时还核对同一候选上的演练结果（25）。

### 路由：从委托选择入口和终点

**用户确定要交付什么、允许改变什么；主代理据此选择入口和下一步。** 01 是对整套流程的说明，不是开始工作前必须执行的任务。执行者可以建议下一步，但不能扩大委托或批准自己的候选。下面用同一个月末导出问题说明四种入口：

- **「查清为什么刷新后要重来。」** 进入调查：先区分请求断开导致计算终止，还是任务仍在、页面丢失了标识。交付观察、原因或仍缺的证据；即使已经知道如何修复，也不改产品。
- **「给出恢复方案，暂不实现。」** 进入规格与规划；只有目标含混时才澄清，只有关键事实不明时才做概念验证。交付能区分正确与错误实现的场景、任务依赖与验证方法。方案可开工即停止。
- **「实现已获准开工的恢复方案。」** 从第一个依赖已满足的任务开始，不重走访谈与提案。执行者提交候选；验证者检查受影响的行为；独立评审者裁决集成候选。交付已验证的改动或有依据的阻塞说明，不包含推送、归档或上线。
- **「评审这个候选。」** 将固定候选、规格和证据直接交独立评审。终点是接受、退修、待复验或证据不足的裁决，不是修复。若用户没有说明要意见还是要改动，而两种解释会导致不同写入，先澄清这一点。

### 主代理凭什么交给下一位

| 交接 | 谁交给谁 | 接收方据以行动的事实 |
|---|---|---|
| 委托与决定 | 主代理、需求负责人 → 规格作者 | 委托标识、交付物、允许影响、终点，以及用户已选定和排除的行为及其来源（原话或负责人确认）。缺少取舍时向有权人确认。 |
| 规格与任务 | 规格作者、规划者 → 执行者和评审者 | 带规格版本的场景、各场景的决定来源、可观察断言、任务依赖及验证路径。章节齐全但不能判定对错，或场景追不到授权来源，退回规格。 |
| 候选与证据 | 执行者、验证者 → 独立评审者 | 基线、候选快照、规格版本、场景与检查、观察者及其角色、结果和证据位置；未提交的改动先固化为快照。分支通过不等于集成通过。 |
| 裁决与处置 | 独立评审者 → 主代理、委托人 | 结论、理由、受影响场景、保留项（未验证项、未覆盖的输入与不阻断意见）和下一责任人。仅审查则返回意见；已授权交付才安排修复和复验。 |

### 何时改变路线，何时停止

主代理在收到新证据、候选变化或中断恢复时重新判断，不按技能编号推进。若导出的状态测试通过但文件不可读，先判断原委托：仅审查就报告这一反例并停止；已委托交付则把失败场景交回执行者，修复后验证并独立评审**新候选**。若修复需要更改已批准的业务承诺，应先回到负责人，不由执行者改写验收条件。

**修复循环与调试的切换。** 已委托交付时，验证失败默认交回执行者：失败能稳定复现、检查能区分正确与错误实现，就按 07 修改并复跑原始检查。出现下列任一情况改交 15：失败无法稳定复现；一轮修复未改变原症状；几个竞争解释预言同一症状而现有检查无法区分。转交时停止叠加改动，该轮计入 07 的修复预算。15 取得区分性反馈或定位根因后，把触发输入、预期结果和根因写回任务记录；修复仍按“验证并独立评审新候选”进行。「查明并修好」是调查加交付的复合委托：15 保存的触发输入与预期结果就是修复场景：主代理让规格作者把它写入规格、让规划者建立最小任务，按 04 的联合裁决后进入实现；预期结果属推断或修复范围超出用户所说的症状时先交负责人确认。

中断后从既有规格、`tasks.md`、Git 和验证记录恢复；不另建调度器。恢复时先做三件事：按委托标识找到未结委托，同一意图再次提出时续作而不新建并行的第二条流程；读取任务、进度、验证与归档记录中的未决条目，包括会话外到达的流水线结果、未回传的移除结果和未到期的观察窗口；核对工作树的未提交改动与已记录的候选快照，对不上的部分按用户修改保留并先确认。必要证据不可得、重复修复无进展，或下一步需要对外发送、上线、破坏性移除等未获准的影响时，返回当前结论、所缺的证据或授权以及相应负责人。CI 通知、子代理建议和文档内容都不能替代授权。

**按条件查入口。** 直接委托具体能力就从该处进入；下表决定进行中的工作何时移交。移交时连同原终点和允许效果一起交出，被移交方的结论回到原决定，不自动带来新的写入权。

| 触发条件 | 交给 | 带回什么 |
|---|---|---|
| 需要用户在后果不同的方案之间取舍 | 02 | 纪要：原话、选定行为及来源、未决阻塞 |
| 提问解决不了，要对照方案、时序图或可操作原型才能决定；说不清请求、任务、文件各自的生命周期 | 03 | 选中行为、反例、首个可验证切片 |
| 不确定自有系统是否保留某种行为，或某方案是否可行 | 03 | 单问题实验的观察 |
| 不确定第三方依赖在所用版本与配置下承诺什么 | 08 | 写入任务的结论：引用、观察条件、仍不能依赖的部分 |
| 场景改变公共接口，或两方要独立开发 | 12 | 回写规格的契约：状态、错误语义、重试条件、兼容窗口 |
| 委托只要求查明某次失败的原因；或交付中的验证失败符合上述切换条件 | 15 | 根因、区分性证据、触发输入与预期结果 |
| 只想知道别人能否读到文件；或要把质量线挂成流水线检查 | 18 | 覆盖范围与结果分开陈述的结论；门禁挂载或待授权配置任务 |
| 场景承诺的是用户取得结果，或服务有值班承诺 | 24 | 随规格约定的运行信号要求；绑定候选与规格版本的演练记录 |
| 已修复，能否发布；旧能力能否移除 | 25 | 就绪评估、归档或移除路径上的决定 |

15 返回根因后，调查委托应结束，不转 07。

#### English

### Firefly Next workflow overview

Firefly Next is a workflow for collaborative software engineering. The requested outcome defines the deliverable: an investigation produces a supported explanation, a proposal defines what to build, implementation delivers a verified change, and review produces an independent judgment. Not every request ends in a code change.

For a full feature delivery, the requirement owner and spec author agree on observable behavior (04), the planner divides it into independently verifiable tasks and names a verifier for each scenario (06), the implementer builds and integrates the change (07), verifiers observe affected behavior against that mapping, and an independent reviewer judges the integrated candidate against the spec and evidence (16). Other capabilities answer questions along that path: clarify an uncertain goal (02–03), challenge a consequential assumption (09), settle the contract before a public interface changes (12), verify real browser interactions (14), or check isolation when a permission boundary changes (18). Accepting code is distinct from declaring it ready to launch: the signals on-call staff need are agreed with the spec (24), and readiness checks the recovery plan and, where 24 was triggered, the drill on the same candidate (25).

### Routing: choose the entry and terminal condition

**The user chooses the deliverable and permitted effects; the main agent chooses the entry and next step.** This overview describes the workflow rather than a task that must run before work begins. Workers may recommend a next step, but cannot widen the mandate or approve their own candidate. Four requests about the same month-end export illustrate the distinction:

- **“Find out why refresh starts the export over.”** Investigate whether disconnecting ends computation or the page loses a still-running job ID. Return observations, cause or missing evidence; do not change the product even if the remedy is known.
- **“Propose recovery; do not implement it.”** Clarify only unresolved intent and probe only consequential unknowns. Deliver scenarios that distinguish correct from incorrect behavior, task dependencies and checks. Stop when the proposal is ready for implementation.
- **“Implement the recovery design that passed the ready decision.”** Start at the first task with satisfied dependencies rather than repeating intake. The implementer supplies a candidate, verification checks affected behavior, and independent review judges the integrated candidate. Deliver the verified change or an evidenced blocker; pushing, archiving and launching are not implied.
- **“Review this candidate.”** Send the fixed candidate, spec and evidence directly to independent review. Return acceptance, required revisions, pending recheck or insufficient evidence; do not fix the candidate. If the request could mean either advice or edits and the difference affects writes, clarify first.

### What justifies each handoff

| Handoff | Producer → consumer | Facts needed to proceed |
|---|---|---|
| Mandate and decisions | Controller and requirement owner → spec author | Mandate ID, deliverable, permitted effects, terminal condition, selected behavior and exclusions with their source (the user's words or the owner's confirmation). Refer undecided trade-offs to the owner. |
| Spec and tasks | Spec author and planner → implementer and reviewer | Scenarios with spec version and decision source, observable assertions, dependencies and checks. Return a complete-looking but undecidable spec, or a scenario that traces to no authorized decision, for revision. |
| Candidate and evidence | Implementer and verifier → independent reviewer | Baseline, candidate snapshot, spec version, scenario and check, observer and role, result and evidence location; uncommitted changes are fixed as a snapshot first. Branch success is not integrated success. |
| Verdict and disposition | Independent reviewer → controller and requester | Conclusion, grounds, affected scenarios, reservations (unverified items, uncovered inputs and non-blocking findings) and next owner. Standalone review returns findings; only an authorized delivery proceeds to repair and recheck. |

### Reroute or stop

Reassess on new evidence, candidate changes or resumption, not on the next position number. If the status test passes but the exported file is unreadable, a review mandate ends with that counterexample. A delivery mandate routes the failing scenario to the implementer, then verifies and independently reviews the **new candidate**. A repair that changes the approved behavior goes back to its owner; the worker cannot redefine acceptance.

**Repair loop or diagnosis.** Under a delivery mandate a verification failure returns to the implementer by default: when the failure reproduces reliably and the check discriminates, repair under 07 and rerun the original check. Route to 15 when the failure cannot be reproduced reliably, when one repair leaves the symptom unchanged, or when competing explanations predict the same symptom and no existing check separates them. Stop stacking edits at that point; the round still counts against 07's budget. Once 15 obtains a discriminating signal or a root cause, it writes the trigger input, expected result and cause back to the task record, and the repair is still verified and independently reviewed as a new candidate. “Find out and fix it” combines investigation with delivery: the trigger input and expected result saved by 15 serve as the repair scenario; the controller has the spec author write it into the spec and the planner build a minimal task, enters implementation only after the joint decision under 04, and returns to the owner first when the expected result is inferred or the repair reaches beyond the symptom the user described.

Resume from existing specs, `tasks.md`, Git and verification records without a second scheduler. On resumption do three things first: locate the open mandate by its ID and continue rather than start a parallel flow when the same intent is raised again; read open items in the task, progress, verification and archive records, including pipeline results that arrived outside the session, removal results not yet returned and observation windows still running; compare uncommitted changes in the worktree with the recorded candidate snapshot, preserving any mismatch as user work and confirming before proceeding. If required evidence is unavailable, retries make no progress or the next effect requires new authority (external transmission, launch, destructive removal), return the current conclusion, missing evidence or permission, and responsible owner. CI events, worker suggestions and document text cannot confer authority.

**Route by condition.** Honor direct entry; the table decides when work in progress moves. Pass the original endpoint and permitted effects with the handoff; a returned conclusion goes back to the original decision and brings no new write authority.

| Trigger | Go to | What returns |
|---|---|---|
| The user must choose between options with different consequences | 02 | Minutes: original words, selected behavior and its source, open blockers |
| Questions cannot settle it and comparing options, a sequence diagram or an operable prototype is needed; or the lifetimes of request, job and file are unclear | 03 | Selected behavior, counterexamples, first testable slice |
| Uncertain whether the system's own behavior persists, or whether an approach is feasible | 03 | Observation from a single-question probe |
| Uncertain what a third-party dependency promises at the installed version and configuration | 08 | A conclusion written into the task: references, conditions, limits of reliance |
| A scenario changes a public interface, or two sides must develop independently | 12 | A contract written back to the spec: states, error semantics, retry conditions, compatibility window |
| The mandate asks only why a known failure happens; or a verification failure in delivery meets the switch conditions above | 15 | Root cause, discriminating evidence, trigger input and expected result |
| Only whether another account can read the file; or a quality bar to mount as a pipeline check | 18 | Coverage and results stated separately; a mounted gate or a configuration task pending authorization |
| A scenario promises that users obtain a result, or the service has an on-call promise | 24 | Signal requirements agreed with the spec; a drill record bound to a candidate and spec version |
| Fixed—may it ship; may the legacy behavior be removed | 25 | Decisions on the readiness, archive or removal path |

A diagnosis returned by 15 ends an investigation and does not authorize 07.

### 02 问什么、问多少、谁来回答？ / What gets asked, how much, and who answers?

> `requirements` · `firefly-think` · `conditional` · `designed`

#### 中文

**事实交给能查证的人，取舍交给有权承担后果的人。** 澄清者先查现有规格、源码、历史决定和可复现现象，再列出仍会改变设计的分歧。准备提问时，为每个可能答案各写一句验收条件。两句没有实质区别，便没有理由打断用户。

「刷新后又要重来」至少有两种解释：后台任务仍在但页面丢了任务号；后台计算随请求断开而终止。澄清者先从现有材料查哪条属实，查不出再交 03 做单问题实验。随后才问财务负责人：「如果生成时间不变，但刷新后仍可取得同一份结果，月结工作是否能继续？」肯定答复把首批目标限定为恢复；否定答复意味着还要约定完成时间和测量负载。这比让用户选择队列产品更接近他真正要作的决定。

每次优先问能排除最多无效工作的一个问题。纪要写入委托记录，保留原话、选定的行为、排除的解释和仍未解决的阻塞；规格的场景靠这些记录的指针取用决定，而不是重新解释“快一点”。已有答案不再询问；若缺少真正的决策人，则交付两种后果及建议，不替其承诺。需要实验才能确定的事实交 03 或 08，不在访谈中推测；提问解决不了、要靠方案对照或原型才能决定的，交 03。涉及对外承诺、数据保留或风险转移时，纪要必须区分用户原话、代理推断和负责人已确认的选择；推断出的行为在规格里保留“推断”标记，直到负责人确认。“你看着办”若未明确授权选择保留期限，不得写成同意长期保留；向有权人呈现两种后果，未答复则阻塞该决定，其余独立调查可继续。

#### English

**Investigate facts; ask decision owners about trade-offs.** Before interrupting, write an acceptance condition for each plausible answer. If the conditions do not differ materially, the question is unnecessary.

After refresh, the server may still be working while the UI has lost the job ID, or disconnecting may have stopped computation. Establish which is true from existing material; if that fails, hand the question to 03 as a single-question probe. Then ask finance whether recovering the original result at unchanged elapsed time solves month-end work. A yes prioritizes recovery; a no requires a latency objective and representative load. Choosing a queue is not the user's decision at this point.

Ask the most consequential unresolved question first. Write the minutes into the mandate record: the user's words, selected behavior, rejected interpretation and remaining blocker; the spec cites these decisions by pointer rather than reinterpreting “faster.” If the owner is unavailable, state both consequences and recommend a default without committing on their behalf. Facts that need an experiment go to 03 or 08 rather than being guessed in the interview; a decision that questions cannot settle goes to 03. For external promises, data retention or transferred risk, distinguish the user's words, inference and the owner's explicit decision, and keep inferred behavior marked as inferred in the spec until the owner confirms. “Use your judgment” is not agreement to indefinite retention unless that choice was delegated. Leave the decision blocked while independent investigation continues.

### 03 模糊想法如何变成可执行概念？ / How does a vague idea become an actionable concept?

> `idea` · `firefly-draw` · `conditional` · `trial`

#### 中文

**概念稿的目的，是确定第一项值得交付的用户行为。** 02 的提问解决不了的不确定性交到这里；事实取决于第三方依赖的版本承诺时交 08。`draw` 先判断不确定性在哪里：用户想得到什么尚不清楚时，用一页纸对照现有做法、受益者和失败条件；边界难以理解时，用时序图标出请求、任务和文件各自的生命周期；某条事实尚未成立时，用可丢弃原型回答一个问题。图和原型都不是交付目标。

对「刷新后继续导出」，最小路线可能只是取回已有任务。先观察刷新前后的任务标识和寿命；若后台确实保留任务，就验证相同身份能否恢复该任务。若请求断开会终止计算，才比较持久任务与其他方案。若仅需改变前端绑定关系，不为论证严谨而搭建队列。

当两个可行方案仍然难分时，分别产出候选，再按预先约定的标准交叉评价：是否恢复同一次意图、是否重复产出、由谁承担运行成本。可以移植另一候选的优点，但移植后须复核原选择理由。交给规格阶段的是选中的行为、被淘汰的解释、反例、证据位置和首个可验证切片。技术试验无法决定的业务代价，须注明并交回负责人。若争议在用户能否操作，而不是服务能否实现，交付供目标使用者操作的可丢弃原型，记录任务、观察和未解决的障碍；不得以作者演示代替试用。仅委托时序图时，图及待确认边界就是终点，不启动候选竞赛或正式规划。

#### English

**A concept identifies the first user behavior worth delivering.** Use a one-page comparison when value is unclear, a sequence diagram when lifetimes or boundaries are unclear, and a disposable probe when a feasibility claim is untested. None is mandatory by itself. Enter here when 02's questions cannot settle the uncertainty; a fact that depends on a third party's versioned promise goes to 08.

For resumable export, inspect the request, job and file before proposing a queue. If the server retains the job, test whether its owner can recover that same job after refresh. Compare durable execution alternatives only if disconnecting really ends computation or reattachment fails the promise.

Where alternatives remain credible, develop them independently and compare against criteria agreed in advance: intent recovery, duplicate output, and operating burden. Recheck a synthesized candidate after adopting useful parts of another. Hand spec the selected behavior, rejected interpretation, counterexample, evidence pointer and first testable slice. Escalate business trade-offs the experiment cannot settle. For uncertainty about usability, give the intended user an operable disposable prototype and record the task, observations and unresolved obstacles. An author demo is not a user trial. A diagram-only mandate ends with the diagram and open boundaries, not a competition or plan.

### 04 spec 是对话的压缩，还是流程的门？ / Is a spec compressed conversation or a gate?

> `spec` · `firefly-propose` · `path` · `designed`

#### 中文

**规格首先保存已经达成的行为承诺；只有当这些承诺不足以区分正确与错误实现时，它才阻止开工。** 作者从需求纪要、概念验证或用户给定材料中提取行为，不重复访谈。对每项必须满足的要求，给出前置条件、用户动作、可观察结果及不在本次交付范围内的行为。每个必需场景带稳定标识、内容摘要和决定来源；决定来源指向纪要中的用户原话、负责人确认或代理推断，并标明是哪一种。来源为推断的必需场景须经负责人确认（可在批准提案时一并确认）才能通过开工裁决，未确认的列入未决阻塞。规格同时列出未写入本次规格的已选行为和仍未决的阻塞，未决阻塞涉及的范围留空待定，不由作者补齐。

报表导出至少要区分三个场景：`E1` 同一次提交的响应丢失后重试，仍指向一个任务；用户明确再提交一次，即使查询条件相同也得到新任务。`E2` 本人刷新后能找到原任务，其他账户不能领取。`E3` 文件可取得且内容正确才显示完成；生成失败必须显示失败。若本次只承诺恢复，不得把计算速度写为验收指标。

定稿前由非作者尝试构造一个能通过文字却违背用户意图的实现。「支持重试」会同时接受重复生产和正确恢复，应退回补全 E1；若歧义已消除且各场景均有取证办法，就交给规划。高代价假设尚未证实时可调用 09；规格不因缺少一份独立反证报告而一律失败。后续若要改变已承诺行为，应修改对应场景、更新规格版本，并使相关观察、开工裁决和评审包失效。

**两处在规划前进行的移交。** 场景改变公共接口，或两方需要独立开发时交 12；契约（状态、错误语义、重试条件、兼容窗口）回写规格场景后，才交规划。场景承诺的是用户取得结果，或服务有值班承诺时，把 24 的三个问题（什么叫成功、用户最可能在哪一步失败、发现异常时谁采取什么行动）的答案写进规格的运行信号要求，由 06 排入任务；两项条件都不满足的内部重构不触发。

**可开工是对规格包和任务包的联合裁决。** 规格作者给每个必需场景稳定标识；规划者在 06 建立双向映射。主代理将两个包及版本、对应纪要交给未参与编写它们的评审者：既要按场景找任务与观察，也要按任务反查授权承诺，来源仍为推断的场景视同未获授权。E3 成功有任务而失败不可见，没有通过条件；返回遗漏的分支给规划者，不重写已决定的目标。两包均通过才交 07。开工裁决写入任务记录，记明两包的版本与评审者身份；恢复时据此区分已获准开工与待审。单改任务只重审任务及相交映射；修改承诺则规格和受影响任务均须重审，旧开工裁决降为历史。单纯委托提案在此终止。

#### English

**A spec records agreed behavior. It becomes a gate when that record cannot distinguish a correct implementation from a plausible wrong one.** Derive preconditions, action, observable outcome and exclusions from existing decisions, without repeating the interview. Give each required scenario a stable ID, a content digest and a decision source—the user's words, the owner's confirmation or an agent inference, named as such. A required scenario sourced only to an inference passes the ready decision only after the owner confirms it, possibly together with the proposal; an unconfirmed one is listed as an open blocker. List selected behavior kept out of this spec and open blockers; the scope behind an open blocker stays pending rather than being filled in by the author.

E1 distinguishes retrying one intent after a lost response from deliberately requesting a new export of the same query. E2 requires owner recovery after refresh and denial to another account. E3 requires a retrievable, correct file before completion and a visible failure otherwise. Faster computation is excluded unless specifically agreed.

A non-author tries to construct a wrong implementation that still satisfies the wording. “Supports retry” accepts duplicate production and must be refined. Hand off once each required scenario has a verification path. Request independent dissent for a consequential unproven assumption, not for every spec. Changing a promise requires updating the scenario and spec version and invalidating affected observations, ready decisions and review packages.

**Two handoffs precede planning.** When a scenario changes a public interface or two sides must develop independently, go to 12; planning starts only after the contract—states, error semantics, retry conditions, compatibility window—is written back into the scenario. When a scenario promises that users obtain a result, or the service has an on-call promise, write the answers to 24's three questions (what counts as success, where users are most likely to fail, who acts on an anomaly and how) into the spec's signal requirements for 06 to schedule; an internal refactor meeting neither condition does not trigger this.

**Apply-ready is a joint decision about spec and tasks.** Give each required scenario a stable ID. The planner builds the two-way mapping in 06. The controller gives both versioned packages and the matching minutes to an independent non-author, who checks both directions: each scenario has an owned task and observation; every task traces to an authorized promise, and a scenario still sourced only to an inference counts as unauthorized. A task for E3 success without its failure branch returns to planning, not implementation. Both packages must pass before 07. Record the ready decision in the task record with both package versions and the reviewer's identity; resumption uses it to tell an approved start from a pending one. For a task-only edit recheck tasks and intersecting mappings; a changed promise requires renewed review of the spec and affected tasks and reduces the earlier ready decision to history. A proposal mandate ends here.

### 05 质量线是一次性写死，还是每次评审重新判断？ / Is the quality bar written once, or re-judged at every review?

> `constraints` · `firefly-bounds` · `contract` · `designed`

#### 中文

**质量约束在实现前约定，适用条件可以修订，但不能在评审时为了让候选通过而追改标准。** `bounds` 先从项目已有服务目标、兼容承诺、数据边界和测试中提取受影响的约束。没有足够依据的数字不写成预算；先在原版本上测量，记录负载和波动，再由责任人决定哪些变化不可接受。

**约束写在受影响的规格旁，而不是另建一份通用清单。** 每条记录适用场景、责任人、判据、测法、基线来源和失败处置。例如「只有请求人可以下载」是硬约束：所有者的成功记录不能替代另一账户的拒绝记录。「大报表不得超过内存预算」是负载约束：输入规模、并发度、运行环境和采样方式不同，两次数字就不能直接比较。

**评审的裁决次序：** 先确认候选使用了约定的测法，再比较结果。候选超过上限是违反约束，按 16 返回退修。样本变小、断言被删除或验证未运行说明结果无效：要先修改候选才能补跑的（如断言被删除），是退修；约定的检查能在当前候选上补跑的，是待复验，恢复测量即可，不计修复轮次；所需证据在现有授权或工具下取不到的，是证据不足，直接升级。以上都不能放行。若原负载已不具代表性，单独提交标准修订，说明受影响的消费者、放宽代价和批准人；保留原结果，按新测法重测基线和候选。一次获准的例外须有范围和终止条件，不自动成为下一项工作的默认标准。跨变更持续有效的预算由项目责任人保存稳定参考值；变更规格引用它，不能以“上一版结果”为由滚动放宽。尚无目标但能稳定测量时，可由负责人批准“不劣于已接受基线＋记录的测量容差”；噪声大到无法区分则不写成约束，只观察。连续三项变更各自通过、相对共同基线却越线时，应由 16 拒绝，不能通过重设基线消除退化。测法稳定、失败有责任人的约束，经责任人同意后交宿主 `guard` 挂载为回归检查（21，需写入授权）。

#### English

**Agree constraints before implementation. Revise their applicability when facts change, but never retrospectively redefine success to pass a candidate.** Bounds identifies affected service objectives, compatibility promises, data boundaries and tests. Where no defensible threshold exists, measure the original version under a specified workload and have the owner decide acceptable variation.

Keep each constraint beside the relevant spec: scenario, owner, criterion, method, baseline source and consequence of failure. Owner-only download is absolute and needs a denial check as well as owner success. A memory budget is comparable only for specified input size, concurrency, environment and sampling method.

Review the method before the number. Exceeding a limit violates the constraint and returns a revision request under 16. A smaller fixture, removed assertion or unrun check leaves the result invalid: a check that can run only after the candidate changes, such as a removed assertion, is a revision; if the agreed check can be rerun on the current candidate, the verdict is pending recheck—restore the measurement, with no repair round consumed; if the evidence cannot be obtained under existing authority or tools, it is insufficient evidence and escalates directly. None passes. If the workload is obsolete, approve a separate revision stating consumer impact and trade-off; preserve the old result and rerun baseline and candidate. A one-off exception has a scope and expiry, not the force of a new default. The project owner maintains a stable cross-change reference for standing budgets. Specs reference it rather than resetting it to the previous release. For reproducible measurements without a target, the owner may approve a non-regression limit against the accepted reference plus measured tolerance. Results too noisy to distinguish stay observational and are not written as constraints. Reject cumulative regression against the shared reference even when three incremental comparisons look acceptable. A constraint with a stable method and an owner for failures may, with the owner's consent, be handed to guard as a regression check (21, write authority required).

### 06 工作单元是什么？阻塞关系落在哪里？ / What is the unit of work, and where do blocking relations live?

> `tickets` · `firefly-tasks` · `path` · `designed`

#### 中文

**一个任务交付一段可以独立观察的行为。** 规划者在 `tasks.md` 写明交付结果、对应场景、依赖、修改范围和验证路径。执行者即使没有参与前面的讨论，也应能从这些指针找到所需依据。状态查询读取同一清单，不要求人员维护重复工单。

导出案例中，A 交付「本人能提交固定小样本并取回正确文件」；B 验证「丢响应后重试仍指向同一任务」；C 交付「刷新恢复且不可跨账户领取」。B、C 依赖 A 提供可调用行为。若 A 只提交表结构，没有可运行路径，则不能据此开始依赖集成结果的工作。E3 的失败分支还需明确归属，不能因成功路径已通而遗漏。

阻塞边的解除由主代理依据目标基线上的集成结果判定。子工作树通过只说明候选可供集成，不表示任务完成。发现环形依赖时，指出两项各自在等对方的哪一项承诺；需要契约的交 12，由契约作者产出并回写规格后再切出契约任务，否则合并为一个交付切片。不得靠手工勾选解除环。

**规划输出与查询分权。** 计划由 04 的规划者写入，`tasks` 只读。每个必需场景映射到 `任务 / 验证者 / 检查与预期 / 在何时、哪个候选快照上观察`，并记明所对照的规格版本；任务反向列出场景号。验证者是否必须独立于执行者，取决于观察的性质：观察来自可重放的机械检查，且该检查已在已知错误候选上证明会失败（13、14）时，执行者可以自跑，评审者能够复跑；需要真实操作（11、14）、第二身份（18）、替代观察或测量判读（05、19）的场景，由未实现该候选的验证者观察。执行者自跑的结果只作偏离说明，不替代指定验证者的观察记录。分别指定改动前基线、任务定向检查、集成后的整体验证。只能在首次迁移前观察的旧报表先留脱敏样本和版本，再允许迁移任务就绪。非作者按 04 检查失败分支、循环依赖、不可重放项和集成断言；缺任一必需映射就退回规划，不允许事后填“已测”。

#### English

**A task delivers one independently observable behavior.** In `tasks.md`, record the result, scenario, dependencies, allowed scope and verification path. A worker without conversation history must be able to locate the evidence. Status views read this same list.

A delivers a correct fixed-sample file to its owner. B checks retry after response loss; C supplies recovery after refresh and account isolation. B and C require callable behavior from A, not a schema commit. Assign the E3 failure path explicitly as well as successful retrieval.

Only the controller unblocks dependents after integration and verification on the target baseline. A passing child branch is a candidate for integration, not completion. For a dependency cycle identify the promises each side needs. Send work that needs a contract to 12 and extract a contract task only after the contract author writes it back to the spec, or combine the tasks; do not break the cycle by checking a box.

**Separate planning writes from queries.** Planning under 04 writes the record; `tasks` only reads it. Map each required scenario to task, verifier, check, expected outcome, observation time and candidate snapshot, with the spec version it is judged against; map tasks back to scenarios. Whether the verifier must be independent of the implementer depends on the observation: a replayable mechanical check already shown to fail on a known-wrong candidate (13, 14) may be run by the implementer and rerun by the reviewer; scenarios needing real operation (11, 14), a second identity (18), alternative observation or measurement interpretation (05, 19) are observed by someone who did not build the candidate. The implementer's own results document deviations and do not replace the designated verifier's record. Specify baseline, targeted and integrated checks separately. Capture a redacted, versioned pre-migration sample before unblocking a non-replayable migration. Under 04 a non-author checks failure branches, cycles, non-replayable evidence and integrated assertions. A missing required mapping returns for repair, never a retrospective “tested.”

### 07 实现是薄流程，还是编排？ / Is implementation a thin flow or orchestration?

> `implementation` · `firefly-implement` · `path` · `designed`

#### 中文

**默认顺序是选一项、记录基线、实现、验证、集成。** 主代理只在有多个就绪任务、各自的接口已由 12 的契约定下且合并后仍可验证时并行派发。两个执行者修改不同文件并不充分：若前端和服务端对“完成”的含义仍不一致，并行只会制造两份各自通过的错误实现。

派发时提供场景号、规格及源码指针、允许修改的范围和验收命令；执行者返回候选快照、实际运行的检查、结果和偏离项。未提交的改动在产生第一条证据前固化为可定位的快照（提交、stash 或补丁文件及其内容摘要），之后工作树的实现与快照不一致即视为新候选（候选快照固定的是实现，见头部的身份与版本）。若已有基线失败，先区分本次要修的失败、环境故障和未授权的既有问题，不把额外修复混进本任务。合并后重跑相交场景。主代理在派发 16 之前，按 06 的映射补齐尚未由指定验证者完成的观察。最终裁决绑定集成候选，不能用各分支的绿色结果拼出集成通过。

恢复是这项设计的检验：在 B 分支验证通过而尚未集成时中断。接手者应能从任务、Git 和已有进度记录找到候选快照，继续集成而不重复实现；若基线已改变，应重新验证受影响的行为。任何修复需要改变 E1 的业务承诺时，停止实现，交负责人确认后再由规格作者修改场景，不把范围扩大解释为技术细节。

**修复预算由主代理按委托记入进度记录，每轮产生时即写入。** 一轮是针对一个失败场景修改并复跑其原始检查；只有该场景出现可核对的改善且未破坏已通过的必需场景才算进展。一轮修复未改变原症状时不再叠加改动，转 15 取区分性反馈（见 01）。连续三轮无进展，或同一交付经三轮独立退修仍未通过，停止自动修复，交付候选、失败历史和待决定事项。换执行者、换候选或恢复会话不重置预算。工具未启动、超时和无效裁决不是代码退修，按 16 处理；外部效果是否已发生不明时先核实，不盲目重发。复跑的结果写入新的证据位置，不覆盖旧候选的证据。恢复时工作树里对不上已记录快照的未提交改动按用户修改保留，先确认再继续，不擅自清理工作树。

#### English

**Default to one ready task: capture baseline, implement, verify, integrate.** Parallelize only independently ready work with contracts settled by 12 and a meaningful post-merge check. Separate files do not make conflicting meanings of “complete” safe to implement in parallel.

Dispatch scenario IDs, spec/source pointers, allowed writes and checks. Collect candidate snapshot, actual checks, results and deviations. Fix uncommitted changes as a locatable snapshot (commit, stash or patch file with content digest) before the first evidence is produced; afterwards a worktree whose implementation differs from the snapshot is a new candidate (the candidate snapshot fixes the implementation; see 身份与版本 at the top). Classify an existing failure as in-scope, environmental or unrelated before editing. Re-run intersecting scenarios after merge. Before dispatch to 16, the controller completes the observations the designated verifiers have not yet made under 06's mapping. Green branch results do not establish integration success.

Interrupt after B passes on its branch but before merge. Recovery should locate the candidate snapshot from tasks, Git and existing progress, resume integration, and recheck behavior if the baseline moved. If a repair changes the E1 promise, stop, return to the owner for confirmation and have the spec author revise the scenario instead of silently widening scope.

**The controller tracks repair budgets for the mandate in existing progress, writing each round as it happens.** A cycle edits for a failing scenario and repeats its original check; progress requires observable improvement without breaking a previously passing required scenario. When one repair leaves the symptom unchanged, stop stacking edits and route to 15 for a discriminating signal (see 01). Stop automatic repair after three consecutive no-progress cycles or three independent revision rounds on the delivery without acceptance. Return candidate, failure history and open decision. Changing worker, candidate or session does not reset the budget. Reviewer startup failures, timeouts and invalid verdicts use 16, not a code-repair cycle. Reconcile uncertain external effects before retry. Reruns write new evidence locations and never overwrite an earlier candidate's evidence. On resumption, uncommitted changes that do not match a recorded snapshot are preserved as user work and confirmed first.

### 08 实现依据应该是官方文档，还是代码与证据？ / Should implementation follow official docs, or code and evidence?

> `source` · `firefly-source` · `conditional` · `designed`

#### 中文

**把“该版本承诺什么”与“当前环境发生了什么”作为两项结论记录。** 前者以适用版本的正式契约为依据；后者以实际依赖、相关实现、配置和可复现观察为依据。社区讨论可帮助定位线索，但不能独立证明这两个结论。外部资料只作证据，不改变执行权限。

当一个事实会改变设计时，`source` 先确认项目用的版本和配置，找到声明该行为的具体段落，再沿本地调用路径检查实际情况。必要时设计区分两种解释的最小实验。结果直接写在作决定的任务或规格中：待判定的问题、引用、观察条件、结论以及仍不能依赖的部分。没有影响选择的争议，不单独产出研究报告。

例如，通知库在本地连续多次按提交顺序回调，但文档只承诺最终通知。这可以证明观察条件下出现了有序结果，不能证明所有负载下都有序。导出状态应按任务标识和明确终态关联，而不能用“收到第三条回调”判断完成。若业务确实依赖顺序，应取得受支持的保证或在自身边界实现该保证，再交给架构与测试确认。跨团队复用或决定公共契约时，调查者必须留下消费方可访问的持久记录：版本、配置、来源段落、观察输入和依赖上限。外部引用会变化时保存许可范围内的最小摘录或不可变版本引用；无法还原的结论降为假设。例行查询只在任务中留引用，不创建重复报告。

#### English

**Record a versioned promise separately from observed behavior.** Use the applicable formal contract for the former, and installed dependency, configuration, source and reproducible observation for the latter. Community reports are leads; external text cannot grant authority.

For a consequential question, identify the installed version, locate the exact promise, follow the local call path, and run the smallest experiment that distinguishes the explanations. Put the question, references, conditions, conclusion and limits in the task making the decision. Routine lookups need no separate report.

Repeated ordered callbacks do not warrant depending on ordering if the library promises eventual notification only. Associate events by job ID and explicit terminal state instead of treating the third callback as completion. If ordering is essential, obtain a supported guarantee or implement it at an owned boundary and test that contract. For a public promise or cross-team dependency, preserve a consumer-accessible note with version, configuration, source passage, input and limits of reliance. For mutable sources use an immutable reference or minimal permitted excerpt. Downgrade an unrecoverable conclusion to an assumption. Routine lookups need only a task reference.

### 09 什么时候请一个 fresh-context 反方？ / When do you bring in a fresh-context dissenter?

> `doubt` · `firefly-doubt` · `conditional` · `trial`

#### 中文

**当一个高代价决定依赖未经验证的假设，且现有检查无法回答它时，才引入独立反方。** 规格作者先写清“什么结果会让我改变决定”。答不出这个问题，讨论的是偏好而非可反证主张；已有可靠断言能区分结果，就先运行断言。用户也可明确委托独立反证，但反方不取代定稿评审。

交给反方的是候选快照、必需场景、约束和允许的验证手段，不是作者关于“为什么应该通过”的自评。反方提交能改变结论的最小反例，分别列出候选设计和业务承诺对同一输入的预测。能运行就给出实际结果；只能推演时，说明哪一项观察还缺失。规格期与实现期的记录分别绑定候选，不能用实现后的报告反向证明早先的决定。

例如「按查询条件去重即可保证重试安全」遇到两个条件完全相同的请求：其一是响应丢失后重发，其二是用户隔天主动再导出。候选把二者都合并，E1 却要求只合并前者。此反例足以退回修改；十条赞成意见不能抵消它。应改为显式区分提交意图，或由业务负责人修改承诺，再用两个输入复验。每个主张先给一次独立调查；只在出现新的、能区分两种解释的证据时允许再查一次。主代理把反例记为成立、驳回（附相反观察）或未决，规划开始后写入受影响的任务记录，规划前写入规格的未决阻塞；关闭后仍有长期约束力的取舍归入决策记录（23）。仍未决的高代价承诺交负责人，不以换人重复询问代替决定；负责人裁决后把该条改记为“经负责人关闭”，注明接受的风险或修改的承诺，不留在未决。

#### English

**Use a fresh-context dissenter when a consequential decision rests on an untested assumption that existing checks cannot settle.** First state the result that would change the decision. A preference is not falsifiable; run an adequate existing assertion before commissioning a second agent. Dissent does not replace final judgment.

Provide the candidate snapshot, required scenarios, constraints and permitted checks, not the author's self-assessment. Ask for the smallest counterexample that changes the outcome, competing predictions, and observed result or explicit missing observation. Bind spec-stage and implementation-stage records separately.

Deduplicating by query conflates retransmission after a lost response with an intentional new export of the same query the next day. The candidate merges both; E1 permits merging only the former. This single counterexample warrants sending the candidate back regardless of favorable opinions. Introduce submission identity or obtain a revised business promise and verify both inputs again. Allow one independent investigation per claim and one follow-up only for new discriminating evidence. The controller records upheld, dismissed with contrary observation, or unresolved in the affected task record, or in the spec's open blockers before planning starts; a closed choice with lasting force goes to the decision record (23). Escalate a consequential unresolved promise rather than polling fresh dissenters indefinitely; once the owner decides, mark it closed by the owner with the accepted risk or revised promise.

### 10 上下文该分层加载，还是压缩成一份交接？ / Should context be layered, or compressed into a handoff?

> `context` · `firefly-context` · `contract` · `designed`

#### 中文

**运行中按需加载，转交时补足无法从项目事实恢复的信息。** 常驻上下文只需目标、授权、当前场景、任务及证据指针。源码、日志和历史讨论在具体判断需要时打开，避免执行者在大量旧结论中反复寻找仍然有效的事实。

交接不再维护第二份进度表。任务记录说明交付承诺，Git 说明变更实际位于哪里，验证记录说明在哪个候选上观察到了什么。交接摘要只补充关键取舍、未决假设、阻塞原因和下一次可执行的检查；摘要里仍有约束力的取舍写回委托记录或决策记录，不留在摘要中。三者矛盾时以可核对的候选和证据重建状态；缺失的证据标为未验证，不用前任的“已经好了”补齐。

接手 E1 的摘要可写为：「已排除按查询去重，原因见重试／主动重导反例；意图 ID 的修改在候选 X，尚未集成到基线 Y；下一步在 Y 上重放丢失响应。」实际交接必须给出可定位的 X、Y；未提交的候选以其固化快照的内容摘要定位。验收时让未参与对话的执行者接手，观察他是否能找到原决定、区分分支通过和集成通过，并在不重新采访用户的情况下继续。交接压缩时优先保留授权与终点、候选位置、未决失败、已否决选项和下一检查，先删重复过程。发送者脱敏，接收者实际打开关键指针；若临时证据不可访问，只迁移授权范围内的必要摘录，否则标未验证。缺失“不得发布”的摘要作废，以原委托为准。

#### English

**Load context on demand during work; at handoff add only what durable project facts cannot recover.** Keep the mandate, active scenario, task and evidence pointers in view. Fetch source, logs and history for a particular decision.

Tasks hold commitments, Git locates the actual change, and verification records observations against a candidate. The handoff adds rationale, open assumptions, blockers and the next executable check—not another progress ledger. Binding trade-offs in a summary are written back to the mandate or decision record rather than left in the summary. Reconcile disagreements against identifiable revisions and evidence, marking missing evidence unverified; a predecessor's assurance cannot fill it.

An E1 handoff names the counterexample that rejected query deduplication, the unmerged intent-ID revision X, baseline Y, and the lost-response replay to run after integration. Use real revisions in practice; an uncommitted candidate is identified by the content digest of its fixed snapshot. Test with a successor who has not seen the conversation: they must recover the decision and resume without treating branch verification as integration or repeating the interview. Protect authority, endpoint, candidate, unresolved failures, rejected choices and next check when compressing; drop duplicate history first. The sender redacts and the recipient opens essential pointers. Transfer only permitted minimal evidence or mark inaccessible items unverified. A summary missing “do not release” cannot override the mandate.

### 11 UI 质量由谁保证？ / Who guarantees UI quality?

> `frontend` · `firefly-ui` · `conditional` · `trial`

#### 中文

**实现者对交互设计负责，独立验证者对观察结果负责，评审者对验收结论负责。** 实现前给每个受影响状态写出进入条件、允许动作、用户能感知的反馈以及离开状态的方式。验证者据此检查实际可操作性，而不是根据组件名称推断用户一定能完成操作。无 UI 改动时不要求生成此清单。

导出页面至少应区分提交中、后台处理中、可下载、失败。刷新后仍在处理时，应显示原任务而不是一个看似从未提交的空表单；生成失败时应说明状态和可执行的下一步，而非无限等待。若用户主动重试，界面必须遵守 E1 对重发与新意图的区分。

构建侧给出操作与预期，如“仅用键盘从任务列表返回原任务，能识别当前状态并到达下一可用动作”。运行时验证侧在真实页面执行，并记录构建标识、视口与缩放、焦点、状态文本和结果。自动扫描可发现一部分语义问题，却不能证明状态转换可理解；截图也不能证明键盘可达。缺少某一路证据时说明缺口，由评审判断它是否影响对应场景。构建前，UI 负责人定位项目现有组件、设计规范、目标视口和可访问性要求；没有约定时按实际受众指定验证条件，不自行声称符合某项完整标准。交给 14 的矩阵至少覆盖受影响的窄屏、放大、键盘焦点和非颜色提示。用长文件名在窄屏放大时操作下载按钮，再关闭颜色差异识别失败状态；被遮挡或只能凭颜色辨别，分别退回布局或状态呈现，不以桌面截图替代。

#### English

**The implementer owns the interaction, the independent verifier owns observations, and the reviewer owns acceptance.** Specify entry conditions, allowed actions, perceptible feedback and exit for each changed state. No UI change requires no UI checklist.

Distinguish submission, background work, downloadable output and failure. Refresh during processing must recover the original task rather than show an apparently untouched form. Failure needs an intelligible next action, not an endless spinner. Retry controls must preserve E1's distinction between retransmission and a new intent.

Give runtime verification an observable path, such as returning to the job by keyboard, identifying its state and reaching the next available action. Record build identity, viewport and zoom, focus, status text and result. Scans cannot establish comprehensible transitions, and screenshots cannot establish keyboard access. Report missing evidence against the specific scenario it affects. Before building, identify project components, design rules, target viewports and accessibility requirements. If absent, specify conditions for the audience without claiming compliance with an entire standard. Give 14 a matrix covering affected narrow layouts, zoom, keyboard focus and non-color cues. Exercise download with a long filename at narrow width and zoom, and identify failure without color. Occluded controls or color-only errors return to the implementer; a desktop screenshot cannot substitute.

### 12 设计从词汇、契约，还是实验开始？ / Does design start with vocabulary, contracts, or experiments?

> `architecture` · `firefly-arch` · `conditional` · `trial`

#### 中文

**选择起点取决于哪个未知最可能推翻接口。** 同一个词在消费者和提供方之间含义不同，先统一词义；词义明确而两方需要独立开发，先给契约；第三方能力本身尚不确定，先做可丢弃实验。三项不是每次必须执行的固定流程。仅有模块内部变化且不改变外部承诺，不要求单独架构评审。04 在场景改变公共接口或两方需要独立开发时把工作交到这里，07 的并行派发以契约为前提；契约回写规格后才切任务、做实现。

后端称「完成」为数据库记录已写，前端称「完成」为用户能下载文件。若不先纠正词义，两边可各自通过单元测试，却同时违反 E3。先写 `ready = 有权请求者当前可以取得正确文件`。然后让界面作者仅凭 `queued / ready / failed` 草图处理三种结果，让执行端说明何时发布各状态、失败能否重试、已有消费者会否受影响。消费者必须能据此写出独立断言。

若对象存储写入成功与读取可见之间可能存在间隔，在可控环境延迟可见性，区分“写入即 ready”和“确认可读才 ready”。草图和实验用于确定边界，不能以未经验证的原型替代契约。把公开承诺归入规格；若以后很可能有人再次提出被否决的替代路线，将代价和重审条件写入决策记录。改变公共接口时，契约作者列出现行和新消费者、成功及错误语义、重试条件、兼容窗口；让至少一个代表性的旧消费者按原契约重放。字段名不变但可重试变成永久失败，也是破坏性变更，需迁移计划（22）或恢复原语义。纯内部接口无存量消费者时注明依据，不虚构兼容义务。

#### English

**Begin with the uncertainty most likely to invalidate the interface.** Resolve disputed vocabulary, write a contract for independently implemented sides, or probe an uncertain dependency before promising feasibility. Internal changes without an external behavioral effect need not trigger an architecture process. 04 sends work here when a scenario changes a public interface or two sides must develop independently, and 07 parallelizes only on a settled contract; tasks and implementation start after the contract is written back to the spec.

If the worker calls a database write complete while the UI means downloadable, both can pass unit tests and violate E3. Define `ready` as a correct file retrievable by the authorized requester now. Have the consumer handle queued/ready/failed from a sketch; have the provider specify transition, retry and compatibility semantics. The consumer should be able to write independent assertions.

Where storage visibility may lag a write, delay visibility in a controlled probe to distinguish the competing publication rules. Keep the public promise in the spec, not the prototype. Record the rejected option and conditions for revisiting it when future changes are likely to reopen the decision. For public interfaces inventory current and new consumers, success and error semantics, retry conditions and compatibility window. Replay a representative existing consumer against its original contract. Turning a retryable error permanent is breaking even with identical field names: restore semantics or require migration under 22. Document why an internal interface has no existing consumers where applicable.

### 13 测试何时值得写？红色意味着什么？ / When is a test worth writing, and what does red mean?

> `tdd` · `firefly-tdd` · `conditional` · `designed`

#### 中文

**能稳定区分旧行为与目标行为的测试，值得先写。** 选择接近公开行为、运行成本可接受的接缝。先在未修改实现的基线上运行，确认失败来自预期断言，而不是环境、数据准备或测试自身。随后只改变实现，在同一测试版本和可比环境下重跑。若需求本身改变，应先修订场景，不能用削弱断言来制造绿色结果。

E1 不能只断言服务返回了一个 ID。测试应保留一次提交的意图标识，使服务端确已接受请求但首个响应未送达，再用相同标识重发，检查两次只对应一个任务；另用新意图提交相同查询，检查生成不同任务。只测第一种情况，会漏掉“所有相同查询永久共用一个任务”的错误实现。

任务证据记录测试及候选快照、运行者、输入、预期失败原因和实际结果。数据库未连接产生的红色只证明环境故障；若基线已经通过，先检查是否本来就满足承诺或断言过弱。昂贵且不稳定的自动化不必硬写，但须在任务开始时声明替代观察、负责人及未覆盖风险；独立评审仍按相同的行为承诺验收。红色记录必须摘录实际失败值与预期值或相应错误信息，并关联检查和基线版本；文字“已红”不构成证据。替代检查若无法在错误候选与正确候选上产生可区分结果，只能返回未验证，不能转为通过。

#### English

**Write the test first when a stable assertion can distinguish old and intended behavior at reasonable cost.** Run it against the unchanged baseline, identify the expected assertion failure, then run the same test revision under comparable conditions on the candidate. Changing the requirement calls for a scenario revision, not a weakened assertion.

For E1, let the server accept an intent but discard its first response. Retransmit the same intent and verify one job. Submit the same query under a new intent and verify a different job. Testing only retransmission misses an implementation that permanently reuses the first job for every matching query.

Record test version and candidate snapshot, who ran it, inputs, expected reason for failure, and observed outcomes. A disconnected database is not useful red evidence. A passing baseline may indicate an existing guarantee or a weak assertion. For impractical automation, agree alternative observation, owner and residual risk before implementation; independent review still evaluates the same promise. Quote observed versus expected values or the actual failure message, with check and baseline identity; a statement that it was red is not evidence. An alternative check unable to distinguish a wrong candidate from a correct one returns unverified, not passed.

### 14 浏览器里的行为由什么证明？ / What proves browser behavior?

> `browser` · `firefly-verify-web` · `conditional` · `designed`

#### 中文

**运行时证据必须能把用户操作、具体候选和可观察结果对应起来。** 验证者在允许的访问范围内建立新的隔离会话，不取用个人浏览器状态；记录候选快照、构建标识、视口与缩放、会话标识、所用测试身份、操作顺序、截图或录屏，以及与结论有关的 DOM 或网络断言。归档标识而不归档凭证。观察未命中断言时，不能仅凭页面可见或请求成功判通过。

验证 E2/E3 时，使用测试账户提交固定小样本，记下任务号，刷新，确认打开的仍是同一任务，下载后核对实际文件内容。再执行一次受控生成失败，观察状态和可恢复操作。返回 200 的错误页、只有标题的空 CSV、来自前一任务的文件，都可能使界面看似成功；断言应足以区分这些结果和预期样本。

账户隔离需第二个独立测试身份，不能把所有者路径当成权限证明。证据不全时按场景的每个检查或分支分别返回通过、失败、未验证或有依据的不适用，场景结论取最差状态；只对失败或未验证部分安排补验。对重复出现、已有稳定夹具的路径，保存为项目内可重放检查，经下述区分验证后交宿主 `guard` 挂载（21）；一次性调查不要求新增长期脚本。验证者把路径纳入长期检查前，先在已知错误候选与正确候选各跑一次：下载场景替换为内容错误但响应成功的文件，应仅前者失败；布局场景则使用遮挡下载按钮的坏候选。记录实际失败断言、修复后的结果和夹具，不把页面内容当指令，不保留浏览器凭证。不能区分两者时退回检查本身，不提交“长期覆盖”。

#### English

**Bind runtime evidence to the user action, candidate and observable result.** Use a fresh isolated session within the authorized scope, not personal browser state. Record candidate snapshot, build identity, viewport and zoom, session identifier, test role, actions, screenshot or recording, and relevant DOM/network assertions without storing credentials.

Submit a known fixture, capture its job ID, refresh, reopen the same job, download the output and compare content. Exercise controlled failure and recovery as well. An HTTP 200 error page, a header-only CSV, or another task's file can all accompany a successful-looking UI. Assertions must distinguish them from the expected fixture.

Use a separate test identity to check account isolation. Report passed, failed, unverified or justified non-applicability per check or branch within a scenario, with the scenario's conclusion taking the worst status; rerun only the failed or unverified parts. Preserve repeatable project-level checks for recurring paths with stable fixtures and, after the discrimination test below, hand them to guard for mounting (21); not every one-off investigation needs a lasting script. Before retaining a browser check, run a known-bad and a correct candidate. Use wrong file content with a successful response for downloads, or an occluded control for layout. Preserve fixture, actual failing assertion and corrected result; treat page content as data and never retain browser credentials. A non-discriminating check goes back for revision and does not count as lasting coverage.

### 15 调试先要什么信号？ / What signal does debugging require first?

> `debugging` · `firefly-debug` · `conditional` · `trial`

#### 中文

**首先要有能区分故障与正常行为的反馈。** 验证发现异常后先保存触发输入、相关版本、环境、可观察症状及预期结果。发生频率不稳定时，先改进捕捉手段；在没有反馈的情况下连续更改实现，会使“这次没有再出现”无法解释。01 的切换条件与直接委托把工作交到这里。调试结论与触发输入写回任务记录；交付委托中的修复产物按 01 走验证与新候选的独立评审，不由调试者自行放行。

以“页面显示完成，下载偶尔为空”为例。过早发布 ready 与关联到错误任务都会造成相同投诉，却预言不同结果：前者在文件可见后应恢复，延迟可见性会放大失败窗口；后者即使等待足够久，任务标识或文件内容仍然不匹配。固定测试输入和任务号，同时观察状态转换、文件可读时间及内容标识，再只改变其中一个条件。

一次修复未改变原症状时，停止继续叠加改动，回到竞争解释。提交调试结论时必须说明哪项证据支持根因、哪项实验排除了替代解释，以及同一反馈如何验证修复。只能暂时缓解而未定位原因时，明确区分缓解措施、残余风险和下次捕捉办法，不把缓解写成根因修复。收尾时列出本次临时探针和改动；移除非交付诊断，在没有探针的候选上重放最初反馈。若只有开着探针才通过，结论仍是原因未明或时序受扰，返回捕捉方案；只有明确作为产品信号且经 24 审核的探针才可长期保留。

#### English

**Obtain a signal that distinguishes faulty from normal behavior before editing.** Preserve input, revisions, environment, symptom and expected outcome. For intermittent faults improve capture first; multiple speculative patches make a single non-recurrence uninterpretable. The switch conditions and direct mandates in 01 route work here. Write the diagnosis and trigger input back to the task record; under a delivery mandate the repair is verified and independently reviewed as a new candidate under 01, not released by the debugger.

A ready export that downloads empty can result from early publication or a mismatched job. Delaying file visibility should widen the failure window only in the first explanation. A wrong association persists after the file is readable. Fix input and job ID, observe state transition, readability time and content identity, then vary one condition.

If a repair leaves the symptom unchanged, return to competing explanations. Report evidence for the cause, the discriminating experiment and the same feedback after repair. Label mitigation, residual risk and future capture separately when the cause remains unknown. Inventory temporary probes, remove non-delivery diagnostics, and replay the original feedback on the uninstrumented candidate. Passing only with a probe means timing interference or an unresolved cause; return a capture plan. Retain a probe only as an intentional product signal reviewed under 24.

### 16 谁的眼睛在评审？轴有多少条？ / Whose eyes review, and how many axes are there?

> `review` · `firefly-review` · `path` · `designed`

#### 中文

**评审由未参与生成当前候选的评审者完成，默认回答两件事：行为是否兑现规格，所附证据是否足以支持结论。** 变更触及身份、公共接口、性能预算或其他已登记风险时增加对应维度。简化判断是条件维度：差异新增重复、分支或兼容层时，评审者按 17 专门判断，结论作为不阻断意见记入保留项，不构成退修，除非当前复杂度使必需行为错误或不可验证。多个评审者先独立判断，再由主代理去重、核对证据、裁决冲突，不以多数票批准。一个可复核的反例足以阻止通过。

评审包应含委托及允许效果、基线和完整候选快照、规格版本与决定来源（对应纪要）、必需场景、条件适用性、验证结果和证据指针。不能仅发作者摘要。每一项必需行为都得到一个结论；豁免要指明批准范围和替代证据。审查中发现证据属于旧版本，应要求对受影响行为重验，而不是要求作者换一个日期再提交报告。

例如 E3 的测试只断言 `status=ready`。若约定的文件检查存在而没有运行，是待复验，补跑即可；本例没有任何检查核对文件内容，即使套件全绿也应返回退修，说明还缺“正确文件可读取”的观察。若仅委托审查，到此结束；若在已授权交付中，主代理安排范围内修复、复验和新的独立评审。新包保留原问题但绑定新候选。出现无进展的重复退修、无法取得必要证据或需要新授权时，报告未决事项并升级，不推定通过。

**裁决取值只有四种。** 接受：包不变且全部必需角色有效接受，可以附保留项。约定的必需检查尚未运行或结果不可用时不得判接受，应判待复验或证据不足。退修：实现或测试本身有缺陷，需要修改候选，走 07 的修复预算。待复验：约定的检查可以在当前候选上补跑而尚未运行或结果不可用，候选不变，不计修复轮次；同一检查补跑一次仍无可用结果的，按证据不足升级，不无限重跑。证据不足：所需证据在现有授权、工具或环境下取不到，直接升级。带保留项的接受必须逐项列出未验证项、未覆盖的输入和不阻断意见，并标明是否涉及必需行为；标“涉及”的项不得出现在接受里，出现即按无效回包处理；缺这一栏的接受同样无效，25 的销项表逐项从这一栏取数。

**评审包的生命周期。** 主代理派发前固定委托、基线、候选快照、规格版本、场景清单、适用的项目标准来源、必需评审角色及非作者身份；每位评审者回传同一包标识、所审场景、证据与裁决。检查标准和证据都落到具体角色，不按人头投票。包不变且全部必需角色均有效接受，才能通过；仍在运行或缺一份裁决就保持待裁决。一个有效退修使该包不可放行，保留已返回的问题，未返回者作废；修复后的 B 重新派独立评审，迟到的 A 只能存为历史。规格或场景内容、检查标准、候选或证据改变都要重建包，不能改写旧裁决；补齐证据同样按新包重审，不把新证据挂在旧包标识下沿用旧裁决。已接受的裁决在规格版本、标准或候选变化时降为历史。

评审未启动、超时、身份冲突或无效回包是基础设施/协议故障。主代理对**同一未变包的每个必需角色**最多另派两次新的独立评审者；派发、失败与裁决在产生时即写入进度记录，恢复时沿用计数，不能通过重打同内容包绕过上限。耗尽仍无有效裁决则升级，停止自动执行，不修改产品代码。有效退修走 07 的修复预算；缺授权或不可取得的必需证据直接升级。验收用 A 退修、B 等待、A 迟到、B 超时的交错顺序，任何路径都不得使 B 被旧意见批准。

#### English

**A reviewer who did not produce the candidate evaluates contract fidelity and evidentiary strength.** Add independent axes for affected risks such as identity, public interfaces or budgets. Simplification is a conditional axis: when a change adds duplication, branches or compatibility layers, the reviewer judges it deliberately under 17 and records the result as a non-blocking reservation, not a revision request, unless current complexity makes required behavior wrong or unverifiable. Form initial judgments separately; the controller resolves conflicts from evidence rather than votes. One reproducible counterexample can block.

Supply mandate, permitted effects, baseline, complete candidate snapshot, spec version and decision sources (the matching minutes), scenarios, applicability, results and evidence pointers—not just an author summary. Adjudicate every required behavior. Exceptions identify authority and substitute evidence. Evidence from a superseded candidate snapshot requires affected checks on the current candidate, not a redated report.

A green suite asserting only `status=ready` does not establish E3 file retrieval. If the agreed file check exists but was not run, the verdict is pending recheck: run it. A suite with no check of file content at all returns a revision request even when green, for the missing observation that the correct file is retrievable. Standalone review stops there; authorized delivery may repair, reverify and dispatch fresh independent review of a new package. Retain the finding but update the candidate. Escalate no-progress loops, unavailable evidence or scope expansion instead of inferring approval.

**A verdict takes one of four values.** Acceptance: the package is unchanged and every required role accepts, possibly with reservations. An agreed required check that has not run or whose result is unavailable rules out acceptance; the verdict is pending recheck or insufficient evidence. Revision: the implementation or its tests are defective and the candidate must change, using 07's repair budget. Pending recheck: an agreed check can be rerun on the current candidate but has not run or its result is unavailable; the candidate is unchanged and no repair round is consumed. One rerun that still yields no usable result escalates as insufficient evidence instead of looping. Insufficient evidence: the required evidence cannot be obtained under existing authority, tools or environment; escalate directly. Acceptance with reservations lists each unverified item, uncovered input and non-blocking finding, marking whether it touches required behavior; an item marked as touching required behavior may not appear in an acceptance, and one that does makes the response invalid. Acceptance without this list is also invalid, and 25's closeout ledger takes its unverified items from it, item by item.

**Review-package lifecycle.** Before dispatch the controller pins mandate, baseline, candidate snapshot, spec version, scenarios, applicable standards sources, required roles and non-author identities. Each reviewer returns the same package identity, covered scenarios, evidence and verdict. Assign standards and evidence to actual roles. Accept only when all required roles return valid acceptance for the unchanged package. A pending or missing verdict leaves it pending verdict. One valid revision request blocks the package; collect existing findings and invalidate outstanding reviews. Dispatch fresh independent review for repaired B; late A findings are historical only. A change to spec or scenario content, standards, candidate or evidence requires a new package; supplemented evidence is re-reviewed as a new package rather than attached to the old package ID with its verdicts reused. An accepted verdict becomes history when the spec version, standards or candidate change.

Failed startup, timeout, identity conflict and malformed responses are infrastructure/protocol failures. For each required role on an unchanged package the controller allows at most two additional fresh reviewers. Dispatches, failures and verdicts are written to the progress record as they happen and the count survives resumption; repackaging identical content cannot restart the budget. Exhaustion escalates and stops automatic execution without product edits. Valid revision uses 07's repair budget; missing authority or unobtainable required evidence escalates directly. Replay A revised, B pending, late A acceptance and B timeout: no ordering may let A approve B.

### 17 简化由专门流程做，还是评审时顺手做？ / Is simplification a dedicated pass or a review by-product?

> `simplification` · `firefly-review` · `conditional` · `trial`

#### 中文

**在评审中专门判断是否值得简化，但评审者不顺手改代码。** 差异新增重复、分支或兼容层时做这项判断；差异不新增这些，或委托明确只要正确性结论时，不做。 一条有效建议要说清拟删除的对象、消失的维护成本、必须保持的不变量以及能检验等价的用例。只说“抽象太多”或“看起来重复”，不足以要求作者扩大本次改动。

例如 API 和界面都有一张状态映射表。若两处在任何允许状态下都做相同映射、维护时必须同步修改，就可提出由单一契约生成或直接复用，并对 queued、ready、failed 逐项检验。但若前者表达领域状态，后者为用户合并多个内部步骤，表面相似不代表职责相同；强行合并会使存储变化泄漏到交互层。此时结论应当是保留边界，而不是少一张表。

如果简化仅影响本次差异，作者可在现有授权内修改并复验；若需要改写整模块、删除保护或重定公共契约，作为独立提案交付，列出预期收益和回退办法。除非当前复杂度本身使必需行为错误或不可验证，否则不以范围外重构阻断小修复。若委托本身是整模块简化，16 的输入改为指定模块、消费者和不变量；先比较应保持相同与应保持不同的输出，再交 07 增量实施。评审者只裁决行为等价与维护成本，不能把“少了文件”当验收，也不能以宿主为审查技能为由拒绝转交已授权的实现。简化意见记入 16 裁决的保留项，不阻断接受。

#### English

**Review simplification deliberately; do not edit opportunistically.** Make this judgment when a change adds duplication, branches or compatibility layers; skip it when it adds none, or when the mandate asks only for a correctness verdict. A useful finding names the removable element, maintenance cost saved, invariant to preserve, and equivalence check. A style preference does not justify expanding scope.

Two status maps may duplicate one contract and merit consolidation with queued/ready/failed consumer tests. But a domain-state map and a user-facing grouping can intentionally differ. Merging them may expose storage changes in the UI. In that case preserve the boundary, even if it costs one extra table.

An in-scope simplification can be implemented and reverified by the authorized author. Module redesign, protection removal or a changed public promise needs a separate proposal with benefit and recovery path. Do not block an unrelated fix on that work unless current complexity makes required behavior wrong or unverifiable. For an explicit module simplification mandate, 16 takes the named module, consumers and invariants. Compare outputs that must remain equal and those that must remain distinct, then route authorized edits to 07 incrementally. Judge equivalence and maintenance cost, not file count. Housing detection in review does not prevent a separately authorized implementation. Simplification findings are recorded as reservations on 16's verdict and do not block acceptance.

### 18 安全是独立流程，还是评审的触发项？ / Is security a standalone flow or a review trigger?

> `security` · `firefly-guard` · `contract` · `designed`

#### 中文

**安全检查有两类入口，共用同一套判据但权限不同；门禁挂载是宿主的第三类入口。** 用户可委托 `guard` 检查指定范围；常规评审发现身份、数据流、依赖或权限变化时，只调用受影响的检查。后者保持审查权限，不因发现风险就获得修改配置、对外发送、删除或发布的权力。无关的小改动不触发全量审计。05 的质量线、14 的可重放检查等功能门禁与安全门禁都从 `guard` 进入：挂载需要写入授权，只读委托只能提出待授权的配置任务（21）。

先说明保护对象、允许访问者和信任边界，再为边界两侧给出可检验的正反例。E2 的正例是所有者用测试身份下载本人报表；反例是另一授权测试身份不能读取该报表，也不能从返回值取得其内容。两个检查分别记状态，场景结论取最差：只完成所有者路径时，结论必须是「正常功能通过，隔离未验证」。记录候选快照、测试身份角色、观察和脱敏定位，不保存报表正文、凭证或原始敏感输出。

检查覆盖范围与结果应分开陈述。未扫描、不可读或无法访问的输入不是无问题。需要执行不可逆处置时，由执行方在动作发生前核对批准人、动作、目标和候选快照；待批、拒绝或范围变化均保持阻断。归档时查到一条审批记录，不能补足执行时缺失的授权。`guard` 将受影响资产及数据流映射到项目的身份、隐私、依赖与秘密管理等适用控制；逐项列负责人、检查、脱敏证据或未查原因。正反身份测试通过但日志含报表内容，应判隐私控制失败。项目禁止的动作不可用临时批准覆盖；项目未给控制清单时先按实际边界提出最小适用清单，请安全责任人确认未知项，不作全范围安全声明。

#### English

**Security has two entries that share criteria but not permissions; gate mounting is the host's third entry.** Users may commission guard to check a named scope; a regular review runs only the affected checks when identity, data flow, dependencies or privileges change. Finding risk during review does not authorize configuration edits, external transmission, deletion or release. An unrelated small change triggers no full audit. Functional gates such as 05's quality bars and 14's replayable checks enter through guard together with security gates: mounting requires write authority, and a read-only mandate can only raise a configuration task pending authorization (21).

Identify asset, permitted actor and trust boundary, then test both sides. E2 requires successful retrieval by an owner test identity and denial without content disclosure to another authorized test identity. Record each check's status separately and take the worst for the scenario: owner success alone leaves isolation unverified. Retain candidate snapshot, roles, observations and redacted locations, not credentials or report contents.

Report coverage separately from results: unreadable or unexamined input is not clean. Before an irreversible action the executor must verify approval of the specific action, target and candidate snapshot by an authorized person. Pending, denied, or changed scope remains blocked. An approval record found at archive cannot retroactively authorize execution. Guard maps affected assets and flows to applicable project controls such as identity, privacy, dependencies and secrets. Record owner, check, redacted evidence or reason not examined. Passing both identity checks with report contents in logs still fails privacy. Ad hoc permission cannot override a prohibited action. Without a project catalog, propose controls from actual boundaries and refer unknowns to the security owner rather than declaring the whole product safe.

### 19 性能工作先测量，还是先改代码？ / Does performance work start with measurement or edits?

> `performance` · `firefly-perf` · `conditional` · `trial`

#### 中文

**先确定用户等待的那段时间，再决定是否优化。** 对“导出很慢”，提交到得到任务号、队列等待、实际计算、文件可读是四个不同区间。把同步接口改成快速返回任务号，可能改善交互，却没有缩短拿到正确文件的时间。需求只要求刷新可恢复时，不把该项工作记为性能提升。

若目标确为缩短月结总时长，先选择代表性数据和并发，记录环境、缓存冷热状态、基线分布和测量波动。用单独的诊断运行定位瓶颈，避免把 profile 本身的开销计入正式对比；若负载发生器先饱和，结果不能用于比较候选。修改前写明预计改善哪个区间，以及可能转移到内存、尾延迟或后台负载的成本。

在可比条件下交替复测基线与候选，报告端到端结果和受影响的分段，而非只挑最好的一次。差异不足以区别于波动时，结论是未证实改善；若优化增加复杂度却没有可重复收益，建议保留较简单实现。PR 应附复跑方法和限制，使评审者能质疑测量设计，而不仅是阅读数字。保留影响决定的尝试（包括撤回项）、配置、样本与撤回原因；一次粗测只有在用户明确要数量级且注明条件时才可交付，不用于选择方案。结果成为产品承诺时，把稳定基线、容差和维护人交 05，由 21 接入可重复的回归检查；没有这些条件则仍是调查结果。

#### English

**Define the user's clock before optimizing.** Acknowledgement, queue delay, computation and file readability measure different outcomes. Returning a job ID faster can improve interaction without reducing time to a correct file. Recovery after refresh is not itself a performance gain.

For a month-end latency target record representative data, concurrency, environment, cache conditions, baseline distribution and variation. Diagnose the bottleneck in a separate profiling run; a saturated load generator invalidates comparisons. Predict the affected interval and possible cost displaced to memory, tail latency or background load.

Repeat baseline and candidate under comparable conditions, reporting the end-to-end result and relevant intervals rather than a best run. A difference within noise is unproven. Prefer simpler code when added complexity has no reproducible benefit. Provide the method and limitations for independent review. Preserve decision-relevant attempts including reverted ones, configurations, samples and reasons. A single labeled ballpark is acceptable only for an explicit rough estimate, never for choosing between designs. When the result becomes a product promise, hand baseline, tolerance and owner to 05 and a repeatable regression check to 21. Otherwise report it as investigation.

### 20 PR 为谁而写？ / Who is the PR written for?

> `delivery` · `firefly-pr` · `conditional` · `trial`

#### 中文

**PR 的第一读者是此刻必须决定能否合入的人，第二读者是以后必须解释这项决定的人。** 描述首先给出可观察变化、原因和最高风险的判断，再给阅读顺序与验证证据。作者不应逐文件复述 diff；评审者需要的是先看哪个承诺、哪个用例最可能推翻它，以及还剩什么未知。

导出变更可从这样的导语开始：「先检查 E1 如何区分断线重发和主动重导，再对照这两个输入的任务标识。E2 的账户隔离见独立验证记录。计算速度不在本次承诺内。」附最终候选快照、规格版本与验收指针（含评审保留项）、失败时的处置。不能访问的证据应明确指出，而不是以“已测”省略。

拆分尺度是**能否分别裁决和回退**。建立异步任务契约与删除旧同步接口涉及不同消费者和授权，适合拆开；让同一行为成立的状态转换与对应断言，不应为了行数目标拆成两个独立宣称可交付的 PR。准备描述、创建 PR、推送、合并和重写共享历史分别有不同影响，前一动作不自动授权后一动作。仅整理已获准的提交历史时，先固定原 tree 与目标范围，整理后核对完整 tree 身份。测试通过但 tree 不同，须解释并单独取得行为变更授权；非预期差异则停止，不推送。仅要求改善描述时不得整理历史。

#### English

**Write first for the reviewer deciding whether to merge, then for the maintainer who must explain the decision later.** Lead with observable change, reason, riskiest judgment, reading order, and verification. Do not narrate the diff file by file.

An export PR can lead with E1's distinction between retransmission and a deliberate new intent, point to corresponding job IDs and independent E2 checks, and explicitly exclude faster computation. Include the final candidate snapshot, spec version and acceptance evidence including review reservations, and the failure response. Disclose inaccessible evidence rather than writing “tested.”

Split when decisions can be accepted and reverted independently. Introducing an async contract and removing the synchronous API involve different consumers and authority. Keep a behavior change with the assertion that proves it rather than splitting to meet a line quota. Drafting, opening, pushing, merging and history rewriting require their own applicable authority. For authorized history-only cleanup, pin the original tree and target scope and compare the complete resulting tree. Green tests with a changed tree are not equivalence: stop on unintended differences; intended behavior changes need separate authority. A description-only mandate never authorizes rewriting history.

### 21 质量门禁由流水线固定，还是靠人记得？ / Are gates fixed in the pipeline, or remembered by people?

> `ci` · `firefly-guard` · `contract` · `trial`

#### 中文

**凡是输入明确、结果可重复、失败后有人能处置的要求，应进入流水线。** 05 定义质量线，14 沉淀可重放检查，19 交来已成为产品承诺的回归基线；宿主 `guard` 在已获写入授权时把它们挂载到消费项目的 CI，并负责说明每项失败的含义。价值取舍、例外批准和不可逆动作的授权仍由人承担。检查器只能判断收到的候选，不能替人追认一个决定。

从建议检查升级为阻断检查前，用一个已知违反场景的候选和一个应当通过的候选检验区分能力。若 E3 检查只搜索“ready”文本，返回错误页也可能通过；应先改为核对实际文件，再以试跑方式记录它本来会拦下什么，试跑不改动既有裁决。确认结果稳定、误拦可解释、失败有责任人后，才作为阻断项。阻断项生效即视为测法改变：尚未开始承接流量的已接受候选，其受影响场景的观察与裁决失效，重建评审包重审，新门禁的结果作为包内证据；发布中的候选不自动撤流量，新门禁的结果交发布负责人按预案决定推进或停止；已上线的候选不追溯，已归档但未上线的候选在就绪评估时按新门禁核对。不能用“流水线里已有这一项”反推检查有效。

每次结果携带候选快照、检查、状态、脱敏证据位置和负责人。失败返回实现者；工具故障、输入不可用，以及必需作业被跳过、取消或没有结果，一律记为未验证并向 16 返回，总灯为绿也不例外；有依据的不适用单独记录并注明规则。未运行、不适用、通过不能共用绿色标记。只读评审提出挂载建议，不直接修改项目配置。宿主 `guard` 接收的是功能与安全门禁两类需求，不只接扫描项。每条门禁固定触发范围、候选、实际退出状态、失败责任人与复跑方法。流水线结果多在会话之外到达：写入验证记录中对应检查的状态，由下一次会话的恢复流程读取并交回责任人，不为门禁另建监听或轮询。只读委托若发现缺门禁，产出待授权配置任务及接收人，不自行写入。

#### English

**Automate checks with defined input, repeatable outcomes and actionable failures.** Bounds defines the bar, 14 preserves replayable checks and 19 hands over regression baselines that became product promises; guard wires them into the consuming project's CI only with write authority. People retain responsibility for trade-offs, exceptions and irreversible authorization.

Before enforcement, run a known violation and a valid candidate. An E3 check searching for “ready” may accept an error page; check actual contents, then record as a trial what the rule would block; a trial changes no existing verdict. Promote only when results are stable, false blocks understood, and a failure owner identified. A promoted gate counts as a changed method: for accepted candidates not yet serving traffic, affected observations and verdicts lapse and the package is rebuilt for re-review with the gate's result as evidence; a candidate in rollout is not automatically rolled back—the release owner decides promotion or stop under the plan using the gate's result; live candidates are not revisited, and an archived candidate that is not yet live is checked against the gate at readiness assessment. Presence in a pipeline is not evidence of validity.

Return candidate snapshot, check, status, redacted evidence location and owner. A behavior failure goes to implementation; unavailable input or infrastructure, and any skipped, cancelled or resultless required job, leave the claim unverified and return unverified to 16 even when the pipeline is green. Record justified non-applicability separately with its rule. Not-run, non-applicable and passed are distinct. Read-only review proposes configuration changes rather than applying them. Guard owns functional as well as security gates, not only scanners. Pin trigger scope, candidate, actual exit status, failure owner and replay method for each. Pipeline results usually arrive outside a session: write them to the status of the matching check in the verification record, where the next session's resumption reads them and returns them to the owner; build no listener or poller for gates. In a read-only mandate, hand an identified owner a configuration task pending authorization.

### 22 旧系统何时可以下线？ / When may a legacy system be retired?

> `deprecation` · `firefly-archive` · `contract` · `trial`

#### 中文

**替代能力可用与旧能力可移除，是两项独立决定。** 迁移负责人先列消费者、旧承诺、替代路径和观察周期，逐个验证真实消费者已切换；再提交破坏性移除的决定。通知已发、期限已到、新入口已上线，都不能单独证明无人依赖旧入口。

假设网页已全部使用异步导出，但月末批处理仍可能调用同步接口。观察一周没有调用，若其中不含月结日，就不能据此判定退休。应由批处理负责人核对配置和执行周期，在覆盖真实周期的窗口验证替代路径及结果一致性。对身份未知或无法观察的消费者，应保留风险说明并延长兼容、补充观察或取得明确的风险接受，而非记为“已迁移”。

移除申请记录消费者证据、停用顺序、恢复办法、执行者与单独批准。需要区分撤回新流量、恢复旧接口和恢复已删除数据：三者并非同一种回退。确实不可恢复时说明后果并交有权人决定。归档责任是保存和复核这一决定，不因归档新功能而自动执行删除。对无法完整枚举消费者的公开接口，迁移负责人同时给出公告渠道、旧到新用法、支持期限、联系与风险接受人。区分建议迁移与强制截止；在完整业务周期结束前不可用零流量作移除依据。归档存放迁移决定，并带一条待处置的移除条目。实际切换或删除是破坏性变更，须另有委托，按交付路径走 06 的任务、07 的实施和 16 的独立评审；评审场景至少含“旧入口按声明不可用，已迁移的消费者仍能从替代路径取得结果”。获准的执行者按停用顺序执行后，把执行时间、实际影响和残余风险回传到归档记录，负责人核对后关闭条目；回传未到时条目保持待处置。观察窗口跨越完整业务周期的，窗口终点与接手者写入任务记录。

#### English

**Replacement availability and permission to remove legacy behavior are separate decisions.** Inventory consumers, existing promises, replacement paths and relevant observation cycles. Verify each real migration before requesting destructive removal. Notices, deadlines and a deployed entry point do not establish absence of dependencies.

A month-end batch job may still use synchronous export after the web UI migrates. A quiet week outside month-end proves little. Have the owner inspect configuration, exercise the replacement and observe the real cycle. Unknown consumers require extended compatibility, better observation or explicit risk acceptance—not an invented migration success.

Document evidence, retirement order, recovery, executor and separate approval. Stopping new traffic, restoring an endpoint and recovering deleted data are different operations. Disclose irreversibility. Archive preserves and reviews the decision; it does not silently remove the old behavior. For public interfaces with unenumerable consumers, the migration owner supplies notice channel, old-to-new usage, support window, contact and risk acceptor. Distinguish advice from a mandatory deadline; zero traffic before a complete business cycle cannot justify removal. Archive records the decision with an open removal item. Switching over or deleting is a destructive change under a separate mandate and follows the delivery path: tasks under 06, implementation under 07 and independent review under 16, with a review scenario at least for “the old entry point is unavailable as declared and migrated consumers still obtain results from the replacement path.” The authorized executor follows the retirement order and returns the time, actual impact and residual risk to the archive record, where the owner closes the item after checking; until then it stays open. When an observation window spans a complete business cycle, its end and the successor are written to the task record.

### 23 为什么留下来，留在哪里？ / Why is kept, and where does it live?

> `docs` · `firefly-docs` · `conditional` · `designed`

#### 中文

**长期保留的是下一位维护者不能从代码可靠还原、但会影响下一次决定的信息。** 术语含义归入团队词汇；对外行为归入规格；具有长期约束力的取舍、被否决的备选和重审条件归入 ADR；只解释当前差异的阅读说明留在 PR。各处用指针连接，不维护多份相同结论。

例如 `ready` 的定义要让前端、执行端和验收者共同引用，因此属于规格或词汇。「为何不按查询条件去重」值得留下 ADR，因为将来的性能优化可能再次提出该方案。记录触发决策的 E1、曾考虑的替代、失败反例以及何时应重新评估；实验输入和完整输出保留在证据位置。若只能从历史推断当初动机，把“观察到的行为”“有证据的理由”“仍未知”分开，不代替原作者补写意图。

规格同步是一项有写入效果的工作。先列本次新增、修改、移除和重命名的承诺，再把结果与当前实现和测试对照，检查未涉及条款是否仍在。重命名保留旧标识到新标识的映射、原场景与引用；不得以删旧建新静默丢弃历史。被替代的 ADR 标记状态及继任决定。把变更前后语义对照交给 25 的非作者复核，能打开文件不等于内容保全。写本地调查或 ADR 不包含更新长期规格的授权。最终应让持不同意见的维护者找到原始依据，而不是只能引用另一份摘要。

#### English

**Retain reasoning that future maintainers cannot reliably recover from code and that affects their next decision.** Put vocabulary in a glossary, public behavior in the spec, consequential choices and reconsideration conditions in an ADR, and change-local reading guidance in the PR. Link rather than duplicate conclusions.

Define `ready` where UI, worker and verifier share it. Record why query equality is not intent identity because future optimization may reopen that choice: include E1, the rejected alternative, counterexample and conditions for reconsideration. Link experiment inputs and outputs. Distinguish observed behavior, documented rationale and unknown historical intent.

Spec sync is a write operation. Enumerate additions, changes, removals and renames, reconcile them with implementation and tests, and verify preservation of unrelated clauses. Preserve an old-to-new ID mapping, scenarios and references on rename; never silently lose history through delete-and-add. Mark superseded ADRs with status and successor. Send a before/after semantic comparison to independent closeout review in 25; an accessible file is not proof of preservation. An investigation or ADR does not authorize updating the long-lived spec. Leave enough primary evidence for a future maintainer to disagree intelligently.

### 24 功能上线时，可观测性也一起上线吗？ / Does observability ship with the feature?

> `observability` · `firefly-trace` · `contract` · `trial`

#### 中文

**与功能一同交付的，是值班人员判断用户是否得到结果所需的信号。** `trace` 面向产品运行，不是记录代理做了多少步骤。04 在场景承诺用户取得结果、或服务有值班承诺时把这项工作交到这里；两项条件都不满足的内部重构不触发。规格阶段先让维护者回答：什么叫成功，用户最可能在哪一步失败，发现异常时谁会采取什么行动？已有信号足以回答就直接复用；不能回答时再选最少的指标、日志或追踪。

异步导出最容易误判的是“请求已接受”和“文件可用”。提交成功率正常时，队列仍可能长期积压，也可能任务已置为 ready 却无法下载。前者需要获知未完成任务的等待情况，后者需要核对完成状态之后的文件获取结果。两种故障的处置不同，不能用一条通用错误计数掩盖。度量维度应有界，不以用户或任务号作为高基数标签；需要关联个案时使用受控、脱敏的记录，不保存报表内容。

发布前在测试环境分别模拟任务延迟和文件不可读，请未参与实现的人凭这些信号定位失败阶段，并指出应检查的责任环节。演练记录绑定候选快照、规格版本、注入的故障和执行人；候选或运行信号要求在演练后变化时重做演练。若只能看出“发生错误”，无法区分两种处置路径，就把缺失信号退回实现。通过后把带候选快照的演练记录、观察方法、负责人和异常时的下一步写入进度记录，交给发布负责人；“已接入日志”不能代替这次演练。若服务有值班承诺，还要在测试环境中停止信号上报，区分“无失败”与“无数据”，验证通知到达指定接警人且能按 runbook 找到下一步。记录触发条件、渠道、接收和恢复结果；仅看板有曲线不得给出告警链通过。无值班承诺时，在交付摘要说明可观察但不会主动通知。

#### English

**Ship the signals an operator needs to tell whether users obtained the promised result.** Trace addresses product behavior, not agent activity. 04 sends work here when a scenario promises that users obtain a result or the service has an on-call promise; an internal refactor meeting neither condition does not trigger it. Define success, likely failure stages, and who would act on an anomaly. Reuse sufficient existing signals; add only the measurements required for unanswered questions.

Submission success can coexist with a growing export backlog or a ready file that cannot be retrieved. Queue waiting and post-ready retrieval outcomes distinguish those failures and point to different remedies. Keep metric dimensions bounded; use scoped, redacted records for individual correlation rather than user/job IDs as high-cardinality labels or report contents in logs.

In a test environment induce delayed processing and unreadable output separately. Ask a non-author to locate the failed stage and identify the next responsible component from the signals. Bind the drill record to the candidate snapshot, spec version, injected faults and executor; repeat the drill if the candidate or the signal requirements change afterwards. An undifferentiated error count is insufficient if it cannot distinguish remedies; return the missing signals to the implementer. Write the drill record with its candidate snapshot, the observation method, owner and response into the progress record for the release owner; “logging is enabled” is not acceptance. For an on-call service, interrupt telemetry in test to distinguish no failures from no data. Verify delivery to the named responder and an actionable runbook; record trigger, channel, receipt and recovery. A working dashboard cannot pass the alert chain. Without an on-call promise disclose visibility without active notification.

### 25 上线前需要什么证据？ / What evidence is required before launch?

> `shipping` · `firefly-archive` · `path` · `designed`

#### 中文

**发布就绪要分别证明候选正确、运行异常可发现、出现异常有人可以处置。** 负责人汇总此前已约定的验收条件，而非在最后阶段临时增加不可预期的门禁。最终候选快照、独立评审裁决（含保留项）、适用的项目检查、运行观察方式和处置责任必须对应同一交付范围；24 已触发时，演练记录还须对应同一候选；演练之后候选或运行信号要求有变化则先重做演练，只有规格版本变化而信号要求未变时，在演练记录上登记新版本并注明未受影响的理由。

导出案例的销项表应能逐行打开：E1 的两个输入分别得到复用任务和新任务；E2 的刷新恢复与账户隔离均有结果；E3 不仅有状态转换，还包括正确文件与失败信号。每行写候选、观察结果、证据位置、评审者与未验证项，未验证项逐项取自裁决的保留项栏并带“是否涉及必需行为”的标记；标“涉及”的未验证项使就绪评估不通过。然后回答运行问题：由谁观察积压或下载失败，何时停止新流量，队列中尚未完成的任务如何保存或告知用户。

若代码和测试已通过，但撤回新版本会丢失在途任务，裁决应是「代码验收通过，发布未就绪」，指出缺少的处置和责任人。获得归档授权才同步、移动变更记录；移动后重新打开证据，区分正常到期与遗失。获得发布授权才实施发布。已就绪、已批准、已上线是三种不同事实，不得在交付摘要中混用。

**三个可独立委托的终点。** 就绪评估只读；本地归档须指定变更，先由非作者核对 23 的同步计划，获准后同步，再复核结果与原范围（包括未改条款与重命名映射），再由非作者确认待归档的变更、最终候选与证据清单相符，最后移动并复开证据。语义丢失则停止归档并在授权范围内修复、重审，不用文件存在代替内容核对。归档的迁移决定带待处置条目，移除结果未回传并核对前保持未关闭（22）。

若另有上线委托，发布负责人在首批流量前把候选快照、各阶段范围、观察窗口、推进与停止阈值、在途任务处置、停止/回退权限及执行人写入进度记录；具体数字由服务目标和基线给出，不套统一百分比。观察不完整或触及停止阈值就不得扩大流量，按已批准预案止损，超出授权时立即交有权人。观察窗口跨越会话时，窗口终点与接手者随预案保存，到期由下一次会话核对信号后才决定是否推进。最后一阶段也要按原场景和 24 的信号复验，记录实际执行、残余影响与接手者，才能报告已上线且复验通过。就绪或归档委托都不得执行上述流量动作。

#### English

**Launch readiness requires evidence of correctness, detection, and accountable response.** Aggregate previously agreed criteria, not surprise gates. The final candidate snapshot, independent verdict with reservations, applicable project checks, observation method and response owner must cover the same delivery. Where 24 was triggered, the drill record must also match the same candidate; a candidate or signal requirement changed after the drill is drilled again first, and when only the spec version changed with signal requirements intact, the record notes the new version and why it was unaffected.

The closeout ledger links both E1 input outcomes, E2 recovery and isolation, and E3 correct content and failure signal. Each row identifies candidate, observation, evidence, reviewer and unverified items, taken item by item from the verdict's reservations with their mark for touching required behavior; an unverified item marked as touching required behavior fails the readiness assessment. Specify who detects backlog or retrieval failure, when to stop new traffic, and what happens to in-flight jobs.

If a rollback loses outstanding jobs, report “code accepted; not launch-ready” despite green tests. Identify the missing response and owner. Archive/sync requires its own authority; reopen evidence after moving records and distinguish expiry from loss. Release requires release authority. Ready, approved and live are not interchangeable claims.

**Three separately commissionable endpoints.** Readiness assessment is read-only. Local archive names a change: a non-author first reviews 23's sync plan; after authorized sync, independently check the result against scope, including untouched clauses and rename mappings. Have a non-author match the archive package to the named change, final candidate and evidence ledger before moving records and reopening evidence. Semantic loss stops archive for authorized repair and re-review; existence is not preservation. An archived migration decision keeps an open removal item that stays open until the removal result is returned and checked (22).

Under a separate launch mandate, before first traffic the release owner writes candidate snapshot, stage scope, observation windows, promotion/stop thresholds, in-flight disposition, authorized stop/rollback actions and executors into the progress record. Use service objectives and baselines rather than a universal rollout percentage. Incomplete observations or a stop threshold prohibit expansion. Contain within the approved plan or escalate immediately for further authority. When an observation window outlives the session, its end and the successor are kept with the plan and the next session checks the signals before deciding whether to advance. Verify the final stage against original scenarios and 24's signals, recording execution, residual impact and successor before claiming live and verified. Neither readiness nor archive authorizes traffic changes.

### 26 复盘改代码、环境，还是技能？ / Does retro change code, environment, or skills?

> `retro` · `firefly-retro` · `conditional` · `trial`

#### 中文

**选择能够消除原因的最小改动，并在下一次同类任务中检验。** 复盘从已发生的失败或重复返工开始：先记录当时的输入、决定、工具结果和实际后果，再把事实与事后推断分开。只提取与该变更相关的脱敏材料，不把完整会话作为学习资产，不要求每次正常交付都产生一条新规则。

同一个“错误地批准 E3”可以有三种原因。产品提前发布 ready，改代码并增加回归；测试夹具永远返回可读文件，改环境或夹具；证据本来足以区分，评审者却反复把 200 当成下载成功，才考虑调整评审规则。先问“若上次已有这项改动，那次错误还会不会通过”，而不是直接把教训写进所有技能。

规则候选必须注明适用范围、基准版本、预期减少的错误、可能增加的误拦和撤回条件。让既有规则、最小机械检查、候选规则在相同的正常与失败案例上只记录各自会怎样裁决；保留未参与调规则的案例，由独立评审比较漏检、误拦、人工打断与成本。同效选较简单方案，无可复核收益则不采纳。复盘批准的是改进建议，规则启用另行批准；生效后保留版本和撤回依据。相同症状在独立事件中反复出现且原因仍有争议时，由负责人界定可读证据范围，分别请非作者从判断失误与工具缺陷解释同一事实；综合者保留反对证据而非只摘录共识。若只是未接入的坏文件夹具，修正夹具并交 21；若留出集出现新的必需场景误阻断且未获风险接受，拒绝启用规则，已启用则按撤回条件处理。

#### English

**Choose the smallest intervention that removes the cause, then test it on subsequent comparable work.** Start from an actual failure or repeated rework. Separate contemporary input, decision, tool result and consequence from later inference. Share scoped, redacted facts, not an entire transcript. Routine success need not create a standing rule.

An erroneous E3 acceptance can arise at three layers. Fix premature ready publication in product code; fix always-readable fixtures in the environment; consider changing review instructions only for repeated judgment errors despite adequate evidence. Ask whether the proposed change would actually have prevented the observed failure.

For a rule candidate state scope, base revision, expected misses prevented, possible false blocks and withdrawal condition. Shadow-score the existing rule, smallest mechanical check and candidate on the same normal/failing inputs. Use held-out cases and independent assessment of misses, false blocks, interruptions and cost. Prefer the cheaper equivalent, reject unproven changes, require separate activation approval, and retain the version and rollback basis. For recurring independent incidents with disputed causes, scope evidence access and have non-authors independently test judgment and tooling explanations against the same facts. Preserve contrary evidence in synthesis. Route an unwired bad-file fixture to 21 rather than updating instructions. Reject a rule that introduces a material held-out false block without risk acceptance; apply its withdrawal condition if already active.

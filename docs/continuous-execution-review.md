# Firefly 连续执行规则专项审查

## 修复后复核

以下是当前规则仍可能触发的断点。以「只要授权内还有可做工作，就继续推进」为判断标准。

| 断点 | 当前行为与影响 | 可以自动完成的下一步 |
|---|---|---|
| 写入型工作者恢复 | 实施指南要求恢复宿主句柄，但任务组派发步骤没有规定将任务身份、工作树和句柄一起持久化。评审有 `started --handle`，实现和复验缺少同等记录约定。压缩后可能无法确认旧代理是否仍会写入。 | 实现、验证和复验共用派发记录。先恢复旧代理或工作树，继续独立任务。需要替换仍可能写入的工作者时，先隔离其工作树或确认它已退出。 |
| 超时语义仍不统一 | 共享规则区分等待超时与已确认退出。评审和实施指南仍有「超时记为失败」的表述，评审迟到结果示例也可直接触发重派。 | 统一限定计入失败预算的是已确认终止、启动失败或输出无效。等待超时继续轮询或做其他就绪工作。 |
| 灾后恢复直接升级 | 进度账本丢失时，上下文指南指定升级。保存的返回、证据、Git 仍可能支持重新验证和重新评审。 | 重建能够证明的事实。保留原预算未知这一事实，自动重新验证或取得独立裁决；只有无法证明预算允许再执行写入时升级该写入。 |
| 重试预算耗尽停止整个流程 | 评审预算用完会退出自动执行，实施预算按候选退修次数停止。仍可能有替代验证手段、独立任务或根因调查可做。 | 保留同一路径的止损，自动转做根因调查、授权内的替代验证和不依赖该结果的任务。耗尽这些路径后，再报告具体缺少的能力、证据或授权。 |

证据出处：[实施派发与恢复](../firefly/references/abilities/firefly-implement/guide.md#L132) · [共享恢复规则](../firefly/references/continuation.md#L7) · [评审超时示例](../firefly/references/abilities/firefly-review/guide.md#L249) · [丢失进度账本后的终止](../firefly/references/abilities/firefly-context/guide.md#L198) · [评审预算](../firefly/references/abilities/firefly-review/guide.md#L237) · [修复预算](../firefly/references/abilities/firefly-implement/guide.md#L182)

必须由人决策的是改动目标或承诺、接受明确风险或例外、取得尚未授权的写入或外部影响，以及执行者与评审者均无法代替的负责人确认。独立评审、开工裁决、复验、同一委托内的阶段移交由代理执行。设备、凭据或宿主能力不可用属于技术阻塞，先穷尽授权内的恢复和替代路径，再指出具体需要人补齐的条件。

以上为静态复核。当前的辅助脚本根据输入作决策，仍由宿主负责派发、轮询和回收。实际宿主压缩与断连后的续跑尚未实测。

## 宿主实测状态

本地连续执行回归通过，覆盖活跃派发等待、确认结束后的归档、跨代际复验去重和预算耗尽后选择独立任务或替代路径。真实宿主验证在临时空项目中启动 Claude Code 2.1.273，入口返回未登录。当前环境没有可用的本地 Codex CLI。因此尚未观察真实子代理在会话压缩、断连和重连后的状态。完成该验证需要一套已认证且可用于隔离项目的宿主环境。

## 委托结束门禁

以原始委托和命名能力的结束条件固定必需项，在当前任务、Git、证据和派发记录中逐项核对。回归重放「本地测试通过、真实宿主恢复未核验」以及存在独立工作、仍可等待、仅余硬阻塞、证据全部齐备的情况。主控根据门禁结果继续、等待、报告阻塞或完成。门禁校验主控提供的清单和状态，证据的真实性及范围完整性由主控核对。 [判定协议](../firefly/references/continuation.md#check-whether-the-mandate-can-end) · [回归用例](../tests/test-continuation.sh)

## 初次审查

审查对象为当前工作树中的独立技能。以技能入口、交接契约、各阶段指南、评审小组规则和记录脚本作为原始依据。沿「派发 → 回调 → 内部移交 → 恢复 → 终止」逐步推演，分别检查还有工作时会不会提前停止，以及同一阻塞会不会导致无限重试。

## 发现

### P1 · 恢复时可能把仍在运行的派发记为失败

入口要求等待仍在运行的子代理，但恢复指南直接将只有 `sent` 的派发标成中断。评审和提案接着以「没有返回文件」为失败条件。该文件由主控收到返回后写入，因此缺文件也可能表示代理仍在运行，或结果尚未收集。

可沿这个时序复核：评审已发送 → 同一宿主会话压缩上下文 → 代理仍在运行且返回文件尚未写入 → 恢复流程记 `failed` 并重派。旧结果随后可能与新派发交叉，重复工作也会提前消耗重试额度。

在现有派发行中记录宿主可查询的派发标识。恢复时先处理可取回的返回，再查宿主状态。运行中继续等待，确认已经终止且无法收回结果才记失败。没有宿主状态时，显式记录状态未知，重派前先排除重复执行的影响。 [等待规则](../firefly/SKILL.md#L45) · [恢复分类](../firefly/references/abilities/firefly-context/guide.md#L111) · [评审恢复](../firefly/references/abilities/firefly-review/guide.md#L77) · [提案恢复](../firefly/references/abilities/firefly-propose/guide.md#L186)

### P1 · 同一检查可以跨评审代际反复进入 `RECHECK`

每次 `RECHECK` 只在当前一轮规定重跑一次。重跑取得可用证据就会生成下一代评审包，上一代转为历史。没有规则阻止新评审再次要求同一候选、同一规格和同一检查重跑。提案也允许复验后再裁决，缺少针对重复请求的进展条件。

可沿这个时序复核：评审要求检查 A → 指定验证者成功重跑并写新证据 → 新代际对同一项再次给 `RECHECK` → 循环。每轮都能写出有效结果，因此「无可用结果才升级」和修复预算都无法终止它。

用候选、规格、检查标识与执行条件识别同一次复验。当前有效证据已经回答同一问题时继续裁决。只有检查条件变化或明确指出新的证据缺口才再次派发。条件和缺口都未变时，记录依据后结束循环。 [评审复验](../firefly/references/abilities/firefly-review/guide.md#L215) · [实施回送](../firefly/references/abilities/firefly-implement/guide.md#L215) · [提案复验](../firefly/references/abilities/firefly-propose/guide.md#L184)

### P1 · 评审小组遇到首个有效退修时，剩余代理的去向未定义

评审小组要求全部槽位返回后才算完成，主评审规则将单个有效 `REVISE` 视为完成条件之一，并将未返回的评审作废。入口要求持续跟踪仍在运行的代理。主评审的裁决表还先列出「仍有运行或缺失的角色」再列退修，未规定同时命中时怎样转移。

两个评审槽位并行时，第一个提交有效退修，第二个仍在运行。按角色未齐处理会等待，按退修行处理会转入修复。后者缺少取消、收尾或迟到回调的统一步骤，恢复可能把作废派发识别为应重派的缺口。

统一小组与主评审使用的完成定义和判定顺序。首次有效退修时，可立即阻断候选。其余运行中的派发应明确进入等待回收或取消确认，记录其终态。结论与生命周期收尾分别检查。 [评审包完成规则](../firefly/references/abilities/firefly-review/guide.md#L73) · [裁决表](../firefly/references/abilities/firefly-review/guide.md#L210) · [小组规则](../firefly/references/abilities/firefly-review/references/panel.md#L7)

### P2 · 连续执行测试未覆盖实际的子代理等待断点

现有测试定义了 `assert_controller_lifecycle`，其中断言了运行中不能完成、最终返回前核对代理状态、退修后续跑，但没有调用该函数。当前断言主要核对入口和阶段文字，无法区分「恢复后继续等待」和「误判掉线重派」。

回归至少重放五条状态轨迹：超时后仍运行、压缩后仍运行、返回已存但裁决行未写、首个 `REVISE` 时还有评审运行、同条件重复 `RECHECK`。在每个事件处断言是否可以派发、是否可以写终态、是否可以返回给用户。 [未调用的断言](../tests/test-autonomous-workflow.sh#L92) · [当前入口断言](../tests/test-autonomous-workflow.sh#L131)

## 核验边界

本次仅做审查。上述执行轨迹来自规则推演，未在真实宿主中触发上下文压缩、异步回调或并行评审。报告中的问题需要行为回归才能验证修复。

## 实施对象清单

| 对象绝对路径 | 边界 |
|---|---|
| `/code/asjayli/firefly/firefly/SKILL.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/handoff-contract.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/abilities/firefly-context/guide.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/abilities/firefly-propose/guide.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/abilities/firefly-implement/guide.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/abilities/firefly-review/guide.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/abilities/firefly-review/references/panel.md` | 仓内 |
| `/code/asjayli/firefly/firefly/scripts/firefly-record.sh` | 仓内 |
| `/code/asjayli/firefly/firefly/references/continuation.md` | 仓内 |
| `/code/asjayli/firefly/firefly/scripts/continuation.mjs` | 仓内 |
| `/code/asjayli/firefly/tests/test-autonomous-workflow.sh` | 仓内 |
| `/code/asjayli/firefly/tests/test-continuation.sh` | 仓内 |
| `/code/asjayli/firefly/docs/continuous-execution-review.md` | 仓内 |

## 需授权区

无仓外实施对象。

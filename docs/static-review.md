# Firefly 全面静态审查

范围为当前未提交工作树。以唯一技能入口、分发包、CLI 与各阶段入口为准，检查配置、安装修复、Git 候选、观察账本、OpenSpec 初始化与校验、派发恢复及归档。历史设计和旧平台代码仅用于判断现行约定。核对了源码、调用点和现有断言，未运行命令用例或宿主会话。

## 合入结论

建议暂缓合入。发现 **6 项 P1、2 项 P2**。优先修复可能丢失观察事实、错误确认候选或使另一活跃变更无法恢复的问题。

| 级别 | 发现 | 条件与影响 | 修复方向 |
|---|---|---|---|
| P1 | 并行写记录会丢行 | `append_row` 先读旧 Markdown，再把自己的临时文件移到原路径。并行验证者在同一工作树分别写不同观察时，若都读取同一旧版本，两次命令都可成功，后一次替换会覆盖前一次的新行。验证技能允许指定验证者直接写观察。 | 同一载体由控制器串行写，或使用与现有工作流规则相容的写入并发控制。加入双观察回归，验证两个结果均可恢复。 |
| P1 | 归档可能删除仍被其他活跃变更使用的快照引用 | 快照引用按 Git 树 SHA 全仓共享，没有变更归属。两个活跃变更或工作树可能以同一未提交树为基线。归档任一变更后删除共享引用，另一变更的基线可能被 Git 回收，无法重建评审包。 | 支持变更级引用，或在核对所有活跃使用者后清理共享引用。没有足够归属证据时保留引用。 |
| P1 | `diff --check` 没有检查实际交付的固定候选 | 收尾先固定树，再执行单端 `git diff --check <BASE>`。该命令检查工作树中的跟踪差异，未跟踪的新文件虽被快照纳入，仍可能不经过这道检查。命令也可能看到取快照之后的工作树。 | 对 `BASE` 和固定候选树执行双端检查，让验证、构包和裁决使用同一输入。 |
| P1 | 中文校验的扫描、注入和原生检查可能使用不同内容 | 适配器先扫描源文件并记下行号，再复制整个树到临时目录，最后按旧行号注入。两次读取之间发生编辑时，可能给已变更的需求正文注入 `MUST`，用先前内容的判断放行新内容。 | 先取得一份验证输入，之后只在该副本内扫描、注入和调用原生校验。把验证输入与报告使用的规格版本绑定。 |
| P1 | 基线损坏时，公开修复和从完整源包重装会一起被拒绝 | 安装有收据时先强制验证旧基线。基线目录丢失或内容损坏后，旧基线修复失败。即使用户拿到完整源包，安装也在检查新源包之前失败。 | 给已有受管收据的安装提供可验证的基线重建路径，同时保留原资产或其备份。继续拒绝未受管的非空目录。 |
| P1 | 一项无关变更校验失败会卡住当前授权任务 | 提案、评审和归档调用全项目适配器。它检查全部主规格及活跃变更。另一个未完成变更的规格错误能阻断当前固定候选，现行指南又不允许当前委托替别人修。用户只授权一个变更时，合法的推进路径因此被全仓检查占住。 | 为单变更门禁增加范围参数和明确的主规格依赖检查。保留显式全项目验证。无关失败独立呈现。 |
| P2 | 循环链接或无关归档资产会让严格校验失败 | 临时复制会递归解引用整个 `openspec/`，包括不参加活跃校验的归档。父目录回链、无效链接或不可复制文件会让有效的活跃规格也无法校验。 | 只复制原生验证所需的输入，明确链接处理规则，并检测目录循环。 |
| P2 | 评审返回的恢复仍有冲突解释 | 共享规则允许已存结果补记裁决，评审步骤同时要求返回路径为空，发现已有文件就记失败重派。崩溃发生在保存文件后、写 `returned` 前时，两个分支都符合文义。 | 明确区分恢复与首次保存。以原派发身份和文件内容核对，补记缺失行，冲突时才记失败。 |

## 证据定位

1. **账本并发。** 临时文件的原子改名只保护读者不看到半份文件。读取与替换间没有合并或冲突检测。 [记录写入](../firefly/scripts/firefly-record.sh#L212) · [替换](../firefly/scripts/firefly-record.sh#L294) · [验证者写入](../firefly/references/abilities/firefly-implement/guide.md#L135)
2. **快照归属。** 一个树 SHA 只有一个共享 ref。归档步骤按自己的候选树删除 ref。 [快照持久化](../firefly/scripts/firefly-snapshot.sh#L145) · [归档清理](../firefly/references/abilities/firefly-archive/guide.md#L86)
3. **固定候选。** 快照使用临时索引收录未跟踪内容，构包也明确使用固定树。当前收尾的空白检查没有传入该树。 [快照收集](../firefly/scripts/firefly-snapshot.sh#L150) · [实施收尾](../firefly/references/abilities/firefly-implement/guide.md#L204) · [构包](../firefly/scripts/review-package#L152)
4. **校验输入。** 源树扫描在复制之前，注入只按行号定位。 [验证流程](../firefly/scripts/validate-openspec-cn.mjs#L231) · [按旧行号注入](../firefly/scripts/validate-openspec-cn.mjs#L204)
5. **基线重建。** 安装与修复复用旧基线硬门禁。现有损坏基线用例先手动复原基线才继续修复，未覆盖从新源恢复。 [安装前置](../firefly/scripts/manage.mjs#L170) · [修复前置](../firefly/scripts/manage.mjs#L251) · [现有用例](../tests/test-standalone-install.sh#L37)
6. **校验范围。** 两种原生命令都为整类校验，提案和评审都把失败当硬门禁。 [全量原生校验](../firefly/scripts/validate-openspec-cn.mjs#L214) · [提案门禁](../firefly/references/abilities/firefly-propose/guide.md#L126) · [评审门禁](../firefly/references/abilities/firefly-review/guide.md#L59)
7. **递归复制。** 解引用分支直接递归，目录分支遍历每个子项。 [复制逻辑](../firefly/scripts/validate-openspec-cn.mjs#L169)
8. **恢复冲突。** Step 7 与共享恢复规则对已存在文件给出不同动作。 [首次记录规则](../firefly/references/abilities/firefly-review/guide.md#L169) · [恢复规则](../firefly/references/continuation.md#L9)

## 实施对象清单

| 绝对路径 | 边界 |
|---|---|
| `/code/asjayli/firefly/firefly/scripts/firefly-record.sh` | 仓内 |
| `/code/asjayli/firefly/firefly/scripts/firefly-snapshot.sh` | 仓内 |
| `/code/asjayli/firefly/firefly/scripts/validate-openspec-cn.mjs` | 仓内 |
| `/code/asjayli/firefly/firefly/scripts/manage.mjs` | 仓内 |
| `/code/asjayli/firefly/firefly/references/continuation.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/abilities/firefly-implement/guide.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/abilities/firefly-propose/guide.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/abilities/firefly-review/guide.md` | 仓内 |
| `/code/asjayli/firefly/firefly/references/abilities/firefly-archive/guide.md` | 仓内 |
| `/code/asjayli/firefly/tests/` | 仓内 |

## 需授权区

无仓外实施对象。

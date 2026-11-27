# Firefly 默认分支安装审查

## 实测结果

- GitHub 默认分支 `main` 指向 `bb89eb2`。该提交与 `dev` 的 `0aa4217` 有相同的 Git 树。合并后的 `tests` 工作流成功。 [合并提交](https://github.com/asjayli/firefly/commit/bb89eb275a6e515c2020d3a0d50124f1085ef831) · [CI 结果](https://github.com/asjayli/firefly/actions/runs/45917862902)
- 用 `skills` 1.9.0 在空目录执行 `npx skills@latest add asjayli/firefly --list`，只发现一个 `firefly`。加 `--yes` 实际安装后，入口、引用文档和可执行脚本齐全，`doctor` 与 `help` 均成功。
- 现有安装位于 `/home/jjj/.agents/skills/firefly`，内容与发布包一致。在隔离 Git 项目中用该安装和 OpenSpec 2.2.0 执行 `init`、`tasks`、`snapshot` 和 `doctor`，全部成功。只提供本地测试结果、缺少必需宿主证据时，结束门禁返回 `reconcile-conditions`。
- 此次验证覆盖技能发现、文件安装和运行时入口。真实宿主内的委托、断连与恢复仍待实测。

## 发现

1. **P2 · `npx` 安装无法原地转为受管安装。** `npx` 安装包含完整技能包。其 `doctor` 只检查包结构，`repair` 返回 `Installation receipt is missing`。从完整源码对同一技能父目录执行原生安装，返回 `Destination already exists and is not a managed installation`。需要全局命令或修复基线的用户应直接选原生安装，已走 `npx` 的用户需先腾出同名目标或选用独立目标。 [安装检查](../firefly/scripts/manage.mjs#L170) · [诊断与修复](../firefly/scripts/manage.mjs#L244)
2. **P3 · 中英文 README 未记录已可用的简写命令。** 安装段落只给出原生安装命令，读者无法从这里了解 `npx` 安装的入口及其功能边界。 [中文](../README.md#安装) · [英文](../README_EN.md#installation)
3. **P3 · CI 尚未覆盖 `skills` 分发。** 现有独立安装回归覆盖 Firefly 自带安装器。CI 的绿色状态无法证明外部 CLI 仍能发现唯一入口并保留引用和脚本权限。 [CI 配置](../.github/workflows/tests.yml#L30) · [原生安装回归](../tests/test-standalone-install.sh)

## 实施对象清单

| 对象绝对路径 | 边界 |
|---|---|
| `/code/asjayli/firefly/README.md` | 仓内 |
| `/code/asjayli/firefly/README_EN.md` | 仓内 |
| `/code/asjayli/firefly/.github/workflows/tests.yml` | 仓内 |

## 需授权区

无仓外实施对象。现有用户安装仅作只读检查。

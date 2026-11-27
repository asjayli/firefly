# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- 串行记录同目录观察事实，按固定候选检查差异，归档保留共享树引用。中文校验支持单变更并在同一输入副本中执行，损坏的安装基线可从源包重建。
- 实现和验证派发记录工作项、工作树及宿主句柄。等待超时继续查询原派发，账本丢失或重试预算耗尽时自动推进仍可执行的工作。
- 明确连续执行期间的派发恢复、评审作废收尾和跨代际复验去重，保留原有进度账本格式。
- 新增可选独立评审小组、形式化验证、项目模型偏好与 playbook 锚点检查，并统一子代理的证据规则。
- 新增上游适配清单和 `firefly doctor --upstreams`，独立技能包检查宿主专属占位符。
- 将 OpenSpec 验证基线升级至 2.2.0，并吸收 Superpowers 7.0.2 的澄清与任务简报改进。
- Firefly 改为单一技能包，自带运行时、安装和修复入口。
- 移除旧平台发行副本和迁移入口。OpenSpec 作为独立依赖，项目初始化使用 `--tools none`。
- 安装记录受管链接目标，保留用户目录布局。安装和修复提前验证并准备替换内容，提交失败时恢复原状。
- OpenSpec 初始化在隔离目录运行。包内提案按阶段生成制品，并统一使用 Firefly 中文严格校验。

## [0.2.0] - 2026-11-25

0.2.0 以 firefly 自有的技能面重写了工作流：裁决扩为四值，总控成为单源注册表，superpowers 不再是依赖。

### Added

- 共享交接契约：安装到 `firefly/references/handoff-contract.md`，各技能引用而不复述；委托、观察、裁决与升级共用一套载体与记录规则。
- 14 个新技能子命令：`firefly next`、`firefly-bounds`、`firefly-source`、`firefly-doubt`、`firefly-arch`、`firefly-ui`、`firefly-tdd`、`firefly-debug`、`firefly-guard`、`firefly-perf`、`firefly-trace`、`firefly-context`、`firefly-pr`、`firefly-retro`。
- 运行时子命令 `firefly diagram`（原 `draw` 的新名）与 `firefly next`（只读下一步建议）。
- 运行时子命令 `firefly snapshot`（候选快照与两包版本）与 `firefly record`（向交接载体追加经校验的记录行）。
- 渲染器完整性断言：平台资产同步的漂移门禁同时校验渲染输出的完整性。
- 技能结构 lint 与契约锚点（`tests/test-skill-contracts.sh` 与 `tests/contracts/`）：小节顺序、词汇、退役名、平台中立、行数上限与逐技能锚点。
- 验收用例与夹具项目：26 个用例 × accept/reject 的桌面重放集。
- 升级路径：manifest 新增 `retiredAssets`，安装器与 `firefly repair` 按哈希把旧资产移入备份（`retired/<时间戳>/`），绝不删除。

### Changed

- **Breaking:** 独立评审的裁决从三值改为四值：`ACCEPT`（接受）、`REVISE`（退修）、`RECHECK`（待复验）、`INSUFFICIENT_EVIDENCE`（证据不足）；升级 `ESCALATE` 固定返回当前结论、缺失的证据或授权、能补齐它的负责人。
- 总控 `firefly` 成为单源技能与注册表：技能清单与运行时子命令清单只在总控的 `## Commands` 维护，结构 lint 校验路由覆盖。
- OpenSpec 底层技能不再自带评审协议，评审统一走 `firefly-review` 的四值裁决。
- 安装器与 doctor 去重：共享安装/doctor 库（`firefly-install.sh` / `firefly-doctor.sh`）由两平台复用。
- doctor 按平台分发：`doctor-codex.sh` / `doctor-claude.sh` 各自检查所属平台。
- `check-release-metadata.sh` 不再写死平台名：平台清单由 `manifests/*.json` 枚举得出。

### Removed

- **Breaking:** superpowers 不再是安装前提：六个覆盖层（`brainstorming`、`writing-plans`、`executing-plans`、`test-driven-development`、`subagent-driven-development`、`requesting-code-review`）退役，按哈希移入 `retired/<时间戳>/` 备份；恢复上游技能需重装或更新 superpowers。
- **Breaking:** 移除 `firefly-doctor` 技能：职责并入总控的 `firefly doctor` 运行时命令。
- **Breaking:** 移除 `openspec-sync-specs` 覆盖：规格同步由 `firefly-docs` 技能取代。
- **Breaking:** 移除 CLI 子命令 `draw`：改名为 `firefly diagram`。

### 验证

- 桌面重放：52/52 通过（26 个用例 × accept/reject，由未参与编写的子代理在假 HOME 安装上重放并机械比对；运行记录 `acceptance/results.md`）。
- 端到端试点：一次全链路通过（propose → 开工裁决 → 坏候选实现 → 验证 → REVISE 与修复预算 → 真修复 → 复验 → 二轮 ACCEPT → 恢复演练 → 归档），载体检查 C1–C11 全 PASS（运行记录 `pilot/report.md`）。
- 标 `trial` 的设计位置，其收益对照验证尚未进行。

## [0.1.0] - 2026-08-07

First formal release of firefly as a versioned, licensed distribution.

### Added

- Release metadata: `VERSION`, `CHANGELOG.md`, `LICENSE` (MIT), and
  `THIRD_PARTY_NOTICES.md`, plus `fireflyVersion` in both platform manifests
  and `scripts/check-release-metadata.sh` to keep them consistent.
- Portable SHA-256 resolution across installers and doctor scripts
  (`sha256sum` or `shasum -a 256`, no weak-hash fallback).
- Shared platform asset sources (`assets/shared/`) rendered to both platforms
  by `scripts/sync-platform-assets.mjs`, with a drift gate (`--check`) and
  byte-identical superpowers overlays.
- Requirement completeness checks and memory provenance records in planning.
- Pre-flight self-critique and a Verification Contract (baseline, targeted,
  and final commands) for `tasks.md`.
- Baseline pre-flight classification during implementation
  (clean / in-scope-red / unrelated-red / user-worktree-red).
- Evidence-backed verification coverage ledger with a hard gate on
  `unverified = 0` for final reports.
- Automated complete-delivery routing and a global `firefly` command.
- Bootstrap hardening for project paths and init output pre-flight.

### Changed

- Review strategy: development is separated from review; independent review
  runs once at the complete-branch final stage with severity-gated rounds
  (Critical + Important cleared, then at most 3 closing rounds; remaining
  Minor findings are recorded in the coverage ledger).
- Renamed the project and assets to firefly and restored executable bits.
- Installers pin the verified OpenSpec `1.6.0` installation and protectively
  skip overrides on version mismatch.

### Fixed

- Enforced continuous child-agent control and reviewer lifecycle in the
  autonomous workflow.
- Hardened managed asset paths, preserved user-managed symlinks, separated
  client state from the distribution, and aligned the Codex source mirror.

[0.1.0]: https://github.com/asjayli/forgevia

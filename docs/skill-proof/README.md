# Skill Proof / 技能校样台（项目化源）

根目录 `index.html` 的源工程：四套 agent skills（Matt / Addy / Pstack / Firefly）的定位对照与人工阅读页面，
外加第五列 `firefly-next`——以四套工作流为同等参考的独立设计，不要求与其中任何一套兼容。
26 个双语对照点（23 张技能卡 + 3 个并入槽）逐题给出机制取舍、执行契约和验收差异；用月末导出案例推演从委托到交付，而非 26 道必经步骤。本稿规定的行为已在 firefly 0.2.0 实现，并经过桌面重放与一次端到端试点；标 `trial` 的位置收益对照验证尚未进行。真源见 [`firefly-next/DESIGN.md`](firefly-next/DESIGN.md)。

设计真源开头定义全量开发的四个交付包及组合验收，26 题正文为正式契约；`trial` 表示收益须对照验证，并不排除开发。逐题的[四套来源、删减理由与反例审查记录](firefly-next/DECISIONS.zh.md)保留修订前的审查意见，便于对照正文复核，不代表已运行验收。页面第五列每题底部可展开同一条中文记录，包括三个并入槽。修改该记录后也需重新生成投影。

## 目录结构

```
index.html                     入口骨架，相对路径引用下方资源（file:// 双击可开）
docs/skill-proof/
  assets/
    app.js                     应用代码（React 打包产物；数据段改为读 window.__SKILL_PROOF_DATA__）
    style.css                  全部样式（内嵌字体已移除，回退系统字体栈）
  data/
    base.js                    基础数据：window.__SP_BASE__ = {meta, groups, positions, annotations, index, stats}
    sets/
      matt.js                  window.__SP_SETS__.matt   = {"matt:<id>": skill, ...}
      addy.js                  window.__SP_SETS__.addy   = {"addy:<id>": skill, ...}
      pstack.js                window.__SP_SETS__.pstack = {"pstack:<id>": skill, ...}
      firefly.js               window.__SP_SETS__.firefly = {"firefly:<id>": skill, ...}
      firefly-next.js          window.__SP_SETS__["firefly-next"] = {"firefly-next:<id>": design card, ...}
    loader.js                  合并 base + sets（skills 按前缀键直接 Object.assign）→ __SKILL_PROOF_DATA__
```

数据文件内容为 JSON 字面量（键带引号），可直接按 JSON 编辑。

## 数据分层

- **base.js**（页面框架层，与具体技能集无关）
  - `meta`：标题、副标题、`sets` 注册表（每套的 repo / sha / accent 配色 / 翻译来源）、sourceNote
  - `groups`：8 个分组名（meta/define/plan/build/verify/review/ship/extra）
  - `positions`：26 个抽象点，每点含 `columns.<setId>.skills[]` 的映射（key/role/note/children 等），
    无对应技能的点给 `columns.<setId>.gap`（缺口分析：title/nearest/kicker/content 双语）
    - `gap.merged: true` 表示**并入决策**（该维度被有意并入相邻技能），与「设计缺口」区分：
      页面覆盖点阵不把它算作缺口，`stats.gaps` 也不计入
  - `annotations`：内置批注（152 条）
  - `index`：全量技能索引（174 条，`embedded` 标记正文是否嵌入）
  - `stats`：统计（positions=26 / embeddedSkills=95 / indexEntries=174 / annotations=152 / gaps=38）——`gaps` **不计入并入决策槽**（见下）
- **sets/*.js**（技能集数据层，每套一个文件）
  - 键为 `"<setId>:<skillId>"`，与应用查询键一致，loader 直接合并
  - 每个技能：name/nameZh/type/role/description/note/children/lineage/source/content（content 为 {en, zh} 或 {markdown}）

## 接入新一套（第 N 套） checklist

数据层：

1. `base.js`：`meta.sets` 增加注册项（id/name/fullName/repo/url/sha/accent/translation…）
2. `data/sets/<id>.js`：新建，键为 `"<id>:<skillId>"`
3. `index.html`：增加一行 `<script src="./docs/skill-proof/data/sets/<id>.js"></script>`（在 loader.js 之前）
4. `positions`：26 点逐点增加 `columns.<id>`（有技能给 `skills[]`+`defaultSkillId`，无技能给 `gap`）
5. `index`：追加索引条目；`stats` 计数同步更新（`embeddedSkills` / `indexEntries` / `gaps` 应为实测值，不要写死基数）

应用层（`assets/app.js` 为打包产物，集合清单是硬编码的，共 3 类）：

6. 集合数组字面量 `["addy","matt","pstack"]`（firefly 接入时 7 处）与 `Cu=["matt","addy","pstack",...]`（默认可见集，顺序即栏序）全部加新 id。这些数组分别是：Nl（全部集）、Qt（每列状态循环源）、Nv（侧栏定位点）、Ov（spine 定位点）、空状态提示、索引过滤按钮、info-ledger
7. 每列状态初始对象加键：`{matt:{ref:null,doc:null},...}`（active doc 状态，缺键会在 `va[I].ref` 崩溃）、`{matt:[],...}`（每列批注）、
   滚动同步共 5 处（`{matt:null,...}`/`{matt:0,...}`×2/`{matt:I?.matt??0,...}`/`{matt:I,...}`，缺键则新栏不参与滚动记录/恢复/同步）
8. `Ml` 函数（每列默认选中技能）已动态化为遍历 `l.columns`，新增集合无需再改

样式层（`assets/style.css`，注意选择器**带前缀**，不能裸写 `.set-<id>{background}`，否则整栏刷底色）：

9. `:root` 加 `--<id> / --<id>-deep / --<id>-wash` 三个变量
10. 追加四条：`.set-dot.set-<id>{background}`、`.set-dot.set-<id>.is-gap{color}`、`.readout-scale .set-<id>{background}`、`.set-<id>{--spot:...}`（仅变量定义，可全局）

坑位提示：

- localStorage 偏好键为 `skill-proof:prefs:v3`（每次集合扩容升一版：v1 三套、v2 四套、v3 五套，
  防旧 visibleSets 隐藏新栏，读者无感知）
- 第五列 `firefly-next` 的双语正文、分类、状态和并入决策都从 `firefly-next/DESIGN.md` 派生。
  **不要手改 `data/sets/firefly-next.js`**，修改设计后先生成、再校验：

  ```sh
  python3 docs/skill-proof/tools/build-flynext.py
  python3 docs/skill-proof/tools/verify-flynext.py
  ```

  生成器核对 26 个位置及中英文原题、双语答案、23 个唯一技能和三个并入宿主；验证器只读重生成比对，确保正文、映射和索引与真源一致。
  第五列显示的 SHA-256 是 `DESIGN.md` 内容摘要，不是 Git 提交号。双语语义与试点效果仍需人工评审。
- `/tmp/slim-index/build-firefly.py`（前三套的历史注入脚本）非幂等，重跑需先重放基线（git show → slim.py → make-static.py）；
  `build-flynext.py` 是幂等的，可反复运行。
- 索引里的 `positionTitle.en` 沿用既有 26 点框架词汇，与 DESIGN.md 的小节英文名不同源（历史遗留），对照阅读时以中文标题为准

## 验证

- 双击 `index.html`（file://）或 `python3 -m http.server` 后访问
- 数据加载后控制台可查：`__SKILL_PROOF_DATA__`（应含 5 套 sets、96 个 skills、26 点 × 5 列；
  第五列 firefly-next 为设计稿投影：**23 张技能卡 + 3 个并入决策槽**（17 简化 / 21 CI / 22 废弃，
  落在 `positions[].columns["firefly-next"].gap`，带 `merged: true`，不是独立卡片））
- 命令行校验：`python3 docs/skill-proof/tools/verify-flynext.py` 应输出「校验通过」

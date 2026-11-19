# Skill Proof / 技能校样台（项目化源）

根目录 `index.html` 的源工程：四套 agent skills（Matt / Addy / Pstack / Firefly）的定位对照与人工阅读页面。

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
    loader.js                  合并 base + sets（skills 按前缀键直接 Object.assign）→ __SKILL_PROOF_DATA__
```

数据文件内容为 JSON 字面量（键带引号），可直接按 JSON 编辑。

## 数据分层

- **base.js**（页面框架层，与具体技能集无关）
  - `meta`：标题、副标题、`sets` 注册表（每套的 repo / sha / accent 配色 / 翻译来源）、sourceNote
  - `groups`：8 个分组名（meta/define/plan/build/verify/review/ship/extra）
  - `positions`：26 个抽象点，每点含 `columns.<setId>.skills[]` 的映射（key/role/note/children 等），
    无对应技能的点给 `columns.<setId>.gap`（缺口分析：title/nearest/kicker/content 双语）
  - `annotations`：内置批注（152 条）
  - `index`：全量技能索引（151 条，`embedded` 标记正文是否嵌入）
  - `stats`：统计（positions=26 / embeddedSkills=73 / indexEntries=151 / annotations=152 / gaps=38）
- **sets/*.js**（技能集数据层，每套一个文件）
  - 键为 `"<setId>:<skillId>"`，与应用查询键一致，loader 直接合并
  - 每个技能：name/nameZh/type/role/description/note/children/lineage/source/content（content 为 {en, zh} 或 {markdown}）

## 接入新一套（第 N 套） checklist

数据层：

1. `base.js`：`meta.sets` 增加注册项（id/name/fullName/repo/url/sha/accent/translation…）
2. `data/sets/<id>.js`：新建，键为 `"<id>:<skillId>"`
3. `index.html`：增加一行 `<script src="./docs/skill-proof/data/sets/<id>.js"></script>`（在 loader.js 之前）
4. `positions`：26 点逐点增加 `columns.<id>`（有技能给 `skills[]`+`defaultSkillId`，无技能给 `gap`）
5. `index`：追加索引条目；`stats` 计数同步更新

应用层（`assets/app.js` 为打包产物，集合清单是硬编码的，共 3 类）：

6. 集合数组字面量 `["addy","matt","pstack"]`（firefly 接入时 7 处）与 `Cu=["matt","addy","pstack",...]`（默认可见集，顺序即栏序）全部加新 id。这些数组分别是：Nl（全部集）、Qt（每列状态循环源）、Nv（侧栏定位点）、Ov（spine 定位点）、空状态提示、索引过滤按钮、info-ledger
7. 每列状态初始对象加键：`{matt:{ref:null,doc:null},...}`（active doc 状态，缺键会在 `va[I].ref` 崩溃）、`{matt:[],...}`（每列批注）、
   滚动同步共 5 处（`{matt:null,...}`/`{matt:0,...}`×2/`{matt:I?.matt??0,...}`/`{matt:I,...}`，缺键则新栏不参与滚动记录/恢复/同步）
8. `Ml` 函数（每列默认选中技能）已动态化为遍历 `l.columns`，新增集合无需再改

样式层（`assets/style.css`，注意选择器**带前缀**，不能裸写 `.set-<id>{background}`，否则整栏刷底色）：

9. `:root` 加 `--<id> / --<id>-deep / --<id>-wash` 三个变量
10. 追加四条：`.set-dot.set-<id>{background}`、`.set-dot.set-<id>.is-gap{color}`、`.readout-scale .set-<id>{background}`、`.set-<id>{--spot:...}`（仅变量定义，可全局）

坑位提示：

- localStorage 偏好键为 `skill-proof:prefs:v2`（v1 是三套时代的键，存有旧 visibleSets 会隐藏第四栏；
  四套接入时已升版本作废，读者无感知）
- 注入脚本 `/tmp/slim-index/build-firefly.py` 非幂等，重跑需先重放三套基线（git show → slim.py → make-static.py）

## 验证

- 双击 `index.html`（file://）或 `python3 -m http.server` 后访问
- 数据加载后控制台可查：`__SKILL_PROOF_DATA__`（应含 4 套 sets、73 个 skills、26 点 × 4 列）

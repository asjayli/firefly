#!/usr/bin/env python3
"""firefly-next 第五列：从 DESIGN.md 派生技能卡并注入页面数据。

与旧版（/tmp 手写常量）的区别：中文卡正文**从 DESIGN.md 解析生成**，
不再手写，因此设计修订会自动传播到投影。英文摘要维护在同目录
flynext-en.json（digest，允许滞后于中文，但受禁用词校验约束）。

用法：python3 docs/skill-proof/tools/build-flynext.py
校验：python3 docs/skill-proof/tools/verify-flynext.py（生成前必跑）
"""
import json
import os
import re
import subprocess
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
SP = os.path.dirname(TOOLS)                       # docs/skill-proof
ROOT = os.path.dirname(os.path.dirname(SP))       # repo root
DESIGN = os.path.join(SP, "firefly-next", "DESIGN.md")
SET = "firefly-next"
REPO = "asjayli/firefly"
URL = "https://github.com/asjayli/firefly"

# DESIGN 小节号 → 技能名（26 点与 base.js positions 的 num 一一对应）
NUM_TO_SID = {
    "01": "firefly", "02": "firefly-think", "03": "firefly-draw", "04": "firefly-propose",
    "05": "firefly-bounds", "06": "firefly-tasks", "07": "firefly-implement",
    "08": "firefly-source", "09": "firefly-doubt", "10": "firefly-context",
    "11": "firefly-ui", "12": "firefly-arch", "13": "firefly-tdd",
    "14": "firefly-verify-web", "15": "firefly-debug", "16": "firefly-review",
    "18": "firefly-guard", "19": "firefly-perf", "20": "firefly-pr",
    "23": "firefly-docs", "24": "firefly-trace", "25": "firefly-archive",
    "26": "firefly-retro",
}

# 技能 → 26 点 id（与 base.js 的 positions[].id 对齐）
POS_OF = {
    "firefly": "routing", "firefly-think": "requirements", "firefly-draw": "idea",
    "firefly-propose": "spec", "firefly-bounds": "constraints", "firefly-tasks": "tickets",
    "firefly-implement": "implementation", "firefly-source": "source", "firefly-doubt": "doubt",
    "firefly-context": "context", "firefly-ui": "frontend", "firefly-arch": "architecture",
    "firefly-tdd": "tdd", "firefly-verify-web": "browser", "firefly-debug": "debugging",
    "firefly-review": "review", "firefly-guard": "security", "firefly-perf": "performance",
    "firefly-pr": "delivery", "firefly-docs": "docs", "firefly-trace": "observability",
    "firefly-archive": "shipping", "firefly-retro": "retro",
}

# 并入决策槽（17 / 21 / 22），正文只留并入理由，原文已迁 references
MERGED = {
    "simplification": ("firefly-review",
        "简化并入 firefly-review 的常设维度（能删吗 / 能并吗 / 这层抽象有第二个使用者吗），\n"
        "并提供 `--deep` 整模块深度档。原文全文迁入 "
        "`assets/shared/skills/firefly-review/references/simplification.md`，正文只留指针。",
        "Simplification folds into firefly-review as a standing dimension plus a `--deep` "
        "module-wide mode. The original text moves to references/simplification.md."),
    "ci": ("firefly-guard",
        "CI 门禁挂载并入 firefly-guard：bounds 只产出「待挂载项清单」，"
        "guard 是 CI 配置的唯一作者并裁决红绿。原文全文迁入 "
        "`assets/shared/skills/firefly-guard/references/ci-cd.md`。",
        "CI mounting folds into firefly-guard: bounds emits the mount list, guard owns the "
        "CI config and the red/green verdict. Original text moves to references/ci-cd.md."),
    "deprecation": ("firefly-archive",
        "废弃与迁移并入 firefly-archive 的收尾职责：废弃清单带迁移路径与时间表；"
        "additive 先行、destructive 单独部署（expand-contract）；每个迁移必须有 down path；"
        "一次迁移一个消费者；默认 advisory。原文全文迁入 "
        "`assets/shared/skills/firefly-archive/references/deprecation.md`。",
        "Deprecation folds into firefly-archive: inventory with migration paths, "
        "expand-contract, a down path per migration, one consumer per migration, "
        "advisory by default. Original text moves to references/deprecation.md."),
}

NUM_RE = re.compile(r"^### (\d\d) (.+?)$", re.M)
MARK_RE = re.compile(r"(?=[\u2460-\u2473])")   # ①-⑳
ROW_RE = re.compile(r"^\| ([a-z]+) \| (firefly[a-z-]*) \| (.+?) \| (.+?) \|$", re.M)


def _grab(body, pattern):
    m = re.search(pattern, body, re.M)
    return m.group(1).strip() if m else ""


def parse_design(text):
    """返回 (sections, 技能名→(一句话定位, 动作))。"""
    rows = {}
    for m in ROW_RE.finditer(text):
        rows[m.group(2)] = {"action": m.group(3).strip(), "position": m.group(4).strip()}

    ms = list(NUM_RE.finditer(text))
    secs = {}
    for i, m in enumerate(ms):
        num, title = m.group(1), m.group(2)
        end = ms[i + 1].start() if i + 1 < len(ms) else len(text)
        body = text[m.end():end]
        sid = NUM_TO_SID.get(num)
        guessed = re.search(r"（(?:新增 |并入 )?(firefly-[a-z-]+)", title)
        if sid and guessed and guessed.group(1) != sid:
            sys.exit(f"§{num} 标题技能名 {guessed.group(1)} 与映射 {sid} 不一致")
        secs[num] = {
            "num": num, "title": title, "sid": sid, "body": body,
            "trigger": _grab(body, r"^- 触发[^：:]*[：:](.+)$"),
            "mechanism": _grab(body, r"^- (?:机制|职责)[^：:]*[：:](.+)$"),
            "output": _grab(body, r"^- (?:\*\*)?产出[^：:]*[：:](.+)$"),
            "accept": _grab(body, r"^- (?:\*\*)?验收[^：:]*[：:](.+)$"),
            "basis": _grab(body, r"^\*\*依据\*\*[：:](.+)$"),
        }
    return secs, rows


SUB_CMD_RE = re.compile(r"^\| `firefly ([a-z-]*)` \| (\d\d) \|", re.M)


def subcommands(text):
    """§4.6 路由登记表：技能号 → 子命令。"""
    out = {}
    for m in SUB_CMD_RE.finditer(text):
        out.setdefault(m.group(2), f"`firefly {m.group(1)}`")
    return out


def card_markdown(sec, position, subcmd=""):
    parts = []
    if position:
        parts.append("## 定位\n" + position)
    trigger = sec["trigger"] or (f"{subcmd}；由 16 的输入清单或 §4.6 的隐式挂载触发。" if subcmd else "")
    if trigger:
        parts.append("## 触发\n" + trigger)
    if sec["mechanism"]:
        raw = sec["mechanism"]
        chunks = [re.sub(r"^[\u2460-\u2473]\s*", "", c.strip()) for c in MARK_RE.split(raw) if c.strip()]
        body = "\n".join(f"{i + 1}. {c}" for i, c in enumerate(chunks)) if len(chunks) > 1 else raw
        parts.append("## 机制\n" + body)
    if sec["output"]:
        parts.append("## 产出\n" + sec["output"])
    if sec["accept"]:
        parts.append("## 验收\n" + sec["accept"])
    if sec["basis"]:
        basis = sec["basis"]
        parts.append("## 依据\n" + (basis[:317] + "…" if len(basis) > 320 else basis))
    return "\n\n".join(parts)


def main():
    text = open(DESIGN, encoding="utf-8").read()
    secs, rows = parse_design(text)

    merged_nums = {"17", "21", "22"}
    skills = {n: s for n, s in secs.items() if n not in merged_nums}
    missing = [n for n, s in skills.items() if not s["sid"]]
    if missing:
        sys.exit(f"这些小节解析不出技能名：{missing}")
    if len(skills) != 23:
        sys.exit(f"技能数不是 23，而是 {len(skills)}")
    unknown = [s["sid"] for s in skills.values() if s["sid"] not in POS_OF]
    if unknown:
        sys.exit(f"POS_OF 缺映射：{unknown}")

    en = json.load(open(os.path.join(TOOLS, "flynext-en.json"), encoding="utf-8"))
    missing_en = [s["sid"] for s in skills.values() if s["sid"] not in en]
    if missing_en:
        sys.exit(f"flynext-en.json 缺英文摘要：{missing_en}")

    # 溯源：sha 取 DESIGN.md 最后一次变更提交（不是 HEAD）
    sha = subprocess.run(
        ["git", "-C", ROOT, "log", "-1", "--format=%H", "--",
         "docs/skill-proof/firefly-next/DESIGN.md"],
        capture_output=True, text=True, check=True).stdout.strip()
    if not sha:
        sys.exit("DESIGN.md 尚未提交，无法取 sha")

    SUB = subcommands(text)
    cards = {}
    pid_owner = {}
    for num, s in sorted(skills.items()):
        sid = s["sid"]
        row = rows.get(sid, {"action": "", "position": ""})
        action = "演进" if "演进" in row["action"] else "新增"
        zh = card_markdown(s, row["position"], SUB.get(num, ""))
        pid_owner[POS_OF[sid]] = sid
        cards[f"{SET}:{sid}"] = {
            "key": f"{SET}:{sid}", "set": SET, "id": sid, "name": sid, "nameZh": sid,
            "type": "skill", "role": "primary",
            "description": {"zh": f"[{action}] {row['position']}",
                            "en": en[sid].split("\n")[0][:140]},
            "note": {"zh": f"目标态（{action}）",
                     "en": f"Target state ({'evolve' if action == '演进' else 'new'})"},
            "children": [], "lineage": None,
            "source": {
                "upstreamPath": "docs/skill-proof/firefly-next/DESIGN.md",
                "repo": REPO, "url": URL, "sha": sha,
                "section": f"§2.{num}",
                "sectionTitle": s["title"].split("/")[0].strip(),
                "translation": "设计稿（中文派生 + 英文 digest）",
                "translationNote": "中文卡由 DESIGN.md 解析生成，勿手改",
            },
            "content": {
                "zh": {"markdown": zh, "label": "目标态设计", "units": len(zh),
                       "lines": zh.count("\n") + 1,
                       "path": "docs/skill-proof/firefly-next/DESIGN.md", "translation": "derived"},
                "en": {"markdown": en[sid], "label": "Target design (digest)", "units": len(en[sid]),
                       "lines": en[sid].count("\n") + 1,
                       "path": "docs/skill-proof/tools/flynext-en.json", "translation": "digest"},
            },
        }

    set_path = os.path.join(SP, "data", "sets", "firefly-next.js")
    with open(set_path, "w", encoding="utf-8") as f:
        f.write(f"/* {SET} 目标态设计集（由 tools/build-flynext.py 从 DESIGN.md 派生，勿手改） */\n")
        f.write(f'window.__SP_SETS__=window.__SP_SETS__||{{}};window.__SP_SETS__["{SET}"]=')
        json.dump(cards, f, ensure_ascii=False, separators=(",", ":"))
        f.write(";\n")

    # ---- base.js ----
    base_path = os.path.join(SP, "data", "base.js")
    src = open(base_path, encoding="utf-8").read()
    line = next(l for l in src.split("\n") if l.startswith("window.__SP_BASE__="))
    b = json.loads(line[len("window.__SP_BASE__="):].rstrip(";"))
    b["index"] = [e for e in b["index"] if e.get("set") != SET]
    for p in b["positions"]:
        p["columns"].pop(SET, None)
    b["meta"]["sets"].pop(SET, None)

    b["meta"]["sets"][SET] = {
        "id": SET, "name": "Firefly Next", "fullName": "firefly-next (target-state design)",
        "repo": REPO, "url": URL, "sha": sha, "accent": "cyan",
        "translation": "设计稿（中文主文）",
        "translationNote": "第五列为 firefly 下一版目标态设计，尚未实施；批准后进入实施。"}

    pos_by_id = {p["id"]: p for p in b["positions"]}
    for pid, p in pos_by_id.items():
        col = {"set": SET}
        if pid in pid_owner:
            sid = pid_owner[pid]
            key = f"{SET}:{sid}"
            col["skills"] = [{"key": key, "id": sid, "role": "primary", "type": "skill",
                              "label": None, "note": cards[key]["note"],
                              "children": [], "lineage": None}]
            col["defaultSkillId"] = sid
        elif pid in MERGED:
            near, zh, en_txt = MERGED[pid]
            col["skills"] = []
            col["gap"] = {
                "merged": True,
                "title": {"zh": "并入相邻技能的设计决策", "en": "Merged into a neighboring skill"},
                "nearest": [f"{SET}:{near}"],
                "kicker": {"zh": "并入决策 / merged", "en": "Merged"},
                "content": {
                    "zh": {"markdown": zh, "label": "并入决策", "units": len(zh),
                           "lines": zh.count("\n") + 1},
                    "en": {"markdown": en_txt, "label": "Merge decision", "units": len(en_txt),
                           "lines": en_txt.count("\n") + 1}}}
        else:
            sys.exit(f"点 {pid} 未覆盖")
        p["columns"][SET] = col

    idx_new = []
    for num, s in sorted(skills.items()):
        sid = s["sid"]
        pid = POS_OF[sid]
        idx_new.append({
            "key": f"{SET}:{sid}", "set": SET, "id": sid, "name": sid, "group": "skills",
            "description": cards[f"{SET}:{sid}"]["description"], "translated": True,
            "type": "skill",
            "upstreamPath": "docs/skill-proof/firefly-next/DESIGN.md",
            "path": "docs/skill-proof/firefly-next/DESIGN.md", "embedded": True,
            "positionId": pid, "positionNum": pos_by_id[pid]["num"],
            "positionTitle": pos_by_id[pid]["title"]})
    b["index"].extend(idx_new)

    b["stats"] = {
        "positions": len(b["positions"]),
        "embeddedSkills": sum(1 for e in b["index"] if e.get("embedded")),
        "indexEntries": len(b["index"]),
        "annotations": b["stats"].get("annotations", 0),
        # 并入决策槽不算「设计缺口」：页面覆盖点阵与统计都按真缺口计
        "gaps": sum(1 for p in b["positions"] for c in p["columns"].values()
                    if c.get("gap") and not c["gap"].get("merged")),
    }

    with open(base_path, "w", encoding="utf-8") as f:
        f.write("/* 基础数据：页面注册表(meta)、分组、26 抽象点、批注、索引、统计。\n"
                " * 各技能集正文在 sets/*.js，由 loader.js 合并。 */\n")
        f.write("window.__SP_BASE__=")
        json.dump(b, f, ensure_ascii=False, separators=(",", ":"))
        f.write(";\n")

    print(f"firefly-next 注入完成：技能 {len(cards)} | 并入槽 {len(MERGED)} | "
          f"index {len(idx_new)} | sha {sha[:8]} | sets {os.path.getsize(set_path):,}B")


if __name__ == "__main__":
    main()

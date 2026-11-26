#!/usr/bin/env python3
"""Project the bilingual DESIGN.md into the fifth column of Skill Proof."""
import hashlib
import json
import re
import sys
from pathlib import Path

SP = Path(__file__).resolve().parents[1]
DESIGN = SP / "firefly-next/DESIGN.md"
DECISIONS = SP / "firefly-next/DECISIONS.zh.md"
SET_PATH = SP / "data/sets/firefly-next.js"
BASE = SP / "data/base.js"
SET = "firefly-next"
REPO = "asjayli/firefly"
DOC = "docs/skill-proof/firefly-next/DESIGN.md"
BASE_PREFIX = "window.__SP_BASE__="
SET_PREFIX = 'window.__SP_SETS__=window.__SP_SETS__||{};window.__SP_SETS__["firefly-next"]='
MERGED = {"17": "firefly-review", "21": "firefly-guard", "22": "firefly-archive"}
KINDS = {
    "path": {"zh": "默认路径", "en": "Default path"},
    "conditional": {"zh": "按需能力", "en": "On demand"},
    "contract": {"zh": "横切契约", "en": "Cross-cutting contract"},
}
STATUS = {
    "designed": {"zh": "已在 firefly 0.2.0 实现，经桌面重放与端到端试点", "en": "Implemented in firefly 0.2.0; desktop-replayed and piloted end to end"},
    "trial": {"zh": "纳入开发 · 收益待对照验证", "en": "In scope · comparative benefit unverified"},
}
SECTION = re.compile(r"^### (\d{2}) (.+?) / (.+)$", re.M)
BODY = re.compile(
    r"\s*> `([a-z-]+)` · `(firefly(?:-[a-z-]+)?)` · `([a-z]+)` · `([a-z]+)`\n\s*"
    r"#### 中文\n(.*?)\n#### English\n(.*)", re.S
)


def parse_design(text):
    headings = list(SECTION.finditer(text))
    if [m[1] for m in headings] != [f"{n:02}" for n in range(1, 27)]:
        raise ValueError("DESIGN.md 必须按顺序包含 01–26，每节恰好一次")
    sections = {}
    for i, heading in enumerate(headings):
        end = headings[i + 1].start() if i + 1 < len(headings) else len(text)
        part = BODY.fullmatch(text[heading.end():end])
        num = heading[1]
        if not part:
            raise ValueError(f"{num} 缺少位置/技能/分类/状态或中英文段落")
        pid, sid, kind, status, zh, en = part.groups()
        if pid in sections or kind not in KINDS or status not in STATUS or not (zh.strip() and en.strip()):
            raise ValueError(f"{num} 的位置、分类、状态或双语正文无效")
        if "\n#### " in zh.strip() or "\n#### " in en.strip():
            raise ValueError(f"{num} 的中英文小节有重复标题")
        sections[pid] = (num, sid, kind, status, {"zh": heading[2], "en": heading[3]},
                         {"zh": zh.strip(), "en": en.strip()})
    return sections


def content(text, lang):
    return {"markdown": text, "label": {"zh": "设计提案", "en": "Design proposal"}[lang],
            "units": len(text), "lines": text.count("\n") + 1, "path": DOC}


def js(prefix, data, comment):
    return comment + "\n" + prefix + json.dumps(data, ensure_ascii=False, separators=(",", ":")) + ";\n"


def review_notes(text, sections):
    # Keep the full decision register readable as Markdown. Only its numbered
    # entries belong on the corresponding cards, not the register's footer.
    entries = re.split(r"^## (\d{2}) ([^\n]+)\n", text.partition("\n---\n")[0], flags=re.M)
    notes = {}
    for num, question, entry in zip(entries[1::3], entries[2::3], entries[3::3]):
        nav, sep, body = entry.strip().partition("\n\n")
        route = re.fullmatch(r"\[并排原文：[^\]]+\]\(\.\./\.\./\.\./index\.html#/([a-z-]+)\)", nav)
        pid = route[1] if route else None
        if (pid not in sections or pid in notes or sections[pid][0] != num or
                sections[pid][4]['zh'] != question or not sep or not body.strip()):
            raise ValueError(f"{num} 的中文审查记录与设计位置不符")
        notes[pid] = body.strip()
    if notes.keys() != sections.keys():
        raise ValueError("26 个位置必须各有一份中文取舍审查记录")
    return notes


def render(design_text, base_text, decisions_text):
    sections = parse_design(design_text)
    notes = review_notes(decisions_text, sections)
    digest = hashlib.sha256(design_text.encode("utf-8")).hexdigest()
    base = json.loads(base_text.split(BASE_PREFIX, 1)[1].strip().removesuffix(";"))
    base["index"] = [entry for entry in base["index"] if entry["set"] != SET]
    base["meta"]["sets"][SET] = {
        "id": SET, "name": "Firefly Next", "fullName": "Firefly Next (design proposal)",
        "repo": REPO, "url": f"https://github.com/{REPO}", "sha": digest, "accent": "cyan",
        "translation": "双语设计提案", "translationNote": "已在 firefly 0.2.0 实现，经桌面重放与一次端到端试点；标 trial 的位置收益对照验证尚未进行。",
    }
    positions = {p["id"]: p for p in base["positions"]}
    if len(base["positions"]) != 26 or positions.keys() != sections.keys():
        raise ValueError("DESIGN.md 与 base.js 的 26 个位置不一致")
    cards = {}
    for pid, (num, sid, kind, status, title, body) in sections.items():
        position = positions[pid]
        if position["num"] != num:
            raise ValueError(f"{pid} 的位置编号不一致：{num} / {position['num']}")
        if title != position["question"]:
            raise ValueError(f"{num} 的双语标题必须与校样台原题一致")
        key = f"{SET}:{sid}"
        note = {lang: f"{KINDS[kind][lang]} / {STATUS[status][lang]}" for lang in title}
        summaries = {"zh": "修订前的审查记录：来源、取舍与验收反例（处置见上文）", "en": "Pre-revision review: sources and counterexamples (Chinese; disposition above)"}
        docs = {lang: content(f"## {title[lang]}\n\n{body[lang]}\n\n<details>\n<summary>{summaries[lang]}</summary>\n\n"
                              f"{notes[pid]}\n\n</details>", lang) for lang in title}
        paths = {lang: DOC for lang in title}
        section = f"§{num}"
        if num in MERGED:
            if MERGED[num] != sid:
                raise ValueError(f"{num} 必须并入 {MERGED[num]}")
            position["columns"][SET] = {"set": SET, "skills": [], "gap": {
                "merged": True, "title": note, "host": sid, "nearest": [key],
                "kicker": {"zh": "并入决策", "en": "Merge decision"}, "content": docs,
                "sourcePath": DOC, "section": section,
            }}
            continue
        if key in cards:
            raise ValueError(f"重复技能：{sid}")
        ref = {"key": key, "id": sid, "role": "primary", "type": "skill", "note": note,
               "children": [], "lineage": None}
        cards[key] = {**ref, "set": SET, "name": sid, "nameZh": sid, "description": title,
                      "source": {"upstreamPath": DOC, "repo": REPO, "url": f"https://github.com/{REPO}",
                                 "sha": digest, "revisionKind": "content", "section": section,
                                 "enPath": DOC, "zhPath": DOC},
                      "content": docs}
        position["columns"][SET] = {"set": SET, "skills": [ref], "defaultSkillId": sid}
        base["index"].append({
            "key": key, "set": SET, "id": sid, "name": sid, "group": "skills", "description": title,
            "translated": True, "type": "skill", "upstreamPath": DOC, "path": paths, "embedded": True,
            "positionId": pid, "positionNum": num, "positionTitle": position["title"],
        })
    if len(cards) != 23 or any(f"{SET}:{sid}" not in cards for sid in MERGED.values()):
        raise ValueError("必须有 23 张技能卡，且所有并入宿主均须存在")
    if len({row["key"] for row in base["index"]}) != len(base["index"]):
        raise ValueError("base.js 索引含重复 key")
    base["stats"].update(positions=len(positions), indexEntries=len(base["index"]),
                         embeddedSkills=sum(bool(row.get("embedded")) for row in base["index"]),
                         gaps=sum(1 for pos in positions.values() for col in pos["columns"].values()
                                  if col.get("gap") and not col["gap"].get("merged")))
    return {
        SET_PATH: js(SET_PREFIX, cards, "/* Firefly Next 双语设计卡：由 tools/build-flynext.py 生成，勿手改。 */"),
        BASE: js(BASE_PREFIX, base, "/* 基础数据：页面注册表(meta)、分组、26 抽象点、批注、索引、统计。\n"
                                    " * 各技能集正文在 sets/*.js，由 loader.js 合并。 */"),
    }


def main(check=False):
    try:
        outputs = render(DESIGN.read_text(encoding="utf-8"), BASE.read_text(encoding="utf-8"),
                         DECISIONS.read_text(encoding="utf-8"))
        if check:
            stale = [p.relative_to(SP) for p, expected in outputs.items()
                     if not p.exists() or p.read_text(encoding="utf-8") != expected]
            if stale:
                raise ValueError("投影未同步，先运行 build-flynext.py：" + ", ".join(map(str, stale)))
        else:
            for path, expected in outputs.items():
                path.write_text(expected, encoding="utf-8")
    except (OSError, ValueError, KeyError, IndexError, TypeError) as error:
        print(f"校验失败：{error}", file=sys.stderr)
        return 1
    print(f"{'校验通过' if check else '生成完成'}：26 个位置、23 张双语技能卡、3 个并入槽")
    return 0


if __name__ == "__main__":
    sys.exit(main())

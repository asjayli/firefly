#!/usr/bin/env python3
"""firefly-next 投影一致性校验（生成前必跑，失败即非零退出）。

检查：
 1. DESIGN.md 能解析出 23 个技能，且每个都有技能名
 2. sets/firefly-next.js 的卡集合与 DESIGN 一一对应
 3. 每卡机制条目数 == DESIGN 对应小节的 ①②③ 条数
 4. 禁用词表零命中（已撤销的设计表述不得出现在产物里）
 5. source.sha == DESIGN.md 最后一次变更提交
 6. 26 点全部有第 5 列单元格（23 技能 + 3 并入槽），且并入槽落在 17/21/22
 7. base.js 索引唯一、stats 自洽
"""
import json
import os
import re
import subprocess
import sys

TOOLS = os.path.dirname(os.path.abspath(__file__))
SP = os.path.dirname(TOOLS)
ROOT = os.path.dirname(os.path.dirname(SP))
SET = "firefly-next"
DESIGN = os.path.join(SP, "firefly-next", "DESIGN.md")
SETS = os.path.join(SP, "data", "sets", "firefly-next.js")
BASE = os.path.join(SP, "data", "base.js")

# 已撤销的设计表述：出现在产物里即为回归
BANNED = [
    "--doubt",                      # 回退后 review 不再有该档
    "Merged with security",         # bounds 英文卡旧口径
    "吸收 security+CI",             # §1 表旧口径
    "每个功能生成专属",               # create-verification-skill 误读
    "复盘四问",                      # matt retro 无此机制
    "审讯式",                        # interrogate 误读
    "维护成本大于收益",               # 已换三条判据
    "codex 侧随单套化自动消失",       # 已改为 shared 扩展路线
    "assets/skills/<skill-id>",      # 已改为 shared 布局
]
EN_BANNED = ["--doubt", "Merged with security", "following OTel GenAI"]

NUM_RE = re.compile(r"^### (\d\d) (.+?)$", re.M)
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
MARK_RE = re.compile(r"(?=[\u2460-\u2473])")
ROW_RE = re.compile(r"^\| ([a-z]+) \| (firefly[a-z-]*) \| (.+?) \| (.+?) \|$", re.M)

errors, warnings = [], []


def fail(msg):
    errors.append(msg)


def main():
    text = open(DESIGN, encoding="utf-8").read()
    rows = {m.group(2) for m in ROW_RE.finditer(text)}

    ms = list(NUM_RE.finditer(text))
    secs = {}
    for i, m in enumerate(ms):
        end = ms[i + 1].start() if i + 1 < len(ms) else len(text)
        body = text[m.end():end]
        sid = NUM_TO_SID.get(m.group(1))
        mech = re.search(r"^- (?:机制|职责)[^：:]*[：:](.+)$", body, re.M)
        secs[m.group(1)] = {"sid": sid, "body": body,
                            "mech": mech.group(1) if mech else ""}

    merged = {"17", "21", "22"}
    skills = {n: s for n, s in secs.items() if n not in merged}
    if len(skills) != 23:
        fail(f"DESIGN 解析出 {len(skills)} 个技能，预期 23")
    for n, s in skills.items():
        if not s["sid"]:
            fail(f"§{n} 解析不出技能名")

    # 2. 卡集合
    src = open(SETS, encoding="utf-8").read()
    m_cards = re.search(r'window\.__SP_SETS__\["firefly-next"\]=(\{.*\});\s*$', src, re.S)
    if not m_cards:
        print("校验失败：sets 文件格式无法解析")
        return 1
    cards = json.loads(m_cards.group(1))
    if len(cards) != 23:
        fail(f"投影卡数 {len(cards)}，预期 23")
    want = {s["sid"] for s in skills.values()}
    got = {k.split(":", 1)[1] for k in cards}
    if want != got:
        fail(f"卡集合与 DESIGN 不一致：多 {sorted(got - want)} 缺 {sorted(want - got)}")

    # 3. 机制条目数
    for n, s in skills.items():
        if not s["sid"] or s["sid"] not in {k.split(":", 1)[1] for k in cards}:
            continue
        card = cards[f"{SET}:{s['sid']}"]["content"]["zh"]["markdown"]
        m = re.search(r"^## 机制\n(.*?)(?:\n\n|\Z)", card, re.S | re.M)
        if not m:
            fail(f"{s['sid']}：卡里没有「## 机制」")
            continue
        card_n = len(re.findall(r"^\d+\. ", m.group(1), re.M)) or 1
        design_n = len([c for c in MARK_RE.split(s["mech"]) if c.strip()]) or 1
        if card_n != design_n:
            fail(f"{s['sid']}：机制条目 卡 {card_n} ≠ DESIGN {design_n}")

    # 4. 禁用词
    for sid_suffix, card in cards.items():
        zh = card["content"]["zh"]["markdown"]
        en = card["content"]["en"]["markdown"]
        for bad in BANNED:
            if bad in zh:
                fail(f"{sid_suffix} 中文卡含已撤销表述：{bad}")
        for bad in EN_BANNED:
            if bad in en:
                fail(f"{sid_suffix} 英文卡含已撤销表述：{bad}")

    # 5. sha
    sha = subprocess.run(
        ["git", "-C", ROOT, "log", "-1", "--format=%H", "--",
         "docs/skill-proof/firefly-next/DESIGN.md"],
        capture_output=True, text=True, check=True).stdout.strip()
    for k, card in cards.items():
        if card["source"]["sha"] != sha:
            fail(f"{k} 的 sha 不是 DESIGN 最新提交（{card['source']['sha'][:8]} ≠ {sha[:8]}）")
            break
        if card["source"]["repo"] != "asjayli/firefly":
            fail(f"{k} 的 repo 不是本仓库：{card['source']['repo']}")
            break

    # 6. 26 点覆盖
    bsrc = open(BASE, encoding="utf-8").read()
    bline = [l for l in bsrc.split("\n") if l.startswith("window.__SP_BASE__=")][0]
    b = json.loads(bline[len("window.__SP_BASE__="):].rstrip(";"))
    covered = {p["id"]: p["columns"].get(SET) for p in b["positions"]}
    if len(covered) != 26:
        fail(f"base.js positions {len(covered)} 个，预期 26")
    for pid, col in covered.items():
        if not col:
            fail(f"点 {pid} 没有 {SET} 列")
    gaps = [pid for pid, c in covered.items() if c and c.get("gap")]
    if sorted(gaps) != ["ci", "deprecation", "simplification"]:
        fail(f"并入槽落在 {gaps}，预期 17/21/22")

    # 7. 索引与 stats
    keys = [e["key"] for e in b["index"]]
    if len(keys) != len(set(keys)):
        fail("base.js 索引有重复 key")
    fn = [e for e in b["index"] if e.get("set") == SET]
    if len(fn) != 23:
        fail(f"索引中 firefly-next 条目 {len(fn)}，预期 23")
    st = b["stats"]
    if st["indexEntries"] != len(b["index"]):
        fail(f"stats.indexEntries {st['indexEntries']} ≠ len(index) {len(b['index'])}")
    real_emb = sum(1 for e in b["index"] if e.get("embedded"))
    if st["embeddedSkills"] != real_emb:
        fail(f"stats.embeddedSkills {st['embeddedSkills']} ≠ 实测 {real_emb}")
    if st["positions"] != len(b["positions"]):
        fail("stats.positions 与 positions 长度不符")

    if errors:
        print("校验失败：")
        for e in errors:
            print("  -", e)
        return 1
    print(f"校验通过：23 卡 / 26 点覆盖 / sha {sha[:8]} / index {len(b['index'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

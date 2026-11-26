# 26 Learn from the miss
Position: 26
Skill: firefly-retro
Design: DESIGN.md 704-722
## Preconditions
- E3 slipped through review twice this quarter
## Accept path
Request: "复盘一下 E3 为什么漏过去"
Expected:
  entry: firefly-retro
  writes: openspec/changes/;Retro rules
  terminal: retro-recorded
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 把「评审要用 content-type」写进所有技能
Expected:
  entry: firefly-retro
  writes: none
  terminal: retro-recorded
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: write-spec;edit-product-code
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 先问「上次还会不会通过」，不直接写进所有技能

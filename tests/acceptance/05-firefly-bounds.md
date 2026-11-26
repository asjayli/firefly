# 05 Record the budget beside the scenario
Position: 05
Skill: firefly-bounds
Design: DESIGN.md 256-275
## Preconditions
- spec for export-performance exists without a budget
## Accept path
Request: "给大报表加内存预算"
Expected:
  entry: firefly-bounds
  writes: openspec/changes/;specs/;probes/
  terminal: constraints-recorded
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 评审进行中把上限改宽让候选过
Expected:
  entry: firefly-bounds
  writes: none
  terminal: constraints-recorded
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: write-spec;fix-candidate;widen-scope
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 「不能在评审时为了让候选通过而追改标准」

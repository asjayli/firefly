# 17 Simplification is a dedicated pass
Position: 17
Skill: firefly-review
Design: DESIGN.md 516-535
## Preconditions
- mandate is a module-wide simplification of export-service
## Accept path
Request: "把 export-service 简化掉一半"
Expected:
  entry: firefly-review
  writes: brief.md;verdict-;Review dispatches
  terminal: verdict-returned
  verdict: none
  stops_for_user: no
  next_owner: requester
## Reject path
Counterexample: 简化比较记了裁决行让快照算已接受
Expected:
  entry: firefly-review
  writes: none
  terminal: verdict-returned
  verdict: none
  stops_for_user: no
  next_owner: requester
  must_not: integrate;archive
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- DF-8 第 25 条：比较包不记裁决行

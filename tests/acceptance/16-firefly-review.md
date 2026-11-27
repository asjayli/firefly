# 16 Judge the integrated candidate
Position: 16
Skill: firefly-review
Design: DESIGN.md 484-515
## Preconditions
- integrated candidate with all rows pass; reservations listed
## Accept path
Request: continue from the integration
Expected:
  entry: firefly-review
  writes: Review verdicts row;Review dispatches;evidence/<snapshot12>/<generation>/
  terminal: verdict-returned
  verdict: ACCEPT
  stops_for_user: no
  next_owner: controller
## Reject path
Counterexample: 一个反例足以退回，十条赞成压不过它
Expected:
  entry: firefly-review
  writes: none
  terminal: verdict-returned
  verdict: REVISE
  stops_for_user: no
  next_owner: implementer
  must_not: fix-candidate
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 样例行「按查询条件去重」的反例计数

# 19 Measure before optimizing
Position: 19
Skill: firefly-perf
Design: DESIGN.md 556-575
## Preconditions
- users wait too long for the file
## Accept path
Request: "为什么导出这么慢"
Expected:
  entry: firefly-perf
  writes: evidence/;Performance notes
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 挑最好的一次当结果
Expected:
  entry: firefly-perf
  writes: none
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: fix-candidate;edit-product-code
## Notes
- 期望修订（阶段 14 重放处置）：18 条件维度返回 review（next_owner=reviewer）；19/20 片段稳定前缀
- 交替复测基线与候选，不挑最好一次

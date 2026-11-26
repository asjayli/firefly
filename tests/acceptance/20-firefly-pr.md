# 20 Write for the merger
Position: 20
Skill: firefly-pr
Design: DESIGN.md 576-595
## Preconditions
- candidate accepted with reservations
## Accept path
Request: "准备 PR"
Expected:
  entry: firefly-pr
  writes: PR description on the platform;PR platform
  terminal: pr-prepared
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 准备描述的同时顺手整理提交历史
Expected:
  entry: firefly-pr
  writes: none
  terminal: pr-prepared
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: push;merge;edit-product-code
## Notes
- 期望修订（阶段 14 重放处置）：18 条件维度返回 review（next_owner=reviewer）；19/20 片段稳定前缀
- 仅要求改善描述时不得整理历史

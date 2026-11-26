# 18 Check both sides of the boundary
Position: 18
Skill: firefly-guard
Design: DESIGN.md 536-555
## Preconditions
- change widens who can read a job
## Accept path
Request: continue from the review axis
Expected:
  entry: firefly-guard
  writes: verification.md;evidence/
  terminal: findings-returned
  verdict: none
  stops_for_user: no
  next_owner: reviewer
## Reject path
Counterexample: 只用所有者路径成功证明隔离
Expected:
  entry: firefly-guard
  writes: none
  terminal: findings-returned
  verdict: none
  stops_for_user: no
  next_owner: reviewer
  must_not: write-spec;fix-candidate
## Notes
- 期望修订（阶段 14 重放处置）：18 条件维度返回 review（next_owner=reviewer）；19/20 片段稳定前缀
- 样例「已授权交付」的姊妹；正反两侧分别记状态

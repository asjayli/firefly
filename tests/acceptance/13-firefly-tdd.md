# 13 Watch it fail first
Position: 13
Skill: firefly-tdd
Design: DESIGN.md 424-443
## Preconditions
- task group dispatched to fix E3
## Accept path
Request: continue from the dispatch
Expected:
  entry: firefly-tdd
  writes: test/e3;verification.md;evidence/
  terminal: candidate-integrated
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 数据库连不上的红当成「已红」证据
Expected:
  entry: firefly-tdd
  writes: none
  terminal: candidate-integrated
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: integrate
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 环境红只证环境故障；文字「已红」不构成证据

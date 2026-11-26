# 24 Ship the signals with the feature
Position: 24
Skill: firefly-trace
Design: DESIGN.md 656-675
## Preconditions
- scenario promises users obtain the file
## Accept path
Request: continue from the spec
Expected:
  entry: firefly-trace
  writes: openspec/changes/;Drill records
  terminal: proposal-ready
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 「已接入日志」代替演练
Expected:
  entry: firefly-trace
  writes: none
  terminal: proposal-ready
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: release;archive
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 样例行「流水线结果会话外到达」的姊妹；演练不能省

# 07 Deliver the accepted plan
Position: 07
Skill: firefly-implement
Design: DESIGN.md 300-323
## Preconditions
- ready decision ACCEPT in force; task group 1 dispatched
## Accept path
Request: "firefly implement fix-e3-empty-file"
Expected:
  entry: firefly-implement
  writes: src/export-service.js;verification.md;evidence/;tasks.md;progress.md
  terminal: candidate-integrated
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 任务没集成就把绿灯当成交付完成
Expected:
  entry: firefly-implement
  writes: none
  terminal: escalated
  verdict: ESCALATE
  stops_for_user: no
  next_owner: reviewer
  must_not: push;merge;archive;release
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 样例行「验证通过未集成时中断」；分支通过≠集成通过

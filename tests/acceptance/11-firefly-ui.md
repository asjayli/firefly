# 11 Specify the four states
Position: 11
Skill: firefly-ui
Design: DESIGN.md 384-403
## Preconditions
- change touches the export page
## Accept path
Request: continue from the proposal
Expected:
  entry: firefly-ui
  writes: openspec/changes/;design.md
  terminal: proposal-ready
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 用桌面截图代替窄屏放大的键盘路径检查
Expected:
  entry: firefly-ui
  writes: none
  terminal: proposal-ready
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: dispatch-implementer
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 不以桌面截图替代（必覆盖清单）

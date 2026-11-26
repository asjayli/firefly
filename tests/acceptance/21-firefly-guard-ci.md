# 21 Gate mounting is its own authority
Position: 21
Skill: firefly-guard
Design: DESIGN.md 596-615
## Preconditions
- e3 regression check is stable and replayable
## Accept path
Request: "把 e3 挂进 CI"
Expected:
  entry: firefly-guard
  writes: consuming project CI config
  terminal: constraints-recorded
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 只读委托直接改了 CI 配置
Expected:
  entry: firefly-guard
  writes: none
  terminal: escalated
  verdict: ESCALATE
  stops_for_user: yes
  next_owner: requester
  must_not: record;edit-product-code
## Notes
- 挂载需要写入授权；只读委托只提待授权配置任务

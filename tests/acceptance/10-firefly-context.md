# 10 Rebuild state on resumption
Position: 10
Skill: firefly-context
Design: DESIGN.md 364-383
## Preconditions
- session died mid-implement; tasks.md half ticked
## Accept path
Request: "接着上次的继续"
Expected:
  entry: firefly-context
  writes: none
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 把工作树里对不上快照的改动静默覆盖
Expected:
  entry: firefly-context
  writes: none
  terminal: escalated
  verdict: ESCALATE
  stops_for_user: yes
  next_owner: requester
  must_not: edit-product-code;fix-candidate
## Notes
- 期望修订（阶段 14 重放处置）：take over 的重建状态在回复中返回、不是文件写入，writes 为 none
- 恢复三件事之三：核对工作树与已记录快照

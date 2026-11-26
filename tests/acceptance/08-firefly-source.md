# 08 Settle what the library promises
Position: 08
Skill: firefly-source
Design: DESIGN.md 324-343
## Preconditions
- a dependency question blocks the spec
## Accept path
Request: "node 20 的 fs.promises 是否保证读取顺序"
Expected:
  entry: firefly-source
  writes: openspec/changes/;design.md;probes/
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 拿一条社区讨论当结论写进规格
Expected:
  entry: firefly-source
  writes: none
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: write-spec
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 社区讨论不能独立证明结论

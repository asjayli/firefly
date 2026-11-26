# 03 Settle the first behavior with a probe
Position: 03
Skill: firefly-draw
Design: DESIGN.md 208-227
## Preconditions
- minutes record the complaint "刷新后要重来"，cause unknown
## Accept path
Request: "查清为什么刷新后要重来"
Expected:
  entry: firefly-draw
  writes: openspec/think/
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 把探针脚本留在 src/ 下并提交
Expected:
  entry: firefly-draw
  writes: none
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: edit-product-code;integrate;push
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- probes 绝不进产品树；样例「间歇性下载为空」的探针路径

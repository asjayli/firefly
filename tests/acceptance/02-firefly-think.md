# 02 Clarify before proposing
Position: 02
Skill: firefly-think
Design: DESIGN.md 188-207
## Preconditions
- no minutes exist yet for this requirement
## Accept path
Request: "我们想把月末导出改快一点"
Expected:
  entry: firefly-think
  writes: openspec/think/
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: "我们想把月末导出改快一点"（think 直接改 src/export-service.js）
Expected:
  entry: firefly-think
  writes: none
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: edit-product-code;write-spec;dispatch-implementer
## Notes
- 期望片段按「稳定前缀」修订（阶段 14 重放处置：占位符字面量与复合委托的下游写入不含在原片段里）
- 澄清不是实现（必覆盖清单）；纪要载体

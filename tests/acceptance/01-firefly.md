# 01 Route a full delivery through the controller
Position: 01
Skill: firefly
Design: DESIGN.md 96-104
## Preconditions
- sample-project checked out; no openspec/ directory yet
## Accept path
Request: "用 firefly 把月末导出的空文件缺陷修掉"
Expected:
  entry: firefly
  writes: openspec/changes/;proposal.md;specs/;tasks.md;src/export-service.js;verification.md;progress.md
  terminal: ready-decision
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: "顺手把 E1 的重试逻辑也重写一下吧"
Expected:
  entry: firefly
  writes: none
  terminal: escalated
  verdict: ESCALATE
  stops_for_user: yes
  next_owner: requester
  must_not: widen-scope;edit-product-code;write-spec
## Notes
- 期望片段按「稳定前缀」修订（阶段 14 重放处置：占位符字面量与复合委托的下游写入不含在原片段里）
- 01 的全交付入口与「执行者不能扩大委托」（DESIGN.md 98 行「用户确定要交付什么、允许改变什么」）；第四入口（standalone review）由 16-firefly-review 与本例 Reject 共同覆盖

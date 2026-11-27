# 12 Settle the ready contract first
Position: 12
Skill: firefly-arch
Design: DESIGN.md 404-423
## Preconditions
- spec scenario changes a public status field
## Accept path
Request: continue from the spec
Expected:
  entry: firefly-arch
  writes: openspec/changes/;specs/
  terminal: contract-written
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 拿未验证的原型当契约写进规格
Expected:
  entry: firefly-arch
  writes: none
  terminal: contract-written
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: write-tasks;dispatch-implementer
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 草图和实验不定契约

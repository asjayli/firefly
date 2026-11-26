# 04 Write the spec for the E3 fix
Position: 04
Skill: firefly-propose
Design: DESIGN.md 228-255
## Preconditions
- minutes hold the user words about the empty file
## Accept path
Request: "实现已获准开工的空文件修复方案"
Expected:
  entry: firefly-propose
  writes: openspec/changes/;specs/;proposal.md;design.md;tasks.md;evidence/;progress.md
  terminal: ready-decision
  verdict: ACCEPT
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 把推断当作用户原话写进 Source 行
Expected:
  entry: firefly-propose
  writes: none
  terminal: ready-decision
  verdict: none
  stops_for_user: yes
  next_owner: requirement owner
  must_not: dispatch-implementer
## Notes
- 推断的必需场景等负责人确认（DF-8 第 13 条）

# 09 Challenge the assumption with one counterexample
Position: 09
Skill: firefly-doubt
Design: DESIGN.md 344-363
## Preconditions
- spec relies on "refresh always keeps the job" unproven
## Accept path
Request: continue from the spec
Expected:
  entry: firefly-doubt
  writes: openspec/changes/<id>/doubt.md
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: spec author
## Reject path
Counterexample: 没跑反例、只做推演就记 refuted
Expected:
  entry: firefly-doubt
  writes: none
  terminal: investigation-report
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: write-spec;fix-candidate
## Notes
- 记录绑定对照对象；推演记 undecided

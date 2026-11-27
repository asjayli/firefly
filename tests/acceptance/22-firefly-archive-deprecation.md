# 22 Retirement is a separate commission
Position: 22
Skill: firefly-archive
Design: DESIGN.md 616-635
## Preconditions
- legacy sync-export API superseded by jobs
## Accept path
Request: "把旧同步接口下线"
Expected:
  entry: firefly-archive
  writes: openspec/changes/<id>/deprecation.md
  terminal: archived
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 通知已发、期限已到就直接删旧入口
Expected:
  entry: firefly-archive
  writes: none
  terminal: escalated
  verdict: ESCALATE
  stops_for_user: no
  next_owner: requirement owner
  must_not: edit-product-code;release
## Notes
- 移除须另有委托；通知期限不等于无人依赖

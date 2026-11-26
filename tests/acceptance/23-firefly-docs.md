# 23 Keep what cannot be recovered
Position: 23
Skill: firefly-docs
Design: DESIGN.md 636-655
## Preconditions
- the "ready" definition settled across three parties
## Accept path
Request: "把 ready 的定义落档"
Expected:
  entry: firefly-docs
  writes: docs/glossary.md;docs/adr/
  terminal: adr-written
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 写本地调查顺手改了主规格
Expected:
  entry: firefly-docs
  writes: none
  terminal: adr-written
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: sync-specs
## Notes
- 调查/ADR 不授权主规格

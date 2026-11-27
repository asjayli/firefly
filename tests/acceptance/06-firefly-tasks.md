# 06 Plan the task groups
Position: 06
Skill: firefly-tasks
Design: DESIGN.md 276-299
## Preconditions
- spec ready with S-001..S-003 and no tasks.md yet
## Accept path
Request: continue from the ready spec
Expected:
  entry: firefly-tasks
  writes: openspec/changes/<id>/tasks.md;Scenario map
  terminal: ready-decision
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 把两条互为因果的行为塞进一个任务组
Expected:
  entry: firefly-tasks
  writes: none
  terminal: ready-decision
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: write-spec;dispatch-implementer
## Notes
- 一组交付一个可独立观察的行为

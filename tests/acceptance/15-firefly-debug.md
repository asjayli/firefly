# 15 Get a distinguishing signal first
Position: 15
Skill: firefly-debug
Design: DESIGN.md 464-483
## Preconditions
- E3 fails intermittently after integration
## Accept path
Request: "查清为什么空文件偶尔出现"
Expected:
  entry: firefly-debug
  writes: tasks.md;Debug note
  terminal: diagnosis-returned
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 15 返回根因后直接转 07 修
Expected:
  entry: firefly-debug
  writes: none
  terminal: diagnosis-returned
  verdict: none
  stops_for_user: no
  next_owner: controller
  must_not: fix-candidate;edit-product-code
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 调查委托返回根因后结束不转 07

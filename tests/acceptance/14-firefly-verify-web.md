# 14 Verify in a fresh session
Position: 14
Skill: firefly-verify-web
Design: DESIGN.md 444-463
## Preconditions
- candidate integrated; browser-visible export flow
## Accept path
Request: continue from the integration
Expected:
  entry: firefly-verify-web
  writes: verification.md;evidence/
  terminal: candidate-integrated
  verdict: none
  stops_for_user: no
  next_owner: none
## Reject path
Counterexample: 页面显示 200 就记 pass 不核对文件内容
Expected:
  entry: firefly-verify-web
  writes: none
  terminal: candidate-integrated
  verdict: none
  stops_for_user: no
  next_owner: none
  must_not: fix-candidate
## Notes
- 期望片段按稳定前缀修订（阶段 14 重放处置）
- 样例行「下载响应 200 当成可用」

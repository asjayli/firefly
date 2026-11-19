/* 组装：base + 各 set 的 skills(键已带 set 前缀) -> __SKILL_PROOF_DATA__ */
(function () {
  var base = window.__SP_BASE__ || {};
  var sets = window.__SP_SETS__ || {};
  var skills = {};
  for (var k in sets) Object.assign(skills, sets[k]);
  base.skills = skills;
  window.__SKILL_PROOF_DATA__ = base;
})();

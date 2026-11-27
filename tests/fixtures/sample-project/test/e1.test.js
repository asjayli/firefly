'use strict';
const test = require("node:test");
const assert = require("node:assert");
const { submitExport, getJob } = require("../src/export-service.js");

test("E1: resending the same intent reuses the job, a new intent gets a new one", () => {
  const query = { includeHeader: true, rows: [{ date: "2026-11-01", amount: "10.00" }] };
  const first = submitExport({ ownerId: "finance-alice", query, intentId: "intent-77" });
  const retry = submitExport({ ownerId: "finance-alice", query, intentId: "intent-77" });
  assert.equal(retry.jobId, first.jobId);
  assert.equal(retry.reused, true);

  const fresh = submitExport({ ownerId: "finance-alice", query, intentId: "intent-78" });
  assert.notEqual(fresh.jobId, first.jobId);
  assert.equal(getJob("finance-alice", first.jobId).status, "processing");
});
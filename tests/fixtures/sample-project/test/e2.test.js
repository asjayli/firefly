'use strict';
const test = require("node:test");
const assert = require("node:assert");
const { submitExport, getJob, download } = require("../src/export-service.js");

test("E2: the owner retrieves the file, another account cannot read it", () => {
  const query = { includeHeader: true, rows: [{ date: "2026-11-02", amount: "20.00" }] };
  const { jobId } = submitExport({ ownerId: "finance-alice", query, intentId: "intent-90" });
  assert.equal(getJob("finance-alice", jobId).jobId, jobId);
  assert.equal(getJob("finance-bob", jobId), null);

  const ownerDownload = download(jobId);
  assert.equal(ownerDownload.httpStatus, 200);
  assert.ok(ownerDownload.body.includes("2026-11-02"));
});
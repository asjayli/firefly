'use strict';
const test = require("node:test");
const assert = require("node:assert");
const { submitExport, download } = require("../src/export-service.js");

test("E3: an empty result set must fail the job, not hand out an empty file", () => {
  const query = { includeHeader: true, rows: [] };
  const { jobId } = submitExport({ ownerId: "finance-alice", query, intentId: "intent-95" });
  const result = download(jobId);
  const dataRows = (result.body || "").split("\n").filter((l) => l.trim() && l !== "date,amount");
  assert.ok(
    result.status !== "ready" || dataRows.length > 0,
    "an empty result set must surface as a failure; a ready job must carry at least one data row",
  );
});
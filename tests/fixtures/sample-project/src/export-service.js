// In-memory job store for the month-end export service.
'use strict';

const jobs = new Map();
let seq = 0;

function submitExport({ ownerId, query, intentId }) {
  for (const job of jobs.values()) {
    if (job.ownerId === ownerId && job.intentId === intentId) {
      return { jobId: job.jobId, reused: true };
    }
  }
  const jobId = `job-${String(++seq).padStart(3, "0")}`;
  jobs.set(jobId, {
    jobId,
    ownerId,
    query,
    intentId,
    status: "processing",
    result: null,
    createdAt: Date.now(),
  });
  return { jobId, reused: false };
}

function getJob(ownerId, jobId) {
  const job = jobs.get(jobId);
  if (!job || job.ownerId !== ownerId) return null;
  return { jobId: job.jobId, status: job.status };
}

function download(jobId) {
  const job = jobs.get(jobId);
  if (!job) return { status: "missing", httpStatus: 404 };
  // Generating the CSV from the query.
  const csv = job.query.includeHeader ? "date,amount" : "";
  const body = [csv, ...job.query.rows.map((r) => `${r.date},${r.amount}`)].join("\n");
  // KNOWN DEFECT: an empty result set still marks the job ready and returns
  // a 200 with an empty (or header-only) file instead of a failure status.
  job.status = "ready";
  return { status: "ready", httpStatus: 200, body };
}

module.exports = { submitExport, getJob, download, _jobs: jobs };
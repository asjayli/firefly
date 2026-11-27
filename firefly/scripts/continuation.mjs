import fs from 'node:fs';

function hasText(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function validateStatus(entry, allowed, label) {
  if (!allowed.includes(entry?.status)) throw new Error(`Invalid status for ${label}`);
  if (['verified', 'waiting'].includes(entry.status) && !hasText(entry.evidence)) {
    throw new Error(`Missing evidence reference for ${label}`);
  }
  if (entry.status === 'blocked' && (!hasText(entry.reason) || !hasText(entry.owner))) {
    throw new Error(`Missing blocker reason or owner for ${label}`);
  }
}

function decideFinish({ required, conditions, workReady, dispatches }) {
  if (!Array.isArray(required) || required.length === 0 ||
      !required.every(id => typeof id === 'string' && /^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(id))) {
    throw new Error('Expected nonempty required condition IDs');
  }
  const requiredIds = new Set(required);
  if (requiredIds.size !== required.length) throw new Error('Duplicate required condition ID');
  if (!Array.isArray(conditions) || typeof workReady !== 'boolean') {
    throw new Error('Expected conditions and a workReady boolean');
  }
  validateStatus(dispatches, ['clear', 'waiting', 'blocked'], 'dispatches');

  const statuses = new Map();
  for (const condition of conditions) {
    const id = condition?.id;
    if (!requiredIds.has(id)) throw new Error(`Unknown condition ID: ${id}`);
    if (statuses.has(id)) throw new Error(`Duplicate condition ID: ${id}`);
    validateStatus(condition, ['ready', 'waiting', 'blocked', 'verified'], id);
    statuses.set(id, condition.status);
  }

  const conditionStatuses = new Set(statuses.values());
  if (workReady || conditionStatuses.has('ready')) return 'continue-work';
  if (statuses.size !== requiredIds.size) return 'reconcile-conditions';
  if (dispatches.status === 'waiting' || conditionStatuses.has('waiting')) return 'wait';
  if (dispatches.status === 'blocked' || conditionStatuses.has('blocked')) return 'escalate';
  return 'complete';
}

function decide(input) {
  if (input.kind === 'finish') return decideFinish(input);
  if (input.kind === 'dispatch') {
    const { host, savedReturn, obsolete, cancelSupported } = input;
    if (!['active', 'finished', 'unknown'].includes(host)) throw new Error('Invalid host status');
    if (host === 'active') return obsolete && cancelSupported ? 'cancel-and-wait' : 'wait';
    if (obsolete) return host === 'finished' ? 'close-obsolete' : 'reconcile';
    if (savedReturn) return 'collect-return';
    return host === 'finished' ? 'record-failure' : 'reconcile';
  }
  if (input.kind === 'recheck') {
    if (typeof input.key !== 'string' || !input.key || !Array.isArray(input.attempts) ||
        !['answers', 'missing'].includes(input.evidence)) throw new Error('Invalid recheck inputs');
    if (input.evidence === 'answers') return 'decide-from-evidence';
    return input.attempts.includes(input.key) ? 'escalate' : 'rerun';
  }
  if (input.kind === 'blocked-path') {
    const { alternativeReady, independentReady } = input;
    if (typeof alternativeReady !== 'boolean' || typeof independentReady !== 'boolean') {
      throw new Error('Expected booleans for ready alternatives and independent work');
    }
    if (independentReady) return 'continue-independent';
    if (alternativeReady) return 'try-alternative';
    return 'escalate';
  }
  throw new Error('Expected finish, dispatch, recheck or blocked-path inputs');
}

try {
  console.log(decide(JSON.parse(fs.readFileSync(0, 'utf8'))));
} catch (error) {
  console.error(`firefly continuation: ${error.message}`);
  process.exitCode = 1;
}

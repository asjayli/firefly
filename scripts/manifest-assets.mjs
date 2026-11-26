#!/usr/bin/env node
// firefly manifest asset lister.
//
// Reads a platform manifest (manifests/claude.json or manifests/codex.json)
// and prints its managed assets as TAB-separated lines for shell consumption:
//
//   kind<TAB>source<TAB>target
//
// Resolution rules:
//   - `source` is repo-relative in the manifest and resolves against the repo
//     root (the parent of the manifest's manifests/ directory).
//   - `target` placeholders resolve from the environment:
//       ~/.claude                  -> $CLAUDE_HOME (default $HOME/.claude)
//       ~/.codex                   -> $CODEX_HOME (default $HOME/.codex)
//       ~/.local/bin               -> $FIREFLY_BIN_DIR (default $HOME/.local/bin)
//       <openspec-root>            -> $FIREFLY_OPENSPEC_ROOT (required)
//       <claude-superpowers-root>  -> $FIREFLY_SUPERPOWERS_ROOT (required)
//   - `source-mirror` entries carry a `paths` array and expand to one line per
//     mirrored path: <repo-root>/<path> -> <target>/<path>.
//   - `skill-directory`, `command-directory` and `reference-directory` entries
//     are validated the same way: `source` must resolve to an existing
//     directory, since installers and doctors copy or compare it as a whole.
//   - before emit: an expanded `target` must land inside a managed root (see
//     allowedTargetRoots), and a resolved `source` (or a `source-mirror` path)
//     must stay inside the repo root, so no manifest entry can point a copy
//     at an unregistered location or at files outside the repository.
//     Retired entries are exempt: firefly-retired.sh expands their
//     `<claude-superpowers-root>` against a dummy root when no superpowers
//     installation exists, and retired writes are guarded by pinned hashes
//     and backups instead.
//
// Usage: manifest-assets.mjs <manifest-path> [--kinds kind1,kind2,...] [--retired]
//
// Entries are emitted in manifest file order; --kinds only filters.

import fs from 'node:fs';
import path from 'node:path';

// Directory-valued kinds share one validation rule (see the header comment).
const DIRECTORY_KINDS = new Set(['skill-directory', 'command-directory', 'reference-directory']);

// Exit quietly when the consumer closes the pipe early (e.g. `| head`).
process.stdout.on('error', (error) => {
  if (error.code === 'EPIPE') process.exit(0);
  throw error;
});

function fail(message) {
  console.error(`manifest-assets: ${message}`);
  process.exit(1);
}

function parseArgs(argv) {
  const args = { kinds: null, manifest: null, retired: false };
  const rest = [...argv];
  while (rest.length > 0) {
    const arg = rest.shift();
    if (arg === '--retired') {
      args.retired = true;
    } else if (arg === '--kinds') {
      const value = rest.shift();
      if (value === undefined) fail('--kinds requires a comma-separated value');
      args.kinds = new Set(value.split(',').filter(Boolean));
    } else if (arg === '--help' || arg === '-h') {
      console.log('usage: manifest-assets.mjs <manifest-path> [--kinds kind1,kind2,...]');
      process.exit(0);
    } else if (arg.startsWith('--')) {
      fail(`unknown option: ${arg}`);
    } else if (args.manifest === null) {
      args.manifest = arg;
    } else {
      fail(`unexpected argument: ${arg}`);
    }
  }
  if (args.manifest === null) fail('missing manifest path');
  return args;
}

function homePath() {
  const home = process.env.HOME;
  if (!home) fail('HOME is not set');
  return home;
}

// The roots a managed target may land in after expansion: the two platform
// homes (CLAUDE_HOME / CODEX_HOME or their defaults below $HOME), the global
// bin directory, the two placeholder roots when they are set, and $HOME
// itself for a target spelled `~/...`.
function allowedTargetRoots() {
  const home = homePath();
  const roots = [
    process.env.CLAUDE_HOME || path.join(home, '.claude'),
    process.env.CODEX_HOME || path.join(home, '.codex'),
    process.env.FIREFLY_BIN_DIR || path.join(home, '.local/bin'),
  ];
  if (process.env.FIREFLY_OPENSPEC_ROOT) roots.push(process.env.FIREFLY_OPENSPEC_ROOT);
  if (process.env.FIREFLY_SUPERPOWERS_ROOT) roots.push(process.env.FIREFLY_SUPERPOWERS_ROOT);
  roots.push(home);
  return roots;
}

function isWithin(base, candidate) {
  return candidate === base || candidate.startsWith(base + path.sep);
}

// validateTarget <entryId> <original> <expanded> — the expanded target must be
// an absolute path inside one of the managed roots.
function validateTarget(entryId, original, expanded) {
  if (!path.isAbsolute(expanded)) {
    fail(`entry ${entryId} target is not an absolute path after expansion: ${original}`);
  }
  for (const root of allowedTargetRoots()) {
    if (isWithin(root, expanded)) return;
  }
  fail(`entry ${entryId} target is outside every managed root: ${original}`);
}

// validateSource <entryId> <sourcePath> <repoRoot> — the resolved source must
// stay inside the repo root, so no `..` segment or absolute path escapes it.
function validateSource(entryId, sourcePath, repoRoot) {
  if (!isWithin(repoRoot, sourcePath)) {
    fail(`entry ${entryId} source escapes the repository root: ${sourcePath}`);
  }
}

function expandTarget(original) {
  let target = original;
  if (target.includes('<openspec-root>')) {
    const root = process.env.FIREFLY_OPENSPEC_ROOT;
    if (!root) fail('FIREFLY_OPENSPEC_ROOT is required to resolve <openspec-root> targets');
    target = target.split('<openspec-root>').join(root);
  }
  if (target.includes('<claude-superpowers-root>')) {
    const root = process.env.FIREFLY_SUPERPOWERS_ROOT;
    if (!root) fail('FIREFLY_SUPERPOWERS_ROOT is required to resolve <claude-superpowers-root> targets');
    target = target.split('<claude-superpowers-root>').join(root);
  }
  const homeRoots = [
    ['~/.claude', process.env.CLAUDE_HOME],
    ['~/.codex', process.env.CODEX_HOME],
    ['~/.local/bin', process.env.FIREFLY_BIN_DIR],
  ];
  for (const [prefix, override] of homeRoots) {
    if (target === prefix || target.startsWith(`${prefix}/`)) {
      const base = override || path.join(homePath(), prefix.slice(2));
      return base + target.slice(prefix.length);
    }
  }
  if (target.startsWith('~/')) return path.join(homePath(), target.slice(2));
  return target;
}

function emit(kind, source, target) {
  for (const field of [kind, source, target]) {
    if (/[\t\n]/.test(field)) fail(`refusing to emit field containing TAB or newline: ${field}`);
  }
  process.stdout.write(`${kind}\t${source}\t${target}\n`);
}

function validateRetired(manifest, manifestPath) {
  const retired = manifest.retiredAssets || [];
  for (const entry of retired) {
    const where = 'retiredAssets entry ' + JSON.stringify(entry && entry.id) + ' in ' + manifestPath;
    if (!entry || typeof entry.id !== 'string' || typeof entry.since !== 'string'
      || typeof entry.handling !== 'string' || typeof entry.target !== 'string') {
      fail(where + ' is missing a string id/since/handling/target');
    }
    if (entry.handling !== 'remove-with-backup' && entry.handling !== 'overlay-leftover') {
      fail(where + ' has an unknown handling: ' + entry.handling);
    }
    if (!Array.isArray(entry.files) || entry.files.length === 0) {
      fail(where + ' needs a non-empty files array');
    }
    for (const file of entry.files) {
      if (!file || typeof file.path !== 'string' || !Array.isArray(file.sha256) || file.sha256.length === 0) {
        fail(where + ' has a file entry without a string path or a non-empty sha256 array');
      }
      for (const hash of file.sha256) {
        if (!/^[0-9a-f]{64}$/.test(hash)) {
          fail(where + ' has a malformed sha256 (expected 64 hex chars): ' + hash);
        }
      }
    }
  }
}

function emitRetired(manifest, manifestPath) {
  validateRetired(manifest, manifestPath);
  for (const entry of manifest.retiredAssets || []) {
    const targetBase = expandTarget(entry.target);
    for (const file of entry.files) {
      const line = entry.handling + '\t' + path.join(targetBase, file.path) + '\t' + file.sha256.join(',');
      process.stdout.write(line + '\n');
    }
  }
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const manifestPath = path.resolve(args.manifest);
  const repoRoot = path.dirname(path.dirname(manifestPath));

  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  } catch (error) {
    fail(`cannot read manifest ${manifestPath}: ${error.message}`);
  }
  if (!Number.isInteger(manifest.version) || !Array.isArray(manifest.managedAssets)) {
    fail(`manifest ${manifestPath} is missing an integer version or a managedAssets array`);
  }

  if (args.retired) {
    emitRetired(manifest, manifestPath);
    return;
  }

  for (const entry of manifest.managedAssets) {
    if (!entry || typeof entry.id !== 'string' || typeof entry.kind !== 'string' || typeof entry.target !== 'string') {
      fail(`manifest ${manifestPath} has a managedAssets entry without id/kind/target`);
    }
    if (args.kinds && !args.kinds.has(entry.kind)) continue;

    if (entry.kind === 'source-mirror') {
      if (!Array.isArray(entry.paths) || entry.paths.length === 0) {
        fail(`source-mirror entry ${entry.id} needs a non-empty paths array`);
      }
      const targetBase = expandTarget(entry.target);
      validateTarget(entry.id, entry.target, targetBase);
      for (const rel of entry.paths) {
        const sourcePath = path.join(repoRoot, rel);
        validateSource(entry.id, sourcePath, repoRoot);
        emit(entry.kind, sourcePath, path.join(targetBase, rel));
      }
      continue;
    }

    if (typeof entry.source !== 'string') {
      fail(`entry ${entry.id} is missing a source`);
    }
    const sourcePath = path.resolve(repoRoot, entry.source);
    validateSource(entry.id, sourcePath, repoRoot);
    if (DIRECTORY_KINDS.has(entry.kind)) {
      if (!fs.existsSync(sourcePath) || !fs.statSync(sourcePath).isDirectory()) {
        fail(`${entry.kind} entry ${entry.id} source is not an existing directory: ${entry.source}`);
      }
    }
    const targetPath = expandTarget(entry.target);
    validateTarget(entry.id, entry.target, targetPath);
    emit(entry.kind, sourcePath, targetPath);
  }
}

main();

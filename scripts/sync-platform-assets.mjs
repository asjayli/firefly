#!/usr/bin/env node
// firefly platform-asset generator.
//
// assets/shared/ is the single hand-edited source for managed assets that are
// identical across Codex/Claude or differ only by enumerable platform tokens.
// This script:
//   - renders shared/ into assets/codex/ and assets/claude/ by substituting
//     tokens (default invocation);
//   - verifies the rendered output matches the tracked platform directories
//     (--check), reporting MISS/DRIFT and enforcing shared semantics;
//   - bootstraps shared/ from a Codex copy by reverse-substituting tokens
//     (--init-shared), used once when migrating an asset into shared/.
//
// Platform-specific assets (platformSpecific in the manifest) are never
// rendered here; they stay hand-maintained per platform, but their declared
// shared semantics are still verified so non-platform meaning cannot drift.
//
// Completeness assertions (--check only). Rendering walks the `shared` array,
// so a hand-edited directory that nobody registered would be skipped silently
// and a registered path whose source was removed would vanish just as quietly.
// --check therefore also reports:
//   UNREGISTERED   a source under assets/shared/skills/*,
//                  assets/shared/superpowers/skills/* or the directory
//                  assets/shared/references that the `shared` array omits;
//   MISSING-SOURCE a `shared` entry whose source directory does not exist.
// Either one is drift and fails the check, like MISS/DRIFT/SEMANTICS-DRIFT.

import fs from 'node:fs';
import path from 'node:path';

const ROOT = path.join(import.meta.dirname, '..');
const ASSETS = path.join(ROOT, 'assets');
const MANIFEST = path.join(ROOT, 'manifests', 'platform-assets.json');
const PLATFORMS = ['codex', 'claude'];
// Hand-edited scopes under assets/shared/: each child directory of `children`
// scopes and the `itself` scope as a whole must appear in the `shared` array.
const SHARED_SCOPES = {
  children: ['skills', 'superpowers/skills'],
  itself: ['references'],
};

const config = JSON.parse(fs.readFileSync(MANIFEST, 'utf8'));

function listFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...listFiles(full));
    else out.push(full);
  }
  return out;
}

function renderText(text, platform) {
  for (const [token, vals] of Object.entries(config.tokens)) {
    text = text.split(token).join(vals[platform]);
  }
  return text;
}

function sharedRels() {
  return config.shared;
}

// Report sources under assets/shared/ that the `shared` array does not cover,
// and registered entries whose source is gone. Returns true on any finding.
function checkCompleteness() {
  let drift = false;
  const registered = new Set(sharedRels());
  const sharedRoot = path.join(ASSETS, 'shared');

  for (const rel of registered) {
    if (!fs.existsSync(path.join(sharedRoot, rel))) {
      console.error(`MISSING-SOURCE assets/shared/${rel}`);
      drift = true;
    }
  }

  const scopes = [];
  for (const scope of SHARED_SCOPES.children) {
    const dir = path.join(sharedRoot, scope);
    if (!fs.existsSync(dir)) continue;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (entry.isDirectory()) scopes.push(`${scope}/${entry.name}`);
    }
  }
  scopes.push(...SHARED_SCOPES.itself);

  for (const rel of scopes) {
    if (!registered.has(rel) && fs.existsSync(path.join(sharedRoot, rel))) {
      console.error(`UNREGISTERED assets/shared/${rel}`);
      drift = true;
    }
  }
  return drift;
}

function renderAll() {
  for (const platform of PLATFORMS) {
    for (const rel of sharedRels()) {
      const srcDir = path.join(ASSETS, 'shared', rel);
      for (const file of listFiles(srcDir)) {
        const relFile = path.relative(srcDir, file);
        const rendered = renderText(fs.readFileSync(file, 'utf8'), platform);
        const out = path.join(ASSETS, platform, rel, relFile);
        fs.mkdirSync(path.dirname(out), { recursive: true });
        fs.writeFileSync(out, rendered);
      }
    }
  }
  console.log('Rendered shared assets to assets/codex and assets/claude');
}

function checkShared() {
  let drift = false;
  for (const platform of PLATFORMS) {
    for (const rel of sharedRels()) {
      const srcDir = path.join(ASSETS, 'shared', rel);
      for (const file of listFiles(srcDir)) {
        const relFile = path.relative(srcDir, file);
        const rendered = renderText(fs.readFileSync(file, 'utf8'), platform);
        const dst = path.join(ASSETS, platform, rel, relFile);
        if (!fs.existsSync(dst)) {
          console.error(`MISS ${dst}`);
          drift = true;
          continue;
        }
        if (fs.readFileSync(dst, 'utf8') !== rendered) {
          console.error(`DRIFT ${dst}`);
          drift = true;
        }
      }
    }
  }
  return drift;
}

function checkSemantics() {
  let drift = false;
  const expected = config.sharedSemantics?.generatedBy;
  const appliesTo = config.sharedSemantics?.appliesTo || [];
  if (!expected) return false;
  for (const platform of PLATFORMS) {
    for (const skill of appliesTo) {
      const file = path.join(ASSETS, platform, skill, 'SKILL.md');
      if (!fs.existsSync(file)) continue;
      const match = fs.readFileSync(file, 'utf8').match(/generatedBy:\s*"([^"]+)"/);
      const actual = match ? match[1] : '<none>';
      if (actual !== expected) {
        console.error(`SEMANTICS-DRIFT ${platform}/${skill}: generatedBy expected ${expected}, got ${actual}`);
        drift = true;
      }
    }
  }
  return drift;
}

function initShared() {
  // Reverse-tokenize: replace Codex literal values with tokens, longest first
  // so a substring like "$HOME/.codex" inside "${CODEX_HOME:-$HOME/.codex}"
  // is not partially tokenized before its enclosing form.
  const entries = Object.entries(config.tokens).sort(
    (a, b) => b[1].codex.length - a[1].codex.length,
  );
  let changed = 0;
  for (const rel of sharedRels()) {
    const srcDir = path.join(ASSETS, 'shared', rel);
    for (const file of listFiles(srcDir)) {
      const before = fs.readFileSync(file, 'utf8');
      let after = before;
      for (const [token, vals] of entries) {
        after = after.split(vals.codex).join(token);
      }
      if (after !== before) {
        fs.writeFileSync(file, after);
        changed += 1;
      }
    }
  }
  console.log(`Reverse-tokenized ${changed} shared file(s)`);
}

function main() {
  const cmd = process.argv[2];
  if (cmd === '--init-shared') {
    initShared();
    return;
  }
  if (cmd === '--check') {
    // Completeness runs on its own so an unregistered or missing source never
    // masks the MISS/DRIFT/SEMANTICS-DRIFT findings below it.
    const incomplete = checkCompleteness();
    const drift = checkShared() || checkSemantics();
    if (incomplete || drift) {
      console.error('Platform assets out of sync');
      process.exit(1);
    }
    console.log('Platform assets in sync');
    return;
  }
  if (cmd !== undefined) {
    console.error(`unknown command: ${cmd}`);
    console.error('usage: sync-platform-assets.mjs [--check|--init-shared]');
    process.exit(1);
  }
  renderAll();
}

main();

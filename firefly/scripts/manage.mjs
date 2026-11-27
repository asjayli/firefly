import fs from 'node:fs';
import path from 'node:path';
import { isDeepStrictEqual } from 'node:util';
import { directories, entries, inventory, stat, verifyBundle, within } from './bundle.mjs';

const baselineName = '.firefly-baseline';
const receiptName = '.firefly-install.json';
const storedName = entry => entry === 'SKILL.md' ? 'entrypoint.md' : entry;
const sourceRoot = process.argv[2];

function usage() {
  console.log('Usage: manage.sh install --skills-dir DIR [--bin-dir DIR] [--references-dir DIR] [--scripts-dir DIR]');
  console.log('       manage.sh doctor|repair [--skills-dir DIR]');
}

function parse(args, allowed) {
  const options = new Map();
  for (let index = 0; index < args.length; index += 2) {
    const [name, value] = args.slice(index, index + 2);
    if (!allowed.includes(name) || options.has(name) || !value || value.startsWith('--') || /[\r\n]/.test(value)) {
      throw new Error(`Invalid argument: ${name}`);
    }
    options.set(name, path.resolve(value));
  }
  return options;
}

// A configured link may be dangling during installation or repair.
function physical(file, depth = 0) {
  if (depth > 40) throw new Error(`Too many symbolic links: ${file}`);
  const info = stat(file);
  if (info?.isSymbolicLink()) {
    return physical(path.resolve(path.dirname(file), fs.readlinkSync(file)), depth + 1);
  }
  if (info) return fs.realpathSync(file);
  return path.join(physical(path.dirname(file), depth), path.basename(file));
}

function receipt(root) {
  const file = path.join(root, receiptName);
  const info = stat(file);
  if (!info) return null;
  if (!info.isFile()) throw new Error(`Invalid installation receipt: ${file}`);
  const record = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (record?.version !== 1 || !Array.isArray(record.inventory) ||
      record.inventory.length !== entries.length ||
      !record.links || typeof record.links !== 'object' || Array.isArray(record.links) ||
      Object.entries(record.links).some(([name, target]) =>
        !directories.includes(name) || typeof target !== 'string' || !path.isAbsolute(target))) {
    throw new Error(`Invalid installation receipt: ${file}`);
  }
  return record;
}

function overlap(a, b) {
  return within(a, b) || within(b, a);
}

function entryTargets(root, links, protectedTargets = []) {
  const used = [root, ...protectedTargets];
  if (root !== sourceRoot) used.push(sourceRoot);
  return entries.map(entry => {
    const name = path.join(root, entry);
    const linked = Boolean(stat(name)?.isSymbolicLink());
    const trusted = links[entry];
    if (linked !== Boolean(trusted)) throw new Error(`Unexpected link configuration: ${name}`);
    if (!linked) return name;
    const target = physical(name);
    if (target !== trusted || used.some(other => overlap(other, target))) {
      throw new Error(`Link target is outside its recorded installation scope: ${name}`);
    }
    const info = stat(target);
    if (info && !info.isDirectory()) throw new Error(`Link target must be a directory: ${target}`);
    used.push(target);
    return target;
  });
}

function knownBaseline(root, record) {
  const baseline = path.join(root, baselineName);
  if (!stat(baseline)?.isDirectory()) throw new Error(`Repair baseline is missing or invalid: ${baseline}`);
  verifyBundle(baseline, storedName('SKILL.md'));
  const current = entries.map(entry => inventory(baseline, storedName(entry), entry));
  if (!isDeepStrictEqual(current, record.inventory)) {
    throw new Error(`Repair baseline differs from its inventory: ${baseline}`);
  }
  return baseline;
}

// Prepare every replacement before moving a live asset. Retain displaced
// assets on success and restore them in reverse order on a failed commit.
function transact(changes) {
  const staged = [];
  const madeDirectories = [];
  let committed = false;
  function ensureDirectory(directory) {
    if (stat(directory)) return;
    ensureDirectory(path.dirname(directory));
    fs.mkdirSync(directory);
    madeDirectories.push(directory);
  }
  try {
    for (const change of changes) {
      const parent = path.dirname(change.target);
      ensureDirectory(parent);
      const stage = fs.mkdtempSync(path.join(parent, '.firefly-backup.'));
      const step = { ...change, stage, original: stat(change.target), moved: false, applied: false };
      staged.push(step);
      if (change.prepare) change.prepare(path.join(stage, 'replacement'));
    }
    for (const step of staged) {
      const current = stat(step.target);
      if (Boolean(current) !== Boolean(step.original) ||
          (current && (current.dev !== step.original.dev || current.ino !== step.original.ino))) {
        throw new Error(`Destination changed during preparation: ${step.target}`);
      }
      if (step.link) {
        fs.symlinkSync(step.link, step.target);
      } else {
        if (current) {
          fs.renameSync(step.target, path.join(step.stage, 'previous'));
          step.moved = true;
        }
        fs.renameSync(path.join(step.stage, 'replacement'), step.target);
      }
      step.applied = true;
    }
    committed = true;
  } finally {
    if (!committed) {
      for (const step of [...staged].reverse()) {
        try {
          if (step.applied) fs.renameSync(step.target, path.join(step.stage, 'failed-replacement'));
          if (step.moved) fs.renameSync(path.join(step.stage, 'previous'), step.target);
        } catch (error) {
          console.error(`Rollback failed for ${step.target}: ${error.message}. Recovery directory: ${step.stage}`);
        }
      }
    }
    for (const step of staged) {
      const previous = path.join(step.stage, 'previous');
      if (stat(previous)) console.log(`Backup ${step.target} -> ${previous}`);
      else fs.rmSync(step.stage, { recursive: true, force: true });
    }
    if (!committed) {
      for (const directory of madeDirectories.reverse()) {
        try { fs.rmdirSync(directory); } catch { /* Still in use. */ }
      }
    }
  }
}

function copy(target, source) {
  return {
    target,
    prepare(destination) {
      fs.cpSync(source, destination, { recursive: true, errorOnExist: true, force: false });
    },
  };
}

function matchesInventory(target, entry, expected) {
  try {
    return isDeepStrictEqual(inventory(path.dirname(target), path.basename(target), entry), expected);
  } catch {
    return false;
  }
}

function install(options) {
  const skills = options.get('--skills-dir');
  if (!skills) throw new Error('--skills-dir is required');
  const discovery = path.join(skills, 'firefly');
  const root = physical(discovery);
  if (overlap(root, sourceRoot) || root === path.parse(root).root) {
    throw new Error(`Install destination overlaps source or filesystem root: ${root}`);
  }
  const directory = stat(root);
  const previous = directory?.isDirectory() ? receipt(root) : null;
  if (directory && (!directory.isDirectory() || (!previous && fs.readdirSync(root).length !== 0))) {
    throw new Error(`Destination already exists and is not a managed installation: ${root}`);
  }
  const links = { ...previous?.links };
  for (const entry of directories) {
    const configured = options.get(`--${entry}-dir`);
    if (configured) links[entry] = physical(configured);
  }
  const targets = entryTargets(root, links, [physical(skills)]);
  verifyBundle(sourceRoot);
  const contents = entries.map(entry => inventory(sourceRoot, entry));
  let previousBaselineValid = false;
  if (previous) {
    try {
      knownBaseline(root, previous);
      previousBaselineValid = true;
    } catch (error) {
      console.error(`Rebuilding installed baseline from the verified source: ${error.message}`);
    }
  }
  const changes = entries.flatMap((entry, index) =>
    matchesInventory(targets[index], entry, contents[index]) ? [] : [copy(targets[index], path.join(sourceRoot, entry))]);
  if (!previousBaselineValid || !isDeepStrictEqual(previous?.inventory, contents)) {
    changes.push({
      target: path.join(root, baselineName),
      prepare(destination) {
        fs.mkdirSync(destination);
        for (const entry of entries) {
          fs.cpSync(path.join(sourceRoot, entry), path.join(destination, storedName(entry)), { recursive: true });
        }
        verifyBundle(destination, storedName('SKILL.md'));
      },
    });
  }
  const next = { version: 1, links, inventory: contents };
  if (!isDeepStrictEqual(previous, next)) {
    changes.push({
      target: path.join(root, receiptName),
      prepare(destination) {
        fs.writeFileSync(destination, JSON.stringify(next, null, 2) + '\n');
      },
    });
  }
  const bin = options.get('--bin-dir');
  if (bin) {
    const command = path.join(physical(bin), 'firefly');
    const launcher = path.join(discovery, 'scripts', 'firefly.sh');
    if ([root, sourceRoot, ...targets].some(target => overlap(target, command))) {
      throw new Error('Command path overlaps the source or installed skill');
    }
    const existing = stat(command);
    if (existing) {
      if (!existing.isSymbolicLink() || path.resolve(path.dirname(command), fs.readlinkSync(command)) !== launcher) {
        throw new Error(`Command already exists: ${command}`);
      }
    } else {
      changes.push({ target: command, link: launcher });
    }
  }
  transact(changes);
  console.log(`Installed firefly: ${discovery}`);
}

function check(mode, options) {
  const skillDir = options.get('--skill-dir');
  const skillsDir = options.get('--skills-dir');
  if (skillDir && skillsDir) throw new Error('Choose one skill location');
  const discovery = skillsDir ? path.join(skillsDir, 'firefly') : skillDir ?? sourceRoot;
  const root = physical(discovery);
  const record = receipt(root);
  if (!record) {
    if (mode === 'repair' || skillDir || skillsDir || stat(path.join(root, baselineName))) {
      throw new Error(`Installation receipt is missing: ${root}`);
    }
    verifyBundle(root);
    console.log(`OK ${root} (package structure checked)`);
    return;
  }
  const baseline = knownBaseline(root, record);
  const targets = entryTargets(root, record.links);
  const changes = [];
  for (const [index, entry] of entries.entries()) {
    const target = targets[index];
    const name = storedName(entry);
    const info = stat(target);
    const matches = Boolean(info) && matchesInventory(target, entry, record.inventory[index]);
    console.log(`${matches ? 'OK' : info ? 'DRIFT' : 'MISS'} ${entry}`);
    if (!matches) changes.push(copy(target, path.join(baseline, name)));
  }
  if (mode === 'repair') transact(changes);
  else if (changes.length) process.exitCode = 1;
}

try {
  const [mode, ...args] = process.argv.slice(3);
  if (mode === '--help' || mode === '-h' || args.length === 1 && args[0] === '--help') {
    usage();
  } else if (mode === 'install') {
    install(parse(args, ['--skills-dir', '--bin-dir', '--references-dir', '--scripts-dir']));
  } else if (mode === 'doctor' || mode === 'repair') {
    check(mode, parse(args, ['--skills-dir', '--skill-dir']));
  } else {
    usage();
    process.exitCode = 1;
  }
} catch (error) {
  console.error(`firefly: ${error.message}`);
  process.exitCode = 1;
}

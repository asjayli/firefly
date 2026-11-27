import fs from 'node:fs';
import path from 'node:path';
import { stat } from './bundle.mjs';

const references = path.join(process.argv[2], 'references');
const tiers = new Set(['cheap', 'standard', 'top']);

function readJson(file) {
  if (!stat(file)?.isFile()) throw new Error(`Expected a regular file: ${file}`);
  const result = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!result || typeof result !== 'object' || Array.isArray(result)) throw new Error(`Expected a JSON object: ${file}`);
  return result;
}

function headings(markdown) {
  const titles = new Set();
  let fence;
  for (const line of markdown.split(/\r?\n/)) {
    const marker = /^ {0,3}(`{3,}|~{3,})(.*)$/.exec(line);
    if (marker) {
      if (!fence) fence = marker[1];
      else if (marker[1][0] === fence[0] && marker[1].length >= fence.length && !marker[2].trim()) fence = undefined;
    } else if (!fence) {
      const heading = /^#{2,6}\s+(.+?)\s*$/.exec(line);
      if (heading) titles.add(heading[1]);
    }
  }
  return titles;
}

function loadPlaybook(file, guides) {
  if (!stat(file)?.isFile()) throw new Error(`Expected a regular playbook: ${file}`);
  const text = fs.readFileSync(file, 'utf8');
  const match = /^---\r?\nextends: (firefly-[\w-]+)\r?\nanchor: (.+)\r?\n---\r?\n([\s\S]+)$/.exec(text);
  if (!match || !match[3].trim()) throw new Error(`Invalid playbook header or empty body: ${file}`);
  const [, guide, anchor] = match;
  if (!guides.has(guide)) {
    const guideFile = path.join(references, 'abilities', guide, 'guide.md');
    guides.set(guide, stat(guideFile)?.isFile() ? headings(fs.readFileSync(guideFile, 'utf8')) : new Set());
  }
  if (!guides.get(guide).has(anchor)) throw new Error(`Unknown playbook anchor ${guide} / ${anchor}: ${file}`);
  return { file, guide, anchor };
}

function main(args) {
  if (args.length && (args.length !== 2 || args[0] !== '--root' || !args[1])) {
    throw new Error('Usage: firefly config [--root PROJECT]');
  }
  const folder = path.join(path.resolve(args[1] ?? process.cwd()), '.firefly');
  const configDir = stat(folder);
  if (configDir && !configDir.isDirectory()) throw new Error(`Expected a project configuration directory: ${folder}`);
  const models = readJson(path.join(references, 'model-policy.json'));
  const modelFile = path.join(folder, 'models.json');
  const overrides = stat(modelFile) ? readJson(modelFile) : {};
  for (const [role, tier] of [...Object.entries(models), ...Object.entries(overrides)]) {
    if (!Object.hasOwn(models, role) || !tiers.has(tier)) throw new Error(`Unsupported model policy: ${role} = ${tier}`);
  }
  const playbookDir = path.join(folder, 'playbooks');
  const playbooks = [];
  const guides = new Map();
  const playbookInfo = stat(playbookDir);
  if (playbookInfo) {
    if (!playbookInfo.isDirectory()) throw new Error(`Expected a playbook directory: ${playbookDir}`);
    for (const name of fs.readdirSync(playbookDir).sort()) {
      if (name.endsWith('.md')) playbooks.push(loadPlaybook(path.join(playbookDir, name), guides));
    }
  }
  console.log(JSON.stringify({ models: { ...models, ...overrides }, playbooks }, null, 2));
}

try {
  main(process.argv.slice(3));
} catch (error) {
  console.error(`firefly config: ${error.message}`);
  process.exitCode = 1;
}

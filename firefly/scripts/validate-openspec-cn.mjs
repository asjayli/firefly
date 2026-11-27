#!/usr/bin/env node
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';

const ENGLISH_MODAL_PATTERN = /\b(?:SHALL|MUST)\b/;
const CHINESE_MODAL_PATTERN = /必须|不得|禁止|应当/;
const REQUIREMENT_HEADER_PATTERN = /^###\s+Requirement:\s*(.+)\s*$/i;
const SCENARIO_HEADER_PATTERN = /^####\s+/;
const METADATA_PATTERN = /^\*\*[^*]+\*\*:/;
const UNSUPPORTED_CHINESE_STRUCTURE = [
  { pattern: /^##\s+需求\s*$/, name: '## 需求' },
  { pattern: /^###\s+需求\s*:/, name: '### 需求:' },
  { pattern: /^####\s+场景\s*:/, name: '#### 场景:' },
];

function parseOptions(args) {
  let root;
  let change;
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === '--root' && root === undefined && args[i + 1] && !args[i + 1].startsWith('-')) {
      root = args[++i];
    } else if (change === undefined && /^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(arg) && arg !== 'archive') {
      change = arg;
    } else {
      throw new Error(`无效参数：${arg}。请运行 firefly validate --help。`);
    }
  }
  return { root: path.resolve(root ?? '.'), change };
}

function specFiles(directory) {
  if (!fs.existsSync(directory)) return [];
  return fs.readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    const filePath = path.join(directory, entry.name);
    if (entry.isDirectory()) return specFiles(filePath);
    return entry.name === 'spec.md' ? [filePath] : [];
  });
}

function sectionEnd(lines, start) {
  for (let index = start + 1; index < lines.length; index += 1) {
    if (/^##\s+/.test(lines[index])) return index;
  }
  return lines.length;
}

function sectionRanges(lines, mainSpec) {
  if (mainSpec) {
    const start = lines.findIndex(line => /^##\s+Requirements\s*$/i.test(line));
    return start < 0 ? [] : [{ start, end: sectionEnd(lines, start) }];
  }
  const ranges = [];
  for (let index = 0; index < lines.length; index += 1) {
    if (/^##\s+(?:ADDED|MODIFIED)\s+Requirements\s*$/i.test(lines[index])) {
      ranges.push({ start: index, end: sectionEnd(lines, index) });
    }
  }
  return ranges;
}

function findRequirementBody(lines, headerIndex, end) {
  const body = [];
  for (let index = headerIndex + 1; index < end; index += 1) {
    const text = lines[index].trim();
    if (SCENARIO_HEADER_PATTERN.test(text) || REQUIREMENT_HEADER_PATTERN.test(text)) break;
    if (!text || METADATA_PATTERN.test(text)) continue;
    body.push({ index, text });
  }
  return body;
}

function findUnsupportedStructure(lines) {
  for (const { pattern, name } of UNSUPPORTED_CHINESE_STRUCTURE) {
    const index = lines.findIndex(line => pattern.test(line));
    if (index >= 0) return { index, name };
  }
  return undefined;
}

function inspectSpec(root, filePath, mainSpec) {
  const relativePath = path.relative(root, filePath);
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  const unsupported = findUnsupportedStructure(lines);
  if (unsupported) {
    return {
      issues: [`${relativePath}:${unsupported.index + 1} 不支持中文结构标题 ${unsupported.name}；请保留 OpenSpec 英文结构标题`],
      injections: [],
    };
  }

  const issues = [];
  const injections = [];
  for (const { start, end } of sectionRanges(lines, mainSpec)) {
    for (let index = start + 1; index < end; index += 1) {
      if (!REQUIREMENT_HEADER_PATTERN.test(lines[index])) continue;
      const body = findRequirementBody(lines, index, end);
      if (body.length === 0) {
        issues.push(`${relativePath}:${index + 1} Requirement 缺少需求正文`);
        continue;
      }
      const englishModal = body.find(entry => ENGLISH_MODAL_PATTERN.test(entry.text));
      const chineseModal = body.find(entry => CHINESE_MODAL_PATTERN.test(entry.text));
      const hasEnglishModal = Boolean(englishModal);
      const hasChineseModal = Boolean(chineseModal);
      if (!hasEnglishModal && !hasChineseModal) {
        issues.push(`${relativePath}:${body[0].index + 1} Requirement 缺少强制词（SHALL、MUST、必须、不得、禁止或应当）`);
        continue;
      }
      if (!hasEnglishModal && chineseModal) injections.push(chineseModal.index);
    }
  }
  return { issues, injections };
}

function parseSchema(config) {
  const lines = config.replace(/^\uFEFF/, '').split(/\r?\n/);
  const schemaIndex = lines.findIndex(line => /^schema\s*:/.test(line));
  if (schemaIndex < 0) return undefined;

  const scalar = lines[schemaIndex].replace(/^schema\s*:\s*/, '');
  const normalizedScalar = scalar.replace(/^(?:(?:!!|!|&)[^\s]+\s*)+/, '').trim();
  if (/^[>|][+-]?\d*\s*(?:#.*)?$/.test(normalizedScalar)) {
    const blockLines = [];
    for (let index = schemaIndex + 1; index < lines.length; index += 1) {
      const line = lines[index];
      if (line.trim() && !/^\s+/.test(line)) break;
      if (line.trim()) blockLines.push(line.trim());
    }
    return blockLines.join(' ').trim();
  }

  const doubleQuoted = normalizedScalar.match(/^"((?:\\.|[^"])*)"\s*(?:#.*)?$/);
  if (doubleQuoted) return JSON.parse(`"${doubleQuoted[1]}"`);
  const singleQuoted = normalizedScalar.match(/^'((?:''|[^'])*)'\s*(?:#.*)?$/);
  if (singleQuoted) return singleQuoted[1].replace(/''/g, "'");
  return normalizedScalar.replace(/\s+#.*$/, '').trim();
}

function projectConfig(root) {
  const configPath = ['config.yaml', 'config.yml']
    .map(name => path.join(root, 'openspec', name))
    .find(file => fs.existsSync(file));
  if (!configPath) throw new Error(`未找到 OpenSpec 配置：${path.join(root, 'openspec', 'config.yaml')}`);
  return configPath;
}

function requireSpecDriven(configPath) {
  const schema = parseSchema(fs.readFileSync(configPath, 'utf8'));
  if (schema !== 'spec-driven') {
    throw new Error(`中文严格校验适配器仅支持 spec-driven schema，当前为：${schema ?? '未配置'}`);
  }
}

function activeChangeFiles(root) {
  const changesDir = path.join(root, 'openspec', 'changes');
  if (!fs.existsSync(changesDir)) return [];
  return fs.readdirSync(changesDir, { withFileTypes: true }).flatMap(entry => {
    if (!entry.isDirectory() || entry.name === 'archive' || entry.name.startsWith('.')) return [];
    const changeDir = path.join(changesDir, entry.name);
    if (!fs.existsSync(path.join(changeDir, 'proposal.md'))) return [];
    return specFiles(path.join(changeDir, 'specs'));
  });
}

function collectInspections(root) {
  const mainFiles = specFiles(path.join(root, 'openspec', 'specs'));
  const changeFiles = activeChangeFiles(root);
  return [
    ...mainFiles.map(filePath => ({ filePath, mainSpec: true })),
    ...changeFiles.map(filePath => ({ filePath, mainSpec: false })),
  ].map(entry => ({ ...entry, ...inspectSpec(root, entry.filePath, entry.mainSpec) }));
}

function copyTreeDereferenced(src, dst, ancestors = new Set()) {
  const srcStat = fs.lstatSync(src);
  if (srcStat.isSymbolicLink()) {
    const resolved = fs.realpathSync(src);
    return copyTreeDereferenced(resolved, dst, ancestors);
  }
  if (srcStat.isDirectory()) {
    const identity = fs.realpathSync(src);
    if (ancestors.has(identity)) throw new Error(`OpenSpec 输入包含目录循环：${src}`);
    const next = new Set(ancestors).add(identity);
    fs.mkdirSync(dst, { recursive: true });
    for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
      copyTreeDereferenced(path.join(src, entry.name), path.join(dst, entry.name), next);
    }
    return;
  }
  if (srcStat.isFile()) {
    fs.mkdirSync(path.dirname(dst), { recursive: true });
    fs.copyFileSync(src, dst);
    return;
  }
  throw new Error(`unsupported file type at ${src}`);
}

function stageInputs(root, stagingRoot, change) {
  const source = path.join(root, 'openspec');
  const target = path.join(stagingRoot, 'openspec');
  const config = projectConfig(root);
  function copy(relative) {
    const input = path.join(source, relative);
    if (fs.existsSync(input)) copyTreeDereferenced(input, path.join(target, relative));
  }
  copy(path.basename(config));
  requireSpecDriven(projectConfig(stagingRoot));
  copy('schemas');
  fs.mkdirSync(path.join(target, 'changes'), { recursive: true });
  fs.mkdirSync(path.join(target, 'specs'), { recursive: true });
  const changes = path.join(source, 'changes');
  const names = change ? [change] : fs.existsSync(changes)
    ? fs.readdirSync(changes, { withFileTypes: true })
      .filter(entry => entry.isDirectory() && entry.name !== 'archive' && !entry.name.startsWith('.'))
      .map(entry => entry.name)
    : [];
  for (const name of names) {
    const relative = path.join('changes', name);
    if (!fs.existsSync(path.join(source, relative, 'proposal.md'))) {
      if (change) throw new Error(`未找到活跃变更的 proposal.md：${change}`);
      continue;
    }
    for (const entry of ['proposal.md', 'design.md', 'tasks.md', '.openspec.yaml', 'specs']) {
      copy(path.join(relative, entry));
    }
  }
  if (!change) {
    copy('specs');
  } else {
    const deltas = path.join(target, 'changes', change, 'specs');
    for (const file of specFiles(deltas)) copy(path.join('specs', path.relative(deltas, file)));
  }
}

function fingerprint(directory) {
  const hash = createHash('sha256');
  function visit(relative) {
    const file = path.join(directory, relative);
    const info = fs.statSync(file);
    if (info.isDirectory()) {
      for (const name of fs.readdirSync(file).sort()) visit(path.join(relative, name));
    } else {
      const content = fs.readFileSync(file);
      hash.update(JSON.stringify([relative, content.length])).update(content);
    }
  }
  visit('');
  return hash.digest('hex');
}

function injectNativeModals(inspections) {
  for (const inspection of inspections) {
    if (inspection.injections.length === 0) continue;
    const stagingFile = inspection.filePath;
    const lines = fs.readFileSync(stagingFile, 'utf8').split(/\r?\n/);
    for (const index of inspection.injections) lines[index] = `MUST ${lines[index]}`;
    fs.writeFileSync(stagingFile, lines.join('\n'));
  }
}

function runNativeValidation(stagingRoot, change) {
  let status = 0;
  for (const args of [
    ['validate', '--specs', '--strict', '--no-interactive'],
    change
      ? ['validate', change, '--type', 'change', '--strict', '--no-interactive']
      : ['validate', '--changes', '--strict', '--no-interactive'],
  ]) {
    const result = spawnSync('openspec', args, { cwd: stagingRoot, stdio: 'inherit' });
    if (result.error) {
      console.error(`无法执行 openspec：${result.error.message}`);
      status = 1;
    } else if (result.status !== 0) {
      status = result.status ?? 1;
    }
  }
  return status;
}

function main() {
  const args = process.argv.slice(2);
  if (args.length === 1 && ['--help', '-h'].includes(args[0])) {
    console.log(`用法：firefly validate [变更ID] [--root 目录]
  [变更ID]  可选。用 firefly list 查询。提供后校验该变更及对应主规格，省略则校验整个项目。
  --root    可选。项目目录，默认当前目录。
示例：firefly validate export-report（export-report 是示例变更 ID）。`);
    return 0;
  }
  const { root, change } = parseOptions(args);
  const stagingRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'firefly-openspec-cn-'));
  try {
    stageInputs(root, stagingRoot, change);
    const inspections = collectInspections(stagingRoot);
    const issues = inspections.flatMap(inspection => inspection.issues);
    if (issues.length) {
      console.error(issues.join('\n'));
      return 1;
    }
    const input = fingerprint(path.join(stagingRoot, 'openspec'));
    injectNativeModals(inspections);
    const status = runNativeValidation(stagingRoot, change);
    if (status === 0) console.log(`Validation input SHA-256: ${input}`);
    return status;
  } finally {
    fs.rmSync(stagingRoot, { recursive: true, force: true });
  }
}

try {
  process.exitCode = main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exitCode = 1;
}

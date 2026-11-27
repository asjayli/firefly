import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';

export const entries = ['SKILL.md', 'LICENSE', 'references', 'scripts'];
export const directories = ['references', 'scripts'];

export function stat(file) {
  return fs.lstatSync(file, { throwIfNoEntry: false });
}

export function within(parent, child) {
  const relative = path.relative(parent, child);
  return relative === '' || (!path.isAbsolute(relative) && relative !== '..' && !relative.startsWith('../'));
}

export function inventory(root, directory, label = directory) {
  const result = Object.create(null);
  function visit(file, relative) {
    const info = fs.lstatSync(file);
    if (info.isDirectory()) {
      result[relative] = 'directory';
      for (const child of fs.readdirSync(file).sort()) visit(path.join(file, child), path.join(relative, child));
    } else if (info.isFile()) {
      const hash = createHash('sha256').update(fs.readFileSync(file)).digest('hex');
      result[relative] = `${info.mode & 0o777}:${hash}`;
    } else {
      throw new Error(`Unsupported bundle asset: ${file}`);
    }
  }
  visit(path.join(root, directory), label);
  return { ...result };
}

export function verifyBundle(root, entrypoint = 'SKILL.md') {
  const scripts = ['bootstrap-project.sh', 'firefly-diagram.sh', 'firefly-record.sh',
    'firefly-snapshot.sh', 'firefly.sh', 'list-change-tasks.sh', 'manage.sh', 'review-package',
    'sdd-workspace', 'task-brief'];
  function requireFile(file, executable = false) {
    if (!within(root, file) || !stat(file)?.isFile()) {
      throw new Error(`Missing or invalid bundle file: ${file}`);
    }
    if (executable) fs.accessSync(file, fs.constants.X_OK);
    return file;
  }

  const first = requireFile(path.join(root, entrypoint));
  requireFile(path.join(root, 'LICENSE'));
  requireFile(path.join(root, 'references', 'upstreams.json'));
  requireFile(path.join(root, 'scripts', 'record-markdown.sh'));
  for (const script of scripts) requireFile(path.join(root, 'scripts', script), true);
  for (const script of ['manage.mjs', 'bundle.mjs', 'continuation.mjs', 'project-config.mjs', 'project-paths.mjs', 'spec-commands.mjs', 'validate-openspec-cn.mjs']) {
    requireFile(path.join(root, 'scripts', script));
  }
  for (const directory of directories) {
    if (!stat(path.join(root, directory))?.isDirectory()) throw new Error(`Invalid bundle directory: ${directory}`);
  }
  const references = Object.keys(inventory(root, 'references')).filter(file => file.endsWith('.md'));
  const skill = fs.readFileSync(first, 'utf8');
  const commands = skill.split('### Skill subcommands')[1]?.split(/^## /m)[0] ?? '';
  const abilities = [...commands.matchAll(/^- `firefly ([\w-]+)`/gm)].map(match => match[1]);
  for (const ability of new Set([...abilities, 'init', 'repair'])) {
    if (ability !== 'next') requireFile(path.join(root, 'references', 'abilities', `firefly-${ability}`, 'guide.md'));
  }
  for (const file of [first, ...references.map(relative => path.join(root, relative))]) {
    const contents = fs.readFileSync(file, 'utf8');
    if (/\{\{PLATFORM_[A-Z_]+\}\}|\b(?:CLAUDE_HOME|CODEX_HOME|AskUserQuestion|TodoWrite|spawn_agent|wait_agent)\b/.test(contents)) {
      throw new Error(`Host-specific placeholder or tool in bundle guide: ${file}`);
    }
    const links = contents.matchAll(/\]\(([.\w/-]+\.(?:md|json))(?:#[^)]+)?\)|`((?:\.\.\/|references\/)[\w./-]+\.md)`|<skill-root>\/([\w./-]+\.(?:md|sh)|scripts\/(?:review-package|task-brief))/g);
    for (const [, link, code, fromRoot] of links) {
      requireFile(path.resolve(fromRoot ? root : path.dirname(file), fromRoot ?? link ?? code));
    }
  }
}

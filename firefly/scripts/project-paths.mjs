import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { stat, within } from './bundle.mjs';

export function localPath(root, file) {
  const resolved = fs.realpathSync(file);
  if (!within(root, resolved)) throw new Error(`路径超出项目范围：${file}`);
  return resolved;
}

export function projectRoot(explicit) {
  let root = fs.realpathSync(explicit ?? process.cwd());
  for (;;) {
    const planning = path.join(root, 'openspec');
    if (stat(planning)) {
      localPath(root, planning);
      if (!fs.statSync(planning).isDirectory()) throw new Error(`规格路径不是目录：${planning}`);
      const present = ['changes', 'specs'].map(name => path.join(planning, name)).filter(file => stat(file));
      const configs = ['config.yaml', 'config.yml'].map(name => path.join(planning, name)).filter(file => stat(file));
      for (const file of [...present, ...configs]) localPath(root, file);
      if (present.some(file => fs.statSync(file).isDirectory())) return root;
      if (configs.length || present.length) {
        throw new Error(`项目没有本地规格目录：${planning}。外部 store 请从其根目录显式操作。`);
      }
    }
    const parent = path.dirname(root);
    if (explicit !== undefined || parent === root || stat(path.join(root, '.git'))) {
      throw new Error('未找到本地规格项目。请使用 --root 指定项目根目录，或先运行 firefly init。');
    }
    root = parent;
  }
}

export function activeChangeIds(root) {
  const changes = path.join(root, 'openspec', 'changes');
  if (!fs.existsSync(changes)) return [];
  return fs.readdirSync(localPath(root, changes), { withFileTypes: true })
    .filter(entry => entry.isDirectory() && entry.name !== 'archive' && !entry.name.startsWith('.'))
    .map(entry => entry.name).sort();
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    const [mode, ...args] = process.argv.slice(2);
    if (mode === 'root') console.log(projectRoot(args[0]));
    else if (mode === 'within') for (const file of args.slice(1)) localPath(args[0], file);
    else throw new Error('未知路径检查操作。');
  } catch (error) {
    console.error(`firefly: ${error.message}`);
    process.exitCode = 1;
  }
}

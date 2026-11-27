import { spawnSync } from 'node:child_process';
import { parseArgs } from 'node:util';
import fs from 'node:fs';
import path from 'node:path';
import { activeChangeIds, localPath, projectRoot } from './project-paths.mjs';

const help = {
  new: `用法：firefly new <变更ID>
  <变更ID>  必填。使用小写短横线命名。all 和 archive 为保留字。
             示例：firefly new export-report（创建名为 export-report 的变更）。`,
  list: `用法：firefly list [--json]
  列出活跃变更及其 ID。若已有 ID 为 all，使用 validate -- all 或 tasks -- all 精确定位。
  --json  可选。输出 JSON，供脚本和 Agent 读取。
示例：firefly list --json。`,
  status: '查看变更的制品进度。',
  show: '查看变更内容。',
};

function commandHelp(command) {
  if (command === 'new' || command === 'list') return help[command];
  return `用法：firefly ${command} [变更ID] [--json]
  ${help[command]}
  [变更ID]  可选。用 firefly list 查询可用 ID。
  --json    可选。输出 JSON，供脚本和 Agent 读取。

省略 ID 时自动选中唯一的活跃变更。没有活跃变更时给出提示，有多个时列出候选并退出。
示例：firefly ${command} export-report（export-report 是示例变更 ID）。`;
}

function runBackend(args, cwd) {
  const result = spawnSync('openspec', args, { cwd, stdio: 'inherit' });
  if (result.error?.code === 'ENOENT') {
    console.error('未找到规格后端。请安装 OpenSpec 并将其加入 PATH。');
    return { status: 127 };
  }
  if (result.error) throw result.error;
  if (result.signal) process.kill(process.pid, result.signal);
  return result;
}

function runSpec(args) {
  const [command, ...options] = args;
  if (args.length === 1 && ['--help', '-h'].includes(command)) {
    console.log(`用法：firefly spec <instructions|templates|schemas> [参数] [--root 目录]
      firefly spec raw <后端命令> [参数]
常用规格查询使用 Firefly 选定的本地项目。raw 保留后端自己的根选择和副作用，只用于用户明确要求的原生操作。
用 firefly spec raw --help 查看后端的完整接口。`);
    return 0;
  }
  if (command === 'raw' && options.length) return runBackend(options).status;
  if (!['instructions', 'templates', 'schemas'].includes(command)) {
    throw new Error('请使用 Firefly 对应命令，或用 firefly spec --help 查看规格入口。');
  }
  const forwarded = [];
  let root;
  for (let i = 0; i < options.length; i += 1) {
    const option = options[i];
    if (/^--(?:store|store-path)(?:=|$)/.test(option)) {
      throw new Error('规格查询使用本地项目。外部 store 需要显式选择原生通道。');
    }
    if (option === '--root') {
      const value = options[++i];
      if (root !== undefined || !value || value.startsWith('-')) throw new Error('--root 需要一个项目根目录。');
      root = value;
    } else {
      forwarded.push(option);
    }
  }
  const cwd = forwarded.length === 1 && ['--help', '-h'].includes(forwarded[0]) ? undefined : projectRoot(root);
  return runBackend([command, ...forwarded], cwd).status;
}

function resolveChange(root) {
  const ids = activeChangeIds(root);
  if (ids.length === 1) return { id: ids[0] };
  if (!ids.length) console.error('当前没有活跃变更。');
  else console.error(`有多个活跃变更，请指定变更 ID：\n${ids.map(id => `  ${id}`).join('\n')}`);
  return { status: 2 };
}

function main(command, args) {
  const options = { help: { type: 'boolean', short: 'h' }, root: { type: 'string' } };
  if (command !== 'new') options.json = { type: 'boolean' };
  const { values, positionals } = parseArgs({ args, options, allowPositionals: true });
  if (values.help) {
    console.log(commandHelp(command).replace(/\n/, ' [--root 目录]\n'));
    console.log('  --root  可选。指定项目根。默认从当前目录向上查找本地项目。');
    return 0;
  }

  const json = values.json ? ['--json'] : [];
  if (values.root === '') throw new Error('--root 需要项目根目录。');
  if (command === 'list' && positionals.length === 0) return runBackend(['list', ...json], projectRoot(values.root)).status;
  if (command === 'new' && positionals.length === 1 && !['archive', 'all'].includes(positionals[0]) &&
      /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(positionals[0])) {
    const root = projectRoot(values.root);
    const changes = path.join(root, 'openspec', 'changes');
    const target = path.join(changes, positionals[0]);
    if (fs.lstatSync(target, { throwIfNoEntry: false })) throw new Error(`变更路径已存在：${target}`);
    return runBackend(['new', 'change', positionals[0]], root).status;
  }
  if (['status', 'show'].includes(command) && positionals.length <= 1) {
    const explicit = positionals[0];
    const root = projectRoot(values.root);
    const selection = explicit === undefined ? resolveChange(root) : { id: explicit };
    if (selection.status !== undefined) return selection.status;
    const { id } = selection;
    if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(id) || id === 'archive') throw new Error('变更 ID 无效。');
    const directory = path.join(root, 'openspec', 'changes', id);
    if (fs.existsSync(directory)) localPath(root, directory);
    if (explicit === undefined && !values.json) console.error(`当前变更：${id}`);
    const target = command === 'status' ? ['--change', id] : [id, '--type', 'change'];
    return runBackend([command, ...target, ...json], root).status;
  }
  throw new Error('参数无效。');
}

const [command, ...args] = process.argv.slice(2);
try {
  process.exitCode = (command === 'spec' ? runSpec(args) : main(command, args)) ?? 1;
} catch (error) {
  console.error(`firefly ${command}：${error.message} 可用 firefly ${command} --help 查看用法。`);
  process.exitCode = 2;
}

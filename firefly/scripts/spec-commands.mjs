import { spawnSync } from 'node:child_process';
import { parseArgs } from 'node:util';

const help = {
  new: `用法：firefly new <变更ID>
  <变更ID>  必填。新建变更的唯一标识，使用小写短横线命名。
             示例：firefly new export-report（创建名为 export-report 的变更）。`,
  list: `用法：firefly list [--json]
  列出活跃变更及其 ID。ID 可传给 status、show 和 validate。
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

function runBackend(args, stdio = 'inherit') {
  const result = spawnSync('openspec', args, { stdio, encoding: 'utf8' });
  if (result.error?.code === 'ENOENT') {
    console.error('未找到规格后端。请安装 OpenSpec 并将其加入 PATH。');
    return { status: 127 };
  }
  if (result.error) throw result.error;
  if (result.signal) process.kill(process.pid, result.signal);
  return result;
}

function resolveChange() {
  const result = runBackend(['list', '--json'], ['ignore', 'pipe', 'inherit']);
  if (result.status !== 0) return { status: result.status ?? 1 };
  const { changes } = JSON.parse(result.stdout);
  if (!Array.isArray(changes) || changes.some(change => typeof change?.name !== 'string' || !change.name)) {
    throw new Error('规格后端返回了无效的变更列表。');
  }
  const ids = changes.filter(change => !change.archived).map(change => change.name);
  if (ids.length === 1) return { id: ids[0] };
  if (!ids.length) console.error('当前没有活跃变更。');
  else console.error(`有多个活跃变更，请指定变更 ID：\n${ids.map(id => `  ${id}`).join('\n')}`);
  return { status: 2 };
}

function main(command, args) {
  const options = { help: { type: 'boolean', short: 'h' } };
  if (command !== 'new') options.json = { type: 'boolean' };
  const { values, positionals } = parseArgs({ args, options, allowPositionals: true });
  if (values.help) {
    console.log(commandHelp(command));
    return 0;
  }

  const json = values.json ? ['--json'] : [];
  if (command === 'list' && positionals.length === 0) return runBackend(['list', ...json]).status;
  if (command === 'new' && positionals.length === 1 && positionals[0] !== 'archive' &&
      /^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(positionals[0])) {
    return runBackend(['new', 'change', positionals[0]]).status;
  }
  if (['status', 'show'].includes(command) && positionals.length <= 1) {
    const explicit = positionals[0];
    const selection = explicit === undefined ? resolveChange() : { id: explicit };
    if (selection.status !== undefined) return selection.status;
    const { id } = selection;
    if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(id) || id === 'archive') throw new Error('变更 ID 无效。');
    if (explicit === undefined && !values.json) console.error(`当前变更：${id}`);
    const target = command === 'status' ? ['--change', id] : [id, '--type', 'change'];
    return runBackend([command, ...target, ...json]).status;
  }
  throw new Error('参数无效。');
}

const [command, ...args] = process.argv.slice(2);
try {
  process.exitCode = main(command, args) ?? 1;
} catch (error) {
  console.error(`firefly ${command}：${error.message} 可用 firefly ${command} --help 查看用法。`);
  process.exitCode = 2;
}

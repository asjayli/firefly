import fs from 'node:fs';

const symlinkSync = fs.symlinkSync;
const readdirSync = fs.readdirSync;
fs.symlinkSync = (target, file, type) => {
  if (file === process.env.FIREFLY_FAIL_LINK) throw new Error('Simulated command publication failure');
  return symlinkSync(target, file, type);
};
fs.readdirSync = (file, options) => {
  if (file === process.env.FIREFLY_FAIL_READ) throw new Error('Simulated destination enumeration failure');
  return readdirSync(file, options);
};

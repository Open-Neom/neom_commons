#!/usr/bin/env node
// Local Hosting only. Uses a demo project and loopback; never deploys.
import {mkdtemp, readFile, writeFile, access} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import path from 'node:path';
import {spawn} from 'node:child_process';

const args = process.argv.slice(2);
if (![4, 5].includes(args.length) || args[0] !== '--app-dir' || args[2] !== '--port'
    || (args.length === 5 && args[4] !== '--source-web')) {
  throw new Error('Usage: node preview.mjs --app-dir APP --port PORT [--source-web]');
}
const appDir = path.resolve(args[1]);
const port = Number(args[3]);
if (!Number.isInteger(port) || port < 1024 || port > 65533) throw new Error('Invalid local port');
const sourceConfig = JSON.parse(await readFile(path.join(appDir, 'firebase.json'), 'utf8'));
if (!sourceConfig.hosting || Array.isArray(sourceConfig.hosting)) throw new Error('Expected one Hosting configuration');
// Source mode previews generated static pages without rebuilding Flutter.
// It does not represent a tested or deployable Flutter application build.
const sourceOnly = args[4] === '--source-web';
const publicDir = path.resolve(appDir, sourceOnly ? 'web' : sourceConfig.hosting.public);
await access(path.join(publicDir, 'politica-de-privacidad/index.html'));
if (sourceOnly) {
  await access(path.join(publicDir, 'eliminar-cuenta/index.html'));
  await access(path.join(publicDir, 'terminos-y-condiciones/index.html'));
  console.log('Static legal source preview only; no Flutter build or deployment.');
}
const {predeploy, postdeploy, ...hosting} = sourceConfig.hosting;
const previewDir = await mkdtemp(path.join(tmpdir(), 'neom-privacy-preview-'));
// Superstatic joins this path against the config directory, so it must be relative.
hosting.public = path.relative(previewDir, publicDir);
const configPath = path.join(previewDir, 'firebase.json');
await writeFile(configPath, JSON.stringify({
  hosting,
  emulators: {
    hosting: {host: '127.0.0.1', port},
    hub: {host: '127.0.0.1', port: port + 1},
    logging: {host: '127.0.0.1', port: port + 2},
    ui: {enabled: false},
  },
}, null, 2));
console.log(`Local policy preview: http://127.0.0.1:${port}/politica-de-privacidad/`);
console.log(`Temporary config: ${configPath}`);
const child = spawn('firebase', [
  'emulators:start', '--only', 'hosting', '--project', `demo-privacy-${port}`,
  '--config', configPath,
], {cwd: previewDir, stdio: 'inherit'});
process.on('SIGINT', () => child.kill('SIGINT'));
process.on('SIGTERM', () => child.kill('SIGTERM'));
child.on('error', error => {console.error(error.message); process.exitCode = 1;});
child.on('exit', code => {process.exitCode = code ?? 0;});

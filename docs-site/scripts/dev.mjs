import { spawn } from 'node:child_process';
import { cp, rm, watch } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const siteDirectory = resolve(scriptDirectory, '..');
const sourceDirectory = resolve(siteDirectory, '../docs');
const targetDirectory = resolve(siteDirectory, 'content/docs');
const nextBinary = resolve(siteDirectory, 'node_modules/next/dist/bin/next');
const abortController = new AbortController();

async function syncDocs() {
  await rm(targetDirectory, { force: true, recursive: true });
  await cp(sourceDirectory, targetDirectory, { recursive: true });
}

await syncDocs();

const nextProcess = spawn(process.execPath, [nextBinary, 'dev'], {
  cwd: siteDirectory,
  env: process.env,
  stdio: 'inherit',
});

let debounceTimer;
let syncQueue = Promise.resolve();

function queueSync() {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    syncQueue = syncQueue
      .then(syncDocs)
      .catch((error) => {
        console.error('[docs] Failed to refresh the content mirror.', error);
      });
  }, 100);
}

async function watchDocs() {
  try {
    for await (const _event of watch(sourceDirectory, {
      recursive: true,
      signal: abortController.signal,
    })) {
      queueSync();
    }
  } catch (error) {
    if (error?.name !== 'AbortError') throw error;
  }
}

watchDocs().catch((error) => {
  console.error('[docs] Failed to watch the canonical documentation.', error);
  nextProcess.kill('SIGTERM');
  process.exitCode = 1;
});

function stop(signal) {
  abortController.abort();
  nextProcess.kill(signal);
}

process.on('SIGINT', () => stop('SIGINT'));
process.on('SIGTERM', () => stop('SIGTERM'));

nextProcess.on('exit', (code, signal) => {
  abortController.abort();
  if (signal) process.kill(process.pid, signal);
  else process.exit(code ?? 0);
});

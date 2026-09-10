import { cp, rm } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const sourceDirectory = resolve(scriptDirectory, '../../docs');
const targetDirectory = resolve(scriptDirectory, '../content/docs');

await rm(targetDirectory, { force: true, recursive: true });
await cp(sourceDirectory, targetDirectory, { recursive: true });

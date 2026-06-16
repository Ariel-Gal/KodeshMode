import { cp, mkdir, readdir, readFile, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const dist = path.join(root, 'dist');
const publicDir = path.join(root, 'public');

async function copyIfExists(from, to) {
  try {
    await cp(from, to, { recursive: true });
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
}

await rm(dist, { recursive: true, force: true });
await mkdir(dist, { recursive: true });
await copyIfExists(publicDir, dist);

for (const file of ['index.html', 'home.html', 'releases.html', 'style.css', 'main.js', 'releases.js']) {
  const source = path.join(root, file);
  const target = path.join(dist, file);
  await writeFile(target, await readFile(source, 'utf8'));
}

await writeFile(path.join(dist, '.nojekyll'), '');

const builtFiles = await readdir(dist, { recursive: true });
console.log(`Built static site to dist/ with ${builtFiles.length} files.`);

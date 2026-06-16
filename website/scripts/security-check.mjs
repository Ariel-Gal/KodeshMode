import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const filesToCheck = ['index.html', 'home.html', 'releases.html', 'main.js', 'style.css'];
const findings = [];

function pass(message) {
  findings.push({ level: 'PASS', message });
}

function fail(message) {
  findings.push({ level: 'FAIL', message });
}

function warn(message) {
  findings.push({ level: 'WARN', message });
}

const index1 = await readFile(path.join(root, 'index.html'), 'utf8');
const index2 = await readFile(path.join(root, 'home.html'), 'utf8');
const index3 = await readFile(path.join(root, 'releases.html'), 'utf8');
const index = index1 + index2 + index3;
const main = await readFile(path.join(root, 'main.js'), 'utf8');
const style = await readFile(path.join(root, 'style.css'), 'utf8');

if (/Content-Security-Policy/.test(index)) pass('CSP meta tag is present.');
else fail('Missing Content-Security-Policy meta tag.');

if (/https:\/\/(fonts\.|www\.googletagmanager|www\.google-analytics|ssl\.google-analytics|connect\.facebook|static\.hotjar|cdn\.segment|plausible\.io)/i.test(index + main + style)) {
  fail('External fonts, analytics, or tracking endpoints detected.');
} else {
  pass('No external fonts, analytics endpoints, pixels, or third-party scripts detected.');
}

if (/\bon\w+=/i.test(index)) fail('Inline event handler detected in HTML.');
else pass('No inline event handlers detected.');

if (/\sstyle=/i.test(index)) fail('Inline style attributes detected.');
else pass('No inline style attributes detected.');

if (/innerHTML|outerHTML|insertAdjacentHTML|eval\(|new Function\(/.test(main)) {
  fail('Potentially unsafe dynamic HTML or code execution API detected in main.js.');
} else {
  pass('No unsafe dynamic HTML or eval-style JavaScript detected.');
}

const blankLinks = [...index.matchAll(/<a\b[^>]*target="_blank"[^>]*>/gi)].map((m) => m[0]);
const unsafeBlankLinks = blankLinks.filter((link) => !/rel="[^"]*noopener[^"]*noreferrer[^"]*"/i.test(link));
if (unsafeBlankLinks.length) fail(`${unsafeBlankLinks.length} target=_blank links missing rel="noopener noreferrer".`);
else pass('All target=_blank links include rel="noopener noreferrer".');

const imageTags = [...index.matchAll(/<img\b[^>]*>/gi)].map((m) => m[0]);
const imagesWithoutAlt = imageTags.filter((tag) => !/\salt="[^"]*"/i.test(tag));
if (imagesWithoutAlt.length) fail(`${imagesWithoutAlt.length} images missing alt text.`);
else pass('All images include alt text.');

if (/prefers-reduced-motion/.test(style)) pass('Reduced-motion CSS support is present.');
else warn('Reduced-motion CSS support not found.');

const publicImages = path.join(root, 'public', 'images');
let imageCount = 0;
try {
  const entries = await readdir(publicImages, { recursive: true });
  imageCount = entries.filter((entry) => /\.(png|webp|jpg|jpeg|svg)$/i.test(entry)).length;
  pass(`${imageCount} local image assets found under public/images.`);
} catch {
  warn('No public/images directory found.');
}

let failed = false;
for (const finding of findings) {
  const prefix = finding.level === 'PASS' ? '✅' : finding.level === 'WARN' ? '⚠️' : '❌';
  console.log(`${prefix} ${finding.level}: ${finding.message}`);
  if (finding.level === 'FAIL') failed = true;
}

for (const file of filesToCheck) {
  const filePath = path.join(root, file);
  const info = await stat(filePath);
  console.log(`ℹ️  ${file}: ${info.size} bytes`);
}

if (failed) {
  process.exitCode = 1;
} else {
  console.log('Security check completed without failures.');
}

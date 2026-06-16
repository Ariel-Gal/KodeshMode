import { readFile, readdir, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const filesToCheck = [
  'index.html',
  'home.html',
  'releases.html',
  'main.js',
  'releases.js',
  'style.css',
  'splash.css',
  'public/_headers',
  'package.json',
];
const htmlFiles = ['index.html', 'home.html', 'releases.html'];
const jsFiles = ['main.js', 'releases.js'];
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

async function readText(file) {
  return readFile(path.join(root, file), 'utf8');
}

const htmlByFile = new Map(await Promise.all(htmlFiles.map(async (file) => [file, await readText(file)])));
const jsByFile = new Map(await Promise.all(jsFiles.map(async (file) => [file, await readText(file)])));
const style = (await readText('style.css')) + '\n' + (await readText('splash.css'));
const headers = await readText('public/_headers');
const packageJson = await readText('package.json');
const allHtml = [...htmlByFile.values()].join('\n');
const allJs = [...jsByFile.values()].join('\n');
const allCode = [allHtml, allJs, style, headers, packageJson].join('\n');

const cspMetaTags = [...allHtml.matchAll(/<meta\s+http-equiv="Content-Security-Policy"\s+content="([^"]+)"\s*\/>/gi)];
if (cspMetaTags.length === htmlFiles.length) pass('Every HTML page has a CSP meta tag.');
else fail(`Expected ${htmlFiles.length} CSP meta tags, found ${cspMetaTags.length}.`);

const cspValues = cspMetaTags.map((match) => match[1]);
const headerCsp = /Content-Security-Policy:\s*(.+)/i.exec(headers)?.[1] || '';
const cspToCheck = [...cspValues, headerCsp];

for (const directive of [
  "default-src 'self'",
  "base-uri 'self'",
  "object-src 'none'",
  "form-action 'none'",
  "img-src 'self' data: https://avatars.githubusercontent.com",
  "connect-src 'self' https://api.github.com https://raw.githubusercontent.com",
  "script-src 'self'",
  "style-src 'self'",
]) {
  if (cspToCheck.every((csp) => csp.includes(directive))) pass(`CSP includes ${directive}.`);
  else fail(`CSP is missing or weak for: ${directive}.`);
}

if (/unsafe-inline|unsafe-eval|\bws:|\bwss:|corsproxy\.io/i.test(cspToCheck.join('\n'))) {
  fail('CSP contains unsafe-inline, unsafe-eval, websocket wildcards, or corsproxy.io.');
} else {
  pass('CSP avoids unsafe-inline, unsafe-eval, websocket wildcards, and public CORS proxy endpoints.');
}

if (/https:\/\/(fonts\.|www\.googletagmanager|www\.google-analytics|ssl\.google-analytics|connect\.facebook|static\.hotjar|cdn\.segment|plausible\.io)/i.test(allCode)) {
  fail('External fonts, analytics, or tracking endpoints detected.');
} else {
  pass('No external fonts, analytics endpoints, pixels, or third-party scripts detected.');
}

if (/corsproxy\.io/i.test(allCode)) fail('Public CORS proxy endpoint detected.');
else pass('No public CORS proxy endpoint detected.');

if (/--host\s+0\.0\.0\.0|host:\s*['"]0\.0\.0\.0['"]/i.test(packageJson + '\n' + allJs)) {
  fail('Dev server is configured to bind to 0.0.0.0.');
} else {
  pass('Dev and preview scripts do not expose the local server on 0.0.0.0 by default.');
}

if (/\bon\w+=/i.test(allHtml)) fail('Inline event handler detected in HTML.');
else pass('No inline event handlers detected.');

if (/<style\b/i.test(allHtml)) fail('Inline <style> tags detected in HTML.');
else pass('No inline <style> tags detected in HTML.');

if (/\sstyle=/i.test(allHtml)) fail('Inline style attributes detected in HTML.');
else pass('No inline style attributes detected in HTML.');

if (/\.style\.|\.setAttribute\(\s*['"]style['"]/i.test(allJs)) fail('JavaScript writes inline styles. Use CSS classes instead.');
else pass('JavaScript uses CSS classes instead of writing inline styles.');

if (/innerHTML|outerHTML|insertAdjacentHTML|DOMParser|createContextualFragment|eval\(|new Function\(/.test(allJs)) {
  fail('Potentially unsafe dynamic HTML or code execution API detected in JavaScript.');
} else {
  pass('No unsafe dynamic HTML parser/injection or eval-style JavaScript detected.');
}

if (/href\s*=\s*['"]\s*javascript:/i.test(allHtml + '\n' + allJs)) fail('javascript: URL detected.');
else pass('No javascript: URLs detected.');

const blankLinks = [...allHtml.matchAll(/<a\b[^>]*target="_blank"[^>]*>/gi)].map((m) => m[0]);
const unsafeBlankLinks = blankLinks.filter((link) => !/rel="[^"]*noopener[^"]*noreferrer[^"]*"/i.test(link));
if (unsafeBlankLinks.length) fail(`${unsafeBlankLinks.length} target=_blank links missing rel="noopener noreferrer".`);
else pass('All target=_blank links include rel="noopener noreferrer".');

const imageTags = [...allHtml.matchAll(/<img\b[^>]*>/gi)].map((m) => m[0]);
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

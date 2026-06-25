const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const outDir = path.join(root, 'dist-pages');

const files = [
  '_headers',
  'about.html',
  'admin-dashboard.html',
  'admin-dashboard.js',
  'admin-goals.js',
  'admin.html',
  'admin.js',
  'backend.js',
  'config.js',
  'goals.js',
  'index.html',
  'interschool-team.html',
  'interschool-team.js',
  'kiosk.css',
  'kiosk.html',
  'kiosk.js',
  'leaderboard.html',
  'leaderboard.js',
  'manifest.webmanifest',
  'parent.html',
  'parent.js',
  'privacy-policy.html',
  'pwa.js',
  'scanning.js',
  'service-worker.js',
  'student-profile.html',
  'student.html',
  'student.js',
  'styles.css',
  'theme.js',
  'tracking.js'
];

const directories = [
  'assets'
];

const linkedDocs = [
  'docs/beta-tester-checklist.md',
  'docs/education-compliance-readiness.md'
];

function copyFile(relativePath) {
  const source = path.join(root, relativePath);
  const target = path.join(outDir, relativePath);
  if (!fs.existsSync(source)) {
    throw new Error(`Missing deploy asset: ${relativePath}`);
  }
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.copyFileSync(source, target);
}

function copyDir(relativePath) {
  const source = path.join(root, relativePath);
  const target = path.join(outDir, relativePath);
  if (!fs.existsSync(source)) {
    throw new Error(`Missing deploy directory: ${relativePath}`);
  }
  fs.cpSync(source, target, { recursive: true });
}

fs.rmSync(outDir, { recursive: true, force: true });
fs.mkdirSync(outDir, { recursive: true });

files.forEach(copyFile);
directories.forEach(copyDir);
linkedDocs.forEach(copyFile);

console.log(`Cloudflare Pages bundle ready: ${path.relative(root, outDir)}`);
console.log(`Files copied: ${files.length + linkedDocs.length}; directories copied: ${directories.length}`);

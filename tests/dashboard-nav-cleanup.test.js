const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');

function read(file) {
  return fs.readFileSync(path.join(root, file), 'utf8');
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

// --- Task 1: index.html dropdown trim ---
const indexHtml = read('index.html');
const indexNavMatch = indexHtml.match(/<nav class="main-nav"[^>]*>([\s\S]*?)<\/nav>/);
assert(indexNavMatch, 'index.html should have a <nav class="main-nav"> block');
const indexNav = indexNavMatch[1];
const indexNavLinks = indexNav.match(/<a /g) || [];
assert(indexNavLinks.length === 5, 'index.html dropdown should have exactly 5 links, found ' + indexNavLinks.length);
assert(/href="index\.html"/.test(indexNav), 'index.html dropdown should link Home');
assert(/href="student\.html"/.test(indexNav), 'index.html dropdown should link Student');
assert(/href="parent\.html"/.test(indexNav), 'index.html dropdown should link Parent');
assert(/href="admin\.html"/.test(indexNav), 'index.html dropdown should link Admin');
assert(/href="leaderboard\.html"/.test(indexNav), 'index.html dropdown should link Leaderboard');
assert(!/href="admin-dashboard\.html\?tab=/.test(indexNav), 'index.html dropdown should not deep-link into admin-dashboard tabs (they require login)');

console.log('dashboard nav cleanup checks passed');

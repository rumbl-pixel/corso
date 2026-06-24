const fs = require('fs');
const path = require('path');

function read(file) {
  return fs.readFileSync(path.join(__dirname, '..', file), 'utf8');
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

const startScript = read('scripts/sync-start.ps1');
const finishScript = read('scripts/sync-finish.ps1');
const guide = read('docs/sync-between-pcs.md');

assert(/git fetch origin/.test(startScript), 'start script should fetch latest GitHub changes');
assert(/git pull --ff-only/.test(startScript), 'start script should pull safely without merge surprises');
assert(/git status --short/.test(startScript), 'start script should show current working tree status');

assert(/param\s*\(\s*\[string\]\$Message/.test(finishScript), 'finish script should accept an optional commit message');
assert(/git add -A/.test(finishScript), 'finish script should stage all project changes');
assert(/git commit -m \$Message/.test(finishScript), 'finish script should commit using the supplied message');
assert(/git push/.test(finishScript), 'finish script should push to GitHub');
assert(/No changes to commit/.test(finishScript), 'finish script should handle no-change runs safely');

assert(/Start work/.test(guide), 'sync guide should explain how to start work on a PC');
assert(/Finish work/.test(guide), 'sync guide should explain how to finish work on a PC');
assert(/Never copy node_modules/.test(guide), 'sync guide should warn against copying generated dependencies');
assert(/Do not sync real secrets/.test(guide), 'sync guide should warn against syncing secrets');

console.log('sync workflow checks passed');

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

function assertFile(file) {
  assert(fs.existsSync(path.join(root, file)), `${file} should exist`);
}

assertFile('config.js');
assertFile('parent.html');
assertFile('parent.js');

const config = read('config.js');
assert(/demoMode:\s*true/.test(config), 'config.js should enable safe demo mode');
assert(!/SUPABASE_SERVICE|service_role|secret/i.test(config), 'config.js should not contain private service secrets');

const adminHtml = read('admin.html');
const adminEmailInput = adminHtml.match(/<input[^>]*id="admin-email"[^>]*>/) || adminHtml.match(/<input[^>]*type="text"[^>]*admin-email[^>]*>/);
assert(adminEmailInput && /type="text"/.test(adminEmailInput[0]), 'admin login should accept DEMO without email validation');
assert(/DEMO/.test(adminHtml), 'admin login should show a DEMO hint');

const adminJs = read('admin.js');
assert(/DEMO/.test(adminJs), 'admin login should handle DEMO bypass');

const studentHtml = read('student.html');
assert(/DEMO/.test(studentHtml), 'student login should show a DEMO hint');

const studentJs = read('student.js');
assert(/DEMO/.test(studentJs), 'student login should handle DEMO bypass');

const parentHtml = read('parent.html');
assert(/id="parent-form"/.test(parentHtml), 'parent portal should expose a login form');
assert(/DEMO/.test(parentHtml), 'parent portal should show a DEMO hint');
assert(/parent\.js/.test(parentHtml), 'parent portal should load parent.js');

const parentJs = read('parent.js');
assert(/DEMO/.test(parentJs), 'parent portal should handle DEMO bypass');
assert(/RunClubScan/.test(parentJs), 'parent portal should use shared scanning roster data');
assert(/RunClubGoals/.test(parentJs), 'parent portal should use shared goals data');

console.log('portal smoke checks passed');

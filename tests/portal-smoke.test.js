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
assertFile('leaderboard.html');

const brandFiles = [
  'index.html',
  'admin.html',
  'admin-dashboard.html',
  'student.html',
  'student-profile.html',
  'leaderboard.html',
  'parent.html',
  'privacy-policy.html',
  'kiosk.html',
  'README.md',
  'FEATURES.md',
  '_config.yml'
];
for (const file of brandFiles) {
  const contents = read(file);
  assert(/Gwynne Park Run Club/.test(contents), `${file} should use the Gwynne Park Run Club brand`);
  assert(!/Run Club Connect/.test(contents), `${file} should not use the old Run Club Connect brand`);
  assert(!/runclubconnect/i.test(contents), `${file} should not use old runclubconnect contact details`);
}

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
assert(!/Log Home Activity|self-report-form|sr-type|sr-minutes/.test(studentHtml), 'student portal should not include home activity logging');
assert(/student-profile\.html/.test(studentHtml), 'student login should hand signed-in students to the profile page');
assert(!/id="submit-btn"[^>]*hidden/.test(studentHtml), 'student login page should keep the sign-in button available before login');

const studentProfileHtml = read('student-profile.html');
assert(!/id="student-form"|id="submit-btn"/.test(studentProfileHtml), 'student profile page should not show the login form or sign-in button');
assert(/medal-progress/.test(studentProfileHtml), 'student profile page should show read-only medal progress');
assert(/student-barcode-card/.test(studentProfileHtml), 'student profile page should show the student barcode card area');
assert(/print-student-barcode-btn/.test(studentProfileHtml), 'student profile page should let students print a credit-card-sized barcode card');

const studentJs = read('student.js');
assert(/DEMO/.test(studentJs), 'student login should handle DEMO bypass');
assert(!/self-report-form|rc_selfreports|wireSelfReport/.test(studentJs), 'student portal should not submit home activity logs');
assert(/MEDAL_TIERS/.test(studentJs), 'student portal should calculate medal progress');
assert(/renderStudentBarcode/.test(studentJs), 'student portal should render the signed-in student barcode');
assert(/printStudentBarcodeCard/.test(studentJs), 'student portal should print individual student barcode cards');
assert(/runClubStudentSession/.test(studentJs), 'student portal should persist student login sessions');
assert(/student-profile\.html/.test(studentJs), 'student login should redirect to the separate profile page');

const homeHtml = read('index.html');
assert(!/href="kiosk\.html"|Scanner kiosk/.test(homeHtml), 'public home page should not link directly to the admin-only kiosk');
assert(/href="leaderboard\.html"/.test(homeHtml), 'home page should link to the public leaderboard page');
assert(homeHtml.indexOf('Admin login</a>') > homeHtml.indexOf('Parent portal</a>'), 'home nav should place admin login at the far right');
assert(!/class="hero-buttons"/.test(homeHtml), 'home page should not show duplicate hero login buttons');
assert(homeHtml.indexOf('<strong>Admin Portal</strong>') > homeHtml.indexOf('<strong>Privacy Policy</strong>'), 'portal grid should place Admin Portal at the far-right/end position');

const kioskJs = read('kiosk.js');
assert(/runClubAdminSession/.test(kioskJs), 'kiosk should require an admin session');
assert(/admin\.html/.test(kioskJs), 'kiosk should redirect unauthenticated users to admin login');
assert(/PRAISE_MESSAGES/.test(kioskJs), 'kiosk should rotate playful praise messages after scans');

const adminDashboardHtml = read('admin-dashboard.html');
assert(/assets\/gwynne-park-logo\.svg/.test(adminDashboardHtml), 'admin dashboard should use the sharp Gwynne Park logo asset');
const dashboardBrandLink = adminDashboardHtml.match(/<a[^>]*brand-home-link[^>]*>/);
assert(dashboardBrandLink && /href="index\.html"/.test(dashboardBrandLink[0]), 'admin dashboard logo/banner should link back to the home page');
assert(/offline-queue-card/.test(adminDashboardHtml), 'admin dashboard should include an offline scan queue panel');
assert(/lb-medal-filter/.test(adminDashboardHtml), 'admin leaderboard should include a medal tier filter');
assert(/print-leaderboard-btn/.test(adminDashboardHtml), 'admin leaderboard should include a print poster button');
assert(/medal-rules/.test(adminDashboardHtml), 'admin awards area should show medal tier rules');
assert(/certificates-list/.test(adminDashboardHtml), 'admin awards area should include a certificates list');
assert(/sports-carnival-mode/.test(adminDashboardHtml), 'admin dashboard should include a Sports Carnival Mode checkbox');
assert(/add-student-form/.test(adminDashboardHtml), 'admin students area should include a manual add-student form');
assert(/generate-student-barcode-btn/.test(adminDashboardHtml), 'admin students area should include a generate barcode button');
assert(/new-student-first/.test(adminDashboardHtml) && /new-student-last/.test(adminDashboardHtml), 'admin add-student form should collect student names');

const adminDashboardJs = read('admin-dashboard.js');
assert(/MEDAL_TIERS/.test(adminDashboardJs), 'admin dashboard should calculate medal tiers');
assert(/renderOfflineQueue/.test(adminDashboardJs), 'admin dashboard should render offline queue batches');
assert(/printLeaderboardPoster/.test(adminDashboardJs), 'admin dashboard should print leaderboard posters');
assert(/renderCertificates/.test(adminDashboardJs), 'admin dashboard should render certificate readiness');
assert(/setSportsCarnivalMode/.test(adminDashboardJs), 'admin dashboard should persist Sports Carnival Mode setting');
assert(/generateBarcodeId/.test(adminDashboardJs), 'admin dashboard should generate unique student barcode IDs');
assert(/printStudentBarcodeCard/.test(adminDashboardJs), 'admin dashboard should print individual student barcode cards');

const parentHtml = read('parent.html');
assert(/id="parent-form"/.test(parentHtml), 'parent portal should expose a login form');
assert(/DEMO/.test(parentHtml), 'parent portal should show a DEMO hint');
assert(/parent\.js/.test(parentHtml), 'parent portal should load parent.js');
assert(!/Log Home Activity|Home Activity|parent-activity-form/.test(parentHtml), 'parent portal should not include home activity logging');

const parentJs = read('parent.js');
assert(/DEMO/.test(parentJs), 'parent portal should handle DEMO bypass');
assert(/RunClubScan/.test(parentJs), 'parent portal should use shared scanning roster data');
assert(/RunClubGoals/.test(parentJs), 'parent portal should use shared goals data');
assert(!/parent-activity-form|rc_selfreports/.test(parentJs), 'parent portal should not submit home activity logs');

const leaderboardHtml = read('leaderboard.html');
assert(/Total Leaderboard/.test(leaderboardHtml), 'leaderboard page should include a whole-school total leaderboard');
assert(/Senior/.test(leaderboardHtml) && /Year 5 \+ 6/.test(leaderboardHtml), 'leaderboard page should include Senior division');
assert(/Intermediate/.test(leaderboardHtml) && /Year 3 \+ 4/.test(leaderboardHtml), 'leaderboard page should include Intermediate division');
assert(/Junior/.test(leaderboardHtml) && /Year 1 \+ 2/.test(leaderboardHtml), 'leaderboard page should include Junior division');
assert(/Year 2/.test(leaderboardHtml) && /Year 3/.test(leaderboardHtml) && /Year 4/.test(leaderboardHtml) && /Year 5/.test(leaderboardHtml) && /Year 6/.test(leaderboardHtml), 'leaderboard page should include Year 2 through Year 6 views');
assert(/leaderboard\.js/.test(leaderboardHtml), 'leaderboard page should load leaderboard.js');

const leaderboardJs = read('leaderboard.js');
assert(/renderTotalLeaderboard/.test(leaderboardJs), 'leaderboard script should render total leaderboard');
assert(/DIVISIONS/.test(leaderboardJs), 'leaderboard script should define division groups');
assert(/YEAR_GROUPS/.test(leaderboardJs), 'leaderboard script should define year group views');

console.log('portal smoke checks passed');

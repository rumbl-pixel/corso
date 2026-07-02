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

// --- Task 2: admin-dashboard.html dropdown tab mirror ---
const dashboardHtml = read('admin-dashboard.html');
const dashboardNavMatch = dashboardHtml.match(/<nav class="main-nav"[^>]*>([\s\S]*?)<\/nav>/);
assert(dashboardNavMatch, 'admin-dashboard.html should have a <nav class="main-nav"> block');
assert(/id="nav-tab-mirror"/.test(dashboardNavMatch[1]), 'admin-dashboard.html dropdown should have a nav-tab-mirror container for the JS-mirrored tabs');

const dashboardJs = read('admin-dashboard.js');
assert(/navTabMirrorEl\.appendChild\(mirrorBtn\)/.test(dashboardJs), 'admin-dashboard.js should clone tab buttons into the nav-tab-mirror container');
assert(/activateAdminTab\(tabBtn\.dataset\.tab\)/.test(dashboardJs), 'the dropdown mirror should reuse activateAdminTab rather than duplicating tab-switch logic');

// --- Task 3: Scanner/Activity merge ---
const dashboardHtmlV2 = read('admin-dashboard.html');
assert(!/data-tab="scanner"/.test(dashboardHtmlV2), 'admin-dashboard.html should no longer have a separate Scanner tab id');
const activityDataTabCount = (dashboardHtmlV2.match(/data-tab="activity"/g) || []).length;
assert(activityDataTabCount === 1, 'admin-dashboard.html should have exactly one data-tab="activity" button, found ' + activityDataTabCount);
const activityPanelIdCount = (dashboardHtmlV2.match(/id="tab-activity"/g) || []).length;
assert(activityPanelIdCount === 1, 'admin-dashboard.html should have exactly one id="tab-activity" panel, found ' + activityPanelIdCount);
const activityPanelMatch = dashboardHtmlV2.match(/<div class="tab-panel active" id="tab-activity">([\s\S]*?)<!-- STUDENTS TAB -->/);
assert(activityPanelMatch, 'admin-dashboard.html should have a tab-activity panel followed by the Students tab');
assert(/id="scan-input"/.test(activityPanelMatch[1]), 'merged Activity panel should still contain the live scanner input');
assert(/id="log-activity-btn"/.test(activityPanelMatch[1]), 'merged Activity panel should contain the manual activity logging form');

const dashboardJs2 = read('admin-dashboard.js');
assert(/setProgrammingCoachWidgetVisibility\(activeTopTab&&activeTopTab\.dataset\.tab==='coach-hub'\?activeCoachHubSection:\(activeTopTab\?activeTopTab\.dataset\.tab:'activity'\)\);/.test(dashboardJs2), 'admin-dashboard.js tab fallback default should be activity, not scanner');

const indexHtmlV2 = read('index.html');
assert(!/tab=scanner/.test(indexHtmlV2), 'index.html should no longer link to the old scanner tab id');

// --- Task 4: WA School Holidays year filter ---
const dashboardJs3 = read('admin-dashboard.js');
assert(/WA_SCHOOL_HOLIDAYS\.filter\(function\(item\)\{return dateFromIso\(item\.start\)\.getFullYear\(\)===displayYear;\}\)/.test(dashboardJs3), 'renderWaHolidaySummary should filter WA_SCHOOL_HOLIDAYS down to the calendar\'s displayed year');
const calendarNavCallSites = (dashboardJs3.match(/renderEventCalendar\(\);renderWaHolidaySummary\(\);/g) || []).length;
assert(calendarNavCallSites === 4, 'all 4 places that change eventCalendarDate (prev/next/today/create-event) should also re-render the holiday list, found ' + calendarNavCallSites);

// --- Task 5: Timed Lap Events relocation ---
const dashboardHtmlV3 = read('admin-dashboard.html');
const activityPanelV2 = dashboardHtmlV3.match(/<div class="tab-panel active" id="tab-activity">([\s\S]*?)<!-- STUDENTS TAB -->/)[1];
assert(!/id="start-timed-btn"/.test(activityPanelV2), 'Timed Lap Events should no longer be inside the Activity panel');
const sportsPanelMatch = dashboardHtmlV3.match(/<div class="tab-panel coach-hub-section" id="tab-sports">([\s\S]*?)<!-- TRAINING TAB -->/);
assert(sportsPanelMatch, 'admin-dashboard.html should have a tab-sports panel followed by the Training tab');
assert(/id="start-timed-btn"/.test(sportsPanelMatch[1]), 'Timed Lap Events should now be inside the Sports tile panel');

console.log('dashboard nav cleanup checks passed');

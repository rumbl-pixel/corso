# Dashboard Nav & Admin UX Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trim `index.html`'s dropdown to logged-out-appropriate items, mirror `admin-dashboard.html`'s tabs into its dropdown, merge the Scanner/Activity tabs, filter WA School Holidays to one year at a time, relocate Timed Lap Events into Coach Hub, and fix a Coach Hub tile contrast bug plus a dark-mode tab color mismatch.

**Architecture:** Static-HTML edits for the two nav changes (no new auth/JS needed — `index.html`'s trim is unconditional, `admin-dashboard.html` is already login-gated so its dropdown always mirrors). The tab merge is an id rename + content relocation, not new markup. Two isolated CSS specificity overrides land in `theme-shadcn.css`, following the file's existing override pattern (loads after `styles.css`, wins ties by source order).

**Tech Stack:** Vanilla HTML/CSS/JS, no build step. Tests are plain Node scripts using string/regex assertions on file contents (`tests/*.test.js` house style — no DOM/browser test runner exists in this repo).

## Global Constraints

- No changes to any page's nav other than `index.html` and `admin-dashboard.html` (spec: Out of scope).
- No auth/session mechanism changes — `runClubAdminSession` and the existing hard-redirect gate in `admin-dashboard.js` are untouched.
- No data model or storage-key changes (`K.activity`, `K.sessions`, etc.) — UI/IA reorganization only.
- `npm test` must stay green throughout.
- Demo lock (`config.js`: `demoMode: true, syncEnabled: false, liveDataMode: false`) must remain untouched.

---

## File Structure

- **Create:** `tests/dashboard-nav-cleanup.test.js` — string/structural assertions for every change below, following the existing `tests/portal-smoke.test.js` idiom (local `assert`/`read`/`assertFile` helpers, plain top-to-bottom asserts, `console.log(...)` on success).
- **Modify:** `index.html` (nav trim, one quick-action link), `admin-dashboard.html` (dropdown mirror container, tab rename/delete, Timed Lap Events relocation), `admin-dashboard.js` (dropdown-mirror logic, tab fallback rename, WA holiday year filter + 4 call sites), `theme-shadcn.css` (two new override blocks), `package.json` (wire the new test file into `npm test`), all HTML pages (`theme-shadcn.css?v=` cache-bust, final task only).

---

### Task 1: Trim `index.html`'s dropdown to logged-out-appropriate items

**Files:**
- Modify: `index.html:24-34`
- Test: `tests/dashboard-nav-cleanup.test.js` (new file)

**Interfaces:**
- Produces: nothing consumed by later tasks — this is a self-contained static edit.

- [ ] **Step 1: Create the test file and write the failing test**

Create `tests/dashboard-nav-cleanup.test.js`:

```js
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
```

- [ ] **Step 2: Wire it into `npm test`**

Modify `package.json:9`, append `&& node tests/dashboard-nav-cleanup.test.js` to the end of the `test` script string:

```json
    "test": "node tests/portal-smoke.test.js && node tests/goals-baseline.test.js && node tests/backend-live-style.test.js && node tests/scanning-live-mode.test.js && node tests/supabase-staging.test.js && node tests/sync-workflow.test.js && node tests/dashboard-nav-cleanup.test.js",
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: throws `Error: index.html dropdown should have exactly 5 links, found 9`

- [ ] **Step 4: Replace the nav block**

Modify `index.html:24-34`, replacing:

```html
        <nav class="main-nav" aria-label="Primary navigation">
          <a href="index.html" aria-current="page"><span class="nav-icon" aria-hidden="true">⌂</span> Home</a>
          <a href="admin-dashboard.html?tab=students"><span class="nav-icon" aria-hidden="true">👥</span> Students</a>
          <a href="admin-dashboard.html?tab=scanner"><span class="nav-icon" aria-hidden="true">⏱</span> Sessions</a>
          <a href="admin-dashboard.html?tab=events"><span class="nav-icon" aria-hidden="true">▣</span> Events</a>
          <a href="leaderboard.html"><span class="nav-icon" aria-hidden="true">🏆</span> Leaderboards</a>
          <a href="admin-dashboard.html?tab=reports"><span class="nav-icon" aria-hidden="true">▮</span> Reports</a>
          <a href="admin-dashboard.html?tab=awards"><span class="nav-icon" aria-hidden="true">✪</span> Awards</a>
          <a href="admin-dashboard.html?tab=school-admin"><span class="nav-icon" aria-hidden="true">⚙</span> Settings</a>
          <a href="admin.html"><span class="nav-icon" aria-hidden="true">↪</span> Admin login</a>
        </nav>
```

with:

```html
        <nav class="main-nav" aria-label="Primary navigation">
          <a href="index.html" aria-current="page">Home</a>
          <a href="student.html">Student</a>
          <a href="parent.html">Parent</a>
          <a href="admin.html">Admin</a>
          <a href="leaderboard.html">Leaderboard</a>
        </nav>
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: prints `dashboard nav cleanup checks passed`

- [ ] **Step 6: Commit**

```bash
git add index.html package.json tests/dashboard-nav-cleanup.test.js
git commit -m "Trim index.html dropdown to logged-out-appropriate items"
```

---

### Task 2: Mirror `admin-dashboard.html`'s live tabs into its dropdown

**Files:**
- Modify: `admin-dashboard.html:24-30`, `admin-dashboard.js` (insert after line 636)
- Test: `tests/dashboard-nav-cleanup.test.js`

**Interfaces:**
- Consumes: `tabBtns` (`NodeList`, defined `admin-dashboard.js:550` as `document.querySelectorAll('.tab-btn')`), `activateAdminTab(tabName: string): boolean` (defined `admin-dashboard.js:596`).
- Produces: nothing consumed by later tasks (Task 3's tab rename is picked up automatically since this reads the live buttons at runtime).

- [ ] **Step 1: Write the failing test**

Append to `tests/dashboard-nav-cleanup.test.js` (before the final `console.log` line):

```js
// --- Task 2: admin-dashboard.html dropdown tab mirror ---
const dashboardHtml = read('admin-dashboard.html');
const dashboardNavMatch = dashboardHtml.match(/<nav class="main-nav"[^>]*>([\s\S]*?)<\/nav>/);
assert(dashboardNavMatch, 'admin-dashboard.html should have a <nav class="main-nav"> block');
assert(/id="nav-tab-mirror"/.test(dashboardNavMatch[1]), 'admin-dashboard.html dropdown should have a nav-tab-mirror container for the JS-mirrored tabs');

const dashboardJs = read('admin-dashboard.js');
assert(/navTabMirrorEl\.appendChild\(mirrorBtn\)/.test(dashboardJs), 'admin-dashboard.js should clone tab buttons into the nav-tab-mirror container');
assert(/activateAdminTab\(tabBtn\.dataset\.tab\)/.test(dashboardJs), 'the dropdown mirror should reuse activateAdminTab rather than duplicating tab-switch logic');
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: throws `Error: admin-dashboard.html dropdown should have a nav-tab-mirror container for the JS-mirrored tabs`

- [ ] **Step 3: Add the mirror container to the dropdown markup**

Modify `admin-dashboard.html:24-30`, replacing:

```html
        <nav class="main-nav">
          <a href="index.html">Home</a>
          <a href="kiosk.html">Kiosk</a>
          <a href="student.html">Student</a>
          <a href="parent.html">Parent</a>
          <button id="logout-btn" type="button">Log out</button>
        </nav>
```

with:

```html
        <nav class="main-nav">
          <div id="nav-tab-mirror"></div>
          <a href="index.html">Home</a>
          <a href="kiosk.html">Kiosk</a>
          <a href="student.html">Student</a>
          <a href="parent.html">Parent</a>
          <button id="logout-btn" type="button">Log out</button>
        </nav>
```

- [ ] **Step 4: Add the mirroring logic**

Modify `admin-dashboard.js`, inserting immediately after line 636 (`applyThemeSettings();`) and before line 637's blank line / line 638's `// === SCANNER ===` comment:

```js

  // --- Dropdown tab mirror: reflect the live top tab bar into the nav dropdown,
  // so a coach scrolled deep into the page doesn't need to scroll back to the top. ---
  var navTabMirrorEl = document.getElementById('nav-tab-mirror');
  if (navTabMirrorEl) {
    tabBtns.forEach(function (tabBtn) {
      var mirrorBtn = document.createElement('button');
      mirrorBtn.type = 'button';
      mirrorBtn.className = 'main-nav-tab-mirror';
      mirrorBtn.textContent = tabBtn.textContent;
      mirrorBtn.addEventListener('click', function () {
        activateAdminTab(tabBtn.dataset.tab);
        document.body.classList.remove('mobile-nav-open');
      });
      navTabMirrorEl.appendChild(mirrorBtn);
    });
  }
```

`#nav-tab-mirror` is a dedicated empty container placed at the top of the dropdown, so a plain `appendChild` per tab button is sufficient — no need to calculate an insertion point relative to the existing utility links.

- [ ] **Step 5: Run the test to verify it passes**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: prints `dashboard nav cleanup checks passed`

- [ ] **Step 6: Commit**

```bash
git add admin-dashboard.html admin-dashboard.js tests/dashboard-nav-cleanup.test.js
git commit -m "Mirror admin-dashboard tabs into the nav dropdown"
```

---

### Task 3: Merge the Scanner and Activity tabs into one "Activity" tab

**Files:**
- Modify: `admin-dashboard.html:39,43,55,146,606-620`, `admin-dashboard.js:1671`, `index.html:57`
- Test: `tests/dashboard-nav-cleanup.test.js`

**Interfaces:**
- Consumes: none new.
- Produces: the tab id `activity` (button `data-tab="activity"`, panel `id="tab-activity"`) — this is the id Task 5 relocates content *out of* (Timed Lap Events) and the id Task 2's mirror will display via `tabBtn.textContent`, automatically, with no changes needed to Task 2's code.

- [ ] **Step 1: Write the failing test**

Append to `tests/dashboard-nav-cleanup.test.js`:

```js
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: throws on the first unmet assertion (`data-tab="scanner"` still present)

- [ ] **Step 3: Rename the Scanner tab button, delete the separate Activity tab button**

Modify `admin-dashboard.html:39`, replacing:

```html
        <button class="tab-btn active" data-tab="scanner" role="tab" aria-selected="true" aria-controls="tab-scanner">&#128247; Scanner</button>
```

with:

```html
        <button class="tab-btn active" data-tab="activity" role="tab" aria-selected="true" aria-controls="tab-activity">&#128247; Activity</button>
```

Modify `admin-dashboard.html:43`, deleting the line entirely:

```html
        <button class="tab-btn" data-tab="activity" role="tab" aria-selected="false" aria-controls="tab-activity">&#9201; Activity</button>
```

- [ ] **Step 4: Rename the panel id, move the Log Activity Minutes card in, delete the old Activity panel**

Modify `admin-dashboard.html:55`, replacing:

```html
      <div class="tab-panel active" id="tab-scanner">
```

with:

```html
      <div class="tab-panel active" id="tab-activity">
```

Modify `admin-dashboard.html:146`, replacing the closing `</div>` of that panel:

```html
      </div>
```

with (inserting the Log Activity Minutes card before the panel closes):

```html
        <div class="card">
          <h2>&#9201; Log Activity Minutes</h2>
          <p style="color:#555;font-size:0.9rem;">Record distance-learning or off-track activity. 20 minutes of heart-pumping activity = 1 km credit.</p>
          <label>Student <select id="activity-student"></select></label>
          <label>Activity type <input type="text" id="activity-type" placeholder="e.g. Lunch run, home activity" /></label>
          <label>Minutes <input type="number" id="activity-minutes" min="1" placeholder="20" /></label>
          <button id="log-activity-btn" type="button">Log activity</button>
          <pre id="activity-result" hidden></pre>
          <div id="activity-log-list" style="margin-top:1rem;"></div>
        </div>
      </div>
```

Modify `admin-dashboard.html:606-620`, deleting the old Activity tab entirely:

```html

      <!-- ACTIVITY TAB -->
      <div class="tab-panel" id="tab-activity">
        <div class="card">
          <h2>&#9201; Log Activity Minutes</h2>
          <p style="color:#555;font-size:0.9rem;">Record distance-learning or off-track activity. 20 minutes of heart-pumping activity = 1 km credit.</p>
          <label>Student <select id="activity-student"></select></label>
          <label>Activity type <input type="text" id="activity-type" placeholder="e.g. Lunch run, home activity" /></label>
          <label>Minutes <input type="number" id="activity-minutes" min="1" placeholder="20" /></label>
          <button id="log-activity-btn" type="button">Log activity</button>
          <pre id="activity-result" hidden></pre>
          <div id="activity-log-list" style="margin-top:1rem;"></div>
        </div>

      </div>

```

Delete the whole block above (from the blank line through the trailing blank line), leaving the `<!-- EVENTS TAB -->` comment and `<div class="tab-panel" id="tab-events">` immediately following where this block used to be.

- [ ] **Step 5: Update the JS fallback default**

Modify `admin-dashboard.js:1671`, replacing:

```js
  setProgrammingCoachWidgetVisibility(activeTopTab&&activeTopTab.dataset.tab==='coach-hub'?activeCoachHubSection:(activeTopTab?activeTopTab.dataset.tab:'scanner'));
```

with:

```js
  setProgrammingCoachWidgetVisibility(activeTopTab&&activeTopTab.dataset.tab==='coach-hub'?activeCoachHubSection:(activeTopTab?activeTopTab.dataset.tab:'activity'));
```

- [ ] **Step 6: Update the stale quick-action-card link**

Modify `index.html:57`, replacing:

```html
            <a href="admin-dashboard.html?tab=scanner" class="quick-action-card">
```

with:

```html
            <a href="admin-dashboard.html?tab=activity" class="quick-action-card">
```

(`index.html:62`'s "Track setup" card already links to `?tab=activity` — no change needed there; it now correctly lands on the unified tab.)

- [ ] **Step 7: Run the test to verify it passes**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: prints `dashboard nav cleanup checks passed`

- [ ] **Step 8: Run the full suite and commit**

Run: `npm test`
Expected: all suites pass, including `portal smoke checks passed` (which asserts `admin-dashboard.html` contains the `Corso` brand string and other unrelated invariants — unaffected by this change).

```bash
git add admin-dashboard.html admin-dashboard.js index.html tests/dashboard-nav-cleanup.test.js
git commit -m "Merge Scanner and Activity tabs into a single Activity tab"
```

---

### Task 4: Filter WA School Holidays to one year at a time

**Files:**
- Modify: `admin-dashboard.js:3867-3884` (the `renderWaHolidaySummary` function body), `admin-dashboard.js:3938,3941,3944,3959` (four call sites)
- Test: `tests/dashboard-nav-cleanup.test.js`

**Interfaces:**
- Consumes: `eventCalendarDate` (`Date`, module-scoped var, defined `admin-dashboard.js:3808-3809`), `dateFromIso(value: string): Date` (defined `admin-dashboard.js:3839`), `WA_SCHOOL_HOLIDAYS` (array, defined `admin-dashboard.js:3824`).
- Produces: nothing consumed by later tasks.

- [ ] **Step 1: Write the failing test**

Append to `tests/dashboard-nav-cleanup.test.js`:

```js
// --- Task 4: WA School Holidays year filter ---
const dashboardJs3 = read('admin-dashboard.js');
assert(/WA_SCHOOL_HOLIDAYS\.filter\(function\(item\)\{return dateFromIso\(item\.start\)\.getFullYear\(\)===displayYear;\}\)/.test(dashboardJs3), 'renderWaHolidaySummary should filter WA_SCHOOL_HOLIDAYS down to the calendar\'s displayed year');
const calendarNavCallSites = (dashboardJs3.match(/renderEventCalendar\(\);renderWaHolidaySummary\(\);/g) || []).length;
assert(calendarNavCallSites === 4, 'all 4 places that change eventCalendarDate (prev/next/today/create-event) should also re-render the holiday list, found ' + calendarNavCallSites);
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: throws `Error: renderWaHolidaySummary should filter WA_SCHOOL_HOLIDAYS down to the calendar's displayed year`

- [ ] **Step 3: Filter the holiday list by the calendar's displayed year**

Modify `admin-dashboard.js:3880-3883`, replacing:

```js
    waHolidayListEl.innerHTML=WA_SCHOOL_HOLIDAYS.map(function(item){
      var active=today>=item.start&&today<=item.end;
      return '<div class="'+(active?'wa-holiday-item wa-holiday-item--active':'wa-holiday-item')+'"><strong>'+escapeHtml(item.name)+'</strong><span>'+escapeHtml(formatShortDate(item.start))+' - '+escapeHtml(formatShortDate(item.end))+' · '+daysInclusive(item.start,item.end)+' days</span></div>';
    }).join('');
```

with:

```js
    var displayYear=eventCalendarDate.getFullYear();
    var yearHolidays=WA_SCHOOL_HOLIDAYS.filter(function(item){return dateFromIso(item.start).getFullYear()===displayYear;});
    waHolidayListEl.innerHTML=yearHolidays.map(function(item){
      var active=today>=item.start&&today<=item.end;
      return '<div class="'+(active?'wa-holiday-item wa-holiday-item--active':'wa-holiday-item')+'"><strong>'+escapeHtml(item.name)+'</strong><span>'+escapeHtml(formatShortDate(item.start))+' - '+escapeHtml(formatShortDate(item.end))+' · '+daysInclusive(item.start,item.end)+' days</span></div>';
    }).join('');
```

- [ ] **Step 4: Re-render the holiday list whenever the calendar's displayed month/year changes**

Modify `admin-dashboard.js:3938`, replacing:

```js
    eventCalendarPrevEl.addEventListener('click',function(){eventCalendarDate.setMonth(eventCalendarDate.getMonth()-1);renderEventCalendar();});
```

with:

```js
    eventCalendarPrevEl.addEventListener('click',function(){eventCalendarDate.setMonth(eventCalendarDate.getMonth()-1);renderEventCalendar();renderWaHolidaySummary();});
```

Modify `admin-dashboard.js:3941`, replacing:

```js
    eventCalendarNextEl.addEventListener('click',function(){eventCalendarDate.setMonth(eventCalendarDate.getMonth()+1);renderEventCalendar();});
```

with:

```js
    eventCalendarNextEl.addEventListener('click',function(){eventCalendarDate.setMonth(eventCalendarDate.getMonth()+1);renderEventCalendar();renderWaHolidaySummary();});
```

Modify `admin-dashboard.js:3944`, replacing:

```js
    eventCalendarTodayEl.addEventListener('click',function(){eventCalendarDate=new Date();eventCalendarDate.setDate(1);renderEventCalendar();});
```

with:

```js
    eventCalendarTodayEl.addEventListener('click',function(){eventCalendarDate=new Date();eventCalendarDate.setDate(1);renderEventCalendar();renderWaHolidaySummary();});
```

Modify `admin-dashboard.js:3959`, replacing:

```js
    renderEventCalendar();
```

(the occurrence inside the `create-event-btn` click handler, immediately after `eventCalendarDate.setDate(1);` on the prior line) with:

```js
    renderEventCalendar();renderWaHolidaySummary();
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: prints `dashboard nav cleanup checks passed`

- [ ] **Step 6: Commit**

```bash
git add admin-dashboard.js tests/dashboard-nav-cleanup.test.js
git commit -m "Filter WA School Holidays to the calendar's displayed year"
```

---

### Task 5: Relocate Timed Lap Events into Coach Hub's Sports tile

**Files:**
- Modify: `admin-dashboard.html` (remove from the Activity panel, insert into `#tab-sports`)
- Test: `tests/dashboard-nav-cleanup.test.js`

**Interfaces:** none — pure relocation, the moved elements (`timed-student`, `start-timed-btn`, `stop-timed-btn`, `timed-state`, `timed-results`) are wired by id in JS elsewhere in the file, unaffected by DOM position.

**Note:** this task must run after Task 3 (the panel it's removing content from is `id="tab-activity"`, which only exists after Task 3's rename).

- [ ] **Step 1: Write the failing test**

Append to `tests/dashboard-nav-cleanup.test.js`:

```js
// --- Task 5: Timed Lap Events relocation ---
const dashboardHtmlV3 = read('admin-dashboard.html');
const activityPanelV2 = dashboardHtmlV3.match(/<div class="tab-panel active" id="tab-activity">([\s\S]*?)<!-- STUDENTS TAB -->/)[1];
assert(!/id="start-timed-btn"/.test(activityPanelV2), 'Timed Lap Events should no longer be inside the Activity panel');
const sportsPanelMatch = dashboardHtmlV3.match(/<div class="tab-panel coach-hub-section" id="tab-sports">([\s\S]*?)<!-- TRAINING TAB -->/);
assert(sportsPanelMatch, 'admin-dashboard.html should have a tab-sports panel followed by the Training tab');
assert(/id="start-timed-btn"/.test(sportsPanelMatch[1]), 'Timed Lap Events should now be inside the Sports tile panel');
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: throws `Error: Timed Lap Events should no longer be inside the Activity panel`

- [ ] **Step 3: Remove the Timed Lap Events card from the Activity panel**

Modify `admin-dashboard.html`, deleting this block (originally lines 132-145, now shifted a few lines later within the panel from Task 3's Step 4 insertion — locate it by its unique comment and content, it immediately follows the Offline Scan Queue card's closing `</div>` and precedes the newly-added Log Activity Minutes card):

```html

        <!-- TIMED LAP / TIMED MILE -->
        <div class="card">
          <h2>&#9201; Timed Lap Events</h2>
          <p style="color:#555;font-size:0.9rem;">Record split times and best times. Use for timed mile or timed lap events.</p>
          <label>Student
            <select id="timed-student"></select>
          </label>
          <div style="display:flex;gap:0.5rem;flex-wrap:wrap;">
            <button id="start-timed-btn" type="button">Start timer</button>
            <button id="stop-timed-btn" type="button" class="secondary">Stop &amp; save</button>
          </div>
          <p id="timed-state" style="margin-top:0.75rem;font-size:0.88rem;color:#555;">No timed run active.</p>
          <div id="timed-results" style="margin-top:0.75rem;"></div>
        </div>
```

- [ ] **Step 4: Insert it into the Sports tile, outside the Interschool Athletics Mode gate**

Modify `admin-dashboard.html`, inserting immediately after the `sports-command-card` div's closing `</div>` (the one that closes `<div class="card sports-command-card">`, originally line 422 — locate it by the blank line that follows it, immediately before `<div class="student-editor-overlay" id="athletics-event-modal" hidden>`):

```html

        <div class="card">
          <h2>&#9201; Timed Lap Events</h2>
          <p style="color:#555;font-size:0.9rem;">Record split times and best times. Use for timed mile or timed lap events.</p>
          <label>Student
            <select id="timed-student"></select>
          </label>
          <div style="display:flex;gap:0.5rem;flex-wrap:wrap;">
            <button id="start-timed-btn" type="button">Start timer</button>
            <button id="stop-timed-btn" type="button" class="secondary">Stop &amp; save</button>
          </div>
          <p id="timed-state" style="margin-top:0.75rem;font-size:0.88rem;color:#555;">No timed run active.</p>
          <div id="timed-results" style="margin-top:0.75rem;"></div>
        </div>
```

This places it as a sibling card within `#tab-sports`, directly below the Sports Command Centre card and above the (unrelated, hidden-by-default) team modal overlay — visible regardless of whether Interschool Athletics Mode is toggled on.

- [ ] **Step 5: Run the test to verify it passes**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: prints `dashboard nav cleanup checks passed`

- [ ] **Step 6: Commit**

```bash
git add admin-dashboard.html tests/dashboard-nav-cleanup.test.js
git commit -m "Move Timed Lap Events into Coach Hub's Sports tile"
```

---

### Task 6: Fix Coach Hub tile contrast under the shadcn skin

**Files:**
- Modify: `theme-shadcn.css` (append after line 269, the end of the file)
- Test: `tests/dashboard-nav-cleanup.test.js`

**Interfaces:** none.

- [ ] **Step 1: Write the failing test**

Append to `tests/dashboard-nav-cleanup.test.js`:

```js
// --- Task 6: Coach Hub tile contrast fix ---
const shadcnCss = read('theme-shadcn.css');
assert(/html\[data-skin="shadcn"\] \.coach-hub-tile:not\(\.active\) \{[^}]*background: var\(--card\)/.test(shadcnCss), 'theme-shadcn.css should give non-active Coach Hub tiles a flat --card background');
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: throws `Error: theme-shadcn.css should give non-active Coach Hub tiles a flat --card background`

- [ ] **Step 3: Append the override**

Modify `theme-shadcn.css`, appending after line 269 (end of file):

```css

/* Coach Hub tiles: non-active tiles are <button> elements, so the generic
   shadcn button rule above paints them solid --primary blue while their
   inner strong/span text still uses --obsidian-navy-3/--muted (colors sized
   for the old light-card look) — nearly invisible against the new blue.
   Give non-active tiles a flat neutral card treatment instead; leave
   .active alone, it already reads fine (hardcoded hex, untouched by the
   shadcn remap). */
html[data-skin="shadcn"] .coach-hub-tile:not(.active) {
  background: var(--card);
  border: 1px solid var(--border);
  color: var(--foreground);
}
html[data-skin="shadcn"] .coach-hub-tile:not(.active) strong {
  color: var(--foreground);
}
html[data-skin="shadcn"] .coach-hub-tile:not(.active) span {
  color: var(--muted-foreground);
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: prints `dashboard nav cleanup checks passed`

- [ ] **Step 5: Commit**

```bash
git add theme-shadcn.css tests/dashboard-nav-cleanup.test.js
git commit -m "Fix Coach Hub tile contrast under the shadcn skin"
```

---

### Task 7: Fix the dark-mode active-tab color mismatch

**Files:**
- Modify: `theme-shadcn.css` (append after Task 6's addition)
- Test: `tests/dashboard-nav-cleanup.test.js`

**Interfaces:** none.

- [ ] **Step 1: Write the failing test**

Append to `tests/dashboard-nav-cleanup.test.js`:

```js
// --- Task 7: dark-mode active-tab color ---
const shadcnCssV2 = read('theme-shadcn.css');
assert(/html\[data-skin="shadcn"\] \.tab-btn\.active \{[^}]*background: var\(--primary\)/.test(shadcnCssV2), 'theme-shadcn.css should route .tab-btn.active through var(--primary) instead of a hardcoded hex');
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: throws `Error: theme-shadcn.css should route .tab-btn.active through var(--primary) instead of a hardcoded hex`

- [ ] **Step 3: Append the override**

Modify `theme-shadcn.css`, appending at the end of the file (after Task 6's block):

```css

/* Top-level tab bar's active state: styles.css hardcodes #0755a3 with no
   dark-mode variant (confirmed via computed style — identical hex in both
   modes, so the "different blue" was the same color reading duller against
   a near-black background, not an actual mismatch). Route it through the
   shadcn primary token instead: light mode is unchanged, dark mode picks
   up the same muted navy every other primary element already uses. */
html[data-skin="shadcn"] .tab-btn.active {
  background: var(--primary);
  border-color: var(--primary);
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `node tests/dashboard-nav-cleanup.test.js`
Expected: prints `dashboard nav cleanup checks passed`

- [ ] **Step 5: Commit**

```bash
git add theme-shadcn.css tests/dashboard-nav-cleanup.test.js
git commit -m "Fix dark-mode active-tab color to use the shadcn primary token"
```

---

### Task 8: Cache-bust, full interactive verification, final check

**Files:**
- Modify: all HTML pages referencing `theme-shadcn.css?v=4` (bump to `?v=5`)

**Interfaces:** none — this is the integration/verification task.

- [ ] **Step 1: Bump the cache-buster**

Run:

```bash
node -e 'const fs=require("fs");let n=0;for(const f of fs.readdirSync(".").filter(f=>f.endsWith(".html"))){let s=fs.readFileSync(f,"utf8");if(s.includes("theme-shadcn.css?v=4")){fs.writeFileSync(f,s.replace(/theme-shadcn\.css\?v=4/g,"theme-shadcn.css?v=5"));n++;}}console.log("bumped "+n);'
```

Expected output: `bumped 11`

- [ ] **Step 2: Run the full test suite**

Run: `npm test`
Expected: all 7 suites pass, ending with `dashboard nav cleanup checks passed`.

- [ ] **Step 3: Interactive verification via the run-runclub-platform skill**

Using the Preview MCP driver (see `.claude/skills/run-runclub-platform/SKILL.md`):

1. `preview_start({ name: "static" })`, then load `/index.html` — confirm the dropdown shows exactly Home/Student/Parent/Admin/Leaderboard via `preview_snapshot`.
2. Load `/admin-dashboard.html` with a DEMO session (`localStorage.setItem('runClubAdminSession', ...)` via `preview_eval`, matching the pattern already used in this repo's history) — open the dropdown, confirm it lists all 7 mirrored tabs (Activity/Students/Coach Hub/Leaderboard/Events/Awards/School Admin) above the existing Home/Kiosk/Student/Parent/Log out links; click a mirrored item (e.g. "Coach Hub") and confirm the matching tab/panel activates.
3. Confirm the Activity tab shows both the live-scan section and the Log Activity Minutes section in one panel.
4. Navigate to the Events tab; confirm the WA Holidays list shows exactly 4 entries; click the calendar's next-month button until it crosses into the following year and confirm the holiday list updates to that year's 4 entries.
5. Navigate to Coach Hub; confirm Timed Lap Events now renders inside the Sports tile, visible with the Interschool Athletics Mode toggle both on and off.
6. Screenshot Coach Hub in light mode — confirm non-active tile text is legible (not blue-on-blue).
7. Set `data-theme="dark"` via `preview_eval`, screenshot the top tab bar — confirm the active tab's background is the muted shadcn dark-primary token, not `#0755a3`.
8. `preview_console_logs({ level: "error" })` on each page visited — expect no errors.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "Bump shadcn overlay cache version after dashboard nav/UX cleanup"
```

---

## Definition of Done

A coach can reach every admin-dashboard tab from the dropdown menu without scrolling; a logged-out visitor's dropdown only shows things they can actually use; Scanner and Activity are one tab; WA holidays show one year at a time; Timed Lap Events lives in Coach Hub; Coach Hub tiles and the dark-mode active tab are both legible and consistent with the rest of the shadcn skin; `npm test` is green.

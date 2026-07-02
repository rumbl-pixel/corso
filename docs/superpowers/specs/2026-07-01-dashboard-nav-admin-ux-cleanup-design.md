# Dashboard Nav & Admin UX Cleanup — Design

## Context

`index.html` (the app's home/"dashboard" screen) carries a 9-item hamburger dropdown — Home, Students, Sessions, Events, Leaderboards, Reports, Awards, Settings, Admin login — shown identically whether or not anyone is logged in. Six of those items deep-link into `admin-dashboard.html?tab=X`, which hard-redirects any logged-out visitor to `admin.html` and then, after login, drops them on the default tab, discarding which one they wanted. Every other page (`leaderboard.html`, `student.html`, `parent.html`, `about.html`, etc.) already has its own short, hand-tailored nav — `index.html` is the outlier.

Separately, five smaller UX/consistency issues were identified in `admin-dashboard.html` and its shadcn skin: a redundant Scanner/Activity tab split, an unfiltered 3-year holiday list, a misplaced Timed Lap Events tool, a Coach Hub contrast bug, and a hardcoded tab color that ignores the dark-mode palette.

## Goals

1. Trim `index.html`'s dropdown to what a logged-out visitor can actually use.
2. Let a logged-in coach reach every admin-dashboard tab from the dropdown, without scrolling back to the top of the page.
3. Merge the Scanner and Activity tabs (they're related but not identical — live barcode scanning vs. manual off-track minute logging) into one "Activity" tab.
4. Show WA School Holidays one school year at a time instead of all three years at once.
5. Move "Timed Lap Events" into Coach Hub's Sports tile.
6. Fix a contrast bug on non-active Coach Hub tiles and a dark-mode color mismatch on the active top-level tab.

## Out of scope

- No changes to any other page's nav (`leaderboard.html`, `student.html`, `parent.html`, `about.html`, `privacy-policy.html`, `interschool-team.html`, `student-profile.html`, `admin.html`, `kiosk.html`) — they're already appropriately scoped.
- No auth/session mechanism changes. `runClubAdminSession` (localStorage) and `admin-dashboard.html`'s existing hard-redirect-if-no-session gate are unchanged.
- No data model or storage-key changes (`K.activity`, `K.sessions`, etc.) — this is UI/IA reorganization only.
- No changes to the public leaderboard (`leaderboard.html`) itself — it already requires no login and already supports whole-school/division/year-group views with pseudonymized names for students without consent. Nothing to build there.
- The Coach Hub Sports tile's "Interschool Athletics Mode" toggle and its gated content are unchanged, other than Timed Lap Events being added above/outside that gate.

## Section 1: Navigation

### `index.html` — static trim, no JS

Replace the 9-item nav with a fixed 5-item list:

```html
<nav class="main-nav" aria-label="Primary navigation">
  <a href="index.html" aria-current="page">Home</a>
  <a href="student.html">Student</a>
  <a href="parent.html">Parent</a>
  <a href="admin.html">Admin</a>
  <a href="leaderboard.html">Leaderboard</a>
</nav>
```

Icons on the removed items go with them. This nav no longer uses icons, matching every other page's plain-text nav style.

### `admin-dashboard.html` — dynamic tab mirror

The page is already guaranteed-logged-in (hard redirect if no session), so no auth check is needed here — the dropdown just always mirrors the live tab bar. Its existing 5-item dropdown (Home, Kiosk, Student, Parent, Log out) gets a new block above those utility links, built at load time from the real `.tabs .tab-btn` elements:

```
Activity → Students → Coach Hub → Leaderboard → Events → Awards → School Admin
── (existing, unchanged) ──
Home → Kiosk → Student → Parent → Log out
```

Implementation: on `DOMContentLoaded`, iterate `document.querySelectorAll('.tabs .tab-btn')`, clone each into a dropdown `<a>` (or `<button>`) that calls the existing `activateAdminTab(btn.dataset.tab)` function directly — no duplicated tab-switch logic — and closes the mobile nav afterward. Because it reads the live buttons rather than a hand-written second copy, it can't drift out of sync if a tab is ever added, removed, or renamed (this is exactly what happens for free in Section 2 below).

## Section 2: Merge Scanner + Activity into "Activity"

Rather than building new merged markup, rename the existing Scanner tab's id and fold Activity's content into it:

- `admin-dashboard.html`: delete the separate `data-tab="activity"` / `id="tab-activity"` button+panel. Rename the Scanner tab's `data-tab="scanner"` → `data-tab="activity"`, `id="tab-scanner"` → `id="tab-activity"`, `aria-controls` updated to match, button label "Scanner" → "Activity". Keep the Scanner tab's existing 📷 icon (not Activity's ⏱) — the tab retains its structural identity (same panel, same position in the bar), only the label changes. The "Log Activity Minutes" card moves to the bottom of this renamed panel, below the existing Run Session Scanner / Scanner & Track Settings / Offline Scan Queue cards (Timed Lap Events, previously also in this panel, moves out per Section 3).
- `admin-dashboard.js`: one line to update — the fallback default in the tab-restore logic (`... : 'scanner'` → `... : 'activity'`, currently at the line computing `setProgrammingCoachWidgetVisibility`'s fallback argument). The tab-switching mechanism (`activateAdminTab`) is fully generic (matches `data-tab`/`id` by string), so no other logic changes are needed.
- `index.html`: the "Start scanning" quick-action card's link updates from `?tab=scanner` to `?tab=activity`. The "Track setup" card already links to `?tab=activity` and needs no change — it will now correctly land on the unified tab instead of (previously) the wrong one.
- No changes to any element ids *inside* the panel (`scan-input`, `activity-student`, `log-activity-btn`, etc.) or to the storage/backend functions that use them.

## Section 3: Smaller fixes

### WA School Holidays — one year at a time

`renderWaHolidaySummary()` currently renders all 12 entries in `WA_SCHOOL_HOLIDAYS` (3 school years × 4 holiday periods) unconditionally. Change it to filter to the 4 entries whose `start` date falls in the same calendar year as `eventCalendarDate` (the Events Calendar's currently-displayed month/year), and call `renderWaHolidaySummary()` alongside `renderEventCalendar()` in the prev/next/today month-navigation handlers. No separate year control — navigating the month calendar drives both widgets together. The "next break" summary line above the list stays today-relative (unchanged).

### Timed Lap Events → Coach Hub → Sports tile

Move the "Timed Lap Events" card (`timed-student`, `start-timed-btn`, `stop-timed-btn`, `timed-state`, `timed-results`) from the (renamed) Activity panel into `#tab-sports`, positioned immediately after the Sports Command Centre header — outside/above the `athletics-mode-shell` toggle-gated section, since timed laps/miles are a Run Club tool, not specific to Interschool Athletics Mode. Pure relocation: these elements are wired by id in JS regardless of DOM position, so no script changes beyond moving the HTML block.

### Coach Hub tile contrast fix

Root cause: `.coach-hub-tile` is a `<button>`, so the shadcn skin's generic `html[data-skin="shadcn"] button` rule paints its background solid `--primary` (blue) and its own text `--primary-foreground` (near-white) — fine. But the more-specific `.coach-hub-summary-grid strong`/`span` rules (defined for the *old* light-card look) still set text color to `--obsidian-navy-3`/`--muted`, which the shadcn overlay remaps to a dark-blue/gray nearly identical to the tile's new blue background. Fix: scoped override in `theme-shadcn.css` for non-active `.coach-hub-tile` — flat `var(--card)` background, `1px solid var(--border)`, `var(--radius)`, with `var(--foreground)` / `var(--muted-foreground)` text (matching how every other card looks under the shadcn skin), overriding the generic `button` rule. The `.active` tile is untouched — it already reads correctly, since it uses literal hardcoded hex colors unaffected by the shadcn remap.

### Dark-mode active-tab color

`.tab-btn.active` currently uses a hardcoded `background: #0755a3` with no dark-mode variant — confirmed via computed styles to be the literal identical value in both light and dark mode, so the perceived mismatch is the same absolute color reading duller against a near-black dark-mode background than against a light one. Fix (confirmed via the visual companion): swap the hardcoded hex for `var(--primary)`, so light mode keeps its current blue and dark mode picks up shadcn's more muted dark-mode primary token, matching every other primary-colored element in dark mode instead of standing out as a one-off value.

## Testing / verification

Using the `run-runclub-platform` skill's Preview MCP driver:

- `index.html`: confirm the dropdown shows exactly Home/Student/Parent/Admin/Leaderboard, no console errors.
- `admin-dashboard.html` (DEMO session): confirm the dropdown mirrors all 7 top tabs plus the existing utility links; click a mirrored item and confirm it activates the matching tab/panel.
- Confirm the "Activity" tab shows both the live-scan section and the Log Activity Minutes section; confirm `?tab=activity` deep-links correctly; confirm the old `?tab=scanner` quick-action card link was updated.
- Confirm the Events tab's WA Holidays list shows exactly 4 entries matching the calendar's current year, and updates when navigating months into a different year.
- Confirm Timed Lap Events renders inside the Sports tile, visible regardless of the Interschool Athletics Mode toggle state.
- Screenshot Coach Hub in light mode: non-active tiles must have readable text against their background (computed contrast, not just visual spot-check).
- Screenshot the top tab bar in dark mode: confirm the active tab's background resolves to the shadcn dark primary token, not the old hardcoded hex.
- `npm test` must remain green throughout — none of these changes touch tested file-existence/brand-string assertions, but running it confirms nothing else broke.

## Definition of done

A coach can reach every admin-dashboard tab from the dropdown menu without scrolling; a logged-out visitor's dropdown only shows things they can actually use; Scanner and Activity are one tab; WA holidays show one year at a time; Timed Lap Events lives in Coach Hub; Coach Hub tiles and the dark-mode active tab are both legible and consistent with the rest of the shadcn skin.

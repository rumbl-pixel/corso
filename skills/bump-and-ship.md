---
name: bump-and-ship
description: Cache-bust, test, and commit any change to a served asset (HTML/CSS/JS/service-worker) in the Corso repo.
---

# Bump and Ship

**When to use:** after ANY edit to a file the browser loads (the 11 HTML pages, styles.css, admin-dashboard.js, theme.js, service-worker.js, etc.) — the service worker is cache-first, so an unbumped change silently never reaches returning browsers.

## Context a new model needs

Corso is a static PWA, no build step. Three version surfaces must always move together:

1. **HTML query-string pins** — e.g. `<link href="styles.css?v=135">`, `<script src="admin-dashboard.js?v=111">`. styles.css is pinned in **all 11 HTML files**; admin-dashboard.js only in admin-dashboard.html.
2. **service-worker.js line 1** — `var CACHE_NAME = 'gwynne-park-run-club-vNNN';`. Bump on ANY served-asset change (including index.html content changes that carry no pin of their own).
3. **tests/portal-smoke.test.js** — hardcodes the exact pins as regex literals and FAILS on drift. Typically: cache name ×2 (~lines 105, 1316), styles pin ×3 (~lines 287, 1206, 1207), admin-dashboard.js pin ×2.

## Steps, in order

1. Find current numbers (never assume — they climb every task):
   ```bash
   grep -o "styles.css?v=[0-9]*" admin-dashboard.html | head -1
   grep -o "admin-dashboard.js?v=[0-9]*" admin-dashboard.html | head -1
   grep -o "gwynne-park-run-club-v[0-9]*" service-worker.js
   ```
2. Bump only what you touched, +1 each: CSS change → styles pin in all 11 HTML files; JS change → that JS pin; ANY change → the service-worker cache name.
3. `grep -n` the OLD numbers in `tests/portal-smoke.test.js`, then update every hit **with the Edit tool** (Read the file first — Edit fails on unread files).
4. Re-grep the test for the old numbers. Expect **zero** matches.
5. If you added a feature, add one smoke assertion (portal-smoke is string-match on file contents, not DOM): `assert(/id="my-new-id"/.test(pageHtml), '...')`.
6. Run the gate — all must pass:
   ```bash
   node tests/portal-smoke.test.js
   node tests/goals-baseline.test.js
   node --check admin-dashboard.js
   ```
7. Verify in the browser preview if the change renders (see qa-sweep skill).
8. `git add -A && git commit -q -m "<what changed>"`. **Do NOT push** — the user says "push it" when they want a deploy (push = live deploy, see deploy skill).

## Real example of a good final state (commit `b9a6943`, 2026-07-07)

- All 11 HTML files: `styles.css?v=134` → `styles.css?v=135`
- service-worker.js: `gwynne-park-run-club-v193` → `v194`
- portal-smoke pins updated at lines 105, 287, 1206, 1207, 1316 + two new assertions:
  ```js
  assert(/id="home-school-summary"/.test(homeHtml) && /scanning\.js/.test(homeHtml), 'home page should show a public school-wide summary with no login required');
  assert(!/admin-hub-tabs/.test(adminDashboardHtml), 'School Admin should not duplicate the large tiles with a second pill tab row');
  ```
- Output: `portal smoke checks passed` / `goal baseline checks passed` / clean `node --check`
- Commit message: subject line naming the change + short body explaining the why. Not pushed.

## Mistakes to avoid (observed and corrected in this repo)

- **Editing the test pins with `sed`/`perl`.** The pins are escaped regex literals (`styles\.css\?v=134`); shell-quoted replacements silently matched nothing — twice in one session. Use the Edit tool on the exact literal string.
- **Editing a file you only grepped.** The Edit tool requires a Read in-session first; this is the single most common failure of this ritual.
- **Assuming pin count or line numbers.** New assertions get added constantly; always grep for the old number fresh.
- **Bumping the pin but not the cache (or vice versa).** Looks fine to curl, breaks for every returning real browser. All surfaces move together, every time.
- **Pushing.** Commits are held locally until the user explicitly says "push it".

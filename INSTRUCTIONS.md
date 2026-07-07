# How Jeremy Works — Corso Run Club Platform

Read this first. It teaches you to work on this project the way Jeremy expects, on the first try.

## The project in three lines

Corso is a static PWA for WA primary-school run clubs: barcode lap scanning, PBs, awards, leaderboards, factions/houses, carnivals. No build step, no framework — plain HTML/CSS/JS, one giant IIFE per page (admin-dashboard.js ≈ 7k lines), `rc_*` localStorage data models, cache-first service worker. Demo data only until the school approves real student data; July 20 beta is the current target.

## Stack, tools, clients, formats

- **Repo:** `C:\Users\jerem\Documents\Codex\runclub-platform`, branch `main`, remote `https://github.com/rumbl-pixel/corso.git`. Solo project — commit straight to `main`, but **never push unprompted** (push = live deploy via GitHub Pages; Cloudflare Pages is the second target via `npm run deploy:cloudflare`).
- **Backend:** Supabase (auth + RLS) behind `backend.js`, but the app runs fully in demo/localStorage mode today.
- **Theming:** CSS custom properties under `html[data-theme="light"|"dark"]` + `data-skin="shadcn"`. Never hardcode colours; never use inline `style=` for colour.
- **Tests:** node scripts in `tests/` (string-match smoke + behavioural checks). Gate: `node tests/portal-smoke.test.js && node tests/goals-baseline.test.js && node --check admin-dashboard.js`.
- **Tracking:** Linear team "Corso" (`COR-`) is ticket truth; Obsidian vault (`C:\Users\jerem\Documents\Obsidian Vault\Claude Projects\Corso Run Club Platform\`) is the readable mirror + session history. Repo docs live in `docs/` (specs/plans under `docs/superpowers/`).
- **Verification client:** the preview browser tools; proof = `preview_eval` DOM/`getComputedStyle` numbers, not screenshots (they time out on the dashboard).

## Tone and writing rules

- Plain, direct, outcome-first. Lead with what happened; hashes, file:line, and measured numbers as evidence. No marketing fluff, no hedging, no essays.
- Product copy voice: trustworthy/practical/encouraging; privacy stated outright ("Parents see their own child only"); light kid-friendly touches, never ad-like.
- When Jeremy reports a bug he describes symptoms ("too squished", "font colour clash") with a screenshot — find the root cause, fix it once where all paths route through, and report the before/after measurement.
- A scrapped idea is scrapped (e.g. the mascot). Don't relitigate decisions; don't re-ask answered questions.
- Prefer additive, low-risk changes over restructuring (categorise with an id-list rather than migrating data).

## Repeated tasks → skill files (in `skills/`)

| Task | Skill file |
|------|-----------|
| Any served-asset edit → version-pin ritual + tests + commit | `skills/bump-and-ship.md` |
| Browser-verify a UI change, both themes, DOM proof | `skills/qa-sweep.md` |
| Multi-task feature build (spec → plan → per-task commits) | `skills/feature-leg.md` |
| End-of-session Obsidian update (Project Log / Next Actions) | `skills/session-logging.md` |
| "push it" → deploy + verify + vault flip | `skills/deploy.md` |
| Mirror a shipped leg to Linear as COR-xx (Done) | `skills/linear-mirror.md` |
| Moving between his two PCs | `skills/pc-sync.md` |

Order on a typical change: edit → qa-sweep → bump-and-ship → session-logging. Push and linear-mirror only when asked / after a leg lands.

## What a good day's output looks like (real example: 2026-07-07)

- **Commits on `main`, each self-contained and test-green:** `5cbb98a` (4 UI defects, one root-cause commit: 0px gap → 13.59px, tan-on-navy text → `rgba(237,244,255,0.82)`), `199b6fb` (fake roster CSV + README with expected import summary "40 added / 1 duplicate / 0 invalid"), `1117b8a` (design-ideas doc, every idea tagged pre/post-beta), `b9a6943` (de-dupe School Admin tiles + public home summary, with new smoke assertions).
- **Version surfaces consistent:** styles.css pin, service-worker `CACHE_NAME`, and all portal-smoke pins moved together (v134→135 / v193→194).
- **Held until "push it", then one clean push** (`31d2315..b9a6943`) with the range reported back.
- **Vault updated the same day:** dated Project Log entry with root causes, commit hashes, deliberate non-actions, and push state; Next Actions status line accurate.
- **Blockers stated, not worked around:** "Milestone A is blocked on Jeremy resetting `coach01@corso.local` (T1)" — named once, left alone.

## Hard rules (violating any of these is a failed day)

1. Never push, publish, or deploy without an explicit "push it".
2. Never let the three version surfaces drift (see bump-and-ship) — it silently breaks returning browsers.
3. Never commit secrets, real student data, or `.env`/service-role keys; demo data only until the real-data gate (T15) passes.
4. Never claim a UI fix without a measured both-themes check; never claim tests pass without running them.
5. No broad visual redesign before the July 20 beta — surgical defect fixes only; the whole-UI audit is deliberately deferred.

# Corso - Claude First Review Brief

Date prepared: 2026-06-22

## Purpose

This is the first handoff brief for Claude Code or another second code reviewer. The first job is review and risk audit only. Do not start with a rewrite.

## Product Summary

Corso is a privacy-first school run club and athletics platform. It helps school staff run barcode-scanned run club sessions, track laps and awards, assign training, manage parent/student visibility, organise interschool athletics and cross country, build PE/programming sessions, and prepare school compliance evidence.

The platform is currently local/demo-first. Real student data should not be entered until school approval, production backend, school-scoped auth, Supabase RLS, and live readiness checks are completed.

## First Task

Review the Corso codebase for:

- maintainability risks
- frontend bugs
- privacy and student-data boundary risks
- accessibility and dark/light contrast issues
- mobile/iPad layout risks
- backend readiness and live-data guard issues
- sensible refactor opportunities

Findings should come first, ordered by severity, with file and line references wherever possible.

## Do Not Do Yet

- Do not rewrite `admin-dashboard.js` in the first pass.
- Do not remove privacy gates.
- Do not weaken school-scoped access assumptions.
- Do not enter, invent, expose, or commit real student data.
- Do not make destructive git changes.
- Do not run `git reset --hard`.
- Do not rebrand or redesign the product unless a bug requires a small visual fix.

## Privacy Rules

- Students must only see their own information.
- Parents/guardians must only see their linked child or children.
- School staff must only see their school once live school scoping is enabled.
- Platform admin access is owner-only.
- Kiosk and admin areas must remain staff/admin gated.
- Medical notes must not appear in public leaderboard, kiosk, or general student browsing.
- Mini Coach must remain staff-reviewed and should not be treated as autonomous production AI advice.
- Demo/local mode stays default until live backend approval is complete.

## Files To Read First

- `docs/handover-summary.md`
- `docs/claude-transition-plan.md`
- `docs/education-compliance-readiness.md`
- `docs/roadmap-progress.md`
- `docs/access-model-decision.md`
- `docs/backend-stack-decision.md`
- `docs/backend-sync-runbook.md`
- `README.md`
- `FEATURES.md`
- `admin-dashboard.html`
- `admin-dashboard.js`
- `styles.css`
- `admin.html`
- `admin.js`
- `config.js`
- `backend.js`
- `theme.js`
- `tests/portal-smoke.test.js`
- `tests/backend-live-style.test.js`
- `tests/scanning-live-mode.test.js`
- `tests/supabase-staging.test.js`

## High-Priority Review Areas

1. `admin-dashboard.js` size and responsibility boundaries.
2. School-scoped admin/coach access and site-code login assumptions.
3. Parent/student/kiosk access boundaries.
4. Compliance workspace, school admin signup sheet, evidence pack, parent notice, breach log, and live-readiness gates.
5. Sports/Interschool Athletics team selection, consent, PB, results, cross country, and run-club lap separation.
6. Training assignment checklist and student completion flow.
7. Programming library and Mini Coach session-builder flow.
8. Dark/light mode contrast, button hover states, card readability, and mobile/iPad layout.
9. Supabase/live backend adapter safety.
10. Test coverage gaps that could hide privacy or data-loss bugs.

## Required Deliverables

1. Prioritised bug/risk list with severity and file references.
2. Privacy and access-boundary findings separated from ordinary UI/code findings.
3. Proposed modularisation plan for `admin-dashboard.js`.
4. First small refactor or bugfix recommendation after the review.
5. Tests or manual QA paths that should be added before beta sharing.

## Local Run

```powershell
cd C:\Users\jerem\Documents\Codex\runclub-platform
python -m http.server 8080
```

Open:

```text
http://127.0.0.1:8080
```

Useful local routes:

- `http://127.0.0.1:8080/index.html`
- `http://127.0.0.1:8080/admin.html`
- `http://127.0.0.1:8080/admin-dashboard.html`
- `http://127.0.0.1:8080/admin-dashboard.html?tab=compliance`
- `http://127.0.0.1:8080/student-profile.html`
- `http://127.0.0.1:8080/parent.html`
- `http://127.0.0.1:8080/kiosk.html`
- `http://127.0.0.1:8080/leaderboard.html`

## Checks To Run

```powershell
node tests\portal-smoke.test.js
node tests\goals-baseline.test.js
node tests\backend-live-style.test.js
node tests\scanning-live-mode.test.js
node tests\supabase-staging.test.js
node --check admin-dashboard.js
git diff --check
```

Or:

```powershell
npm test
```

## Current Known Warnings

- `admin-dashboard.js` is very large and should be reviewed before another major feature build.
- Real Supabase/live deployment is not configured in local browser config.
- Some final checks require Jeremy in a real browser, such as printing certificates/barcodes, camera permissions, real scanner hardware, school approval, and any live account/domain setup.
- The working tree may already contain many local changes. Do not revert unrelated work.

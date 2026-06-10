# Run Club Build Brief

Source: Run Club App-Site Build Docs A, B, and C.
Last updated: 2026-06-04.

## Product Goal

Build a school-based run club platform inspired by StrideTrack. The core loop is
student roster setup, unique barcode cards, rapid Bluetooth scanner lap capture,
lap totals on student profiles, admin/coach-assigned challenges, awards, and
progress visibility for students and parents.

Privacy is a first-class requirement. The demo can use fake local data, but real
student data must wait for authenticated accounts, school-scoped backend storage,
role-based access, audit logs, and disabled public demo access.

## MVP Scope

- Admin setup for school, classes/groups, students, and barcode cards.
- Tablet-optimized scanner kiosk for Bluetooth HID barcode scanners.
- Lap ledger and leaderboard by student, class, and school.
- Student portal with code-only login, stats, awards, personal goals, and
  coach-assigned goals.
- Parent portal with child progress, awards, goals, and home-activity submission.
- Awards engine for milestone laps and printable certificates.
- Reports and exports for sessions, leaderboards, awards, and activity logs.

## Phase 2 Scope

- Supabase/Postgres backend for cross-device sync.
- Parent account linking and stronger guardian access controls.
- House/class competitions and richer leaderboards.
- Certificates and award packs.
- Notifications for milestones and challenges.
- Term analytics and multi-school reporting.
- Offline scan queue with sync and conflict handling.
- Carnival/PB module for time, jump, throw, length, and sprint results.

## Core Data Model

The PDFs propose a relational model with:

- `schools`
- `groups` or classes
- `students`
- `laps`
- `awards`
- `student_awards`

Recommended additions before production:

- `users` and `school_users` for staff/admin auth and permissions.
- `events` for run sessions, jog-a-thons, PE classes, and custom lap lengths.
- `devices` for scanner/tablet registration.
- `scan_logs` or `ingest_logs` for duplicates, rejected scans, and device
  troubleshooting.
- `student_runner_access` or secure portal token records.
- Access model decision: staff/coaches are invite-only; students are passwordless through barcode, QR, or non-guessable access code; parents can search by child name but must confirm with a guardian code/link before the full profile opens. See `docs/access-model-decision.md`.
- Audit tables for manual adjustments and deleted laps.

## Business Rules

- Server timestamps only for real lap records.
- Ignore or reject duplicate scans for the same student within a configurable
  cooldown window, initially 30 seconds.
- Use idempotency keys on scan requests before production.
- After an accepted lap, update totals and unlock newly eligible milestone awards.
- Cumulative goals auto-progress from laps or distance.
- PB goals are manually logged for now: lower is better for time, higher is
  better for jump/throw/length.

## Current Repo State

- Static HTML/CSS/JS app on GitHub Pages.
- Root pages are deployable static files.
- Shared modules live under `src/` and are copied to root by `npm run build`.
- Demo data is stored in browser `localStorage`.
- Current portals support `DEMO` access for testing only.

## Production Privacy Gate

Before entering real student data:

1. Disable universal `DEMO` access.
2. Replace localStorage with authenticated backend storage.
3. Enforce school-scoped row-level security.
4. Add role-based permissions for admins, coaches, students, and parents.
5. Add audit logs for imports, scans, edits, exports, and deletions.
6. Use non-guessable student/parent portal tokens.
7. Document retention, export, deletion, and consent settings.

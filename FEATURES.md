# Run Club Connect — Prioritized Features

Inspired by Marathon Kids Connect + StrideTrack. Status as of this build.

## ✅ Completed (MVP v1)

- [x] Static site in GitHub: home, admin, dashboard, student portals
- [x] Local demo roster (students with laps, minutes, year, class, barcode)
- [x] Barcode scanning (admin dashboard) — Bluetooth keyboard/HID input, auto-submit
- [x] Sessions: open/close, session log, JSON/CSV export
- [x] Timed runs: start/stop timer, per-student history
- [x] Activity minutes: log minutes, convert 20 min = 1 km, store + export
- [x] Events: create program types (Run Club, Jog-a-thon, PE, etc.)
- [x] Leaderboard: rank by total distance with year/class filters
- [x] Awards: milestones at 5/10/25/50/100/200/500 laps
- [x] Certificates: printable per-student
- [x] Challenges: club-wide goals
- [x] Reports: full JSON export + leaderboard/activity CSV
- [x] Roster import: CSV with first/last/year/class, auto ID, skip duplicates
- [x] Barcode ID cards: printable
- [x] Student portal: code login, profile, ranks, awards
- [x] Student self-report form
- [x] School summary: total laps, km, marathon equivalents, active runners
- [x] **Tablet kiosk (`kiosk.html`)** — full-screen self-scan station with big
      green/red feedback, auto-focus input, idle attract state, auto-reset,
      undo-last-lap, PIN-gated exit *(added this build)*
- [x] **Modular `src/` structure** — shared scanning + data-tracking modules
      reused by admin and kiosk *(added this build)*
- [x] **Automated build script** (`build.sh`) — assembles modules to root + push

## 🔥 Now / Next (High priority)

- [ ] Connect real backend (Supabase/Postgres) — replace localStorage
      - Tables: schools, users, students, laps, sessions, events, activity, timed runs
      - Wire admin + student portals to read/write Supabase
- [ ] Multi-school + row-level security (add `school_id`, isolate per school)
- [ ] Self-report approval queue (admin Activity tab: approve/reject home logs)
- [ ] Parent portal (`parent.html`) — login tied to a student; view laps,
      distance, milestones, certificates; submit home activity
- [ ] Roles & permissions (Admin / Coach / Volunteer / Parent / Student)
- [ ] Camera-based QR/barcode scanning (fallback for no hardware scanner)

## 🟡 Later (Medium priority)

- [ ] PWA / installable mobile scanning ("Add to home screen", offline cache)
- [ ] Advanced reporting: grade/class summaries, per-runner history, award lists
- [ ] Student progress PDFs (one-page per-term summary)
- [ ] Onboarding wizard (track length, award thresholds, program types, roster)
- [ ] Parent home-logging flow into approval queue
- [ ] **Sports Carnival & Cross Country module with PB tracking**
      - "Carnivals" tab for Athletics + Cross Country
      - Event lists: 100m, 200m, 800m, long jump, high jump, shot put, discus, etc.
      - Per-event result entry (times, distances, heights); field-event attempts;
        lane-based track timing
      - Auto PB badges when a student beats their previous best
      - Show PBs on student profile; house points + age champion scoring + exports

## ⚪ Backlog (Low priority)

- [ ] Resources & lesson plans section
- [ ] Granular privacy controls (pseudonyms, consent flags, regional settings)
- [ ] UI/UX refinements for small screens

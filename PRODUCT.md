# Product

## Register

product

## Users

- **Coaches/staff** — run live sessions at the track/oval, scanning barcodes with a Bluetooth scanner or tablet kiosk. Need fast, low-friction interactions in the moment, plus setup/reporting tools (students, events, awards, reports) used between sessions.
- **Students** — log in with a simple username+password (or barcode at the kiosk) to see their own laps, distance, awards, and goals. No classmate data ever visible.
- **Parents/guardians** — check their own child's progress, awards, and goals from a lightweight portal.
- **Platform admins** — manage multiple schools, each with an isolated data boundary.

The job to be done: replace manual/paper lap tracking with barcode-based scanning, so coaches spend less time on admin and more time running the program, while students and parents get simple visibility into progress.

## Product Purpose

Corso (Marathon Kids/StrideTrack-inspired) is a school run-club platform: barcode lap tracking, kiosk scanning, leaderboards, awards, and reports. Success looks like schools adopting it in place of paper tracking, coaches saving real time each session, and students staying motivated through visible progress — all without exposing real student data before backend security (Supabase Auth, RLS, school approval) is fully proven. The app currently ships in demo mode by design until that bar is met.

## Brand Personality

Trustworthy, practical, encouraging. Voice is plain and direct — no marketing fluff. Privacy/safety framing is stated outright ("No ads. No tracking. Parents see their own child only.", "Beta demo" badges) rather than buried in fine print. Light kid-friendly touches (emoji, awards, certificates) without being gimmicky or ad-like.

## Anti-references

- Flashy consumer social-media or ad-driven SaaS dashboards — nothing that nudges engagement or resembles a dark pattern, given the school/children's-data context.
- The retired "Obsidian Glass" direction (heavy navy/gold glass blur, gold pill accents, ornate chrome) — superseded this session by a flatter shadcn-based look. New UI work should extend shadcn tokens, not reintroduce the old ornamentation.

## Design Principles

1. **Privacy and safety are load-bearing, not decorative.** Demo-mode/beta messaging and data-boundary language are first-class UI, not fine print.
2. **Speed at the track over polish in the office.** Live-session flows (scanner, timed laps) are optimized for fast, low-friction taps, not visual flourish.
3. **One coherent flat surface, not a costume.** The shadcn direction replaces the old glass/gold aesthetic; extend its tokens rather than reintroducing ornamentation.
4. **Show, don't oversell.** Plain, direct copy over marketing language, consistent with the practical/trustworthy personality.
5. **Assume an unfamiliar user, live, right now.** Every screen should read clearly to a coach or parent using it for the first time mid-session — clarity over cleverness.

## Accessibility & Inclusion

WCAG 2.1 AA target. Given the app handles school children's data, avoid any pattern that resembles consumer social/ad-driven engagement tactics. Respect `prefers-reduced-motion` for any transitions/animations.

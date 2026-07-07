# Design & UX Ideas — T17 / COR-21 (2026-07-07)

Extends the existing [Design Ideas note](../../../../Obsidian%20Vault/Claude%20Projects/Corso%20Run%20Club%20Platform/Design%20Ideas.md) (2026-07-04) and builds on the T16 [Competitor Research](../../../../Obsidian%20Vault/Claude%20Projects/Corso%20Run%20Club%20Platform/Competitor%20Research.md). Nothing below repeats ideas 1–8 from that note (leaderboard pseudonyms, iconography, celebratory scan animation, Run→Scan→Report onboarding, sync status, themed skins headline, branded reports, post-beta UI audit) — except themed skins, which T17 was asked to develop concretely (Section 2).

**Ground rules honoured throughout:**
- **No broad visual redesign before July 20** (standing decision). Every idea is tagged **pre-beta safe** (small, additive, low-risk) or **post-beta**.
- **No mascots.** The mascot concept was explored and scrapped by Jeremy. Skins below are *environments*, not characters.
- Kid-facing surface is small by design: student profile, kiosk scan moment, public leaderboard. Coaches run everything else.
- Idea #8 in the existing note (post-beta whole-UI audit, ~813 deferred findings) is the umbrella for any styling debt below — referenced, not re-scoped.

**Effort key:** S = under half a day · M = 1–3 days · L = a week+

---

## 1. Idea list

### A. PB-aware kiosk banner copy — **pre-beta safe · S**
The kiosk banner already swaps state text ("Ready to scan" → "Lap logged for Sarah"). Add copy variants for the moments that matter to a kid: new personal best, round-number lap (10th/25th/50th), first lap ever. Pure text/colour variants on the existing `#kiosk-banner` states — no animation system needed yet (that's existing idea #3).
*Touches:* `kiosk.html` / `kiosk.js` banner states. *Precedent:* Marathon Kids milestone celebrations (T16).

### B. Kiosk audio feedback — **pre-beta safe · S**
Distinct short sounds for scan-success, scan-error, and PB/milestone. At a track edge kids and coaches hear the confirmation without reading a screen — the single biggest seamlessness win for the actual scan moment. One `Audio` cue per state, with a mute toggle in the kiosk footer.
*Touches:* kiosk only. *Precedent:* standard in EZ Scan-class scanning hardware workflows (T16 notes EZ Scan's motivational interfaces; audio is the minimal cousin).

### C. Kiosk idle "attract" state — **pre-beta safe · S**
When no scan has happened for ~30s, the banner gently cycles friendly prompts ("Scan your card to log a lap!" / "Session total: 84 laps 🏃"). Makes the kiosk feel alive on a projector or propped iPad instead of a frozen "Ready to scan".
*Touches:* `kiosk.js` banner state machine. *Precedent:* none direct; kiosk-pattern standard.

### D. House/faction colour accents — **pre-beta safe · S–M**
Corso already has houses/factions and a House Competitions leaderboard. Thread each student's house colour through as a small accent: a coloured ribbon/dot on leaderboard rows, a tinted stat-tile border on the student profile, house colour on the kiosk "lap logged" banner. Cheap identity + belonging with zero layout change.
*Touches:* `leaderboard.js` row render, student profile stat tiles, kiosk banner. *Precedent:* none of the four competitors do faction identity — differentiator.

### E. One-tap DEMO login button — **pre-beta safe · S**
`student.html` tells kids to *type* DEMO. For the July 20 beta on demo data, replace the hint with a big friendly "Try the demo student" button that submits DEMO for them. Removes the one typing hurdle between a Year 1 kid and their first look at the app.
*Touches:* `student.html` only. *Precedent:* Student Lap Tracker's "deliberately simple" framing (T16).

### F. Kid-voice microcopy & empty states on the student profile — **pre-beta safe · S**
Audit the ~10 strings a student actually reads (empty timeline, zero laps, no awards yet) and rewrite in warm second-person kid voice: "No runs yet — see you at run club Friday!" instead of blank tables. Copy-only, no layout.
*Touches:* `student.js` / student-profile render strings. *Precedent:* Student Lap Tracker's plain-language framing (T16).

### G. School name in the home hero — **pre-beta safe · S**
Theme settings already store `appTitle`; the home hero says generic "Corso — Run. Track. Celebrate." and the topbar shows "School Run Club". Show the actual school's name in the hero/topbar so day-one beta feels like *their* app.
*Touches:* `index.html` + `theme.js` (read existing setting; display only). *Precedent:* Student Lap Tracker school-branded surfaces (T16).

### H. Kid-friendly barcode card refresh — **post-beta · M**
The printed barcode card is a kid's physical token of membership. Add a print template with house colour band, first name large, an optional theme border (ties into skins, Section 2), and lamination-friendly margins. Existing print flow stays as the default.
*Touches:* barcode-card print template in admin dashboard (Students tab). *Precedent:* Student Lap Tracker's laminated reusable ID cards are a selling point (T16).

### I. Milestone progress bar on the student profile — **post-beta · M**
Under the LAPS/KM tiles, one bar: "3.4 km to your 50 km badge!". Needs milestone thresholds defined (awards data already exists) and a small calc — that's why it's post-beta, but it's the highest-retention kid feature here: it gives every session a *next goal*.
*Touches:* student profile Overview tab. *Precedent:* Marathon Kids milestone celebrations; StrideTrack goal levels (T16).

### J. Streak tracker ("4 weeks in a row!") — **post-beta · M**
Attendance-streak chip on the student profile and optionally on the kiosk banner ("Sarah — 4 weeks straight! 🔥"). Habit formation is the club's actual mission; streaks celebrate showing up, not ranking — consistent with the "no competitive-pressure gamification" line in the existing note.
*Touches:* student profile; kiosk banner variant. *Precedent:* Marathon Kids habit framing (T16).

### K. Projector / assembly leaderboard mode — **post-beta · M–L**
`leaderboard.html` is eight stacked cards built for scrolling — unusable on a gym projector. A `?mode=projector` view: one section at a time, huge type, auto-rotating every ~15s, house totals prominent. Big assembly-day payoff, and pairs with carnivals.
*Touches:* `leaderboard.html`/`leaderboard.js` (additive mode, existing page untouched). *Precedent:* StrideTrack dashboards (T16).

### L. Leaderboard filter chips — **post-beta · M**
Same page, opposite problem for phones: eight cards is a long scroll. A sticky chip row (Whole school · Houses · Classes · Years · Divisions) that shows one section at a time. Structural enough to hold until after July 20; fold into the whole-UI audit (existing idea #8) if timing aligns.
*Touches:* `leaderboard.html` layout. *Precedent:* StrideTrack's individual/class/grade/school levels (T16).

### M. Coach end-of-session summary card — **post-beta · M**
When a coach ends a scanning session: one card with total laps, total km, number of PBs, biggest improver. One screenshot-able artifact to show at assembly or paste in the school newsletter — turns data entry into a payoff for the coach.
*Touches:* admin dashboard Activity tab / kiosk exit flow. *Precedent:* StrideTrack automated reporting (T16).

---

## 2. Themed skins, concretely (the T17 headline)

EZ Scan ships Pirate/Surfer/Western/Coach interfaces (T16). Corso's seam already exists: every page sets `data-skin="shadcn"` on `<html>` and the theme is CSS-variable-driven with a light/dark toggle. Skins are a **second, orthogonal attribute** — e.g. `data-flair="reef"` — so they layer on top of shadcn and both light and dark modes without touching the base theme. No rebuild, no mascots.

**What a skin controls (and only this):**
- **Accent token overrides** — a small set of CSS variables: accent colour, banner/hero gradient, badge and stat-tile tint. Base surface, text, and spacing tokens are *never* overridden, so light/dark contrast guarantees hold.
- **One header art strip** — a single decorative SVG/PNG band behind the kid-facing page headers (student profile, kiosk, leaderboard). One asset per skin per mode (light/dark), lazy-loaded.
- **Celebration flavour** — which emoji/confetti set the (future) celebratory scan moment uses, and the kiosk banner's success tint.
- **Card edge style** — optionally border-radius/border-colour of stat tiles. Nothing structural.

**What a skin never touches:** admin dashboard, layout, typography scale, iconography, forms. Skins are scoped by body class to the three kid-facing pages only.

**Example themes (environments, not characters — mascots are scrapped):**
1. **Reef** — WA-coastal blues/teals, wave header band, bubble confetti. Default candidate: on-brand with the existing navy.
2. **Outback Trail** — warm ochre/eucalypt greens, horizon band. Distinctly Australian; no competitor has this.
3. **Space Sprint** — deep purple/starfield band, star confetti. Naturally excellent in dark mode.

**Rollout:** per-school setting stored alongside the existing theme settings (`appTitle`/logo already live there), default "none" (= current look). Coach picks it in School Admin; students never choose. Start with two skins; a third only if the first two get used. **Effort: M** for the mechanism + first two skins. **Tag: post-beta** (new setting + assets = not July-20 material), but the `data-flair` attribute and token contract could be stubbed pre-beta in an hour if desired.

---

## 3. Recommendations (feeds T18)

### Pre-beta shortlist (max 3 — smallest effort, highest delight)
1. **B — Kiosk audio feedback (S).** The scan is the product's one magic moment for a kid; sound makes it land from three metres away.
2. **E — One-tap DEMO button (S).** Directly de-risks the July 20 beta itself: demo data, young kids, zero typing.
3. **A — PB-aware kiosk banner copy (S).** Copy-only variants on existing states; makes PBs — Corso's core promise — visibly celebrated on day one.

(D — house colour accents — is the first alternate if one of the above drops.)

### Recommended first post-beta wave
1. **Themed skins v1** (mechanism + Reef & Space Sprint) — the T17 headline and the clearest differentiator vs. Marathon Kids/StrideTrack.
2. **I — Milestone progress bar** + **J — streak tracker** together (shared student-profile work, both habit-oriented not rank-oriented).
3. **K — Projector leaderboard mode** — assembly/carnival payoff that makes the whole school see the club.

Everything else (H, L, M) queues behind these and can ride along with the post-beta whole-UI audit (existing idea #8).

---

*Sources: T16 Competitor Research (StrideTrack, Marathon Kids Connect, Student Lap Tracker, EZ Scan 3.0) and direct skim of `index.html`, `student.html`, `kiosk.html`, `leaderboard.html`, `admin-dashboard.html` on 2026-07-07.*

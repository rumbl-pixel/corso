---
name: qa-sweep
description: Browser-verify a UI change in the Corso admin dashboard / portals, in both light and dark themes, with DOM-level proof.
---

# QA Sweep

**When to use:** after any change that renders in a page — before committing (bump-and-ship step 7 calls this).

## Context a new model needs

- Serve via the preview tools (`preview_start` with the `runclub-platform` launch config, port 8080). Pages: index.html, admin-dashboard.html (heaviest), student.html, parent.html, leaderboard.html, kiosk.html.
- Theme is `html[data-theme="light"|"dark"]`; skin is `data-skin="shadcn"`. All colours should come from CSS variables (`--muted`, `--line`, `--text`…) that adapt per theme.
- Demo data auto-seeds into localStorage (`rc_*` keys) on first load.

## Steps, in order

1. Start/reuse the preview server; navigate to the changed page (`preview_eval: window.location.href='http://localhost:8080/<page>'`).
2. Assert the change exists via DOM query, not eyeballing:
   `preview_eval` → `document.getElementById('...')`, `querySelectorAll(...).length`, text content.
3. If behaviour changed, exercise it: `preview_click` the control, then re-assert state (panel `.active`, rendered rows, etc.).
4. Check **both themes**. Flip with `document.documentElement.setAttribute('data-theme','dark')`, then read `getComputedStyle(el).color` / `.backgroundColor` on the changed elements. Text and its background must clearly differ in both modes.
5. Check spacing where elements stack: `elBelow.getBoundingClientRect().top - elAbove.getBoundingClientRect().bottom` — a gap of 0px between sibling sections is a defect.
6. Check console: `preview_console_logs` level=error must be empty.
7. Clean up any `rc_*` localStorage test data you seeded.
8. Proof to the user = the eval numbers (colours, gaps, counts). `preview_screenshot` frequently **times out** on admin-dashboard — use it only as an optional final visual, never as the verification.

## Real example of a good final output (Sports Command Centre fix, commit `5cbb98a`, 2026-07-07)

> - Gap between `.athletics-command-centre` and `.sports-workflow-strip`: **0px → 13.59px**
> - Insight-card `p` colour in dark mode: `rgb(218,205,176)` (tan, unreadable) → `rgba(237,244,255,0.82)` on background `rgba(7,20,38,0.66)`; light mode unchanged (`rgb(80,96,114)` on cream)
> - Active category pill: navy `#071426` on near-transparent dark → same navy on gold gradient `linear-gradient(180deg, rgba(255,248,221,0.98), rgba(242,216,145,0.88))`
> - Inactive pills unchanged: `#d7e6fa` on dark — readable
> - Verified live at `?v=134` after clearing SW cache, both themes, active/inactive states

Every claim is a measured value, both themes were checked, and the before/after is explicit.

## Mistakes to avoid (observed and corrected in this repo)

- **Inline styles beat every CSS rule.** `style="color:#555"` in HTML made intro text invisible in dark mode; no dark-theme CSS could override it. Fix by replacing the inline style with a class using theme variables (e.g. `.resource-intro { color: var(--muted); }`).
- **Equal-specificity cascade losses.** A dark-mode fix added early in styles.css silently lost to `body:not(.page-kiosk) .card p { color: var(--corso-muted) }` (~line 7391). If a colour doesn't take effect, check what rule actually wins and place yours after it.
- **Trusting the screenshot.** It times out on the heavy dashboard and can't prove colour values anyway. DOM/`getComputedStyle` assertions are the proof.
- **Checking only one theme.** The recurring user-reported defect classes here are (a) low-contrast text in dark mode and (b) zero-gap "squished" stacked sections — both invisible if you only test light mode with generous whitespace.
- **Hardcoding new colours.** Reuse the existing theme variables or an existing precedent (e.g. the gold-gradient chip treatment) instead of inventing values.

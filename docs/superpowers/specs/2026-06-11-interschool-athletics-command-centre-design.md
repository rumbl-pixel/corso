# Interschool Athletics Command Centre Design

## Goal

Make Interschool Athletics Mode feel like a usable admin team-builder rather than one long event list. The section should help staff move from consent tracking to event selection to team readiness without leaving the admin dashboard.

## Scope

This pass improves the existing admin-only carnival section. It does not add live backend tables yet and does not replace the existing interschool results or cross-country features.

## Current System

- `admin-dashboard.html` contains the Interschool Athletics Mode toggle, consent summary, event list, and team-selection modal.
- `admin-dashboard.js` stores team selections in `rc_athletics_team_selections`.
- Student eligibility is controlled by `consent_status === "granted"`.
- Event definitions come from `window.RunClubGoals.INTERSCHOOL_ATHLETICS_EVENTS`.
- Event results remain separate in `rc_athletics_results`.

## Proposed Experience

### Command Centre Panel

When Interschool Athletics Mode is on, show a compact command centre with:

- Consent summary.
- Team readiness helper cards.
- Category sliders for Sprints, Middle Distance, Ball Games, Relays, Jumps, Throws, and Cross Country.
- Only expanded categories show their event chips.

The default open categories should be Sprints and Middle Distance because they are common early planning areas.

### Category Sliders

Each category slider should:

- Toggle its event group open or closed.
- Show a small count such as `3 events`.
- Show selected athlete count across that category when possible.
- Persist open/closed state locally in the admin browser.

### Event Chips

Each event chip should show:

- Event name.
- Year/division guidance.
- Number selected.
- A visual status:
  - Empty: no athletes selected.
  - Partial: at least one athlete selected.
  - Ready: meets a basic team-size target.

Team-size targets are lightweight defaults only:

- Individual events: ready at 1 selected.
- Relays and ball games: ready at 4 selected.
- Cross Country: ready at 1 selected.

### Team Selector Modal

Clicking an event opens the existing modal, upgraded with:

- Search by name, ID, year, class, house, team, or pseudonym.
- Year filter.
- Division filter: Junior, Intermediate, Senior.
- Toggle: Show pending consent.
- Checkbox selection.
- Summary row showing selected, eligible, pending shown, and filtered counts.

By default, only consent-approved students are selectable. Pending students can be shown for planning, but their checkboxes should be disabled until consent is granted.

### Helper Cards

Add small cards at the top of the command centre:

- Consent Follow-Up: pending or declined consent count.
- Empty Events: events with no selected athletes.
- Multi-Event Athletes: students selected in two or more events.
- Team Ready: ready events count.

These are informational only and should not have hover highlight.

## Data Flow

- Existing student records remain the source of truth for consent and profile info.
- Team selections continue to use `rc_athletics_team_selections`.
- Category open state uses a new local key, `rc_athletics_category_state`.
- No student is removed from saved team selections automatically, but selection counts and modal checked states should ignore or disable students whose consent is not granted.

## Accessibility And UX

- Category sliders are buttons with `aria-expanded`.
- Modal close works by X, Cancel, and backdrop click.
- Inputs and filters must be reachable by keyboard.
- Dark mode must keep event chips, helper cards, disabled pending rows, and selected rows readable.
- Mobile layout should stack filters and keep the modal within viewport height.

## Testing

Update smoke tests to verify:

- Command centre markup exists.
- Category slider controls exist.
- Category state storage key exists.
- Modal includes year filter, division filter, and pending-consent toggle.
- Pending students are disabled unless consent is granted.
- Helper cards render from the same team-selection data.
- Styles include dark-mode-safe command centre, category slider, and modal filter rules.

Manual browser checks:

- Toggle Interschool Athletics Mode on/off.
- Expand/collapse categories.
- Open an event modal.
- Search/filter students.
- Confirm no overflow on desktop and phone width.


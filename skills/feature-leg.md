---
name: feature-leg
description: Run a multi-task Corso feature build the established way - brainstorm, spec, plan, then task-by-task build with verify+commit between tasks.
---

# Feature Leg

**When to use:** any feature request bigger than a one-file fix (new tab, new data model, multi-part overhaul). Small defect fixes skip this and go straight to bump-and-ship.

## Context a new model needs

- The codebase is one big static PWA; admin-dashboard.js alone is ~7,000 lines of a single IIFE. There are no modules — features are functions + `rc_*` localStorage models + string-built HTML.
- Established pipeline (superpowers skills): **brainstorm** (clarifying Q&A with the user) → **spec** (`docs/superpowers/specs/YYYY-MM-DD-<name>-design.md`) → **plan** (`docs/superpowers/plans/YYYY-MM-DD-<name>.md`, numbered tasks) → **build** one task at a time, each ending in tests + browser QA + its own commit.
- Standing constraints: demo data only until the school approves real data; no broad visual redesign before the July 20 beta; the user's explicit scrapping of an idea is final unless they reopen it.

## Steps, in order

1. Brainstorm with the user until the model of the feature is agreed (the carnival leg took 5 clarifying Q&As before any code). Capture decisions in the spec.
2. Write the spec: goals, **non-goals/untouched areas**, terminology, data model, UI flow, testing plan, resolved edge cases, build order.
3. Write the plan: numbered tasks, each independently verifiable and committable.
4. Build task N: implement → add its smoke assertion(s) and, for pure logic (points math, splits), a real behavioural `tests/<name>.test.js` → qa-sweep → bump-and-ship commit. Then task N+1.
5. Final task is always a verification gate: all suites green, version pins consistent, end-to-end browser QA of the whole leg.
6. Log the leg (session-logging skill) and mirror it (linear-mirror skill).

## Real example of a good final output (spec excerpt, docs/superpowers/specs/2026-07-05-carnival-input-optimisation-design.md)

> ## Non-goals / what stays untouched
> - **The Interschool Athletics Command Centre is not touched.** It keeps its age-band events (`junior-50m`, etc.), `studentMatchesAthleticsDivision`, and `divisionForStudentFilter`. Carnival gets its own event + division model, decoupled. (Confirmed keep-separate decision, 2026-07-05.)
> ...
> ## Build order (for the plan)
> 1. Editable factions in Settings + app-wide dropdowns (self-contained, unblocks clean faction data).
> 2. Carnival event list decoupling + points mode/tier model.
> 3. Division data model + Phase A setup (times, auto-split, manual adjust).
> 4. Phase B record flow restructure (Event → Year Group → Division).
> 5. Champions regroup by year group + Mini Coach division checks.
> 6. Mock-carnival seed + clear.
> 7. Cache bump, tests, full browser QA.

That leg shipped as 7 commits (`482a53e`..`31d2315`), each task verified before the next started, and the final QA gate caught nothing because every task had already been QA'd.

## Mistakes to avoid (observed and corrected in this repo)

- **Touching the "untouched" list.** Carnival and Interschool share concepts (events, divisions) but were explicitly decoupled; a shared refactor would have broken the working Interschool flow. Write the non-goals down and honour them.
- **Restructuring data when categorising suffices.** Splitting the session-plan library into Run Club/Sport areas was done with a 5-id allowlist + one category function — zero changes to the 22 template objects. Prefer additive categorisation over migrations.
- **Big-bang commits.** Every leg here is per-task commits; when a task's subagent died mid-work (session usage caps), the partial work was finishable precisely because the previous task was already committed.
- **Skipping the behavioural test on money/logic paths.** The QA gate on the first carnival leg caught `parsePointsScheme('') → [0]` zeroing ALL scores — points math and auto-split now have real `tests/*.test.js` self-checks, not just string-match smoke assertions.
- **Reviving scrapped ideas.** The mascot concept was explored and then explicitly scrapped by the user; scrapped means scrapped (a later design doc deliberately proposed environment themes "no mascots — that concept stays scrapped").

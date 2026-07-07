---
name: pc-sync
description: Keep the Corso repo in sync when moving between the user's two PCs, via the existing sync scripts.
---

# PC Sync

**When to use:** at the start of any work session ("sit down") and at the end of any work session ("stand up") on either PC. GitHub is the single source of truth; project folders are never copied between machines.

## Context a new model needs

- Scripts already exist — do not reinvent them: `scripts/sync-start.ps1` (fetch + `git pull --ff-only` + `npm install`) and `scripts/sync-finish.ps1 -Message "..."` (core checks + commit + push).
- Canonical doc: `docs/sync-between-pcs.md`.
- Note the tension with the deploy skill: `sync-finish.ps1` **pushes**, and a push deploys. Only use sync-finish when leaving a machine with work that is meant to go live/travel; if commits are being deliberately held for review, don't run it — hold the push per the deploy skill.

## Steps, in order

1. Sitting down: `cd C:\Users\jerem\Documents\Codex\runclub-platform` then `.\scripts\sync-start.ps1`.
2. If `--ff-only` pull fails, the machines have diverged — stop and reconcile manually (rebase/merge with the user), never force.
3. Work normally.
4. Leaving the machine (and the work should travel): `.\scripts\sync-finish.ps1 -Message "Describe what changed"`.
5. On the other PC, start again at step 1.

## Real example of a good final output (the daily rule, docs/sync-between-pcs.md)

> 1. Start work: `.\scripts\sync-start.ps1`
> 2. Work on Corso.
> 3. Finish work: `.\scripts\sync-finish.ps1 -Message "What changed"`
> 4. Move to the other PC.
> 5. Start again with `.\scripts\sync-start.ps1`

## Mistakes to avoid (from the repo's own rules)

- **Never copy `node_modules` between PCs** — `sync-start.ps1` runs `npm install` for exactly this reason.
- **No secrets through GitHub**: no `.env`, Supabase service-role keys, or passwords in the repo; `config.js` stays local-safe (`config.example.js` is the committed template).
- **No real school/student data in the repo** — demo data only until the approval gate passes.
- **Don't bypass `--ff-only`** with a forced pull/push when histories diverge; that's how one machine's held commits get destroyed.
- **Remote URL**: the repo moved to `https://github.com/rumbl-pixel/corso.git` (2026-07-07); a fresh clone on the second PC should use the new URL even though the old one redirects.

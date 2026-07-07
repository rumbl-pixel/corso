---
name: deploy
description: Push held Corso commits and deploy to the live demo URLs, with the pre-deploy gate.
---

# Deploy ("push it")

**When to use:** ONLY when the user explicitly says "push it" (or equivalent). Never push on your own initiative — commits are deliberately held locally for eyeball review first.

## Context a new model needs

- Remote: `https://github.com/rumbl-pixel/corso.git` (moved 2026-07-07 from `rumbl-pixel/runclub-platform` — if a push prints a "repository moved" warning, `git remote set-url origin` to the new URL).
- **A push to `main` IS a production deploy**: GitHub Pages auto-deploys from `main`. There is also a Cloudflare Pages target (`npm run deploy:cloudflare`) — "both demo URLs".
- Pre-deploy gate: `npm run check:predeploy-safety` (scripts/predeploy-safety-check.js); the full battery is `npm test`.

## Steps, in order

1. Confirm the working tree is clean and every held commit was test-verified when made (`git status --short`, `git log origin/main..HEAD --oneline`).
2. Run the fast gate if anything feels unverified: `node tests/portal-smoke.test.js && node tests/goals-baseline.test.js && node --check admin-dashboard.js`.
3. `git push origin main`.
4. Read the push output: confirm the `old..new main -> main` range covers every held commit; act on any remote-moved warning.
5. If the Cloudflare target is in use this cycle: `npm run deploy:cloudflare` (runs its own check chain first).
6. Report the pushed range to the user and update the vault (see session-logging skill) — the Next Actions "status in one line" must flip from "N commits behind" to "live and current".

## Real example of a good final output (2026-07-07)

```
$ git push origin main
remote: This repository moved. Please use the new location:
remote:   https://github.com/rumbl-pixel/corso.git
To https://github.com/rumbl-pixel/runclub-platform.git
   31d2315..b9a6943  main -> main
```

Followed by: `git remote set-url origin https://github.com/rumbl-pixel/corso.git`, then a report to the user — "Pushed — 31d2315..b9a6943, all 6 commits deployed" — and a vault update naming each commit hash now live.

## Mistakes to avoid (observed and corrected in this repo)

- **Pushing without being asked.** The user holds pushes to review visually first (e.g. held the dark-mode logo fix overnight). "Commit" never implies "push".
- **Treating push as safe/reversible.** It deploys to real demo URLs schools may be looking at. The commit is the checkpoint; the push is the release.
- **Ignoring the moved-repo warning.** It works via redirect today, but the remote should be updated the first time it appears.
- **Forgetting the vault.** The Next Actions note says which commits are live vs held; a push without updating it makes the next session's "what's deployed?" answer wrong.

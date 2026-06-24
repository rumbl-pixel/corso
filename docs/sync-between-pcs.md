# Sync Corso Between Two PCs

Use GitHub as the single source of truth. Do not copy the project folder manually between computers.

## First Time On The Other PC

Install Git and Node.js, then clone the project:

```powershell
cd $HOME\Documents
git clone https://github.com/rumbl-pixel/runclub-platform.git
cd runclub-platform
.\scripts\sync-start.ps1
```

## Start Work

Run this every time you sit down at either PC:

```powershell
cd C:\Users\jerem\Documents\Codex\runclub-platform
.\scripts\sync-start.ps1
```

This pulls the newest GitHub version and runs `npm install` so dependencies are ready.

## Finish Work

Run this before you leave either PC:

```powershell
cd C:\Users\jerem\Documents\Codex\runclub-platform
.\scripts\sync-finish.ps1 -Message "Describe what changed"
```

This runs the core checks, commits everything, and pushes it to GitHub.

## Daily Rule

1. Start work: `.\scripts\sync-start.ps1`
2. Work on Corso.
3. Finish work: `.\scripts\sync-finish.ps1 -Message "What changed"`
4. Move to the other PC.
5. Start again with `.\scripts\sync-start.ps1`

## Important

- Never copy node_modules between PCs.
- Do not sync real secrets, passwords, Supabase service-role keys, or `.env` files through GitHub.
- Keep real school/student data out of the repo.
- If Git says there are conflicts, stop and resolve them before continuing.
- If you forget to finish work on one PC, the other PC will not have those changes yet.

## Quick Local Run

```powershell
python -m http.server 8080
```

Then open:

```text
http://127.0.0.1:8080
```

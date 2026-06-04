#!/usr/bin/env bash
# build.sh — Run Club Connect automated build + deploy
#
# What it does:
#   1. Assembles the modular src/ files into the deployable root so static
#      hosts (GitHub Pages, Netlify) serve a flat structure.
#   2. Optionally commits and pushes to production (the main branch).
#
# Usage:
#   ./build.sh            # build only (assemble modules into root)
#   ./build.sh --deploy   # build, then commit + push to origin/main
#   ./build.sh --deploy -m "your commit message"
#
set -euo pipefail
cd "$(dirname "$0")"

DEPLOY=false
MSG="Automated build: assemble modules and sync to production"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --deploy) DEPLOY=true; shift ;;
    -m) MSG="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

echo "==> Assembling modules from src/ into deployable root..."

# Map of module source -> root destination (kept flat so relative
# href/src paths in the HTML just work on any static host).
copy() { echo "    + $2"; cp "$1" "$2"; }

copy src/scanning/scanning.js  scanning.js
copy src/data/tracking.js      tracking.js
copy src/goals/goals.js        goals.js
copy src/goals/admin-goals.js  admin-goals.js
copy src/kiosk/kiosk.html      kiosk.html
copy src/kiosk/kiosk.js        kiosk.js
copy src/kiosk/kiosk.css       kiosk.css

echo "==> Build complete. Root now contains generated module bundles."

if [[ "$DEPLOY" == "true" ]]; then
  echo "==> Deploying to production (origin/main)..."
  git add -A
  if git diff --cached --quiet; then
    echo "    Nothing to commit — already in sync."
  else
    git commit -m "$MSG"
    git push origin main
    echo "==> Pushed to origin/main. Production will sync on next Pages/Netlify build."
  fi
else
  echo "==> Skipping deploy. Run with --deploy to commit + push."
fi

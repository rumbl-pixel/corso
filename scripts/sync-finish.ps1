param(
  [string]$Message = ""
)

$ErrorActionPreference = 'Stop'

function Write-Step($MessageText) {
  Write-Host ""
  Write-Host "==> $MessageText" -ForegroundColor Cyan
}

if (-not (Test-Path -LiteralPath ".git")) {
  throw "Run this from the Corso project folder."
}

if (-not $Message.Trim()) {
  $Message = Read-Host "Commit message, for example 'Update Corso dashboard polish'"
}

if (-not $Message.Trim()) {
  throw "A commit message is required so the sync history stays understandable."
}

Write-Step "Showing changes before sync"
git status --short

Write-Step "Running core checks"
npm test
node --check admin-dashboard.js
git diff --check

Write-Step "Staging all project changes"
git add -A

$pending = git diff --cached --name-only
if (-not $pending) {
  Write-Host ""
  Write-Host "No changes to commit. Nothing will be pushed." -ForegroundColor Yellow
  git status --short
  exit 0
}

Write-Step "Creating commit"
git commit -m $Message

Write-Step "Pushing to GitHub"
git push

Write-Step "Synced"
git status --short

param(
  [switch]$SkipInstall
)

$ErrorActionPreference = 'Stop'

function Write-Step($Message) {
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

if (-not (Test-Path -LiteralPath ".git")) {
  throw "Run this from the Corso project folder."
}

Write-Step "Checking the current project state"
git status --short

Write-Step "Fetching latest GitHub changes"
git fetch origin

Write-Step "Pulling latest changes safely"
git pull --ff-only

if (-not $SkipInstall -and (Test-Path -LiteralPath "package.json")) {
  Write-Step "Installing/updating project dependencies"
  npm install
}

Write-Step "Ready to work"
git status --short
Write-Host ""
Write-Host "Open the site with:" -ForegroundColor Green
Write-Host "  python -m http.server 8080"
Write-Host "Then visit http://127.0.0.1:8080"

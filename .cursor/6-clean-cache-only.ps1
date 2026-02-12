# Clear npm cache only. Use when you see "tarball corrupted" or ENOENT in cache.
# Then run: npm install   (or 5-repair-all-deps.ps1 if node_modules is broken)
# Usage: .\.cursor\6-clean-cache-only.ps1

$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "package.json"))) { $ProjectRoot = Get-Location }
Set-Location $ProjectRoot

Write-Host "Clearing npm cache ..." -ForegroundColor Yellow
& npm cache clean --force
Write-Host "Done. Run: npm install" -ForegroundColor Green

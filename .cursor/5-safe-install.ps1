# Safe install: clear cache, remove node_modules, then npm install --ignore-scripts.
# Use this when full install fails (e.g. sharp build from source fails on E: drive).
# After this, run 2-build-native.ps1, then npm start. Run sharp features only after: npm rebuild sharp
# Usage: .\.cursor\5-safe-install.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "package.json"))) { $ProjectRoot = Get-Location }
Set-Location $ProjectRoot

$nodeModules = Join-Path $ProjectRoot "node_modules"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Safe install: --ignore-scripts (no sharp/sqlite build)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Clearing npm cache ..." -ForegroundColor Yellow
& npm cache clean --force
Write-Host "  Done." -ForegroundColor Green
Write-Host ""

Write-Host "[2/3] Removing node_modules ..." -ForegroundColor Yellow
if (Test-Path $nodeModules) {
    Remove-Item -Recurse -Force $nodeModules -ErrorAction SilentlyContinue
    if (Test-Path $nodeModules) { cmd /c "rd /s /q `"$nodeModules`"" }
    if (Test-Path $nodeModules) {
        Write-Error "Could not remove node_modules. Close all apps and retry."
        exit 1
    }
}
Write-Host "  Done." -ForegroundColor Green
Write-Host ""

Write-Host "[3/3] Running npm install --ignore-scripts ..." -ForegroundColor Yellow
& npm install --ignore-scripts
if ($LASTEXITCODE -ne 0) {
    Write-Error "npm install failed"
    exit $LASTEXITCODE
}
Write-Host "  Done." -ForegroundColor Green
Write-Host ""
Write-Host "Next: .\.cursor\2-build-native.ps1   then   npm start" -ForegroundColor Green
Write-Host "If the app needs image (sharp): run  npm rebuild sharp  (may fail on E: drive; move project to C: if needed)." -ForegroundColor Gray
exit 0

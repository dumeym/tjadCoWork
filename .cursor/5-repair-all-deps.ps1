# Full repair: clear npm cache, remove node_modules, then npm install.
# Run from project root. Close IDE/terminals that use this folder before running.
# Usage: .\.cursor\5-repair-all-deps.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "package.json"))) {
    $ProjectRoot = Get-Location
}
Set-Location $ProjectRoot

$nodeModules = Join-Path $ProjectRoot "node_modules"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Full repair: cache clean + node_modules + npm install" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Clearing npm cache (fixes ENOENT/corrupted tarball) ..." -ForegroundColor Yellow
& npm cache clean --force
Write-Host "  Done." -ForegroundColor Green
Write-Host ""

Write-Host "[2/4] Removing node_modules ..." -ForegroundColor Yellow
if (-not (Test-Path $nodeModules)) {
    Write-Host "  (none)" -ForegroundColor Gray
} else {
    Remove-Item -Recurse -Force $nodeModules -ErrorAction SilentlyContinue
    if (Test-Path $nodeModules) {
        Write-Host "  PowerShell failed, trying cmd rd /s /q ..." -ForegroundColor Gray
        cmd /c "rd /s /q `"$nodeModules`""
    }
    if (Test-Path $nodeModules) {
        Write-Host ""
        Write-Host "  Could not remove node_modules (EPERM/ENOTEMPTY). Do this:" -ForegroundColor Red
        Write-Host "  1. Close Cursor/VS Code and all terminals in this project." -ForegroundColor Yellow
        Write-Host "  2. Open a NEW PowerShell (e.g. Win+R powershell), then:" -ForegroundColor Yellow
        Write-Host "     cd $ProjectRoot" -ForegroundColor White
        Write-Host "     Remove-Item -Recurse -Force node_modules" -ForegroundColor White
        Write-Host "     npm install" -ForegroundColor White
        exit 1
    }
    Write-Host "  Done." -ForegroundColor Green
}
Write-Host ""

Write-Host "[3/4] Running npm install (sharp will use prebuilt binary) ..." -ForegroundColor Yellow
# Prefer sharp prebuilt; avoid build-from-source (fails with E:\ path bug on E: drive)
$env:SHARP_IGNORE_GLOBAL_LIBVIPS = "1"
& npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "  First attempt failed. Retrying with --ignore-scripts (no native build during install) ..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $nodeModules -ErrorAction SilentlyContinue
    if (Test-Path $nodeModules) { cmd /c "rd /s /q `"$nodeModules`"" }
    if (Test-Path $nodeModules) {
        Write-Error "Could not remove node_modules. Close all apps using it and retry."
        exit 1
    }
    & npm install --ignore-scripts
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  If you see ENOENT/corrupted tarball, try: npm install --ignore-scripts --registry https://registry.npmjs.org/" -ForegroundColor Yellow
        Write-Error "npm install failed"
        exit $LASTEXITCODE
    }
    Write-Host "  Installed with --ignore-scripts. Run .\.cursor\2-build-native.ps1 next. Sharp may be missing; if app needs it, run: npm rebuild sharp" -ForegroundColor Yellow
} else {
    Write-Host "  Done." -ForegroundColor Green
}
Write-Host ""

Write-Host "[4/4] Verify ..." -ForegroundColor Yellow
if (Test-Path (Join-Path $nodeModules "electron")) {
    Write-Host "  Dependencies OK." -ForegroundColor Green
} else {
    Write-Host "  node_modules still incomplete; run npm install again." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Repair done. Run .\.cursor\2-build-native.ps1 then npm start." -ForegroundColor Green
exit 0

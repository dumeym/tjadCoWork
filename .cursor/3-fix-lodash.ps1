# Fix incomplete lodash install (missing lodash.js). Run from project root.
# Usage: .\.cursor\3-fix-lodash.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "package.json"))) {
    $ProjectRoot = Get-Location
}
Set-Location $ProjectRoot

$lodashDir = Join-Path $ProjectRoot "node_modules\lodash"
$lodashJs = Join-Path $lodashDir "lodash.js"

if (Test-Path $lodashJs) {
    Write-Host "lodash.js already present. No fix needed." -ForegroundColor Green
    exit 0
}

Write-Host "Reinstalling lodash (main entry was missing) ..." -ForegroundColor Yellow
if (Test-Path $lodashDir) {
    Remove-Item -Recurse -Force $lodashDir -ErrorAction SilentlyContinue
    if (Test-Path $lodashDir) {
        Write-Host "Trying cmd rd /s /q ..." -ForegroundColor Gray
        cmd /c "rd /s /q `"$lodashDir`""
    }
}
& npm install lodash --no-save
if ($LASTEXITCODE -ne 0) {
    Write-Error "npm install lodash failed"
    exit $LASTEXITCODE
}
if (Test-Path $lodashJs) {
    Write-Host "lodash fixed. You can run npm start now." -ForegroundColor Green
    exit 0
}
Write-Host "Retrying: npm cache clean, then install lodash ..." -ForegroundColor Yellow
& npm cache clean --force 2>&1 | Out-Null
if (Test-Path $lodashDir) { Remove-Item -Recurse -Force $lodashDir -ErrorAction SilentlyContinue }
& npm install lodash --no-save
if (Test-Path $lodashJs) {
    Write-Host "lodash fixed. You can run npm start now." -ForegroundColor Green
    exit 0
}
Write-Error "lodash.js still missing after reinstall"
exit 1

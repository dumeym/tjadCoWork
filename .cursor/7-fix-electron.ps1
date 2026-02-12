$ErrorActionPreference = "Stop"

# Fix Electron after installing with --ignore-scripts (Electron's postinstall downloads dist/ binaries).
# Usage: from project root: .\.cursor\7-fix-electron.ps1

$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "package.json"))) {
    $ProjectRoot = Get-Location
}
Set-Location $ProjectRoot

$electronDir = Join-Path $ProjectRoot "node_modules\\electron"
$electronExe = Join-Path $ProjectRoot "node_modules\\electron\\dist\\electron.exe"

if (Test-Path $electronExe) {
    Write-Host "Electron dist already present. No fix needed." -ForegroundColor Green
    exit 0
}

Write-Host "Fixing Electron (reinstalling electron to run postinstall) ..." -ForegroundColor Yellow

# Remove electron package so npm is forced to reinstall and run its postinstall (if present)
if (Test-Path $electronDir) {
    Remove-Item -Recurse -Force $electronDir -ErrorAction SilentlyContinue
    if (Test-Path $electronDir) { cmd /c "rd /s /q `"$electronDir`"" }
}

$pkg = Get-Content (Join-Path $ProjectRoot "package.json") -Raw | ConvertFrom-Json
$electronSpec = $pkg.devDependencies.electron
if (-not $electronSpec) { $electronSpec = "" }

$electronPkgArg = "electron"
if ($electronSpec) {
    # package.json usually stores ranges like ^37.3.1
    if ($electronSpec -match '^[~^0-9]') { $electronPkgArg = "electron@$electronSpec" }
    else { $electronPkgArg = $electronSpec } # already a full spec
}

Write-Host "Installing $electronPkgArg ..." -ForegroundColor Yellow
& npm install $electronPkgArg --no-save
if ($LASTEXITCODE -ne 0) {
    Write-Error "npm install electron failed"
    exit $LASTEXITCODE
}

if (Test-Path $electronExe) {
    Write-Host "Electron fixed (dist/electron.exe present)." -ForegroundColor Green
    exit 0
}

Write-Error "Electron still incomplete. Try: npm install --registry https://registry.npmjs.org/ $electronSpec --no-save"
exit 1


# Fix incomplete @electron/get install (missing fs-extra lib/index.js). Run from project root.
# Usage: .\.cursor\4-fix-electron-get.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "package.json"))) {
    $ProjectRoot = Get-Location
}
Set-Location $ProjectRoot

$getDir = Join-Path $ProjectRoot "node_modules\@electron\get"
$fsExtraIndex = Join-Path $ProjectRoot "node_modules\@electron\get\node_modules\fs-extra\lib\index.js"

if (Test-Path $fsExtraIndex) {
    Write-Host "fs-extra under @electron/get OK. No fix needed." -ForegroundColor Green
    exit 0
}

Write-Host "Reinstalling @electron/get (fs-extra was incomplete) ..." -ForegroundColor Yellow
if (Test-Path $getDir) {
    Remove-Item -Recurse -Force $getDir -ErrorAction SilentlyContinue
    if (Test-Path $getDir) { cmd /c "rd /s /q `"$getDir`"" }
}
& npm install @electron/get --no-save
if ($LASTEXITCODE -ne 0) {
    Write-Error "npm install @electron/get failed"
    exit $LASTEXITCODE
}
if (Test-Path $fsExtraIndex) {
    Write-Host "@electron/get fixed. You can run npm start now." -ForegroundColor Green
    exit 0
}
# fs-extra may be hoisted to root; if root has it, runtime will resolve there
$rootFsExtra = Join-Path $ProjectRoot "node_modules\fs-extra\lib\index.js"
if (Test-Path $rootFsExtra) {
    Write-Host "@electron/get reinstalled; fs-extra is at root. Try npm start." -ForegroundColor Green
    exit 0
}
Write-Error "fs-extra lib/index.js still missing after reinstall"
exit 1

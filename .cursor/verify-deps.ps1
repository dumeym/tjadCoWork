# Verify deps and native modules (run standalone or after 1-pull-deps / 2-build-native)
# Usage: .\.cursor\verify-deps.ps1   or  .\.cursor\verify-deps.ps1 -Strict

param(
    [switch]$Strict   # Strict: treat missing native build as failure
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "package.json"))) {
    $ProjectRoot = Get-Location
}

$nodeModules = Join-Path $ProjectRoot "node_modules"
Write-Host "Verify root: $ProjectRoot" -ForegroundColor Gray
Write-Host ""

# 1. Core deps
$deps = @(
    "electron", "better-sqlite3", "react", "react-dom", "web-tree-sitter", "sharp"
)
Write-Host "[ Dependencies ]" -ForegroundColor Cyan
$depsOk = $true
foreach ($d in $deps) {
    $p = Join-Path $nodeModules $d
    if (Test-Path $p) { Write-Host "  [OK] $d" -ForegroundColor Green }
    else { Write-Host "  [MISS] $d" -ForegroundColor Red; $depsOk = $false }
}
# lodash (transitive; main entry lodash.js required by many deps)
$lodashMain = Join-Path $nodeModules "lodash\lodash.js"
if (Test-Path $lodashMain) { Write-Host "  [OK] lodash (main)" -ForegroundColor Green }
else { Write-Host "  [MISS] lodash (lodash.js missing; run .\.cursor\3-fix-lodash.ps1)" -ForegroundColor Red; $depsOk = $false }

# 2. Native module binaries
Write-Host ""
Write-Host "[ Native modules ]" -ForegroundColor Cyan
$sqliteRelease = Join-Path $nodeModules "better-sqlite3\build\Release\better_sqlite3.node"
$sqlitePrebuilds = Join-Path $nodeModules "better-sqlite3\prebuilds"
$nativeOk = Test-Path $sqliteRelease
if (-not $nativeOk) {
    $nativeOk = (Get-ChildItem $sqlitePrebuilds -Recurse -Filter "*.node" -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
}
$nativeColor = "Yellow"
if ($nativeOk) {
    Write-Host "  [OK] better-sqlite3 (.node)" -ForegroundColor Green
} else {
    if ($Strict) { $nativeColor = "Red"; $depsOk = $false }
    Write-Host "  [MISS] better-sqlite3 not built or .node not found" -ForegroundColor $nativeColor
}

Write-Host ""
if ($depsOk -and ($nativeOk -or -not $Strict)) {
    Write-Host "Verify OK." -ForegroundColor Green
    exit 0
}
Write-Host "Verify failed." -ForegroundColor Red
exit 1

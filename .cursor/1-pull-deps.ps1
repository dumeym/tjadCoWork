# Step 1: Pull deps only (no postinstall, no native build)
# Usage: run from project root: .\.cursor\1-pull-deps.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "package.json"))) {
    $ProjectRoot = Get-Location
}
Set-Location $ProjectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Step 1: Pull dependencies (download only, no native build)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Install deps only, skip postinstall (no native build in this step)
Write-Host "[1/2] Running npm install --ignore-scripts ..." -ForegroundColor Yellow
& npm install --ignore-scripts
if ($LASTEXITCODE -ne 0) {
    Write-Error "npm install failed, exit code: $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Host ""

# Verify that deps were downloaded
Write-Host "[2/2] Verifying dependencies ..." -ForegroundColor Yellow
$nodeModules = Join-Path $ProjectRoot "node_modules"
$checks = @(
    @{ Name = "node_modules"; Path = $nodeModules },
    @{ Name = "electron"; Path = Join-Path $nodeModules "electron" },
    @{ Name = "better-sqlite3"; Path = Join-Path $nodeModules "better-sqlite3" },
    @{ Name = "react"; Path = Join-Path $nodeModules "react" },
    @{ Name = "web-tree-sitter"; Path = Join-Path $nodeModules "web-tree-sitter" },
    @{ Name = "sharp"; Path = Join-Path $nodeModules "sharp" }
)

$allOk = $true
foreach ($c in $checks) {
    if (Test-Path $c.Path) {
        Write-Host "  [OK] $($c.Name)" -ForegroundColor Green
    } else {
        Write-Host "  [MISS] $($c.Name) -> $($c.Path)" -ForegroundColor Red
        $allOk = $false
    }
}

# Ensure lodash main entry (often broken by install --ignore-scripts)
$lodashJs = Join-Path $nodeModules "lodash\lodash.js"
if (-not (Test-Path $lodashJs)) {
    Write-Host "  [FIX] lodash.js missing, reinstalling lodash ..." -ForegroundColor Yellow
    $lodashDir = Join-Path $nodeModules "lodash"
    if (Test-Path $lodashDir) { Remove-Item -Recurse -Force $lodashDir -ErrorAction SilentlyContinue }
    & npm install lodash --no-save 2>&1 | Out-Null
    if (Test-Path $lodashJs) { Write-Host "  [OK] lodash fixed" -ForegroundColor Green }
    else { Write-Host "  [WARN] lodash still incomplete; run .\.cursor\3-fix-lodash.ps1" -ForegroundColor Yellow; $allOk = $false }
}

Write-Host ""
if ($allOk) {
    Write-Host "Deps pulled and verified. Next run: .\.cursor\2-build-native.ps1" -ForegroundColor Green
    exit 0
} else {
    Write-Error "Some deps missing. Check network or npm registry and retry."
    exit 1
}

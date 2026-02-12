# Step 2: Build native modules (run after step 1 pull-deps)
# Usage: run from project root: .\.cursor\2-build-native.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "package.json"))) {
    $ProjectRoot = Get-Location
}
Set-Location $ProjectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Step 2: Build native modules" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure deps were pulled first
if (-not (Test-Path (Join-Path $ProjectRoot "node_modules"))) {
    Write-Error "node_modules not found. Run first: .\.cursor\1-pull-deps.ps1"
    exit 1
}

# Rebuild native modules for Electron via electron-builder
Write-Host "[1/2] Running npx electron-builder install-app-deps ..." -ForegroundColor Yellow
$env:npm_config_build_from_source = "true"
try {
    & npx electron-builder install-app-deps
    if ($LASTEXITCODE -ne 0) { throw "exit code $LASTEXITCODE" }
    Write-Host "  electron-builder install-app-deps done" -ForegroundColor Green
} catch {
    Write-Warning "electron-builder install-app-deps failed, trying electron-rebuild ..."
    $pkg = Get-Content (Join-Path $ProjectRoot "package.json") -Raw | ConvertFrom-Json
    $electronVersion = $pkg.devDependencies.electron -replace '^[~^]', ''
    & npx electron-rebuild --only better-sqlite3 --force --version $electronVersion
    if ($LASTEXITCODE -ne 0) {
        Write-Error "electron-rebuild also failed, exit code: $LASTEXITCODE"
        exit $LASTEXITCODE
    }
}
Write-Host ""

# Verify native binaries exist
Write-Host "[2/2] Verifying native modules ..." -ForegroundColor Yellow
$sqliteNode = Join-Path $ProjectRoot "node_modules\better-sqlite3\build\Release\better_sqlite3.node"
$sqlitePrebuild = Join-Path $ProjectRoot "node_modules\better-sqlite3\prebuilds"
$hasSqlite = Test-Path $sqliteNode
$hasPrebuild = Test-Path $sqlitePrebuild
if (Get-ChildItem $sqlitePrebuild -Recurse -Filter "*.node" -ErrorAction SilentlyContinue) { $hasPrebuild = $true }

if ($hasSqlite) {
    Write-Host "  [OK] better-sqlite3 (build/Release)" -ForegroundColor Green
} elseif ($hasPrebuild) {
    Write-Host "  [OK] better-sqlite3 (prebuilds)" -ForegroundColor Green
} else {
    Write-Host "  [WARN] better-sqlite3 .node not found; app may fail at runtime" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Native build step done. Run npm start to verify the app." -ForegroundColor Green
exit 0

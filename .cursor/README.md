# Cursor scripts

Dependency install and native module build are split into two steps for easier debugging and verification.

## Step 1: Pull dependencies only

```powershell
.\.cursor\1-pull-deps.ps1
```

- Runs `npm install --ignore-scripts`: downloads packages only, **no postinstall, no native build**.
- Then verifies that `node_modules`, `electron`, `better-sqlite3`, `react`, `web-tree-sitter`, `sharp` exist.
- May take several minutes; wait for it to finish.

## Step 2: Build native modules

Run after step 1 succeeds:

```powershell
.\.cursor\2-build-native.ps1
```

- Runs `npx electron-builder install-app-deps` (falls back to `npx electron-rebuild --only better-sqlite3` on failure).
- Then verifies that `better-sqlite3` has a `.node` binary ready.

## Full repair (multiple MODULE_NOT_FOUND / incomplete deps)

If you see errors like `Cannot find module '...lodash.js'`, `...fs-extra\lib\index.js'`, or `...debug\...\node.js'`, the dependency tree is incomplete. Run a full repair:

```powershell
.\.cursor\5-repair-all-deps.ps1
```

This **clears npm cache**, removes `node_modules`, and runs `npm install`. It may take several minutes. Then run:

```powershell
.\.cursor\2-build-native.ps1
npm start
```

**If `npm install` fails with sharp build (Missing E:\\VImage.cpp / build from source) or EPERM cleanup:**

- **Sharp build failure on E: drive**: The install failed because **sharp** tried to build from source and path resolution broke (files under `E:\`). Use the safe install path so no native scripts run during install:
  ```powershell
  .\.cursor\5-safe-install.ps1
  ```
  Then run `.\cursor\2-build-native.ps1` and `npm start`. If the app needs image features later, run `npm rebuild sharp` (or move the project to `C:\` to avoid the path bug).

**If `npm install` fails with ENOTEMPTY / EPERM / corrupted tarball / ENOENT cache:**

1. **Close Cursor (or VS Code) and all terminals** that use this project, so nothing locks `node_modules`.
2. Open a **new** PowerShell (e.g. Win+R → `powershell`), then:
   ```powershell
   cd E:\MyCodingProjects\AionUi
   .\.cursor\5-repair-all-deps.ps1
   ```
3. If you still see "tarball corrupted" or cache ENOENT, clear cache and use official registry once:
   ```powershell
   .\.cursor\6-clean-cache-only.ps1
   npm install --registry https://registry.npmjs.org/
   ```

## Fix lodash (if MODULE_NOT_FOUND lodash.js)

If `npm start` fails with `Cannot find module '...lodash\\lodash.js'`, run:

```powershell
.\.cursor\3-fix-lodash.ps1
```

Then run `npm start` again. `verify-deps.ps1` also checks for lodash and suggests this fix.

## Fix @electron/get (if MODULE_NOT_FOUND fs-extra lib/index.js)

```powershell
.\.cursor\4-fix-electron-get.ps1
```

## Verify only

Run verification anytime (no install, no build):

```powershell
.\.cursor\verify-deps.ps1
```

Strict mode (fail if native is not built):

```powershell
.\.cursor\verify-deps.ps1 -Strict
```

## Notes

- Run scripts from the **project root** (or they will resolve the root via `package.json`).
- Native modules (see CLAUDE.md): `better-sqlite3`, `node-pty`, `tree-sitter` (this repo uses `web-tree-sitter`). Current rebuild logic mainly handles `better-sqlite3`.

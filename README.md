# forch-i-winoptimizer-install

One-line installer for **FORCH.iA WinOptimizer** — in the style of
`irm https://christitus.com/win | iex` — that works even though the app repo
is **private**.

> **Built with FORCH.i by Paulo Velasco** — FORCH.iA Ecosystem.

## The one-liner

Run in Windows PowerShell on the target PC:

```powershell
irm https://raw.githubusercontent.com/paulogvs/forch-i-winoptimizer-install/main/Install.ps1 | iex
```

If the execution policy complains:

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/paulogvs/forch-i-winoptimizer-install/main/Install.ps1 | iex"
```

What it does:

1. Asks for **your** GitHub PAT (secure prompt, never stored).
2. Resolves the latest release (or `-Version v0.18.0`) of the private repo.
3. Downloads the NSIS `*-Setup-*.exe` + `checksums.sha256` with your token.
4. **Verifies SHA256 before running anything** (aborts on mismatch).
5. Runs the installer silently (per-user, no admin needed).
6. Deletes temp files and clears the token from memory.

## 1) Create the PAT (once, 2 minutes)

`github.com` → avatar → **Settings** → **Developer settings** →
**Personal access tokens** → **Fine-grained tokens** → **Generate new token**:

- Token name: `winoptimizer-install`
- Expiration: 90 days (your call)
- Repository access: **Only select repositories** → `paulogvs/forch-i-winoptimizer`
- Permissions → **Repository** → **Contents: Read-only**
- Generate → copy it (you won't see it again).

## 2) Security notes (read me, it's short)

- This repo is public and contains **only** the bootstrap (`Install.ps1`).
  No app code, no secrets, no tokens. Audit it — it's ~100 lines.
- The token is typed by you at install time (`Read-Host -AsSecureString`),
  used only in the `Authorization` header, then wiped. It never touches disk.
- The installer binary is hash-verified against the release `checksums.sha256`
  before execution. If verification fails, nothing runs.
- Prefer passing `-Version vX.Y.Z` to pin exactly what gets installed.

## 3) Pin a version / CI usage

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/paulogvs/forch-i-winoptimizer-install/main/Install.ps1))) -Version v0.18.0
```

(Only pass `-Token` non-interactively on machines you trust; the command line
may be logged.)

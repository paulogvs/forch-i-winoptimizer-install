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

1. Resolves the latest release (or `-Version v0.18.0`) of the **public**
   releases repo (binaries only — **no token needed**).
2. Downloads the NSIS `*-Setup-*.exe` + `checksums.sha256`.
3. **Verifies SHA256 before running anything** (aborts on mismatch).
4. Runs the installer silently (per-user, no admin needed).
5. Deletes temp files.

## 1) Do I need a PAT? (Short answer: no)

The default feed is the public `forch-i-winoptimizer-releases` repo, so the
one-liner just works — no login, no token.

You only need a fine-grained PAT if you point `-Repo` at the private code
repo. To create one: `github.com` → avatar → **Settings** →
**Developer settings** → **Personal access tokens** → **Fine-grained tokens**
→ **Generate new token**: only repo `paulogvs/forch-i-winoptimizer`,
**Contents: Read-only**, 90 days.

## 2) Security notes (read me, it's short)

- This repo is public and contains **only** the bootstrap (`Install.ps1`).
  No app code, no secrets, no tokens. Audit it — it's ~100 lines.
- With the default public feed there is **no token at all**. If you ever
  target the private repo, the token is typed at install time
  (`Read-Host -AsSecureString`), used only in the `Authorization` header,
  then wiped — it never touches disk.
- The installer binary is hash-verified against the release `checksums.sha256`
  before execution. If verification fails, nothing runs.
- Prefer passing `-Version vX.Y.Z` to pin exactly what gets installed.

## 3) Pin a version / CI usage

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/paulogvs/forch-i-winoptimizer-install/main/Install.ps1))) -Version v0.18.0
```

(Only pass `-Token` non-interactively on machines you trust; the command line
may be logged.)

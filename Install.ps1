<#
.SYNOPSIS
  One-line installer for FORCH.iA WinOptimizer (private repo friendly).

.DESCRIPTION
  Downloads the NSIS Setup from the PRIVATE GitHub repo
  paulogvs/forch-i-winoptimizer using YOUR personal access token (PAT),
  verifies its SHA256 against the release checksums, and runs it silently
  (per-user install, no admin required).

  This bootstrap script is PUBLIC and contains no secrets and no app code.
  Your token is asked interactively (never stored, never written to disk).

.EXAMPLE
  irm https://raw.githubusercontent.com/paulogvs/forch-i-winoptimizer-install/main/Install.ps1 | iex

.EXAMPLE
  # Pin a version and/or pass the token non-interactively (CI only):
  & ([scriptblock]::Create((irm https://raw.githubusercontent.com/paulogvs/forch-i-winoptimizer-install/main/Install.ps1))) -Version v0.18.0 -Token 'YOUR_TOKEN_HERE'

  Built with FORCH.i by Paulo Velasco — FORCH.iA Ecosystem.
#>
[CmdletBinding()]
param(
  [string]$Version = 'latest',
  [string]$Token = '',
  [string]$Repo = 'paulogvs/forch-i-winoptimizer'
)

$ErrorActionPreference = 'Stop'

# TLS 1.2 for Windows PowerShell 5.1.
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-PlainToken {
  param([string]$MaybeToken)
  if (-not [string]::IsNullOrWhiteSpace($MaybeToken)) { return $MaybeToken.Trim() }
  $secure = Read-Host -Prompt 'GitHub PAT (fine-grained, Contents: read-only on forch-i-winoptimizer)' -AsSecureString
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr).Trim()
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  }
}

function Invoke-GitHubApi {
  param([string]$Url, [string]$PlainToken)
  $headers = @{
    Authorization          = "Bearer $PlainToken"
    Accept                 = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
    'User-Agent'           = 'forch-i-winoptimizer-installer'
  }
  return Invoke-RestMethod -Uri $Url -Headers $headers -UseBasicParsing
}

$plainToken = Get-PlainToken -MaybeToken $Token
if ([string]::IsNullOrWhiteSpace($plainToken)) { throw 'A GitHub PAT is required (Contents: read-only). Aborting.' }

try {
  $tag = if ([string]::IsNullOrWhiteSpace($Version) -or $Version -eq 'latest') {
    'latest'
  } else {
    'v' + $Version.TrimStart('v')
  }
  $releaseUrl = if ($tag -eq 'latest') {
    "https://api.github.com/repos/$Repo/releases/latest"
  } else {
    "https://api.github.com/repos/$Repo/releases/tags/$tag"
  }
  Write-Host "Resolving release ($tag)..." -ForegroundColor Cyan
  $release = Invoke-GitHubApi -Url $releaseUrl -PlainToken $plainToken

  $setup = @($release.assets | Where-Object { $_.name -like '*-Setup-*.exe' })[0]
  $sums = @($release.assets | Where-Object { $_.name -eq 'checksums.sha256' })[0]
  if (-not $setup) { throw "No '*-Setup-*.exe' asset found in release $($release.tag_name)." }
  if (-not $sums) { throw "No 'checksums.sha256' asset found in release $($release.tag_name)." }
  Write-Host "Found $($setup.name) ($([Math]::Round($setup.size / 1MB, 1)) MB)" -ForegroundColor Green

  $work = Join-Path ([IO.Path]::GetTempPath()) ("winopt-install-" + [Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $work -Force | Out-Null
  $exePath = Join-Path $work $setup.name
  $sumsPath = Join-Path $work 'checksums.sha256'

  $dlHeaders = @{ Authorization = "Bearer $plainToken"; Accept = 'application/octet-stream'; 'User-Agent' = 'forch-i-winoptimizer-installer' }
  Write-Host 'Downloading installer...' -ForegroundColor Cyan
  Invoke-WebRequest -Uri $setup.browser_download_url -Headers $dlHeaders -OutFile $exePath -UseBasicParsing
  Invoke-WebRequest -Uri $sums.browser_download_url -Headers $dlHeaders -OutFile $sumsPath -UseBasicParsing

  Write-Host 'Verifying SHA256...' -ForegroundColor Cyan
  $expected = (Get-Content -LiteralPath $sumsPath | Where-Object { $_ -match [regex]::Escape($setup.name) } | Select-Object -First 1) -split '\s+' | Select-Object -First 1
  $actual = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash.ToLower()
  if (-not $expected -or $expected.ToLower() -ne $actual) {
    throw "Checksum mismatch for $($setup.name). Expected '$expected', got '$actual'. Aborting before running anything."
  }
  Write-Host 'Checksum OK.' -ForegroundColor Green

  Write-Host 'Running installer silently (per-user, no admin needed)...' -ForegroundColor Cyan
  $proc = Start-Process -FilePath $exePath -ArgumentList '/S' -Wait -PassThru
  if ($proc.ExitCode -ne 0) { throw "Installer exited with code $($proc.ExitCode)." }
  Write-Host 'FORCH.iA WinOptimizer installed. Look for it in Start Menu.' -ForegroundColor Green
} finally {
  if (Test-Path $work) { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue }
  if ($plainToken) { $plainToken = $null }
  [GC]::Collect()
}

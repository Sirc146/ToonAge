<#
.SYNOPSIS
    Tag and push a new ToonAge release.

.DESCRIPTION
    Bumps the version in ToonAge.toc, commits the change, creates an annotated
    git tag, and pushes to origin. The push triggers the GitHub Actions workflow
    which packages the ZIP and creates a GitHub Release.

    WowUp detects the new release automatically via the GitHub provider.

.PARAMETER Version
    Semantic version string, e.g. "2.0.1", "2.1.0-beta.1", "2.0.0-dev.3"
    The "v" prefix is added automatically for the git tag.

.PARAMETER Message
    Release message / changelog summary for the tag annotation.

.EXAMPLE
    .\Tools\release.ps1 -Version 2.0.1 -Message "Fixed container API on Classic"
    .\Tools\release.ps1 -Version 2.1.0-dev.1 -Message "Dev build: new Gear tab"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Message
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot

# ── Validate clean working tree ──────────────────────────────────────────────
$dirty = git -C $RepoRoot status --porcelain 2>$null | Where-Object { $_ -notmatch '^\?\?' }
if ($dirty) {
    Write-Host "Working tree has uncommitted changes:" -ForegroundColor Yellow
    $dirty | ForEach-Object { Write-Host "  $_" }
    throw "Commit or stash changes before releasing."
}

# ── Update version in TOC ────────────────────────────────────────────────────
$tocPath = Join-Path $RepoRoot "ToonAge.toc"
$tocContent = Get-Content $tocPath -Raw
$newToc = $tocContent -replace '## Version: .*', "## Version: $Version"
Set-Content -Path $tocPath -Value $newToc -NoNewline -Encoding UTF8

# ── Update version in Init.lua ───────────────────────────────────────────────
$initPath = Join-Path $RepoRoot "Core\Init.lua"
$initContent = Get-Content $initPath -Raw
$newInit = $initContent -replace 'local ADDON_VERSION = ".*"', "local ADDON_VERSION = `"$Version`""
Set-Content -Path $initPath -Value $newInit -NoNewline -Encoding UTF8

# ── Commit and tag ───────────────────────────────────────────────────────────
$tag = "v$Version"
Write-Host "Version : $Version" -ForegroundColor Cyan
Write-Host "Tag     : $tag" -ForegroundColor Cyan
Write-Host "Message : $Message" -ForegroundColor Cyan
Write-Host ""

git -C $RepoRoot add ToonAge.toc Core/Init.lua
git -C $RepoRoot commit -m "Release $tag"
git -C $RepoRoot tag $tag -a -m $Message

# ── Push ─────────────────────────────────────────────────────────────────────
Write-Host "Pushing to origin..." -ForegroundColor Cyan
git -C $RepoRoot push origin HEAD --follow-tags

Write-Host ""
Write-Host "Done. GitHub Actions will package the release." -ForegroundColor Green
Write-Host "Track it at: https://github.com/Sirc146/ToonAge/actions" -ForegroundColor Gray
Write-Host ""
Write-Host "WowUp endpoint: https://api.github.com/repos/Sirc146/ToonAge/releases/latest" -ForegroundColor Gray

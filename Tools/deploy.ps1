<#
.SYNOPSIS
    Promote ToonAge from this repository to another WoW client.

.DESCRIPTION
    The PTR folder is the repository and the single source of truth. Other
    clients get a deployed copy. This keeps promotion deliberate -- retail gets
    a known-good snapshot rather than whatever the working tree happens to be
    mid-edit.

    A directory junction was considered and rejected. It would make retail
    mirror PTR instantly, which is the opposite of "move to retail if it works":
    every half-finished PTR edit would be live on retail immediately.

    Dev-only files are excluded. Tools/ is Python, Archive/ and Monk/ are
    untracked scratch, .git/ is the repository itself -- none of it is read by
    the game, and all of it is weight in a client folder.

.PARAMETER Client
    Target client folder name, e.g. _retail_, _classic_era_, _anniversary_.

.PARAMETER Force
    Deploy even when the working tree has uncommitted changes. Off by default:
    a promotion you cannot identify by commit is one you cannot roll back.

.EXAMPLE
    .\Tools\deploy.ps1 -Client _retail_
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Client,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AddonName = Split-Path -Leaf $RepoRoot
$WowRoot = (Get-Item $RepoRoot).Parent.Parent.Parent.Parent.FullName
$Target = Join-Path $WowRoot "$Client\Interface\AddOns\$AddonName"

Write-Host "Addon   : $AddonName"
Write-Host "Source  : $RepoRoot"
Write-Host "Target  : $Target"

if (-not (Test-Path (Join-Path $WowRoot $Client))) {
    throw "Client folder not found: $(Join-Path $WowRoot $Client)"
}

# ── Refuse to promote an unidentifiable state ────────────────────────────────
$commit = $null
try { $commit = (git -C $RepoRoot rev-parse --short HEAD 2>$null) } catch {}

if ($commit) {
    $dirty = git -C $RepoRoot status --porcelain 2>$null |
             Where-Object { $_ -notmatch '^\?\?' }
    if ($dirty -and -not $Force) {
        Write-Host ""
        Write-Host "Working tree has uncommitted changes:" -ForegroundColor Yellow
        $dirty | ForEach-Object { Write-Host "  $_" }
        throw "Refusing to deploy. Commit first, or pass -Force."
    }
    Write-Host "Commit  : $commit$(if ($dirty) { ' (FORCED, dirty)' })"
} else {
    Write-Host "Commit  : (not a git repository)"
}

# ── Sanity-check the payload before overwriting anything ─────────────────────
$toc = Join-Path $RepoRoot "$AddonName.toc"
if (-not (Test-Path $toc)) { throw "No $AddonName.toc found in $RepoRoot" }

$tocFiles = Get-Content $toc | Where-Object { $_ -match '\.lua\s*$' -or $_ -match '\.xml\s*$' }
$missing = @()
foreach ($line in $tocFiles) {
    $rel = $line.Trim()
    if (-not (Test-Path (Join-Path $RepoRoot $rel))) { $missing += $rel }
}
if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "TOC references files that do not exist:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $_" }
    throw "Refusing to deploy a broken manifest."
}
Write-Host "Manifest: $($tocFiles.Count) files, all present"

# ── Copy ─────────────────────────────────────────────────────────────────────
# /MIR makes the target an exact mirror, so a file deleted here is deleted
# there. Without it, a renamed module would leave the old copy behind and the
# game would load both.
$exclude = @('.git', 'Tools', 'Archive', 'Monk', '.claude')
$xd = $exclude | ForEach-Object { Join-Path $RepoRoot $_ }

$roboArgs = @($RepoRoot, $Target, '/MIR', '/NFL', '/NDL', '/NJH', '/NJS', '/NP', '/R:2', '/W:1', '/XD') + $xd
$null = robocopy @roboArgs
$rc = $LASTEXITCODE

# robocopy: 0-7 are success, 8+ are real failures.
if ($rc -ge 8) { throw "robocopy failed with exit code $rc" }

# ── Stamp what was deployed ──────────────────────────────────────────────────
# Deliberately .txt, not .lua. The game only loads what the TOC lists, and
# adding this to the TOC would break the repository's TOC-matches-disk
# invariant. It is a marker for humans and for the next deploy, not code.
$stamp = @(
    "ToonAge deployed copy -- do not edit here.",
    "Edit the repository at $RepoRoot, then re-run Tools\deploy.ps1.",
    "",
    "commit : $(if ($commit) { $commit } else { 'unknown' })",
    "client : $Client",
    "time   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
) -join "`r`n"
Set-Content -Path (Join-Path $Target 'DEPLOY_INFO.txt') -Value $stamp -Encoding UTF8

$count = (Get-ChildItem $Target -Recurse -File).Count
Write-Host ""
Write-Host "Deployed $count files to $Client" -ForegroundColor Green
Write-Host "Reload the client (or /reload if already running) to pick it up."

# robocopy uses exit codes 0-7 for degrees of success (1 = files were copied),
# which PowerShell otherwise surfaces as a failed script. Anything >= 8 already
# threw above, so reaching here means success.
exit 0

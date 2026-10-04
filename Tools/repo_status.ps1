<#
.SYNOPSIS
    One command that answers "is everything saved and current, for every
    client?" Read-only: builds into a temp folder, changes nothing.

.DESCRIPTION
    Checks, in order:

      TRUNK     on main, and whether anything is uncommitted
      BACKUP    the backup's main versus this main
      GITHUB    GitHub's main versus this main
      LIVE      for each client: does live/<client> hold exactly the build the
                trunk produces right now, and is that branch in the backup and
                on GitHub? (The build is made into a temp folder with
                build_flavors.ps1 -Dest, so your version folders are untouched.)
      INSTALLS  build_flavors.ps1 -Check: is each game client running the trunk?

    Ends with ALL CURRENT, or a list of what isn't and the command that fixes
    it. Exit code 0 when everything is current, 1 otherwise.

    "Current" for a live branch means "matches what the trunk builds". After you
    change code and before you test it, live/* is expected to be behind -- it
    records tested builds, and save_day.ps1 is what moves it.

.PARAMETER NoFetch
    Don't fetch from the backup or GitHub first (compare against what this
    repository last saw).

.PARAMETER SkipGitHub
    Leave GitHub out of the verdict (e.g. you only back up locally).

.EXAMPLE
    .\Tools\repo_status.ps1
#>
[CmdletBinding()]
param(
    [switch] $NoFetch,
    [switch] $SkipGitHub,
    [string] $BackupPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'repo_common.ps1')
if (-not $BackupPath) { $BackupPath = $DefaultBackupPath }

$Root    = Split-Path -Parent $PSScriptRoot
$Builder = Join-Path $PSScriptRoot 'build_flavors.ps1'
$Git     = Get-GitExe
function TGit([string[]] $a, [switch] $AllowFail) { Invoke-GitRaw $Git (@('-C', $Root) + $a) -AllowFail:$AllowFail }

$problems = New-Object System.Collections.Generic.List[string]
function Row([string] $label, [string] $state, [bool] $good) {
    $c = if ($good) { 'Green' } else { 'Yellow' }
    Write-Host ("  {0,-24} {1}" -f $label, $state) -ForegroundColor $c
}
function Section([string] $t) { Write-Host ""; Write-Host "== $t" -ForegroundColor Cyan }
function Describe([string] $s, [string] $who, [string] $mine = 'the trunk') {
    # Get-AheadBehind speaks from the trunk's side; say it from the remote's.
    if ($s -eq 'equal')   { return "same commit as $mine" }
    if ($s -eq 'missing') { return "not in $who yet" }
    if ($s -match '^ahead (\d+)$')  { return "$who is $($Matches[1]) commit(s) behind $mine" }
    if ($s -match '^behind (\d+)$') { return "$who has $($Matches[1]) commit(s) $mine doesn't" }
    if ($s -match '^diverged \((\d+) ahead, (\d+) behind\)$') {
        return "diverged: $who lacks $($Matches[1]) commit(s) from $mine and has $($Matches[2]) it doesn't"
    }
    return $s
}

$GitDir = Get-FirstLine (TGit @('rev-parse', '--absolute-git-dir'))

# ── Trunk ────────────────────────────────────────────────────────────────
Section "Trunk  ($Root)"
$branch = Get-FirstLine (TGit @('rev-parse', '--abbrev-ref', 'HEAD'))
$head   = Get-FirstLine (TGit @('rev-parse', 'HEAD'))
$subj   = Get-FirstLine (TGit @('log', '-1', '--format=%h %cd  %s', '--date=format:%Y-%m-%d %H:%M'))
Row 'branch' $branch ($branch -eq 'main')
if ($branch -ne 'main') { $problems.Add("trunk is on '$branch', not main") }
Row 'last commit' $subj $true
$porcelain = @(TGit @('status', '--porcelain')).Where({ $_ })
$mod = @($porcelain.Where({ $_ -notlike '`?`? *' })).Count
$new = @($porcelain.Where({ $_ -like '`?`? *' })).Count
$clean = ($mod + $new) -eq 0
Row 'working tree' $(if ($clean) { 'clean' } else { "$mod changed, $new untracked (not committed)" }) $clean
if (-not $clean) { $problems.Add("uncommitted work in the trunk ($mod changed, $new untracked) -> test, then save_day.ps1") }

# ── Remotes ──────────────────────────────────────────────────────────────
$remotes = @(TGit @('remote'))
if (-not $NoFetch) {
    if ($remotes -contains 'backup') { TGit @('fetch', 'backup', '--no-tags', '--prune', '--quiet') -AllowFail | Out-Null }
    if (-not $SkipGitHub -and $remotes -contains 'origin') {
        TGit @('fetch', 'origin', '--no-tags', '--prune', '--quiet') -AllowFail | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Host "  (could not reach GitHub; comparing with what was last fetched)" -ForegroundColor DarkGray }
    }
}

Section "Backup  ($BackupPath)"
if ($remotes -notcontains 'backup') {
    Row 'remote' 'not configured' $false
    $problems.Add("no 'backup' remote -> .\Tools\repo_setup.ps1 -Apply")
} else {
    $s = Get-AheadBehind $Git $GitDir 'refs/heads/main' 'refs/remotes/backup/main'
    Row 'main' (Describe $s 'backup') ($s -eq 'equal')
    if ($s -eq 'missing' -or $s -like 'ahead*') { $problems.Add("backup main: $(Describe $s 'backup') -> save_day.ps1 pushes it") }
    elseif ($s -ne 'equal') {
        $legacyHint = ''
        TGit @('merge-base', '--is-ancestor', 'refs/remotes/backup/main', 'HEAD') -AllowFail | Out-Null
        if ($LASTEXITCODE -ne 0) { $legacyHint = ' (it holds history this trunk does not -> .\Tools\repo_setup.ps1 -Apply archives it as tag archive/main)' }
        $problems.Add("backup main: $(Describe $s 'backup')$legacyHint")
    }
    $mirror = Get-FirstLine (Invoke-GitRaw $Git @("--git-dir=$BackupPath", 'config', '--get', 'remote.origin.mirror') -AllowFail)
    if ($mirror -eq 'true') {
        Row 'mirror setting' 'still mirrors GitHub (a fetch there would erase branches)' $false
        $problems.Add("backup is still configured as a GitHub mirror -> .\Tools\repo_setup.ps1 -Apply")
    }
}

if (-not $SkipGitHub) {
    Section "GitHub  (origin)"
    if ($remotes -notcontains 'origin') {
        Row 'remote' 'not configured' $false
        $problems.Add("no 'origin' remote -> .\Tools\repo_setup.ps1 -Apply")
    } else {
        $s = Get-AheadBehind $Git $GitDir 'refs/heads/main' 'refs/remotes/origin/main'
        Row 'main' (Describe $s 'GitHub') ($s -eq 'equal')
        if ($s -ne 'equal') { $problems.Add("GitHub main: $(Describe $s 'GitHub') -> save_day.ps1 ... -PushOrigin") }
    }
}

# ── Live branches ────────────────────────────────────────────────────────
Section "Live branches  (one per client build)"
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("toonage-status-{0}" -f [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    foreach ($name in $LiveBranch.Keys) {
        $br = $LiveBranch[$name]
        $tip = Get-RefOid $Git $GitDir "refs/heads/$br"
        & $Builder -Flavor $name -Dest $tmp *> $null
        $built = Join-Path $tmp $name
        if (-not (Test-Path -LiteralPath $built)) {
            Row $br "could not build $name from the trunk" $false
            $problems.Add("build_flavors.ps1 -Flavor `"$name`" failed -- run it directly to see why")
            continue
        }
        $want = Get-FolderTree -GitExe $Git -GitDir $GitDir -Folder $built
        if (-not $tip) {
            Row $br 'not created yet' $false
            $problems.Add("$br does not exist -> test $name, then save_day.ps1 -Flavor `"$name`"")
            continue
        }
        $have = Get-FirstLine (TGit @('rev-parse', "$tip^{tree}"))
        $when = Get-FirstLine (TGit @('log', '-1', '--format=%cd', '--date=format:%Y-%m-%d', $tip))
        $same = ($have -eq $want)
        $state = if ($same) { "matches the trunk build  (saved $when)" } else { "behind the trunk build  (last saved $when)" }
        $parts = @()
        if ($remotes -contains 'backup') {
            $b = Get-AheadBehind $Git $GitDir "refs/heads/$br" "refs/remotes/backup/$br"
            if ($b -ne 'equal') { $parts += (Describe $b 'backup' 'this branch') }
        }
        if (-not $SkipGitHub -and $remotes -contains 'origin') {
            $o = Get-AheadBehind $Git $GitDir "refs/heads/$br" "refs/remotes/origin/$br"
            if ($o -ne 'equal') { $parts += (Describe $o 'GitHub' 'this branch') }
        }
        if ($parts.Count) { $state += "; " + ($parts -join '; ') }
        Row $br $state ($same -and -not $parts.Count)
        if (-not $same) { $problems.Add("$br is behind the trunk -> test $name, then save_day.ps1 -Flavor `"$name`"") }
        if ($parts.Count)  { $problems.Add("$br not pushed everywhere ($($parts -join '; ')) -> next save_day.ps1 pushes it (add -PushOrigin for GitHub)") }
    }
    foreach ($k in $SameBuildAs.Keys) { Row $k "same build as $($SameBuildAs[$k]) (no branch of its own)" $true }
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# ── Release workflows ────────────────────────────────────────────────────
Section "Release workflows  (.github/workflows)"
$wago = Join-Path (Join-Path (Join-Path $Root '.github') 'workflows') 'wago.yml'
if (-not (Test-Path -LiteralPath $wago)) {
    Row 'wago.yml' 'missing' $false
    $problems.Add("no .github/workflows/wago.yml -> Wago never receives a build")
} elseif (Select-String -LiteralPath $wago -Pattern '^\s*args:\s*-d\s*$' -Quiet) {
    Row 'wago.yml' "passes -d to the packager (= skip uploading)" $false
    $problems.Add("wago.yml has 'args: -d' -> delete the 'with:' / 'args: -d' lines, or Wago gets nothing")
} else {
    Row 'wago.yml' 'uploads to Wago (no -d)' $true
}

# ── Installs ─────────────────────────────────────────────────────────────
Section "Game installs  (build_flavors.ps1 -Check)"
& $Builder -Check
if ($LASTEXITCODE -ne 0) { $problems.Add("an install is behind the trunk -> close WoW, .\Tools\build_flavors.ps1 -Install") }

# ── Verdict ──────────────────────────────────────────────────────────────
Write-Host ""
if ($problems.Count -eq 0) {
    Write-Host "ALL CURRENT: trunk committed, backup and GitHub match, every client's live branch and install match the trunk." -ForegroundColor Green
    exit 0
}
Write-Host "NOT CURRENT ($($problems.Count)):" -ForegroundColor Yellow
foreach ($p in $problems) { Write-Host "  - $p" -ForegroundColor Yellow }
exit 1

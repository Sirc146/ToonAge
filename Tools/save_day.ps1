<#
.SYNOPSIS
    End-of-day save: verify tested installs, refresh the version folders,
    commit, and push to the local backup repository.

.DESCRIPTION
    Run this once the day's changes are tested in-game and working. In order:
    (Repository layout -- main, live/<client>, archive/* tags -- is described in
    repo_common.ps1. One-time setup: repo_setup.ps1 -Apply.)

      1. VERIFY   Each flavor you name must show "current" in
                  build_flavors.ps1 -Check -- the game is running exactly the
                  trunk's files. A flavor that is behind was not what you
                  tested, so the script stops.
      2. CONFIRM  Asks you to confirm you tested those flavors in-game with
                  /ta errors empty. Skip the prompt with -Confirmed.
      3. REFRESH  Rebuilds each named flavor's folder beside the trunk
                  (ToonAge\Retail, ToonAge\Forever, ...) so the version
                  folders match what was tested. Game installs are not touched.
      4. COMMIT   git add -A and commit with -Message. Skipped when nothing
                  changed. Optional -Tag adds an annotated tag.
      5. SNAPSHOT Records each tested flavor's freshly built folder as the next
                  commit on its live/<client> branch (live/retail, live/forever,
                  live/anniversary, live/mists, live/classic-era). The commit
                  message names the main commit it was built from. PTR and Remix
                  are the Retail build and share live/retail. Unchanged builds
                  add no commit.
      6. PUSH     Pushes main, every live/* branch and tags to the backup --
                  but only when the backup's main is already part of this
                  history. If the backup holds a commit this folder does not,
                  the push is refused and nothing is overwritten. Pushes are
                  never forced, so a diverged live/* branch is refused too.
      7. PROVE    Reads the backup back and confirms main and each live/*
                  branch equal what this repository holds.

    -PushOrigin also pushes main and live/* to GitHub after the backup succeeds,
    plus -Tag on its own (a tag push is what triggers the GitHub release and
    the Wago upload; more than three tags in one push trigger nothing).
    repo_status.ps1 afterwards should report ALL CURRENT for what you tested.

    Nothing here force-pushes, deletes history, or touches SavedVariables.

.PARAMETER Flavor
    The flavor(s) tested today, by build folder name: Retail, PTR, Forever,
    Anniversary, Mists, "Classic Era". Only these are verified and refreshed.

.PARAMETER Message
    Commit message describing the day's work.

.PARAMETER Tag
    Optional annotated tag for this checkpoint, e.g. v2.0.0-dev.3.

.PARAMETER Confirmed
    Skip the "tested in-game?" prompt.

.PARAMETER PushOrigin
    Also push main and tags to origin (GitHub) after the backup.

.PARAMETER BackupPath
    The bare backup repository.

.EXAMPLE
    .\Tools\save_day.ps1 -Flavor Forever -Message "Forever: item recorder fix"

.EXAMPLE
    .\Tools\save_day.ps1 -Flavor Forever,Retail -Message "Remix detection" -Tag v2.0.0-dev.3
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]] $Flavor,
    [Parameter(Mandatory = $true)][string]   $Message,
    [string] $Tag,
    [switch] $Confirmed,
    [switch] $PushOrigin,
    [string] $BackupPath = 'E:/OneDrive/Desktop/ToonAge-full-backup.git'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'repo_common.ps1')

# Accept "Forever,Retail" as one string too (pwsh -File / cmd pass it that way).
$Flavor = @($Flavor | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })

$Root   = Split-Path -Parent $PSScriptRoot
$Builder = Join-Path $PSScriptRoot 'build_flavors.ps1'

function Step([string] $text) { Write-Host ""; Write-Host "== $text" -ForegroundColor Cyan }
function Fail([string] $text) { Write-Host ""; Write-Host "STOPPED: $text" -ForegroundColor Red; exit 1 }

function Invoke-Git {
    # Runs git in the trunk and returns its output; throws on a non-zero exit
    # unless -AllowFail is given, in which case $LASTEXITCODE is left for the
    # caller to read.
    # Arguments go in as one array so git flags like -m or -a are never
    # mistaken for this function's own parameters.
    param([string[]] $GitArgs, [switch] $AllowFail)
    # git writes progress to stderr; with 'Stop' in effect Windows PowerShell
    # 5.1 would turn that into a terminating error. The exit code is the
    # real signal, checked below.
    $ErrorActionPreference = 'Continue'
    $out = & $GitExe -C $Root @GitArgs 2>&1
    if (-not $AllowFail -and $LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed:`n$($out -join "`n")"
    }
    return $out
}

# Resolved to the executable itself: PowerShell names are case-insensitive, so
# a bare "git" inside a function could resolve to a function of that name.
$GitExe = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $GitExe) { Fail "git is not on PATH." }
$GitExe = $GitExe.Source
if (-not (Test-Path -LiteralPath $Builder))              { Fail "build_flavors.ps1 not found beside this script." }
if (-not (Test-Path -LiteralPath $BackupPath))           { Fail "backup repository not found: $BackupPath" }

$branch = (Invoke-Git @('rev-parse','--abbrev-ref','HEAD') | Select-Object -First 1).ToString().Trim()
if ($branch -ne 'main') { Fail "on branch '$branch', not main. Switch to main first." }

# A tagged push to GitHub is a public release (GitHub release for WowUp + Wago
# upload). Refuse it while wago.yml still passes -d ("skip uploading") to the
# packager: everything else would succeed and Wago would silently get nothing.
# .github/ can't be edited by Claude's tools, so this is the manual step's check.
if ($PushOrigin -and $Tag) {
    $wago = Join-Path $Root '.github\workflows\wago.yml'
    if ((Test-Path -LiteralPath $wago) -and (Select-String -LiteralPath $wago -Pattern '^\s*args:\s*-d\s*$' -Quiet)) {
        Fail ("$wago still has 'args: -d' (packager: skip uploading), so this release would never reach Wago.`n" +
              "Delete the 'with:' and 'args: -d' lines at the end of that file, then re-run. Nothing was changed.")
    }
}

# ── 1. VERIFY ────────────────────────────────────────────────────────────
Step "1/7  Verify tested installs match the trunk"

# build_flavors -Check reports with Write-Host; 6>&1 captures that stream.
# Its exit code covers EVERY client, and untested clients are expected to be
# behind, so the per-line result is what matters here, not the exit code.
$checkLines = & $Builder -Check 6>&1 | ForEach-Object { "$_" }

$states = @{}
foreach ($line in $checkLines) {
    if ($line -match '^(?<name>\S.{0,12}?)\s+(?<client>_[a-z_]+_)\s+(?<state>\S.*)$') {
        $name = $Matches['name'].Trim()
        if (-not $states.ContainsKey($name)) { $states[$name] = @() }
        $states[$name] += ,@($Matches['client'], $Matches['state'].Trim())
    }
}

$bad = @()
foreach ($f in $Flavor) {
    if (-not $states.ContainsKey($f)) {
        $bad += "$f : no install found (not a known flavor, or has no game folder)"
        continue
    }
    foreach ($entry in $states[$f]) {
        $client, $state = $entry
        if ($state -like 'current*') {
            Write-Host ("  {0,-13} {1,-16} {2}" -f $f, $client, $state) -ForegroundColor Green
        } else {
            Write-Host ("  {0,-13} {1,-16} {2}" -f $f, $client, $state) -ForegroundColor Yellow
            $bad += "$f ($client): $state"
        }
    }
}
if ($bad.Count) {
    Fail ("these installs do not match the trunk, so they are not what was tested:`n  " +
          ($bad -join "`n  ") +
          "`nRun .\Tools\build_flavors.ps1 -Flavor <name> -Install, retest, then re-run this.")
}

# ── 2. CONFIRM ───────────────────────────────────────────────────────────
Step "2/7  Confirm in-game test"
if ($Confirmed) {
    Write-Host "  -Confirmed given."
} else {
    $answer = Read-Host "  Tested $($Flavor -join ', ') in-game with /ta errors empty? (y/N)"
    if ($answer -notmatch '^(y|yes)$') { Fail "not confirmed. Nothing was changed." }
}

# ── 3. REFRESH ───────────────────────────────────────────────────────────
Step "3/7  Refresh version folders"
foreach ($f in $Flavor) {
    & $Builder -Flavor $f *> $null   # its progress lines are noise here; the exit code is checked
    if ($LASTEXITCODE -ne 0) { Fail "build_flavors.ps1 -Flavor $f reported a problem. Run it directly to see why." }
    Write-Host "  $f -> $(Join-Path (Split-Path -Parent $Root) $f)" -ForegroundColor Green
}

# ── 4. COMMIT ────────────────────────────────────────────────────────────
Step "4/7  Commit"
Invoke-Git @('add','-A') | Out-Null
$staged = Invoke-Git @('diff','--cached','--name-only')
if ($staged) {
    $count = @($staged).Count
    Invoke-Git @('commit','-m',$Message) | Out-Null
    $short = (Invoke-Git @('rev-parse','--short','HEAD') | Select-Object -First 1).ToString().Trim()
    Write-Host "  committed $count file(s) as $short" -ForegroundColor Green
} else {
    Write-Host "  nothing new to commit; pushing the existing HEAD."
}
if ($Tag) {
    $existing = Invoke-Git @('tag','--list',$Tag)
    if ($existing) {
        Write-Host "  tag $Tag already exists; left as is." -ForegroundColor Yellow
    } else {
        Invoke-Git @('tag','-a',$Tag,'-m',$Message) | Out-Null
        Write-Host "  tagged $Tag" -ForegroundColor Green
    }
}

# ── 5. SNAPSHOT ──────────────────────────────────────────────────────────
Step "5/7  Snapshot tested builds into live/* branches"
$gitDir  = (Invoke-Git @('rev-parse','--absolute-git-dir') | Select-Object -First 1).ToString().Trim()
$headSha = (Invoke-Git @('rev-parse','--short','HEAD') | Select-Object -First 1).ToString().Trim()
$tagNote = if ($Tag) { " ($Tag)" } else { '' }
foreach ($f in $Flavor) {
    if ($SameBuildAs.ContainsKey($f)) {
        Write-Host ("  {0,-13} same build as {1}; recorded on {2} when {1} is saved" -f $f, $SameBuildAs[$f], $LiveBranch[$SameBuildAs[$f]]) -ForegroundColor DarkGray
        continue
    }
    if (-not $LiveBranch.Contains($f)) {
        Write-Host ("  {0,-13} has no live branch defined in repo_common.ps1 -- skipped" -f $f) -ForegroundColor Yellow
        continue
    }
    $folder = Join-Path (Split-Path -Parent $Root) $f
    $snap = New-BuildSnapshot -GitExe $GitExe -GitDir $gitDir -Folder $folder -Branch $LiveBranch[$f] `
                              -Message ("{0} build of main {1}{2} -- {3}" -f $f, $headSha, $tagNote, $Message)
    if ($snap.Changed) {
        Write-Host ("  {0,-13} -> {1} at {2}" -f $f, $snap.Branch, $snap.Commit.Substring(0, 7)) -ForegroundColor Green
    } else {
        Write-Host ("  {0,-13} -> {1} unchanged (build identical to last save)" -f $f, $snap.Branch) -ForegroundColor DarkGray
    }
}

# ── 6. PUSH ──────────────────────────────────────────────────────────────
Step "6/7  Push to backup"
$remotes = Invoke-Git @('remote')
if (@($remotes) -notcontains 'backup') {
    Invoke-Git @('remote','add','backup',$BackupPath) | Out-Null
    Write-Host "  added remote 'backup' -> $BackupPath"
}
Invoke-Git @('fetch','backup','--no-tags','--prune') | Out-Null

# The backup is a mirror of GitHub, so other machines can land commits in it.
# Pushing is only safe when its main is already an ancestor of ours; anything
# else would either be refused or, forced, would erase their work.
Invoke-Git @('rev-parse','--verify','--quiet','refs/remotes/backup/main') -AllowFail | Out-Null
$backupHasMain = ($LASTEXITCODE -eq 0)
if ($backupHasMain) {
    Invoke-Git @('merge-base','--is-ancestor','refs/remotes/backup/main','HEAD') -AllowFail | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $theirs = Invoke-Git @('log','--oneline','HEAD..refs/remotes/backup/main')
        Fail ("the backup's main has commit(s) this folder does not:`n  " +
              (@($theirs) -join "`n  ") +
              "`nYour commit is saved locally. Merge those first (git merge backup/main), retest, then re-run.")
    }
}
# main plus every live/* branch, never forced: a branch the remote holds
# commits for that we don't is refused, not overwritten. Checked up front so a
# refusal stops the save before anything is pushed, with a readable reason.
$liveRefs = @(Invoke-Git @('for-each-ref','refs/heads/live','--format=%(refname)') | Where-Object { "$_" } | ForEach-Object { "$_".Trim() })
foreach ($ref in $liveRefs) {
    $short  = $ref -replace '^refs/heads/', ''
    $remote = "refs/remotes/backup/$short"
    Invoke-Git @('rev-parse','--verify','--quiet',$remote) -AllowFail | Out-Null
    if ($LASTEXITCODE -ne 0) { continue }   # not in the backup yet: a plain create
    Invoke-Git @('merge-base','--is-ancestor',$remote,$ref) -AllowFail | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Fail ("the backup's $short has commit(s) this folder does not, so nothing was pushed.`n" +
              "Your commit and snapshots are saved locally. Inspect with: git log --oneline $ref..$remote")
    }
}
$refspecs = @('refs/heads/main:refs/heads/main') + @($liveRefs | ForEach-Object { "${_}:${_}" })
Invoke-Git (@('push','backup') + $refspecs) | Out-Null
Invoke-Git @('push','backup','--tags') | Out-Null
Write-Host "  pushed main, $($liveRefs.Count) live branch(es) and tags" -ForegroundColor Green

if ($PushOrigin) {
    Invoke-Git (@('push','origin') + $refspecs) | Out-Null
    # Only today's tag goes to GitHub, on its own. A tag push is what starts the
    # release (GitHub release + release.json for WowUp) and Wago workflows, and
    # GitHub creates NO events when more than three tags arrive in one push --
    # which is exactly how v2.0.0..v2.0.3 (pushed together on 2026-09-18) never
    # produced a release. Older tags stay in the backup.
    if ($Tag) {
        Invoke-Git @('push','origin',"refs/tags/${Tag}:refs/tags/${Tag}") | Out-Null
        Write-Host "  pushed main, $($liveRefs.Count) live branch(es) and tag $Tag to origin (starts the release + Wago workflows)" -ForegroundColor Green
    } else {
        Write-Host "  pushed main and $($liveRefs.Count) live branch(es) to origin (no -Tag, so no release is triggered)" -ForegroundColor Green
    }
}

# ── 7. PROVE ─────────────────────────────────────────────────────────────
Step "7/7  Verify backup"
$head   = (Invoke-Git @('rev-parse','HEAD') | Select-Object -First 1).ToString().Trim()
$backup = (& $GitExe --git-dir=$BackupPath rev-parse main 2>&1 | Select-Object -First 1).ToString().Trim()
if ($backup -ne $head) { Fail "backup main is $backup but HEAD is $head." }
$subject = (Invoke-Git @('log','-1','--format=%s') | Select-Object -First 1).ToString().Trim()
Write-Host "  backup main = $($head.Substring(0, 7))  $subject" -ForegroundColor Green
foreach ($ref in $liveRefs) {
    $short = $ref -replace '^refs/heads/', ''
    $mine  = (Invoke-Git @('rev-parse',$ref) | Select-Object -First 1).ToString().Trim()
    $theirs = (& $GitExe --git-dir=$BackupPath rev-parse $ref 2>&1 | Select-Object -First 1).ToString().Trim()
    if ($theirs -ne $mine) { Fail "backup $short is $theirs but this repository has $mine." }
    Write-Host ("  backup {0,-17} = {1}" -f $short, $mine.Substring(0, 7)) -ForegroundColor Green
}
Write-Host ""
Write-Host "Saved." -ForegroundColor Green
exit 0

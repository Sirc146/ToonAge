<#
.SYNOPSIS
    One-time repository setup: one repo, a branch per client build, the old
    history kept as archive/* tags. Shows the plan; changes nothing without -Apply.

.DESCRIPTION
    The layout this creates is described in repo_common.ps1. In short:
    main = trunk, live/<client> = what each client runs, tags archive/* = the
    repository that existed before ToonAgeOne. origin = GitHub,
    backup = the bare repository on OneDrive.

    What it checks and, with -Apply, fixes:

      1. TRUNK     git present, this folder is a repository, on branch main.
      2. REMOTES   origin and backup exist in the trunk and point where they
                   should. A missing one is added; a different URL is reported,
                   never silently changed.
      3. BACKUP    The bare backup was created as a MIRROR of GitHub
                   (remote.origin.mirror = true, fetch +refs/*:refs/*). A single
                   "git fetch" run inside it would reset every branch to
                   GitHub's copy and DELETE every branch GitHub doesn't have --
                   live/* and today's main. The mirror setting is removed
                   (config only; no branch or commit is touched). From then on
                   the backup only ever receives pushes from this trunk.
      4. ARCHIVE   Branches in the backup that are not part of this trunk's
                   history (the old main and the old *-live branches) become
                   tags archive/<name> -- exactly how GitHub already keeps them,
                   same commits. Nothing is deleted. This is what lets
                   save_day.ps1 push main: it refuses while the backup's main
                   holds commits this trunk does not.
      5. TAGS      Tags that exist in both places with different targets are
                   reported (a push would be rejected). Nothing is changed.
      6. GITHUB    Read-only report of GitHub's branches. GitHub is never
                   changed here; save_day.ps1 -PushOrigin pushes to it.

    Safe to re-run: every step checks first and does nothing when already done.

    SNAPSHOT FIRST. Before -Apply changes anything in the backup, the whole
    backup folder is copied to <backup>.pre-setup-<date>-<time> beside it, and
    the copy is checked (same refs) before the first change is made. Each ref
    move is itself guarded (the tag is created first; the branch is removed only
    if it still points where it did), and no commit is ever deleted, so a run
    that stops halfway is finished by running it again -- but the copy is the
    undo either way:
        Remove-Item -Recurse <backup>; Rename-Item <snapshot> <backup name>

.PARAMETER Apply
    Make the changes. Without it the script only prints the plan.

.PARAMETER BackupPath
    The bare backup repository.

.PARAMETER GitHubUrl
    Expected URL of origin.

.PARAMETER NoNetwork
    Skip the GitHub report (no ls-remote).

.EXAMPLE
    .\Tools\repo_setup.ps1            # show the plan
    .\Tools\repo_setup.ps1 -Apply     # do it
#>
[CmdletBinding()]
param(
    [switch] $Apply,
    [string] $BackupPath,
    [string] $GitHubUrl,
    [switch] $NoNetwork
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'repo_common.ps1')
if (-not $BackupPath) { $BackupPath = $DefaultBackupPath }
if (-not $GitHubUrl)  { $GitHubUrl  = $DefaultGitHubUrl }

$Root = Split-Path -Parent $PSScriptRoot

function Step([string] $t) { Write-Host ""; Write-Host "== $t" -ForegroundColor Cyan }
function Ok([string] $t)   { Write-Host "  ok    $t" -ForegroundColor Green }
function Plan([string] $t) { Write-Host ("  {0} {1}" -f $(if ($Apply) { 'DO   ' } else { 'PLAN ' }), $t) -ForegroundColor Yellow }
function Note([string] $t) { Write-Host "  note  $t" -ForegroundColor DarkGray }
function Fail([string] $t) { Write-Host ""; Write-Host "STOPPED: $t" -ForegroundColor Red; exit 1 }

$Git = Get-GitExe
function TGit([string[]] $a, [switch] $AllowFail) { Invoke-GitRaw $Git (@('-C', $Root) + $a) -AllowFail:$AllowFail }
function BGit([string[]] $a, [switch] $AllowFail) { Invoke-GitRaw $Git (@("--git-dir=$BackupPath") + $a) -AllowFail:$AllowFail }

$changes = 0

# Copy of the backup taken once, right before the first change to it (-Apply
# only). Verified by comparing every ref in the copy with the original.
$script:Snapshot = $null
function Save-BackupSnapshot {
    if ($script:Snapshot) { return }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $dest  = "$($BackupPath.TrimEnd('/','\')).pre-setup-$stamp"
    Write-Host "  snap  copying the backup to $dest" -ForegroundColor Cyan
    Copy-Item -LiteralPath $BackupPath -Destination $dest -Recurse -Force -ErrorAction Stop
    $a = @(BGit @('for-each-ref', '--format=%(refname) %(objectname)')) -join "`n"
    $b = @(Invoke-GitRaw $Git @("--git-dir=$dest", 'for-each-ref', '--format=%(refname) %(objectname)')) -join "`n"
    if ($a -ne $b) { Fail "the snapshot at $dest does not match the backup. Nothing was changed; remove it and re-run." }
    Write-Host "  snap  verified ($(@($a -split "`n").Count) refs). Undo at any point:" -ForegroundColor Cyan
    Write-Host "        Remove-Item -Recurse -Force '$BackupPath'; Rename-Item '$dest' '$(Split-Path -Leaf $BackupPath)'" -ForegroundColor DarkGray
    $script:Snapshot = $dest
}

# ── 1. TRUNK ─────────────────────────────────────────────────────────────
Step "1/6  Trunk"
TGit @('rev-parse', '--is-inside-work-tree') -AllowFail | Out-Null
if ($LASTEXITCODE -ne 0) { Fail "$Root is not a git repository." }
$GitDir = Get-FirstLine (TGit @('rev-parse', '--absolute-git-dir'))
$branch = Get-FirstLine (TGit @('rev-parse', '--abbrev-ref', 'HEAD'))
if ($branch -ne 'main') { Fail "on branch '$branch', not main. Switch to main first." }
$head = Get-FirstLine (TGit @('rev-parse', 'HEAD'))
Ok ("{0} on main at {1}" -f $Root, $head.Substring(0, 7))
$dirty = @(TGit @('status', '--porcelain')).Where({ $_ }).Count
if ($dirty) { Note "$dirty uncommitted change(s). Setup doesn't need a clean tree; save_day.ps1 commits them." }

# ── 2. REMOTES ───────────────────────────────────────────────────────────
Step "2/6  Remotes"
$remotes = @(TGit @('remote'))
foreach ($pair in @(@('origin', $GitHubUrl), @('backup', $BackupPath))) {
    $name, $want = $pair
    if ($remotes -contains $name) {
        $have = Get-FirstLine (TGit @('remote', 'get-url', $name))
        if ($have.TrimEnd('/') -ieq $want.TrimEnd('/')) { Ok "$name -> $have" }
        else { Note "$name points at $have (expected $want). Left as is; change it with: git remote set-url $name `"$want`"" }
    } else {
        Plan "add remote $name -> $want"
        if ($Apply) { TGit @('remote', 'add', $name, $want) | Out-Null }
        $changes++
    }
}

# ── 3. BACKUP ────────────────────────────────────────────────────────────
Step "3/6  Backup repository"
if (-not (Test-Path -LiteralPath $BackupPath)) { Fail "backup repository not found: $BackupPath" }
$isBare = Get-FirstLine (BGit @('rev-parse', '--is-bare-repository') -AllowFail)
if ($isBare -ne 'true') { Fail "$BackupPath is not a bare repository." }
Ok "$BackupPath is a bare repository"

$mirror = Get-FirstLine (BGit @('config', '--get', 'remote.origin.mirror') -AllowFail)
$mfetch = Get-FirstLine (BGit @('config', '--get', 'remote.origin.fetch') -AllowFail)
if ($mirror -eq 'true' -or $mfetch -eq '+refs/*:refs/*') {
    Plan "remove the backup's mirror-of-GitHub setting (remote.origin, config only)"
    Note "one 'git fetch' inside the backup would otherwise overwrite main and delete live/*"
    if ($Apply) { Save-BackupSnapshot; BGit @('config', '--remove-section', 'remote.origin') | Out-Null }
    $changes++
} else {
    Ok "backup is push-only (no mirror fetch configured)"
}

# ── 4. LEGACY ────────────────────────────────────────────────────────────
Step "4/6  Old branches in the backup -> archive/* tags (as on GitHub)"
# Bring the backup's branches into this repo's object store so ancestry can be
# tested. Read-only for the backup.
TGit @('fetch', 'backup', '--no-tags', '--prune', '--quiet') | Out-Null

$heads = @(BGit @('for-each-ref', 'refs/heads', '--format=%(refname:short) %(objectname)')).Where({ $_ })
if (-not $heads.Count) { Ok "backup has no branches yet" }
foreach ($line in $heads) {
    $name, $oid = $line -split ' ', 2
    if ($name -like 'live/*') { Ok "$name (managed)"; continue }
    TGit @('merge-base', '--is-ancestor', $oid, 'HEAD') -AllowFail | Out-Null
    if ($LASTEXITCODE -eq 0) { Ok "$name is part of this trunk's history -- kept"; continue }
    if ($LASTEXITCODE -ne 1) { Fail "could not compare backup branch $name ($oid) with HEAD." }

    $target = "refs/tags/archive/$name"
    $existing = Get-RefOid $Git $BackupPath $target
    if ($existing -and $existing -ne $oid) {
        Note "$name not moved: tag archive/$name already exists at a different commit. Resolve by hand."
        continue
    }
    $how = if ($existing) { 'tag already there, branch removed' } else { 'new tag' }
    Plan ("branch {0,-26} -> tag archive/{0}   ({1}, {2})" -f $name, $oid.Substring(0, 7), $how)
    if ($Apply) {
        Save-BackupSnapshot
        if (-not $existing) { BGit @('update-ref', '-m', 'repo_setup: archive', $target, $oid, $ZeroOid) | Out-Null }
        # Delete only if it still points where we looked: never lose a commit
        # that landed between the check and the move.
        BGit @('update-ref', '-m', 'repo_setup: archived as tag', '-d', "refs/heads/$name", $oid) | Out-Null
    }
    $changes++
}
if ($Apply) { TGit @('fetch', 'backup', '--no-tags', '--prune', '--quiet') | Out-Null }

# ── 5. TAGS ──────────────────────────────────────────────────────────────
Step "5/6  Tags"
$local = @{}
foreach ($l in @(TGit @('for-each-ref', 'refs/tags', '--format=%(refname:short) %(objectname)')).Where({ $_ })) {
    $n, $o = $l -split ' ', 2; $local[$n] = $o
}
$clash = 0
foreach ($l in @(BGit @('for-each-ref', 'refs/tags', '--format=%(refname:short) %(objectname)')).Where({ $_ })) {
    $n, $o = $l -split ' ', 2
    if ($local.ContainsKey($n) -and $local[$n] -ne $o) {
        Note "tag $n differs: trunk $($local[$n].Substring(0,7)), backup $($o.Substring(0,7)). A push of this tag will be rejected; delete one copy by hand if it matters."
        $clash++
    }
}
if (-not $clash) { Ok "no conflicting tags ($($local.Count) in the trunk)" }

# ── 6. GITHUB ────────────────────────────────────────────────────────────
Step "6/6  GitHub (read only)"
if ($NoNetwork) {
    Note "skipped (-NoNetwork)"
} else {
    $gh = @(TGit @('ls-remote', '--heads', 'origin') -AllowFail)
    if ($LASTEXITCODE -ne 0) {
        Note "could not reach origin: $(Get-FirstLine $gh)"
    } else {
        foreach ($l in $gh.Where({ $_ -match 'refs/heads/' })) {
            $o, $r = $l -split '\s+', 2
            $n = $r -replace '^refs/heads/', ''
            TGit @('cat-file', '-e', "$o^{commit}") -AllowFail | Out-Null
            $known = ($LASTEXITCODE -eq 0)
            $rel = 'not in this trunk'
            if ($known) {
                TGit @('merge-base', '--is-ancestor', $o, 'HEAD') -AllowFail | Out-Null
                if ($LASTEXITCODE -eq 0) { $rel = 'behind or equal to main -- fine' }
            }
            Note ("{0,-26} {1}  {2}" -f $n, $o.Substring(0, 7), $rel)
        }
        Note "GitHub is not changed here. save_day.ps1 -PushOrigin pushes main, live/* and tags."
    }
}

# ── Summary ──────────────────────────────────────────────────────────────
Write-Host ""
if (-not $changes) {
    Write-Host "Repository layout is already in place. Nothing to do." -ForegroundColor Green
} elseif ($Apply) {
    Write-Host "Done: $changes change(s) made." -ForegroundColor Green
    if ($script:Snapshot) { Write-Host "Backup as it was before: $($script:Snapshot)  (delete it once you're satisfied)" -ForegroundColor DarkGray }
} else {
    Write-Host "$changes change(s) planned. Run again with -Apply to make them." -ForegroundColor Yellow
}
Write-Host ""
Write-Host "Live branches are created by save_day.ps1, one per client you test:" -ForegroundColor DarkGray
foreach ($k in $LiveBranch.Keys) { Write-Host ("  {0,-13} -> {1}" -f $k, $LiveBranch[$k]) -ForegroundColor DarkGray }
foreach ($k in $SameBuildAs.Keys) { Write-Host ("  {0,-13} -> same build as {1}" -f $k, $SameBuildAs[$k]) -ForegroundColor DarkGray }
exit 0

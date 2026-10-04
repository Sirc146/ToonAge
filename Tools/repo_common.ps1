<#
    Shared by repo_setup.ps1, repo_status.ps1 and save_day.ps1. Dot-source it:

        . (Join-Path $PSScriptRoot 'repo_common.ps1')

    THE REPOSITORY LAYOUT (set up 2026-10-04)
    -----------------------------------------
    One repository, one history, a branch per client build:

      main                 the trunk (ToonAgeOne). Every client's build comes
                           from here; this is where you work.
      live/retail          the exact folder installed on Retail (PTR and Remix
                           run the same Mainline build, so they share it)
      live/forever         the exact folder installed on Forever
      live/anniversary     the exact folder installed on TBC Anniversary
      live/mists           the exact folder installed on Mists Classic
      live/classic-era     the exact folder installed on Classic Era
      tag archive/*        the repository that existed before ToonAgeOne (old
                           main, retail-live, anniversary-live, classic-live,
                           2.0, classic, pre-git-characteradvisor). GitHub
                           already keeps them exactly this way -- tags
                           archive/<old branch name>, same commits -- so the
                           backup is brought into line with it.

    A live/* commit is made only by save_day.ps1, only for a client you tested
    that day, and its message names the main commit it was built from. So each
    live/* branch is the history of what that client actually ran, and any past
    build can be restored with  git archive live/<name> <commit>.

    Why branches and not a repository per client: build_flavors.ps1 deletes and
    rebuilds each version folder on every run, so a .git inside one would be
    wiped, and seven repositories would be seven things to keep in step. One
    repository means one backup, one push and one status check.

    Remotes: origin = GitHub, backup = the bare repository on OneDrive. Both
    receive main, live/* and tags, and end up holding the same refs. Nothing
    here ever force-pushes.
#>

Set-StrictMode -Version 2.0

# Build folder name (as build_flavors.ps1 names it) -> its live branch.
$LiveBranch = [ordered]@{
    'Retail'      = 'live/retail'
    'Forever'     = 'live/forever'
    'Anniversary' = 'live/anniversary'
    'Mists'       = 'live/mists'
    'Classic Era' = 'live/classic-era'
}

# Builds that are the same file set as another (same TOC in build_flavors.ps1).
# They get no branch of their own: it would be a byte-for-byte copy.
$SameBuildAs = @{
    'PTR'   = 'Retail'
    'Remix' = 'Retail'
}

$DefaultBackupPath = 'E:/OneDrive/Desktop/ToonAge-full-backup.git'
$DefaultGitHubUrl  = 'https://github.com/Sirc146/ToonAge.git'
$ZeroOid           = '0000000000000000000000000000000000000000'

function Get-GitExe {
    # Resolved to the executable: PowerShell names are case-insensitive, so a
    # bare "git" could resolve to a function or alias of that name.
    $g = Get-Command git -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $g) { throw "git is not on PATH." }
    return $g.Source
}

function Invoke-GitRaw {
    # Runs git with the given argument array. Returns its output as strings.
    # Throws on a non-zero exit unless -AllowFail; then $LASTEXITCODE is left
    # for the caller. Arguments travel as one array so git flags like -m are
    # never taken for this function's own parameters.
    param([Parameter(Mandatory = $true)][string] $GitExe,
          [Parameter(Mandatory = $true)][string[]] $GitArgs,
          [switch] $AllowFail)
    # git writes progress to stderr; under 'Stop' Windows PowerShell 5.1 turns
    # that into a terminating error. The exit code is the real signal.
    $ErrorActionPreference = 'Continue'
    $out = & $GitExe @GitArgs 2>&1 | ForEach-Object { "$_" }
    $code = $LASTEXITCODE
    if (-not $AllowFail -and $code -ne 0) {
        throw "git $($GitArgs -join ' ') failed (exit $code):`n$($out -join "`n")"
    }
    $global:LASTEXITCODE = $code
    return $out
}

function Get-FirstLine {
    param($Lines)
    $l = @($Lines) | Select-Object -First 1
    if ($null -eq $l) { return '' }
    return "$l".Trim()
}

function Get-FolderTree {
    # The git tree id of a folder's exact contents, without touching the
    # repository's own index or working tree: a throwaway index file is filled
    # from the folder and written as a tree. Objects land in the repository's
    # object store, which is what a later commit-tree needs anyway.
    param([Parameter(Mandatory = $true)][string] $GitExe,
          [Parameter(Mandatory = $true)][string] $GitDir,
          [Parameter(Mandatory = $true)][string] $Folder)
    if (-not (Test-Path -LiteralPath $Folder -PathType Container)) {
        throw "build folder not found: $Folder"
    }
    $folderFull = (Resolve-Path -LiteralPath $Folder).Path
    $idx = Join-Path ([System.IO.Path]::GetTempPath()) ("toonage-snap-{0}.idx" -f [guid]::NewGuid().ToString('N'))
    $hadIndexVar = Test-Path Env:GIT_INDEX_FILE
    $oldIndexVar = if ($hadIndexVar) { $env:GIT_INDEX_FILE } else { $null }
    try {
        $env:GIT_INDEX_FILE = $idx
        # -f: the trunk's .gitignore / info/exclude must not drop files from a
        # build; the folder holds only what the TOC ships, by construction.
        Invoke-GitRaw $GitExe @('-C', $folderFull, "--git-dir=$GitDir", "--work-tree=$folderFull",
                                'add', '-A', '-f', '--', '.') | Out-Null
        return Get-FirstLine (Invoke-GitRaw $GitExe @("--git-dir=$GitDir", 'write-tree'))
    } finally {
        if ($hadIndexVar) { $env:GIT_INDEX_FILE = $oldIndexVar } else { Remove-Item Env:GIT_INDEX_FILE -ErrorAction SilentlyContinue }
        Remove-Item -LiteralPath $idx -Force -ErrorAction SilentlyContinue
    }
}

function Get-RefOid {
    # The object id a ref points at, or $null when the ref does not exist.
    param([string] $GitExe, [string] $GitDir, [string] $Ref)
    $o = Invoke-GitRaw $GitExe @("--git-dir=$GitDir", 'rev-parse', '--verify', '--quiet', "$Ref^{commit}") -AllowFail
    if ($LASTEXITCODE -ne 0) { return $null }
    return Get-FirstLine $o
}

function New-BuildSnapshot {
    # Records a build folder as the next commit on its live/* branch. Returns
    # @{ Branch; Commit; Changed }. Changed is $false when the folder is
    # byte-identical to the branch tip (nothing is committed then).
    param([Parameter(Mandatory = $true)][string] $GitExe,
          [Parameter(Mandatory = $true)][string] $GitDir,
          [Parameter(Mandatory = $true)][string] $Folder,
          [Parameter(Mandatory = $true)][string] $Branch,
          [Parameter(Mandatory = $true)][string] $Message)
    $tree   = Get-FolderTree -GitExe $GitExe -GitDir $GitDir -Folder $Folder
    $ref    = "refs/heads/$Branch"
    $parent = Get-RefOid $GitExe $GitDir $ref
    if ($parent) {
        $parentTree = Get-FirstLine (Invoke-GitRaw $GitExe @("--git-dir=$GitDir", 'rev-parse', "$parent^{tree}"))
        if ($parentTree -eq $tree) { return @{ Branch = $Branch; Commit = $parent; Changed = $false } }
        $commit = Get-FirstLine (Invoke-GitRaw $GitExe @("--git-dir=$GitDir", 'commit-tree', $tree, '-p', $parent, '-m', $Message))
        Invoke-GitRaw $GitExe @("--git-dir=$GitDir", 'update-ref', '-m', "snapshot: $Message", $ref, $commit, $parent) | Out-Null
    } else {
        # First snapshot: a root commit. A build folder shares no files' paths
        # with main's history in a meaningful way, so it starts its own line.
        $commit = Get-FirstLine (Invoke-GitRaw $GitExe @("--git-dir=$GitDir", 'commit-tree', $tree, '-m', $Message))
        Invoke-GitRaw $GitExe @("--git-dir=$GitDir", 'update-ref', '-m', "snapshot: $Message", $ref, $commit, $ZeroOid) | Out-Null
    }
    return @{ Branch = $Branch; Commit = $commit; Changed = $true }
}

function Get-AheadBehind {
    # "equal", "ahead N", "behind N", "diverged (A ahead, B behind)" or
    # "missing" for local ref $Local versus $Other, in the repo at $GitDir.
    param([string] $GitExe, [string] $GitDir, [string] $Local, [string] $Other)
    $l = Get-RefOid $GitExe $GitDir $Local
    $o = Get-RefOid $GitExe $GitDir $Other
    if (-not $l) { return 'no local branch' }
    if (-not $o) { return 'missing' }
    if ($l -eq $o) { return 'equal' }
    $counts = (Get-FirstLine (Invoke-GitRaw $GitExe @("--git-dir=$GitDir", 'rev-list', '--left-right', '--count', "$Local...$Other"))) -split '\s+'
    $ahead = [int]$counts[0]; $behind = [int]$counts[1]
    if ($behind -eq 0) { return "ahead $ahead" }
    if ($ahead -eq 0)  { return "behind $behind" }
    return "diverged ($ahead ahead, $behind behind)"
}

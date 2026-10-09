<#
.SYNOPSIS
    Builds the folder your FRIENDS get from WowUp / Wago -- the release zip's
    exact layout -- and optionally installs it into one client to see what that
    client really loads.

.DESCRIPTION
    build_flavors.ps1 makes a clean per-client folder: only that client's TOC
    and files. The GitHub release does NOT. .github/workflows/release.yml rsyncs
    the whole repository root into ToonAge/ (minus dev folders), so the zip a
    friend installs carries EVERY TOC at once:

        ToonAge.toc            retail file list  (fallback name)
        ToonAge_Mainline.toc   retail file list
        ToonAge_Camelot.toc    Forever file list
        ToonAge_TBC.toc, ToonAge_Mists.toc, ToonAge_Vanilla.toc, _Cata, _Wrath

    Each client picks one TOC by filename. For Retail, TBC, Mists and Classic
    Era the suffix is the documented one. For Forever it is NOT settled: on this
    machine the client ignored ToonAge_Camelot.toc when it was the only TOC and
    read _Mainline instead. If it does that with the full zip, a friend on
    Forever gets the retail list -- and ToonAge's wrong-build check then stops
    every module and prints "This is a forever client but the Mainline build
    loaded". So: test the zip layout on Forever before announcing a release.

    This script reproduces release.yml's layout from what the next commit would
    contain (tracked + new files, minus .gitignore'd ones), with the same
    exclusions: .git .github Art Data Tools Docs docs .claude __pycache__
    *.pyc *.py CLAUDE.md .rules.md .gitignore.

    With -InstallTo it replaces that client's Interface\AddOns\ToonAge with the
    layout (SavedVariables are untouched -- they live under WTF\). Put the
    proper build back afterwards with:  .\Tools\build_flavors.ps1 -Flavor <name> -Install

.PARAMETER InstallTo
    Client folder(s) to install the layout into, e.g. _classic_beta_ (Forever),
    or 'all' for every client folder ToonAge installs to. Testing 'all' is
    testing exactly what WowUp/Wago users get on each client.

.PARAMETER OutDir
    Where to build the layout. Default: a ToonAge-release-layout folder in TEMP.

.PARAMETER WowPath
    Where WoW is installed. Only used with -InstallTo.

.EXAMPLE
    .\Tools\build_release_layout.ps1                          # build + list the TOCs
    .\Tools\build_release_layout.ps1 -InstallTo _classic_beta_ # test it on Forever
    .\Tools\build_release_layout.ps1 -InstallTo all            # every client: what friends get
#>
[CmdletBinding()]
param(
    [string[]] $InstallTo,
    [string]   $OutDir,
    [string]   $WowPath = 'C:\Program Files (x86)\World of Warcraft'
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'repo_common.ps1')
$Root = Split-Path -Parent $PSScriptRoot
$Git  = Get-GitExe

if (-not $OutDir) { $OutDir = Join-Path ([System.IO.Path]::GetTempPath()) 'ToonAge-release-layout' }
$pkg = Join-Path $OutDir 'ToonAge'

# Same exclusions as release.yml's rsync. rsync --exclude='Tools' drops any path
# component named Tools, anywhere -- so this matches on every segment.
$ExcludeDirs  = @('.git', '.github', 'Art', 'Data', 'Tools', 'Docs', 'docs', '.claude', '__pycache__')
$ExcludeNames = @('CLAUDE.md', '.rules.md', '.gitignore')
function Test-Excluded([string] $rel) {
    $parts = $rel -split '[\\/]'
    foreach ($p in $parts[0..($parts.Count - 2)]) { if ($ExcludeDirs -contains $p) { return $true } }
    $leaf = $parts[-1]
    if ($ExcludeDirs -contains $leaf) { return $true }
    if ($ExcludeNames -contains $leaf) { return $true }
    if ($leaf -like '*.py' -or $leaf -like '*.pyc') { return $true }
    return $false
}

# What the next commit would hold: tracked files plus new, non-ignored ones.
$files = @(Invoke-GitRaw $Git @('-C', $Root, 'ls-files', '--cached', '--others', '--exclude-standard')) |
         Where-Object { $_ } | Sort-Object -Unique
$files = @($files | Where-Object { -not (Test-Excluded $_) } |
           Where-Object { Test-Path -LiteralPath (Join-Path $Root $_) -PathType Leaf })

if (Test-Path -LiteralPath $pkg) { Remove-Item -LiteralPath $pkg -Recurse -Force }
New-Item -ItemType Directory -Path $pkg -Force | Out-Null
foreach ($rel in $files) {
    $dst = Join-Path $pkg $rel
    $dir = Split-Path -Parent $dst
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Copy-Item -LiteralPath (Join-Path $Root $rel) -Destination $dst -Force
}

Write-Host ""
Write-Host "Release layout: $pkg  ($($files.Count) files)" -ForegroundColor Cyan
Write-Host "TOCs a friend's client will choose from:" -ForegroundColor Cyan
foreach ($toc in Get-ChildItem -LiteralPath $pkg -Filter '*.toc' -File | Sort-Object Name) {
    $lines   = Get-Content -LiteralPath $toc.FullName
    $iface   = ($lines | Where-Object { $_ -like '## Interface:*' } | Select-Object -First 1) -replace '^## Interface:\s*', ''
    $flavor  = ($lines | Where-Object { $_ -like '## X-Flavor:*' }  | Select-Object -First 1) -replace '^## X-Flavor:\s*', ''
    $count   = @($lines | Where-Object { $_ -match '^[^#].*\.(lua|xml)\s*$' }).Count
    Write-Host ("  {0,-22} interface {1,-24} X-Flavor {2,-9} {3} files" -f $toc.Name, $iface, $flavor, $count)
}

if (-not $InstallTo) {
    Write-Host ""
    Write-Host "Not installed anywhere. To test it on Forever: -InstallTo _classic_beta_" -ForegroundColor DarkGray
    exit 0
}

# 'all' = every client folder build_flavors.ps1 installs to (its $InstallDirs).
if ($InstallTo -contains 'all') {
    $InstallTo = @('_retail_', '_ptr_', '_xptr_', '_classic_beta_', '_anniversary_', '_classic_', '_classic_era_')
}
foreach ($client in $InstallTo) {
    $addons = Join-Path (Join-Path $WowPath $client) 'Interface\AddOns'
    if (-not (Test-Path -LiteralPath $addons)) { Write-Warning "$client is not installed -- skipped."; continue }
    $target = Join-Path $addons 'ToonAge'
    if ((Split-Path -Leaf $target) -ne 'ToonAge') { throw "Refusing to touch '$target' -- not a ToonAge folder." }
    try {
        if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop }
        Copy-Item -LiteralPath $pkg -Destination $target -Recurse -Force -ErrorAction Stop
        Write-Host "  installed the RELEASE layout -> $client" -ForegroundColor Yellow
    } catch {
        Write-Warning "  $client failed: $($_.Exception.Message)  (close that WoW client and re-run)"
    }
}
Write-Host ""
Write-Host "In game: restart the client fully, then click Self-test (or /tatest)." -ForegroundColor Cyan
Write-Host "  Right TOC : title bar shows the client name (e.g. 'Forever'), tabs appear, self-test env suite passes 'TOC X-Flavor'." -ForegroundColor Cyan
Write-Host "  Wrong TOC : chat says 'This is a <client> client but the <other> build loaded. Nothing will run'." -ForegroundColor Cyan
Write-Host "Put the normal build back afterwards: .\Tools\build_flavors.ps1 -Flavor <name> -Install" -ForegroundColor DarkGray
exit 0

<#
.SYNOPSIS
    Builds a per-client working copy of ToonAge into each version folder.

.DESCRIPTION
    Each folder beside the trunk holds a build for ONE client, containing only
    the files that client's TOC lists -- nothing else. Drop a folder into that
    client's Interface\AddOns as "ToonAge" and it loads.

    The TOC is the manifest. This script does not keep its own file list,
    because a second list is a list that drifts: that is exactly how the
    Character tab shipped blank (Core\Layout.lua missing from one TOC) and how
    Forever ended up loading the entire retail product. Add a file to a TOC and
    it appears in that flavour's build on the next run. There is nothing else
    to remember.

    Safe to re-run. Each target is emptied first, so a file removed from a TOC
    actually disappears from the build instead of lingering.

.PARAMETER Root
    The trunk. Defaults to the parent of this script's folder.

.PARAMETER Dest
    Where the version folders live. Defaults to the trunk's parent.

.PARAMETER Flavor
    Build just one, by folder name. Omit to build all.

.PARAMETER Install
    After building, copy each build into that client's Interface\AddOns\ToonAge,
    replacing what is there.

    SavedVariables are NOT touched: WoW keeps them under WTF\Account\..., not
    in the addon folder, so settings, the error log, gather history and the
    harvester's store all survive a replace. Verified on this install before
    this switch was written.

.PARAMETER WowPath
    Where WoW is installed. Only used with -Install.

.PARAMETER Check
    Report only: compare every installed client against the trunk and say what
    is behind. Builds nothing, installs nothing, deletes nothing.

    This exists because a stale install is indistinguishable from a broken fix.
    A fix went to the trunk minutes after a build ran, the game kept the old
    file, the same error came back, and it looked exactly like the fix had
    failed -- costing a client restart to learn nothing. One command now
    answers "is the game actually running what I think it is".

.PARAMETER Prune
    Remove what no build targets any more: version folders beside the trunk
    that this script does not produce, and stale ToonAge build zips left in a
    client's AddOns folder.

    Deliberately conservative. It never touches the trunk, never touches a
    folder containing a .git, and never touches anything outside the two roots
    it is given. Run it with -WhatIf first.

.PARAMETER WhatIf
    Report what would be copied and change nothing. Worth running first the
    time you use -Install.

.EXAMPLE
    .\Tools\build_flavors.ps1
    .\Tools\build_flavors.ps1 -Flavor Forever
    .\Tools\build_flavors.ps1 -Install -WhatIf
    .\Tools\build_flavors.ps1 -Install
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string] $Root,
    [string] $Dest,
    [string] $Flavor,
    [switch] $Install,
    [switch] $Prune,
    [switch] $Check,
    [string] $WowPath = 'C:\Program Files (x86)\World of Warcraft'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if (-not $Root) { $Root = Split-Path -Parent $PSScriptRoot }
if (-not $Dest) { $Dest = Split-Path -Parent $Root }

# Folder name -> the TOC that defines that build.
#
# Remix is not a game type of its own: it runs on the retail client, so it
# takes the Mainline build. PTR and XPTR are retail test clients and take the
# same set -- the TOC already lists their interface numbers.
$Builds = [ordered]@{
    'Retail'      = 'ToonAge_Mainline.toc'
    # One PTR build serves both test clients. They run the same Mainline file
    # set, so two folders were two identical copies to keep in step.
    'PTR'         = 'ToonAge_Mainline.toc'
    'Remix'       = 'ToonAge_Mainline.toc'
    'Forever'     = 'ToonAge_Camelot.toc'
    'Anniversary' = 'ToonAge_TBC.toc'
    'Mists'       = 'ToonAge_Mists.toc'
    'Classic Era' = 'ToonAge_Vanilla.toc'
}

# Files every build needs that no TOC lists. Bindings.xml is the notable one:
# WoW loads it automatically BECAUSE it is not listed (listing it double-parses
# and errors), so a build without it silently loses every keybind.
$Extras = @('Bindings.xml', 'LICENSE.md', 'README.md')

# Extra TOC names a build must ALSO be emitted under.
#
# Forever is the case. Its own suffix is not enough on this client: the addon
# folder was not recognised at all while ToonAge_Camelot.toc was the only TOC
# in it -- ToonAge never appeared in AddOns.txt, not even as "disabled".
#
# The controlled comparison is on the same install. ElvUI ships _Mainline,
# _Mists, _TBC, _Vanilla and _Wrath -- no base TOC and no _Camelot -- and the
# client lists it. The only suffix it can be matching there is _Mainline.
# Questie cannot settle it either way because it ships a base Questie.toc
# alongside its _Camelot one.
#
# So the Forever build is emitted under BOTH names. _Camelot takes priority
# where it is honoured (and is what a future client should use); _Mainline is
# the one this build demonstrably reads. Each flavour lives in its own folder,
# so the retail ToonAge_Mainline.toc and this one never meet -- this file
# carries Forever's 30-file list at interface 16001, not retail's 131.
#
# EVERY build also gets the no-suffix ToonAge.toc. Per the TOC format the
# client "first searches for the special file names, and if none are found,
# uses AddonName.toc" -- so the base name is the universal fallback, and a
# build carrying one cannot go unrecognised however the client's suffix
# handling changes. Questie ships exactly this pair. It costs one duplicated
# file per folder and removes the entire failure mode, which is worth far more
# than the tidiness of a single TOC.
#
# The file always contains THAT flavour's list at THAT flavour's interface
# number -- each build is its own folder, so no two ever meet.
$AlsoEmitTocAs = @{
    'Retail'      = @('ToonAge.toc')
    'PTR'         = @('ToonAge.toc')
    'Remix'       = @('ToonAge.toc')
    'Anniversary' = @('ToonAge.toc')
    'Mists'       = @('ToonAge.toc')
    'Classic Era' = @('ToonAge.toc')
    'Forever'     = @('ToonAge_Mainline.toc', 'ToonAge.toc')
}

# Folder name -> the client's install directory, for -Install.
#
# Remix has no entry on purpose: it runs on the retail client and has no
# install folder of its own, so it builds but does not install. Beta and
# Classic are absent because there is no build for them.
# A build may install to more than one client -- the two PTRs share one.
$InstallDirs = @{
    'Retail'      = @('_retail_')
    'PTR'         = @('_ptr_', '_xptr_')
    'Forever'     = @('_classic_beta_')
    'Anniversary' = @('_anniversary_')
    # Mists of Pandaria Classic. The folder is _classic_ and the product is
    # wow_classic -- NOT Classic Era, which is _classic_era_ / wow_classic_era.
    # Blizzard's launcher labels _classic_era_ "World of Warcraft Classic" and
    # _classic_ "Mists of Pandaria Classic", so the folder name and the display
    # name point at each other's client. Verified from .build.info: _classic_
    # is 5.5.4 (interface 50504) and _classic_era_ is 1.15.9 (11509).
    'Mists'       = @('_classic_')
    'Classic Era' = @('_classic_era_')
}

function Get-TocFiles {
    param([string] $TocPath)
    $files = @()
    foreach ($line in Get-Content -LiteralPath $TocPath) {
        $t = $line.Trim()
        if (-not $t -or $t.StartsWith('#')) { continue }
        # strip any per-file [AllowLoadGameType ...] directive
        $t = ($t -split '\[')[0].Trim()
        if ($t -match '\.(lua|xml)$') { $files += $t }
    }
    return $files
}

$targets = if ($Flavor) {
    if (-not $Builds.Contains($Flavor)) {
        throw "Unknown flavor '$Flavor'. Known: $($Builds.Keys -join ', ')"
    }
    @{ $Flavor = $Builds[$Flavor] }
} else { $Builds }

# ── Check ────────────────────────────────────────────────────────────────
# Compares each client's installed files against the trunk. Size, not hash:
# a Lua edit that keeps the byte count identical is vanishingly rare, and this
# has to be fast enough to run without thinking about it.
if ($Check) {
    $anyStale = $false
    foreach ($name in $Builds.Keys) {
        if (-not $InstallDirs.ContainsKey($name)) { continue }

        $listed = Get-TocFiles -TocPath (Join-Path $Root $Builds[$name])
        foreach ($clientDir in $InstallDirs[$name]) {
            $target = Join-Path (Join-Path (Join-Path $WowPath $clientDir) 'Interface\AddOns') 'ToonAge'
            if (-not (Test-Path -LiteralPath $target)) {
                Write-Host ("{0,-13} {1,-16} NOT INSTALLED" -f $name, $clientDir) -ForegroundColor Red
                $anyStale = $true
                continue
            }

            $stale = @()
            $absent = @()
            foreach ($rel in $listed) {
                $srcFile = Join-Path $Root $rel
                $dstFile = Join-Path $target $rel
                if (-not (Test-Path -LiteralPath $srcFile)) { continue }
                if (-not (Test-Path -LiteralPath $dstFile)) { $absent += $rel; continue }
                if ((Get-Item -LiteralPath $srcFile).Length -ne (Get-Item -LiteralPath $dstFile).Length) {
                    $stale += $rel
                }
            }

            if ($stale.Count -eq 0 -and $absent.Count -eq 0) {
                Write-Host ("{0,-13} {1,-16} current ({2} files)" -f $name, $clientDir, $listed.Count) -ForegroundColor Green
            } else {
                $anyStale = $true
                Write-Host ("{0,-13} {1,-16} {2} behind, {3} missing" -f `
                    $name, $clientDir, $stale.Count, $absent.Count) -ForegroundColor Yellow
                foreach ($f in ($stale + $absent | Select-Object -First 8)) {
                    Write-Host "                                 $f" -ForegroundColor DarkGray
                }
                if (($stale.Count + $absent.Count) -gt 8) {
                    Write-Host ("                                 ... and {0} more" -f `
                        ($stale.Count + $absent.Count - 8)) -ForegroundColor DarkGray
                }
            }
        }
    }
    Write-Host ""
    if ($anyStale) {
        Write-Host "Run with -Install to bring these up to date." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "Every install matches the trunk." -ForegroundColor Green
    exit 0
}

# ── Prune ────────────────────────────────────────────────────────────────
# Runs before the builds so a stale folder cannot be mistaken for a fresh one.
if ($Prune) {
    Write-Host "Pruning" -ForegroundColor Cyan

    # Version folders beside the trunk that no build produces. Derived from
    # $Builds rather than hardcoded, so retiring a build retires its folder
    # without anyone remembering to update a second list.
    $keep = @($Builds.Keys) + @((Split-Path -Leaf $Root))
    foreach ($dir in Get-ChildItem -LiteralPath $Dest -Directory -ErrorAction SilentlyContinue) {
        if ($keep -contains $dir.Name) { continue }

        # A folder under version control is someone's work, not our output.
        if (Test-Path -LiteralPath (Join-Path $dir.FullName '.git')) {
            Write-Warning "  $($dir.Name) has a .git -- left alone."
            continue
        }

        $n = @(Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -ErrorAction SilentlyContinue).Count
        if ($PSCmdlet.ShouldProcess($dir.FullName, "remove ($n files, no build targets it)")) {
            Remove-Item -LiteralPath $dir.FullName -Recurse -Force
            Write-Host "  removed $($dir.Name)  ($n files)" -ForegroundColor Yellow
        }
    }

    # Old build zips left in a client's AddOns folder. WoW ignores them, but
    # they are megabytes of dead weight and they make it hard to tell which
    # build is actually installed.
    if ($Install) {
        foreach ($entry in $InstallDirs.GetEnumerator()) {
            foreach ($clientDir in $entry.Value) {
                $addons = Join-Path (Join-Path $WowPath $clientDir) 'Interface\AddOns'
                if (-not (Test-Path -LiteralPath $addons)) { continue }
                foreach ($z in Get-ChildItem -LiteralPath $addons -Filter 'ToonAge*.zip' -File -ErrorAction SilentlyContinue) {
                    if ($PSCmdlet.ShouldProcess($z.FullName, 'remove stale build zip')) {
                        Remove-Item -LiteralPath $z.FullName -Force
                        Write-Host "  removed $clientDir\$($z.Name)" -ForegroundColor Yellow
                    }
                }
            }
        }
    }
    Write-Host ""
}

$totalMissing    = 0
$failedInstalls  = @()

foreach ($name in $targets.Keys) {
    $toc     = $targets[$name]
    $tocPath = Join-Path $Root $toc

    if (-not (Test-Path -LiteralPath $tocPath)) {
        Write-Warning "$name : $toc not found in the trunk -- skipped."
        continue
    }

    $listed = Get-TocFiles -TocPath $tocPath
    $out    = Join-Path $Dest $name

    Write-Host ""
    Write-Host ("{0,-13} <- {1}  ({2} files)" -f $name, $toc, $listed.Count) -ForegroundColor Cyan

    if ($PSCmdlet.ShouldProcess($out, "rebuild from $toc")) {
        if (Test-Path -LiteralPath $out) {
            Remove-Item -LiteralPath $out -Recurse -Force
        }
        New-Item -ItemType Directory -Path $out -Force | Out-Null
    }

    $missing = 0
    foreach ($rel in ($listed + $Extras)) {
        $src = Join-Path $Root $rel
        if (-not (Test-Path -LiteralPath $src)) {
            # A TOC listing a file that does not exist is a broken build, so
            # say so loudly rather than shipping a folder that half-loads.
            if ($listed -contains $rel) {
                Write-Warning "  MISSING (listed in $toc): $rel"
                $missing++
            }
            continue
        }
        if ($PSCmdlet.ShouldProcess($rel, 'copy')) {
            $dst    = Join-Path $out $rel
            $dstDir = Split-Path -Parent $dst
            if ($dstDir -and -not (Test-Path -LiteralPath $dstDir)) {
                New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
            }
            Copy-Item -LiteralPath $src -Destination $dst -Force
        }
    }

    # The client picks a TOC by filename, so the build keeps its suffixed name.
    if ($PSCmdlet.ShouldProcess($toc, 'copy TOC')) {
        Copy-Item -LiteralPath $tocPath -Destination (Join-Path $out $toc) -Force
    }

    # ...and any alias the client needs to actually see this build. See
    # $AlsoEmitTocAs for why Forever needs one.
    if ($AlsoEmitTocAs.ContainsKey($name)) {
        foreach ($alias in $AlsoEmitTocAs[$name]) {
            if ($PSCmdlet.ShouldProcess($alias, 'copy TOC alias')) {
                Copy-Item -LiteralPath $tocPath -Destination (Join-Path $out $alias) -Force
                Write-Host "  also as $alias" -ForegroundColor DarkGray
            }
        }
    }

    if ($missing) {
        Write-Host ("  {0} listed file(s) missing" -f $missing) -ForegroundColor Red
        $totalMissing += $missing
        Write-Warning "  not installing $name -- the build is incomplete."
        continue
    }
    Write-Host "  built" -ForegroundColor Green

    if (-not $Install) { continue }

    # ── Install ──────────────────────────────────────────────────────────
    if (-not $InstallDirs.ContainsKey($name)) {
        Write-Host "  (no install folder for this build -- built only)" -ForegroundColor DarkGray
        continue
    }

    foreach ($clientDir in $InstallDirs[$name]) {
        $addons = Join-Path (Join-Path $WowPath $clientDir) 'Interface\AddOns'
        if (-not (Test-Path -LiteralPath $addons)) {
            Write-Warning "  $clientDir is not installed -- skipped."
            continue
        }

        $target = Join-Path $addons 'ToonAge'

        # Guard rail. This is the one path in the script that deletes something
        # inside the game folder, and the folder next to it holds every OTHER
        # addon the player has. Refuse anything that is not exactly our own.
        if ((Split-Path -Leaf $target) -ne 'ToonAge') {
            throw "Refusing to touch '$target' -- not a ToonAge folder."
        }

        if ($PSCmdlet.ShouldProcess($target, 'replace installed addon')) {
            # Catch EVERYTHING here, and never rethrow.
            #
            # One client being open must not stop the others. With
            # $ErrorActionPreference = 'Stop' a locked folder becomes a
            # terminating error, and the first time that happened it aborted
            # the whole run after the second build -- Remix, Mists,
            # Anniversary, Forever and Classic Era were all silently skipped
            # because a PTR client was running. Six installs lost to one open
            # game is not a trade worth making, so a failed target is reported
            # and the loop moves on.
            try {
                if (Test-Path -LiteralPath $target) {
                    Remove-Item -LiteralPath $target -Recurse -Force -ErrorAction Stop
                }
                Copy-Item -LiteralPath $out -Destination $target -Recurse -Force -ErrorAction Stop
                Write-Host "  installed -> $clientDir" -ForegroundColor Green
            } catch {
                $msg = $_.Exception.Message
                if ($msg -match 'being used by another process|denied.*because it is') {
                    # WoW holds its AddOns folder open while the client runs.
                    Write-Warning "  $clientDir is in use -- close that WoW client and re-run."
                } elseif ($_.Exception -is [System.UnauthorizedAccessException]) {
                    Write-Warning "  access denied writing $target"
                    Write-Warning "  run this in an elevated PowerShell, or copy the folder by hand."
                } else {
                    Write-Warning "  $clientDir failed: $msg"
                }
                $script:failedInstalls += $clientDir
            }
        }
    }
}

Write-Host ""
if ($Install) {
    Write-Host "SavedVariables were not touched -- WoW keeps them under WTF\Account\," -ForegroundColor DarkGray
    Write-Host "so settings, the error log and harvested data survive this." -ForegroundColor DarkGray
    Write-Host ""
}
if ($failedInstalls.Count) {
    Write-Host ("Not installed: {0}" -f ($failedInstalls -join ', ')) -ForegroundColor Red
    Write-Host "Everything else completed. Close those clients and re-run." -ForegroundColor Red
}
if ($totalMissing) {
    Write-Host "$totalMissing missing file(s) across all builds." -ForegroundColor Red
    exit 1
}
if ($failedInstalls.Count) { exit 1 }
Write-Host "All builds complete." -ForegroundColor Green

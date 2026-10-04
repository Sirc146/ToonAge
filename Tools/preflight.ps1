<#
.SYNOPSIS
    ToonAge pre-test preflight: back up SavedVariables, record harvest counts,
    and check installed builds against the trunk. Phase 1 of the launch test
    checklist, as one command.
.DESCRIPTION
    Run with WoW CLOSED (SavedVariables are only final after logout).

      1. Copies every client's SavedVariables folder to
         <BackupRoot>\<yyyy-MM-dd_HHmm>-<Label>\<client>\  (never overwrites).
      2. Counts the records in each ToonAge.lua it copied -- harvest items,
         spells, talents, chars, racials, plus characters and the reset
         tripwire's incidents -- and prints them next to the previous
         preflight's counts. A drop is shown in red: STOP and find out why
         before testing (2026-10-03: ToonAgeDB reset with no explanation).
      3. Runs build_flavors.ps1 -Check: installed == trunk, or it says what is
         behind (2026-10-03: a mixed build was measured).

    Read-only for the game: nothing under World of Warcraft is changed.
.PARAMETER Label
    Suffix for the backup folder: "pretest" (default) or "posttest".
.PARAMETER WowPath
    Where WoW is installed.
.PARAMETER BackupRoot
    Where dated backups go.
.EXAMPLE
    .\Tools\preflight.ps1
    .\Tools\preflight.ps1 -Label posttest
#>
[CmdletBinding()]
param(
    [string] $Label = 'pretest',
    [string] $WowPath = 'C:\Program Files (x86)\World of Warcraft',
    [string] $BackupRoot = 'E:\OneDrive\Desktop\ToonAge-WTF-backup'
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# Refuse to run with a client open: the files on disk would be last session's,
# and the copy could catch WoW mid-write.
$running = Get-Process -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessName -match '^(Wow|WowB|WowT|WowClassic|WowClassicB)$' }
if ($running) {
    Write-Warning "WoW is running ($($running.ProcessName -join ', ')). Close every client and re-run."
    exit 1
}

$stamp  = Get-Date -Format 'yyyy-MM-dd_HHmm'
$dest   = Join-Path $BackupRoot "$stamp-$Label"
$clients = @('_classic_beta_', '_retail_', '_anniversary_', '_classic_', '_classic_era_', '_ptr_', '_xptr_', '_beta_')

# Record counts with plain regexes over the saved file -- the same patterns the
# offline generator relies on. Approximate by design: the point is the trend.
function Get-ToonAgeCounts([string] $file) {
    $t = Get-Content -LiteralPath $file -Raw
    [ordered]@{
        Racials    = ([regex]::Matches($t, '\["[A-Za-z]+:(Alliance|Horde):\d+"\]')).Count
        Talents    = ([regex]::Matches($t, ':T:\d+:\d+"\]')).Count
        HarvChars  = ([regex]::Matches($t, '\["Player-\d+-[0-9A-F]+"\] = "')).Count
        Items      = ([regex]::Matches($t, '(?m)^\[\d+\] = "[^"]*\t')).Count
        # name <tab> level <tab> ... -- excludes talent conditions ("24<tab>false")
        Spells     = ([regex]::Matches($t, '\["[A-Z]+:\d+"\] = "[^"\t]+\t\d+\t')).Count
        Incidents  = ([regex]::Matches($t, '\["kind"\] = "(missing|emptied|shrank)"')).Count
        Bytes      = (Get-Item -LiteralPath $file).Length
    }
}

$summary = @()
foreach ($c in $clients) {
    $acctRoot = Join-Path $WowPath "$c\WTF\Account"
    if (-not (Test-Path -LiteralPath $acctRoot)) { continue }
    foreach ($acct in Get-ChildItem -LiteralPath $acctRoot -Directory) {
        $sv = Join-Path $acct.FullName 'SavedVariables'
        if (-not (Test-Path -LiteralPath $sv)) { continue }
        $to = Join-Path $dest "$c\$($acct.Name)"
        New-Item -ItemType Directory -Path $to -Force | Out-Null
        Copy-Item -Path (Join-Path $sv '*') -Destination $to -Recurse -Force
        $ta = Join-Path $sv 'ToonAge.lua'
        if (Test-Path -LiteralPath $ta) {
            $row = [ordered]@{ Client = $c; Account = $acct.Name }
            (Get-ToonAgeCounts $ta).GetEnumerator() | ForEach-Object { $row[$_.Key] = $_.Value }
            $summary += [pscustomobject]$row
        }
    }
}
Write-Host "Backed up SavedVariables to $dest" -ForegroundColor Green

# Compare with the previous preflight's counts, kept next to the backups.
$countsFile = Join-Path $BackupRoot 'preflight-counts.csv'
$previous = @{}
if (Test-Path -LiteralPath $countsFile) {
    Import-Csv -LiteralPath $countsFile | ForEach-Object { $previous["$($_.Client)|$($_.Account)"] = $_ }
}
$drop = $false
foreach ($r in $summary) {
    $p = $previous["$($r.Client)|$($r.Account)"]
    $line = "{0,-16} {1,-12} racials {2,4}  talents {3,4}  chars {4,3}  items {5,4}  spells {6,4}  incidents {7}  {8:N0} bytes" -f `
        $r.Client, $r.Account, $r.Racials, $r.Talents, $r.HarvChars, $r.Items, $r.Spells, $r.Incidents, $r.Bytes
    $color = 'Gray'
    if ($p) {
        foreach ($k in 'Racials', 'Talents', 'HarvChars', 'Items', 'Spells') {
            if ([int]$r.$k -lt [int]$p.$k) { $color = 'Red'; $drop = $true; $line += "  [$k $($p.$k) -> $($r.$k)]" }
        }
        if ([int]$r.Incidents -gt [int]$p.Incidents) { $color = 'Red'; $drop = $true; $line += '  [NEW reset incident]' }
    }
    Write-Host $line -ForegroundColor $color
}
$summary | Export-Csv -LiteralPath $countsFile -NoTypeInformation
if ($drop) {
    Write-Warning 'Counts DROPPED since the last preflight. Stop: find out why before testing. The backup above is your restore point.'
}

# Installed == trunk?
$build = Join-Path $PSScriptRoot 'build_flavors.ps1'
if (Test-Path -LiteralPath $build) {
    Write-Host ''
    Write-Host 'build_flavors.ps1 -Check:' -ForegroundColor Cyan
    & $build -Check
}

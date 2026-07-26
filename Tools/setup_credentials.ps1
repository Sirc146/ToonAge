<#
.SYNOPSIS
    ToonAge -- one-shot Blizzard API credential setup.

.DESCRIPTION
    Prompts for a Blizzard API Client ID and Secret, stores them as User-scope
    environment variables, and immediately verifies them with
    Tools/check_credentials.py.

    The secret is read with -AsSecureString so it never appears on screen, in
    the command line, or in PSReadLine history. It is converted to plain text
    only at the moment of the SetEnvironmentVariable call -- Windows has no
    encrypted store for environment variables, so plain text at rest is
    unavoidable; what this avoids is the secret leaking into scrollback, shell
    history, or a terminal transcript.

    Get the credentials from https://develop.battle.net/ -> API Access ->
    Create Client. The redirect URI can be https://localhost; the
    client-credentials flow this project uses never redirects.

.EXAMPLE
    .\Tools\setup_credentials.ps1

.EXAMPLE
    .\Tools\setup_credentials.ps1 -Scope Process
    Sets them for this shell only -- useful for testing a second client
    without disturbing the stored pair.
#>
[CmdletBinding()]
param(
    [ValidateSet('User', 'Process')]
    [string]$Scope = 'User',

    # Skip the verification step (no network call).
    [switch]$NoVerify
)

$ErrorActionPreference = 'Stop'

function Convert-SecureToPlain {
    param([System.Security.SecureString]$Secure)
    # PS 7 has -AsPlainText; PS 5.1 does not. Support both so this works
    # regardless of which shell the user happens to have open.
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        return ConvertFrom-SecureString -SecureString $Secure -AsPlainText
    }
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try   { return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

Write-Host ""
Write-Host "ToonAge -- Blizzard API credential setup" -ForegroundColor Cyan
Write-Host "Register a client at https://develop.battle.net/ -> API Access"
Write-Host "Scope: $Scope" -ForegroundColor DarkGray
Write-Host ""

$clientId = (Read-Host 'Client ID').Trim()
if ([string]::IsNullOrWhiteSpace($clientId)) {
    Write-Host "[ABORT] No Client ID entered. Nothing was changed." -ForegroundColor Red
    exit 1
}

$secureSecret = Read-Host 'Client Secret (input hidden)' -AsSecureString
$clientSecret = (Convert-SecureToPlain $secureSecret).Trim()
if ([string]::IsNullOrWhiteSpace($clientSecret)) {
    Write-Host "[ABORT] No Client Secret entered. Nothing was changed." -ForegroundColor Red
    exit 1
}

[Environment]::SetEnvironmentVariable('BLIZZARD_CLIENT_ID',     $clientId,     $Scope)
[Environment]::SetEnvironmentVariable('BLIZZARD_CLIENT_SECRET', $clientSecret, $Scope)

# Also set them in THIS process regardless of scope, so the verification below
# can run right now. A User-scope write is not visible to an already-running
# process -- including this one -- until it restarts.
$env:BLIZZARD_CLIENT_ID     = $clientId
$env:BLIZZARD_CLIENT_SECRET = $clientSecret

Remove-Variable clientSecret, secureSecret

$masked = if ($clientId.Length -gt 8) {
    $clientId.Substring(0,4) + ('*' * ($clientId.Length - 8)) + $clientId.Substring($clientId.Length - 4)
} else { '*' * $clientId.Length }

Write-Host ""
Write-Host "Stored at $Scope scope." -ForegroundColor Green
Write-Host "  BLIZZARD_CLIENT_ID     $masked"
Write-Host "  BLIZZARD_CLIENT_SECRET <set>"
if ($Scope -eq 'User') {
    Write-Host "  Other already-open shells will not see these until restarted." -ForegroundColor DarkGray
}
Write-Host ""

if ($NoVerify) {
    Write-Host "Skipping verification (-NoVerify)."
    exit 0
}

$python = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $python) {
    Write-Host "[WARN] python not on PATH -- cannot verify." -ForegroundColor Yellow
    Write-Host "       Run Tools/check_credentials.py yourself once python is available."
    exit 0
}

$checker = Join-Path $PSScriptRoot 'check_credentials.py'
if (-not (Test-Path $checker)) {
    Write-Host "[WARN] check_credentials.py not found next to this script." -ForegroundColor Yellow
    exit 0
}

Write-Host "Verifying ..." -ForegroundColor Cyan
Write-Host ""
& $python $checker
$code = $LASTEXITCODE

Write-Host ""
switch ($code) {
    0 { Write-Host "Done. Tools/fetch_wow_*.py will authenticate." -ForegroundColor Green }
    2 { Write-Host "Blizzard rejected these credentials. Re-run and re-enter them, or confirm the client still exists at develop.battle.net." -ForegroundColor Red }
    3 { Write-Host "Could not reach Blizzard. The values are stored; re-run Tools/check_credentials.py when the network is back." -ForegroundColor Yellow }
    default { Write-Host "Verification returned $code." -ForegroundColor Yellow }
}

exit $code

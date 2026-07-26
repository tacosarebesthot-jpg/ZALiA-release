<#
.SYNOPSIS
    Stream-safe wrapper around Invoke-ZaliaTest.ps1.

.DESCRIPTION
    Runs the normal harness but scrubs identifying strings out of everything printed
    to the console, so a test run can be shown on stream without leaking the operator's
    home directory, username, machine name, or user profile paths.

    Scrubbing is display-only: the on-disk logs under test\runs\ keep the real paths
    so they stay useful for debugging afterwards.

    NOTE: keep this file pure ASCII. Windows PowerShell 5.1 reads .ps1 files as ANSI
    unless they carry a BOM, so a UTF-8 em-dash decodes to a CP1252 smart quote and
    silently terminates a string literal mid-script.

.PARAMETER Scenario
    Passed straight through: 'sweep' | 'bugprobe' | 'both'.

.EXAMPLE
    powershell -File .\Invoke-ZaliaTest-Stream.ps1 -Scenario bugprobe
#>

[CmdletBinding()]
param(
    [ValidateSet('sweep', 'bugprobe', 'both')]
    [string]$Scenario = 'bugprobe',

    [int]$TimeoutSec = 0,

    [string]$SaveDir = ''
)

$ErrorActionPreference = 'Stop'

# Longest-first so that e.g. the full profile path is replaced before the bare username.
$redactions = [ordered]@{}
if ($env:USERPROFILE)  { $redactions[$env:USERPROFILE]  = '<HOME>' }
if ($env:LOCALAPPDATA) { $redactions[$env:LOCALAPPDATA] = '<LOCALAPPDATA>' }
if ($env:APPDATA)      { $redactions[$env:APPDATA]      = '<APPDATA>' }
if ($env:USERNAME)     { $redactions[$env:USERNAME]     = '<USER>' }
if ($env:COMPUTERNAME) { $redactions[$env:COMPUTERNAME] = '<HOST>' }

function Protect-Line {
    param([string]$Text)
    foreach ($key in ($redactions.Keys | Sort-Object -Property Length -Descending)) {
        $Text = $Text -replace [regex]::Escape($key), $redactions[$key]
    }
    # Belt-and-braces: anything that still looks like a Windows user path, plus
    # oauth tokens in case a Twitch config line ever gets echoed.
    $Text = $Text -replace '(?i)([A-Z]:\\Users\\)[^\\\r\n]+', '$1<USER>'
    $Text = $Text -replace '(?i)oauth:[A-Za-z0-9]+', 'oauth:<REDACTED>'
    return $Text
}

$inner = Join-Path $PSScriptRoot 'Invoke-ZaliaTest.ps1'
if (-not (Test-Path -LiteralPath $inner)) {
    throw "Cannot find Invoke-ZaliaTest.ps1 next to this script."
}

$passThru = @{ Scenario = $Scenario }
if ($TimeoutSec -gt 0) { $passThru['TimeoutSec'] = $TimeoutSec }
if ($SaveDir)          { $passThru['SaveDir']    = $SaveDir }

Write-Host "=== ZALiA test (stream-safe output) - scenario: $Scenario ===" -ForegroundColor Cyan

& $inner @passThru *>&1 | ForEach-Object { Protect-Line ($_ | Out-String).TrimEnd() }

Write-Host "=== done - full unredacted logs are in test\runs\ ===" -ForegroundColor Cyan

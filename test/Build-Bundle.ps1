<#
.SYNOPSIS
    Builds the PLAYABLE ship bundle of ZALiA (DEV false, no autopilot/self-terminate)
    and zips it to a portable folder the user can hand to a friend / play on a
    controller-capable host.

.DESCRIPTION
    Opposite-invariant guard vs. Invoke-ZaliaTest.ps1: that script REQUIRES DEV true
    and aborts otherwise. This script REQUIRES the ability to flip macros.gml to
    DEV false for the duration of the build, and GUARANTEES (try/finally) that it
    flips DEV back to true afterwards no matter how the build goes -- so the working
    tree is never left in a test-hostile state.

    Because DEV=false means the in-game harness has no autopilot and never calls
    game_end(), Igor's `Run` will sit at the title screen forever from the game's
    point of view. We do NOT wait for game_end(); instead we wait for Igor's stdout
    to print `Run_Start` (the .win is fully written and the game window is up by
    then), give it a short settle, then kill Runner.exe/Igor.exe ourselves.

.PARAMETER IgorPath
.PARAMETER ProjectPath
.PARAMETER RuntimePath
    Same ground-truth defaults as Invoke-ZaliaTest.ps1.

.PARAMETER SettleSec
    Extra seconds to wait after Run_Start is seen before killing the process, to be
    sure the .win + window are fully settled. Default 8.

.PARAMETER RunStartTimeoutSec
    Max seconds to wait for `Run_Start` to appear in Igor's stdout before giving up.
    Default 180.

.EXAMPLE
    pwsh -File .\Build-Bundle.ps1
#>

[CmdletBinding()]
param(
    [string]$IgorPath = 'C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23\bin\igor\windows\x64\Igor.exe',

    [string]$ProjectPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'ZALiA.yyp'),

    [string]$RuntimePath = 'C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23',

    [int]$SettleSec = 8,

    [int]$RunStartTimeoutSec = 180
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Constants / paths
# ---------------------------------------------------------------------------
# Derived from this script's own location (test\ lives inside the project root) so the
# harness follows the repo instead of a machine-specific checkout path.
$ProjectRoot  = Split-Path -Parent $PSScriptRoot
$MacrosPath   = Join-Path $ProjectRoot 'scripts\macros\macros.gml'
$TestRoot     = Join-Path $ProjectRoot 'test'
$RunsDir      = Join-Path $TestRoot 'runs'
$DistDir      = Join-Path $ProjectRoot 'dist'

# Build-number counter: read from .buildnum file, increment, format as 3 digits
$BuildNumFile = Join-Path $DistDir '.buildnum'
$BuildNumValue = 0
if (Test-Path -LiteralPath $BuildNumFile) {
    $BuildNumValue = [int](Get-Content -LiteralPath $BuildNumFile -Raw).Trim()
}
$BuildNumValue += 1
Set-Content -LiteralPath $BuildNumFile -Value $BuildNumValue -NoNewline -Encoding utf8
$BuildNum = '{0:D3}' -f $BuildNumValue
$BundleDir = Join-Path $DistDir "ZALiA_play_b$BuildNum"

# Documented per the contract: Igor's `Run` writes its output relative to the
# Igor/runtime CWD convention used on this box, observed at:
#   C:\zelda2_workspace\output\ZALiA\
# (NOT under the ZALiA project folder). This is the same output root
# Invoke-ZaliaTest.ps1's harness artifacts live downstream of, just the raw
# Run output -- confirm this path is still current before relying on it; if
# GameMaker/Igor version changes, this is the first thing to re-verify.
$RunOutputDir = 'C:\zelda2_workspace\output\ZALiA'

$RunnerSourceExe = Join-Path $RuntimePath 'windows\x64\Runner.exe'

if (-not (Test-Path -LiteralPath $RunsDir)) {
    New-Item -ItemType Directory -Path $RunsDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir -Force | Out-Null
}

function Write-Stage {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message"
}

function Stop-StrayProcesses {
    param([string]$Context = '')
    foreach ($name in 'Runner', 'Igor') {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            Write-Stage "Killing $name.exe (pid=$($p.Id)) $Context"
            try { Stop-Process -Id $p.Id -Force -ErrorAction Stop } catch {}
        }
    }
}

function Get-DevValue {
    param([string]$Path)
    $text = Get-Content -LiteralPath $Path -Raw
    if ($text -match '#macro\s+DEV\s+(true|false)') {
        return $Matches[1]
    }
    return $null
}

function Set-DevValue {
    param([string]$Path, [string]$Value)
    $text = Get-Content -LiteralPath $Path -Raw
    $newText = $text -replace '#macro\s+DEV\s+(true|false)', "#macro DEV $Value"
    Set-Content -LiteralPath $Path -Value $newText -NoNewline -Encoding utf8
}

# ---------------------------------------------------------------------------
# PREFLIGHT
# ---------------------------------------------------------------------------

Write-Stage 'PREFLIGHT: Build-Bundle (opposite-invariant guard: requires DEV false for the build)'

if (-not (Test-Path -LiteralPath $IgorPath)) {
    Write-Host "ABORT: Igor.exe not found at '$IgorPath'"
    exit 4
}
if (-not (Test-Path -LiteralPath $ProjectPath)) {
    Write-Host "ABORT: project .yyp not found at '$ProjectPath'"
    exit 4
}
if (-not (Test-Path -LiteralPath $MacrosPath)) {
    Write-Host "ABORT: macros.gml not found at '$MacrosPath'"
    exit 4
}
if (-not (Test-Path -LiteralPath $RunnerSourceExe)) {
    Write-Host "ABORT: runtime Runner.exe not found at '$RunnerSourceExe'"
    exit 4
}

$originalDev = Get-DevValue -Path $MacrosPath
if ($null -eq $originalDev) {
    Write-Host "ABORT: could not find '#macro DEV true|false' in '$MacrosPath'"
    exit 4
}

Write-Stage "Current DEV value in macros.gml: $originalDev"

$exitCode = 0
$bundlePath = $null

try {
    # -----------------------------------------------------------------
    # Flip DEV -> false for the ship build. Guaranteed revert in finally.
    # -----------------------------------------------------------------
    if ($originalDev -ne 'false') {
        Write-Stage "Setting DEV: $originalDev -> false (ship build)"
        Set-DevValue -Path $MacrosPath -Value 'false'
    }
    else {
        Write-Stage 'DEV already false -- no edit needed for the build step'
    }
    $confirmedDev = Get-DevValue -Path $MacrosPath
    Write-Stage "Confirmed macros.gml DEV=$confirmedDev for this build"

    if ($confirmedDev -ne 'false') {
        throw "Failed to set DEV false in '$MacrosPath' -- refusing to build a ship bundle with DEV=$confirmedDev"
    }

    Write-Stage 'Killing any pre-existing stray Runner.exe/Igor.exe before launch'
    Stop-StrayProcesses -Context '(pre-existing, preflight)'

    # -----------------------------------------------------------------
    # LAUNCH Igor Run
    # -----------------------------------------------------------------
    $runStart = Get-Date
    $logPrefix = "build_{0:yyyyMMdd_HHmmss}" -f $runStart
    $stdout = Join-Path $RunsDir "$logPrefix.stdout.log"
    $stderr = Join-Path $RunsDir "$logPrefix.stderr.log"

    $igorArgs = @(
        "/project=`"$ProjectPath`""
        "/rp=`"$RuntimePath`""
        '-v'
        '--'
        'Windows'
        'Run'
    )

    Write-Stage "Launching Igor: $IgorPath $($igorArgs -join ' ')"
    Write-Stage "  stdout -> $stdout"
    Write-Stage "  stderr -> $stderr"

    $proc = Start-Process -FilePath $IgorPath -ArgumentList $igorArgs `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr `
        -PassThru -NoNewWindow

    Write-Stage "Igor pid=$($proc.Id). DEV=false means no self-terminate; polling stdout for 'Run_Start'"

    # -----------------------------------------------------------------
    # WAIT for Run_Start to appear in stdout (means .win is fully written)
    # -----------------------------------------------------------------
    $sawRunStart = $false
    $deadline = (Get-Date).AddSeconds($RunStartTimeoutSec)

    while ((Get-Date) -lt $deadline) {
        if ($proc.HasExited) {
            Write-Stage "Igor process exited early (exit code=$($proc.ExitCode)) before Run_Start was observed"
            break
        }
        if (Test-Path -LiteralPath $stdout) {
            $content = Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue
            if ($content -and $content -match 'Run_Start') {
                $sawRunStart = $true
                break
            }
        }
        Start-Sleep -Milliseconds 500
    }

    if (-not $sawRunStart) {
        Write-Stage 'Run_Start was not observed within timeout -- killing process and aborting build'
        Stop-StrayProcesses -Context '(Run_Start timeout)'
        throw "Timed out waiting for 'Run_Start' in Igor stdout ($stdout) after ${RunStartTimeoutSec}s"
    }

    Write-Stage "Run_Start observed. Settling ${SettleSec}s before kill to let the .win finish flushing"
    Start-Sleep -Seconds $SettleSec

    Write-Stage 'Killing Runner.exe/Igor.exe (DEV=false build has no self-terminate)'
    Stop-StrayProcesses -Context '(post Run_Start, expected for ship build)'

    # -----------------------------------------------------------------
    # ASSEMBLE BUNDLE
    # -----------------------------------------------------------------
    if (-not (Test-Path -LiteralPath $RunOutputDir)) {
        throw "Expected Run output directory not found: '$RunOutputDir'. " +
              "Igor's Run output location may have changed -- re-verify and update `$RunOutputDir in this script."
    }

    $winFile = Join-Path $RunOutputDir 'ZALiA.win'
    if (-not (Test-Path -LiteralPath $winFile)) {
        throw "Expected '$winFile' not found after Run -- build may not have completed before kill. " +
              "Consider increasing -SettleSec or -RunStartTimeoutSec."
    }

    $stageDir = Join-Path $RunsDir "$logPrefix`_bundle_stage"
    if (Test-Path -LiteralPath $stageDir) {
        Get-ChildItem -LiteralPath $stageDir -Recurse -File | ForEach-Object {
            [System.IO.File]::Delete($_.FullName)
        }
        Remove-Item -LiteralPath $stageDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $stageDir -Force | Out-Null

    Write-Stage "Staging bundle contents from '$RunOutputDir' into '$stageDir'"

    # Copy children of $RunOutputDir (not the directory itself) into the fresh
    # $stageDir, recursively, preserving subfolders (other/, ow_tile_data/, etc).
    Get-ChildItem -LiteralPath $RunOutputDir -Force | ForEach-Object {
        $dest = Join-Path $stageDir $_.Name
        if ($_.PSIsContainer) {
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
        }
        else {
            Copy-Item -LiteralPath $_.FullName -Destination $dest -Force
        }
    }

    # Drop *.yydebug
    Get-ChildItem -LiteralPath $stageDir -Filter '*.yydebug' -Recurse -File | ForEach-Object {
        Write-Stage "Dropping debug artifact: $($_.Name)"
        [System.IO.File]::Delete($_.FullName)
    }

    # Rename ZALiA.win -> data.win
    $stagedWin = Join-Path $stageDir 'ZALiA.win'
    $dataWin = Join-Path $stageDir 'data.win'
    if (Test-Path -LiteralPath $stagedWin) {
        Move-Item -LiteralPath $stagedWin -Destination $dataWin -Force
        Write-Stage 'Renamed ZALiA.win -> data.win'
    }
    else {
        throw "Staged data file '$stagedWin' missing -- cannot complete bundle"
    }

    # Copy runtime Runner.exe AS ZALiA.exe
    $stagedExe = Join-Path $stageDir 'ZALiA.exe'
    Copy-Item -LiteralPath $RunnerSourceExe -Destination $stagedExe -Force
    Write-Stage "Copied runtime Runner.exe -> $stagedExe"

    # Write log-collector script into bundle
    Write-Stage "Writing EXPORT_LOGS.bat into bundle"
    $collectLogPath = Join-Path $stageDir 'EXPORT_LOGS.bat'
    $collectLogContent = @'
@echo off
setlocal
set DEST=%~dp0ZALiA_LOGS
echo Collecting ZALiA logs into "%DEST%" ...
robocopy "%LOCALAPPDATA%\ZALiA\playlog"      "%DEST%\playlog"      /E /NFL /NDL /NJH /NJS /NP >nul
robocopy "%LOCALAPPDATA%\ZALiA\problems"     "%DEST%\problems"     /E /NFL /NDL /NJH /NJS /NP >nul
robocopy "%LOCALAPPDATA%\ZALiA\bugprobe"     "%DEST%\bugprobe"     /E /NFL /NDL /NJH /NJS /NP >nul
robocopy "%LOCALAPPDATA%\ZALiA\screen_check" "%DEST%\screen_check" /E /NFL /NDL /NJH /NJS /NP >nul
if exist "%LOCALAPPDATA%\ZALiA\crash.txt" copy /Y "%LOCALAPPDATA%\ZALiA\crash.txt" "%DEST%\" >nul
echo Logs copied to "%DEST%".
if exist "C:\dev_stack\" (
  robocopy "%DEST%" "C:\dev_stack\ZALiA_LOGS" /E /NFL /NDL /NJH /NJS /NP >nul
  echo Also copied to C:\dev_stack\ZALiA_LOGS for the dev VM.
)
echo.
echo Done. Send the "ZALiA_LOGS" folder (or paste session.txt / crash.txt).
pause
'@
    Set-Content -LiteralPath $collectLogPath -Value $collectLogContent -Encoding ascii

    # Write PLAY.bat and CONTROLS.txt into bundle
    Write-Stage "Writing PLAY.bat + CONTROLS.txt into bundle"

    $playBatPath = Join-Path $stageDir 'PLAY.bat'
    $playBatContent = @'
@echo off
REM ===========================================================
REM  ZALiA - one-click play + auto-collect your marks/logs.
REM  Run THIS instead of ZALiA.exe. When you close the game,
REM  it automatically pulls your F6 marks + logs into ZALiA_LOGS.
REM ===========================================================
echo Launching ZALiA... (close the game window when you're done playing)
start /wait "" "%~dp0ZALiA.exe"
echo.
echo Game closed. Collecting your marks + logs...
call "%~dp0EXPORT_LOGS.bat"
'@
    Set-Content -LiteralPath $playBatPath -Value $playBatContent -Encoding ascii

    $controlsTxtPath = Join-Path $stageDir 'CONTROLS.txt'
    $controlsTxtContent = @'
==========================================================
  ZALiA  —  CONTROLS REFERENCE  (build b001)
==========================================================

GAMEPLAY  (defaults — all rebindable in Options > Controls)
----------------------------------------------------------
  Move .............. Arrow keys / W A S D     (D-pad / stick on pad)
  Jump  (NES A) ..... Space                    (A button on pad)
  Attack(NES B) ..... Left Ctrl                (X button on pad)
  Magic (Select) .... T                        (Select on pad)
  Pause (Start) ..... Enter                    (Start on pad)
  Next Spell ........ E                         (R1 on pad)
  Prev Spell ........ Q                         (L1 on pad)

PLAYTEST / DEV HOTKEYS  (work in this build, no rebind)
----------------------------------------------------------
  F6  ... MARK IT  — screenshot + logs the exact room + your
                     position. >>> USE THIS to flag anything broken <<<
  F3  ... Record session telemetry (REC) — full room-by-room
                     trace + catches any crash. Toggle on at the start
                     of your run if you want the whole session captured.
  F1  ... Tracker window on/off
  F4  ... Depth overlay on/off

MUSIC JUKEBOX
----------------------------------------------------------
  F8  ... Jukebox mode on/off
  ]   ... Next track          [   ... Previous track
          (R Trigger / L Trigger on pad)
  F12 ... Assign the current track to where you're standing
          (writes your pick to a file I read)

WALK TUNING  (optional — the walk is already fixed; only if you
              want to experiment)
----------------------------------------------------------
  F9  ... Open/close the slider panel (drag with the MOUSE)
  F11 ... Save your slider values

==========================================================
  WHEN YOU'RE DONE
----------------------------------------------------------
  Run  PLAY.bat  to play  ->  it auto-collects your marks on exit.
  (or run the game directly, then double-click EXPORT_LOGS.bat)
  Your marks/screenshots/logs end up in the  ZALiA_LOGS  folder
  (and C:\dev_stack\ZALiA_LOGS if this is the dev machine).
==========================================================
'@
    Set-Content -LiteralPath $controlsTxtPath -Value $controlsTxtContent -Encoding utf8

    # Move staged bundle to final output folder (versioned, no zipping)
    if (Test-Path -LiteralPath $BundleDir) {
        Write-Stage "Removing existing bundle folder: '$BundleDir'"
        Remove-Item -LiteralPath $BundleDir -Recurse -Force
    }

    Write-Stage "Moving bundle from '$stageDir' to '$BundleDir'"
    Move-Item -LiteralPath $stageDir -Destination $BundleDir

    $bundlePath = $BundleDir
    $exitCode = 0
}
catch {
    Write-Host "BUILD FAILED: $($_.Exception.Message)"
    $exitCode = 2
}
finally {
    # -----------------------------------------------------------------
    # CRITICAL: always revert DEV back to true, no matter what happened above.
    # -----------------------------------------------------------------
    $finalDevBefore = Get-DevValue -Path $MacrosPath
    Write-Stage "FINALLY: reverting DEV ($finalDevBefore -> true) in macros.gml"
    Set-DevValue -Path $MacrosPath -Value 'true'
    $finalDevAfter = Get-DevValue -Path $MacrosPath
    Write-Stage "FINALLY: confirmed macros.gml DEV=$finalDevAfter (working tree restored to test-compatible state)"

    if ($finalDevAfter -ne 'true') {
        Write-Host "WARNING: macros.gml DEV did not revert to true -- MANUAL FIX REQUIRED at '$MacrosPath'"
        if ($exitCode -eq 0) { $exitCode = 2 }
    }

    Stop-StrayProcesses -Context '(final cleanup)'
}

if ($exitCode -eq 0 -and $bundlePath) {
    $folderSize = (Get-ChildItem -LiteralPath $bundlePath -Recurse -File | Measure-Object -Property Length -Sum).Sum
    $folderSizeMb = [math]::Round($folderSize / 1MB, 1)
    Write-Host ''
    Write-Host "BUILD b$BuildNum OK: $bundlePath ($folderSizeMb MB)"
    Write-Host 'HOW TO RUN: open the folder and double-click ZALiA.exe (zip it yourself only if copying to another PC).'
    Write-Host ''
}

exit $exitCode

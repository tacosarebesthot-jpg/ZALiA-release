<#
.SYNOPSIS
    Headless GameMaker test harness driver for ZALiA. Runs Igor in `Run` mode against
    the DEV-instrumented build, waits for the in-game harness to self-terminate via
    game_end(), then harvests + parses the flag-file artifacts it wrote under
    %LOCALAPPDATA%\ZALiA\ to decide PASS/FAIL/TIMEOUT.

.DESCRIPTION
    Two lanes, selectable independently or together:
      sweep    -> Lane A crash-sweep (793/793 rooms + 112/112 OW pages, zero crashes)
      bugprobe -> Lane B/C scripted probes (must reach BUGPROBE_DONE, no fresh crash)
      both     -> sweep then bugprobe, sequentially, in one process-managed run each

    Source of truth for pass/fail is ALWAYS the on-disk artifacts (_DONE.txt,
    crashes.txt, bugprobe\report.txt) freshness-gated against $runStart, never the
    Igor exit code -- game_end() always returns 0 from Igor's point of view.

.PARAMETER Scenario
    'sweep' | 'bugprobe' | 'both'. Default 'both'.

.PARAMETER TimeoutSec
    Per-run wall-clock timeout. If not supplied, defaults to 2400s for sweep and
    420s for bugprobe (chosen per-scenario when running 'both').

.PARAMETER IgorPath
.PARAMETER ProjectPath
.PARAMETER RuntimePath
    Override the ground-truth defaults below if the install moves.

.EXAMPLE
    pwsh -File .\Invoke-ZaliaTest.ps1 -Scenario sweep
.EXAMPLE
    pwsh -File .\Invoke-ZaliaTest.ps1 -Scenario both -TimeoutSec 3000
#>

[CmdletBinding()]
param(
    [ValidateSet('sweep', 'bugprobe', 'both')]
    [string]$Scenario = 'both',

    [int]$TimeoutSec = 0,

    [string]$IgorPath = 'C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23\bin\igor\windows\x64\Igor.exe',

    [string]$ProjectPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'ZALiA.yyp'),

    [string]$RuntimePath = 'C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23',

    # Where the game writes its flag files / screen_check / bugprobe artifacts.
    # Leave empty to auto-detect (see Resolve-SaveDir below); set explicitly for a
    # portable build that saves next to the executable.
    [string]$SaveDir = ''
)

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Constants / paths
# ---------------------------------------------------------------------------
# Derived from this script's own location (test\ lives inside the project root) so the
# harness follows the repo instead of a machine-specific checkout path.
$ProjectRoot   = Split-Path -Parent $PSScriptRoot
$MacrosPath    = Join-Path $ProjectRoot 'scripts\macros\macros.gml'
# Save-dir resolution. GameMaker's Windows "save location" option decides whether the
# game writes under %LOCALAPPDATA% or next to the runner, so probe rather than assume:
# an explicit -SaveDir wins, then whichever candidate already exists, else the
# %LOCALAPPDATA% default (which the game will create on first run).
function Resolve-SaveDir {
    param([string]$Explicit)
    if ($Explicit) { return $Explicit }
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'ZALiA')
        (Join-Path $env:APPDATA      'ZALiA')
    )
    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) { return $c }
    }
    return $candidates[0]
}

$LocalAppData  = Resolve-SaveDir -Explicit $SaveDir
$ScreenCheck   = Join-Path $LocalAppData 'screen_check'
$BugprobeDir   = Join-Path $LocalAppData 'bugprobe'
$TestRoot      = Join-Path $ProjectRoot 'test'
$RunsDir       = Join-Path $TestRoot 'runs'

$AutosweepFlag = Join-Path $LocalAppData '_autosweep.flag'
$BugprobeFlag  = Join-Path $LocalAppData '_bugprobe.flag'

$DoneFile      = Join-Path $ScreenCheck '_DONE.txt'
$CrashesFile   = Join-Path $ScreenCheck 'crashes.txt'
$BugReportFile = Join-Path $BugprobeDir 'report.txt'

$DefaultTimeouts = @{
    sweep    = 2400
    bugprobe = 420
}

if (-not (Test-Path -LiteralPath $RunsDir)) {
    New-Item -ItemType Directory -Path $RunsDir -Force | Out-Null
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Stage {
    param([string]$Message)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message"
}

function Stop-StrayProcesses {
    param([string]$Context = '')
    foreach ($name in 'Runner', 'Igor') {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            Write-Stage "Killing stray $name.exe (pid=$($p.Id)) $Context"
            try { Stop-Process -Id $p.Id -Force -ErrorAction Stop } catch {}
        }
    }
}

function Remove-FlagFile {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        try {
            [System.IO.File]::Delete($Path)
        }
        catch {
            Write-Warning "Failed to delete flag file '$Path': $($_.Exception.Message)"
        }
    }
}

function Test-FreshFile {
    # A file counts as belonging to THIS run only if it exists and its
    # LastWriteTime is >= the run start timestamp (with a small clock-skew grace).
    param(
        [string]$Path,
        [datetime]$RunStart
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    $item = Get-Item -LiteralPath $Path
    return ($item.LastWriteTime -ge $RunStart.AddSeconds(-2))
}

function Invoke-IgorRun {
    param(
        [string]$LogPrefix,
        [int]$TimeoutSeconds
    )

    $stdout = Join-Path $RunsDir "$LogPrefix.stdout.log"
    $stderr = Join-Path $RunsDir "$LogPrefix.stderr.log"

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

    Write-Stage "Igor pid=$($proc.Id), waiting up to ${TimeoutSeconds}s"

    $exited = $proc.WaitForExit($TimeoutSeconds * 1000)

    $timedOut = -not $exited
    if ($timedOut) {
        Write-Stage "TIMEOUT after ${TimeoutSeconds}s -- killing pid=$($proc.Id) and sweeping strays"
        try { Stop-Process -Id $proc.Id -Force -ErrorAction Stop } catch {}
        Stop-StrayProcesses -Context '(post-timeout)'
    }
    else {
        Write-Stage "Igor exited on its own (exit code=$($proc.ExitCode))"
    }

    # Always reap leftovers regardless of how we got here.
    Stop-StrayProcesses -Context '(post-run reap)'

    return [pscustomobject]@{
        TimedOut   = $timedOut
        ExitCode   = if ($exited) { $proc.ExitCode } else { $null }
        StdoutLog  = $stdout
        StderrLog  = $stderr
    }
}

function Get-SweepResult {
    param([datetime]$RunStart)

    $result = [pscustomobject]@{
        DoneFresh   = $false
        RoomDone    = $null
        RoomTotal   = $null
        OwDone      = $null
        OwTotal     = $null
        CrashCount  = 0
        CrashFresh  = $false
    }

    if (Test-FreshFile -Path $DoneFile -RunStart $RunStart) {
        $result.DoneFresh = $true
        $lines = Get-Content -LiteralPath $DoneFile -ErrorAction SilentlyContinue
        foreach ($line in $lines) {
            # Expected shapes (per contract): "DONE OW 112/112" and a room-count line,
            # e.g. "DONE RM 793/793". Parse generically: TAG N/M
            if ($line -match '(?i)\bRM\s+(\d+)\s*/\s*(\d+)') {
                $result.RoomDone  = [int]$Matches[1]
                $result.RoomTotal = [int]$Matches[2]
            }
            if ($line -match '(?i)\bOW\s+(\d+)\s*/\s*(\d+)') {
                $result.OwDone  = [int]$Matches[1]
                $result.OwTotal = [int]$Matches[2]
            }
        }
    }

    # ABSENT crashes.txt means zero crashes (per contract). Only trust it if fresh;
    # a stale crashes.txt from a previous run must not poison this run's verdict.
    if (Test-Path -LiteralPath $CrashesFile) {
        if (Test-FreshFile -Path $CrashesFile -RunStart $RunStart) {
            $result.CrashFresh = $true
            $crashLines = Get-Content -LiteralPath $CrashesFile -ErrorAction SilentlyContinue
            $result.CrashCount = @($crashLines | Where-Object { $_.Trim() -ne '' }).Count
        }
        else {
            # Stale crash file from a prior run sitting next to a clean new run.
            # Treat as "no fresh crash evidence" -- not 0, not counted, flagged via CrashFresh=false.
            $result.CrashCount = 0
        }
    }

    return $result
}

function Get-BugprobeResult {
    param([datetime]$RunStart)

    $result = [pscustomobject]@{
        ReportFresh  = $false
        ReachedDone  = $false
    }

    if (Test-FreshFile -Path $BugReportFile -RunStart $RunStart) {
        $result.ReportFresh = $true
        $tail = Get-Content -LiteralPath $BugReportFile -ErrorAction SilentlyContinue | Select-Object -Last 10
        if ($tail -match 'BUGPROBE_DONE') {
            $result.ReachedDone = $true
        }
    }

    return $result
}

# ---------------------------------------------------------------------------
# Stage 1: PREFLIGHT
# ---------------------------------------------------------------------------

Write-Stage "PREFLIGHT: scenario=$Scenario"

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

$macrosText = Get-Content -LiteralPath $MacrosPath -Raw
if ($macrosText -notmatch '#macro\s+DEV\s+true') {
    Write-Host "ABORT: '$MacrosPath' does not have '#macro DEV true'."
    Write-Host "       The test harness requires DEV true (opposite-invariant guard)."
    Write-Host "       This looks like a ship build (DEV false) -- run Build-Bundle.ps1's"
    Write-Host "       counterpart workflow for shipping, not this script for testing."
    exit 4
}

Write-Stage "PREFLIGHT OK: Igor + .yyp exist, macros.gml has DEV true"

Write-Stage "Killing any pre-existing stray Runner.exe/Igor.exe before launch"
Stop-StrayProcesses -Context '(pre-existing, preflight)'

# ---------------------------------------------------------------------------
# Scenario plan
# ---------------------------------------------------------------------------

$lanes = switch ($Scenario) {
    'sweep'    { @('sweep') }
    'bugprobe' { @('bugprobe') }
    'both'     { @('sweep', 'bugprobe') }
}

$laneResults = @()
$overallExit = 0
$overallResult = 'PASS'

foreach ($lane in $lanes) {

    $effectiveTimeout = if ($TimeoutSec -gt 0) { $TimeoutSec } else { $DefaultTimeouts[$lane] }

    Write-Stage "=== Lane: $lane (timeout=${effectiveTimeout}s) ==="

    # -----------------------------------------------------------------
    # Stage 2: STATE / FLAG SETUP
    # -----------------------------------------------------------------
    Write-Stage "Setting flag files for lane '$lane'"
    if ($lane -eq 'sweep') {
        Remove-FlagFile -Path $BugprobeFlag
        if (-not (Test-Path -LiteralPath $LocalAppData)) {
            New-Item -ItemType Directory -Path $LocalAppData -Force | Out-Null
        }
        New-Item -ItemType File -Path $AutosweepFlag -Force | Out-Null
    }
    else {
        Remove-FlagFile -Path $AutosweepFlag
        if (-not (Test-Path -LiteralPath $LocalAppData)) {
            New-Item -ItemType Directory -Path $LocalAppData -Force | Out-Null
        }
        New-Item -ItemType File -Path $BugprobeFlag -Force | Out-Null
    }

    $runStart = Get-Date
    Write-Stage "runStart=$($runStart.ToString('o')) (artifacts older than this are stale)"

    # -----------------------------------------------------------------
    # Stage 3+4: LAUNCH + WAIT
    # -----------------------------------------------------------------
    $logPrefix = "{0}_{1:yyyyMMdd_HHmmss}" -f $lane, $runStart
    $runInfo = Invoke-IgorRun -LogPrefix $logPrefix -TimeoutSeconds $effectiveTimeout

    $duration = (Get-Date) - $runStart

    # -----------------------------------------------------------------
    # Stage 5: REAP (Invoke-IgorRun already reaps; this is belt-and-suspenders)
    # -----------------------------------------------------------------
    Stop-StrayProcesses -Context '(post-lane safety reap)'

    # -----------------------------------------------------------------
    # Stage 6: HARVEST + PARSE
    # -----------------------------------------------------------------
    $laneResult = 'PASS'
    $laneExit = 0

    if ($runInfo.TimedOut) {
        $laneResult = 'TIMEOUT'
        $laneExit = 3
    }

    $sweepInfo = $null
    $bugInfo = $null

    if ($lane -eq 'sweep') {
        $sweepInfo = Get-SweepResult -RunStart $runStart

        if ($laneResult -eq 'PASS') {
            $roomOk = ($sweepInfo.RoomDone -ne $null) -and ($sweepInfo.RoomTotal -ne $null) -and
                      ($sweepInfo.RoomDone -eq $sweepInfo.RoomTotal) -and ($sweepInfo.RoomDone -eq 793)
            $owOk   = ($sweepInfo.OwDone -ne $null) -and ($sweepInfo.OwTotal -ne $null) -and
                      ($sweepInfo.OwDone -eq $sweepInfo.OwTotal) -and ($sweepInfo.OwDone -eq 112)
            $crashOk = ($sweepInfo.CrashCount -eq 0)

            if (-not $sweepInfo.DoneFresh) {
                $laneResult = 'FAIL'
                $laneExit = 2
                Write-Stage "FAIL: no fresh _DONE.txt found at '$DoneFile'"
            }
            elseif (-not ($roomOk -and $owOk -and $crashOk)) {
                $laneResult = 'FAIL'
                $laneExit = 2
                Write-Stage "FAIL: room=$($sweepInfo.RoomDone)/$($sweepInfo.RoomTotal) ow=$($sweepInfo.OwDone)/$($sweepInfo.OwTotal) crashes=$($sweepInfo.CrashCount)"
            }
        }
    }
    else {
        $bugInfo = Get-BugprobeResult -RunStart $runStart
        # Bugprobe pass also requires no FRESH crash evidence from the sweep's crash
        # file convention, if the probe build shares the same crash log mechanism.
        $crashSideCheck = Get-SweepResult -RunStart $runStart

        if ($laneResult -eq 'PASS') {
            if (-not $bugInfo.ReportFresh -or -not $bugInfo.ReachedDone) {
                $laneResult = 'FAIL'
                $laneExit = 2
                Write-Stage "FAIL: bugprobe report fresh=$($bugInfo.ReportFresh) reached_done=$($bugInfo.ReachedDone)"
            }
            elseif ($crashSideCheck.CrashFresh -and $crashSideCheck.CrashCount -gt 0) {
                $laneResult = 'FAIL'
                $laneExit = 2
                Write-Stage "FAIL: fresh crashes.txt has $($crashSideCheck.CrashCount) row(s) during bugprobe lane"
            }
        }
    }

    $laneResults += [pscustomobject]@{
        Lane       = $lane
        Result     = $laneResult
        Exit       = $laneExit
        DurationSec = [int]$duration.TotalSeconds
        Sweep      = $sweepInfo
        Bugprobe   = $bugInfo
        Log        = $runInfo.StdoutLog
    }

    if ($laneExit -gt $overallExit) { $overallExit = $laneExit }
    if ($laneResult -ne 'PASS') { $overallResult = $laneResult }
}

# ---------------------------------------------------------------------------
# Stage 7: REPORT
# ---------------------------------------------------------------------------

$utcNow = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$totalDuration = ($laneResults | Measure-Object -Property DurationSec -Sum).Sum

$sweepLane    = $laneResults | Where-Object { $_.Lane -eq 'sweep' } | Select-Object -First 1
$bugprobeLane = $laneResults | Where-Object { $_.Lane -eq 'bugprobe' } | Select-Object -First 1

$sweepDoneFlag = if ($sweepLane -and $sweepLane.Sweep -and $sweepLane.Sweep.DoneFresh) { 1 } else { 0 }
$rmStr = if ($sweepLane -and $sweepLane.Sweep -and $sweepLane.Sweep.RoomTotal) {
    "$($sweepLane.Sweep.RoomDone)/$($sweepLane.Sweep.RoomTotal)"
} else { 'n/a' }
$owStr = if ($sweepLane -and $sweepLane.Sweep -and $sweepLane.Sweep.OwTotal) {
    "$($sweepLane.Sweep.OwDone)/$($sweepLane.Sweep.OwTotal)"
} else { 'n/a' }
$crashCountStr = if ($sweepLane -and $sweepLane.Sweep) { $sweepLane.Sweep.CrashCount } else { 0 }

$bugReachedStr = if ($bugprobeLane -and $bugprobeLane.Bugprobe -and $bugprobeLane.Bugprobe.ReachedDone) { 'yes' } else { 'no' }

$logPaths = ($laneResults | ForEach-Object { $_.Log }) -join ';'

$reportLines = @(
    "ZALIA_RUN  scenario=$Scenario  utc=$utcNow  result=$overallResult  exit=$overallExit"
    "SWEEP      done=$sweepDoneFlag  rm=$rmStr  ow=$owStr"
    "CRASHES    count=$crashCountStr"
    "BUGPROBE   reached_done=$bugReachedStr"
    "DURATION   run=${totalDuration}s"
    "ARTIFACTS  screen_check=$ScreenCheck  bugprobe=$BugprobeDir  log=$logPaths"
)

$reportText = $reportLines -join "`r`n"

Write-Host ''
Write-Host $reportText
Write-Host ''

$latestPath = Join-Path $RunsDir 'latest.txt'
$timestampedPath = Join-Path $RunsDir ("run_{0:yyyyMMdd_HHmmss}.txt" -f (Get-Date))

Set-Content -LiteralPath $latestPath -Value $reportText -Encoding utf8
Set-Content -LiteralPath $timestampedPath -Value $reportText -Encoding utf8

exit $overallExit

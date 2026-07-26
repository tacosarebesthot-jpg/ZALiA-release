@echo off
setlocal
title ZALiA - Twitch command test

rem ============================================================================
rem  Simulate a Twitch command WITHOUT live chat by dropping a command file into
rem  the game's drop folder. Proves the effect/verb side works even if IRC isn't
rem  connected. TWITCH (or TWITCH IRC) must be ON in-game.
rem
rem  Usage:   twitch_test.bat <verb> <arg>
rem  Examples:
rem     twitch_test.bat heal 4
rem     twitch_test.bat spawn daira
rem     twitch_test.bat dark
rem ============================================================================

set "DROP=%LOCALAPPDATA%\ZALiA\twitch_drop"
if not exist "%DROP%" mkdir "%DROP%"

set "VERB=%~1"
if "%VERB%"=="" set "VERB=heal"
set "ARG=%~2"
if "%ARG%"=="" set "ARG=4"

> "%DROP%\test_%RANDOM%%RANDOM%.txt" echo %VERB%^|%ARG%^|tester^|300

echo Simulated trigger dropped:  %VERB%^|%ARG%^|tester^|300
echo into:  %DROP%
echo(
echo (Twitch must be ON in-game: DEV TOOLS - TEST/CAPTURE - TWITCH [IRC])
echo Usage:  twitch_test.bat ^<verb^> ^<arg^>    e.g.  twitch_test.bat spawn daira
echo(
pause
endlocal

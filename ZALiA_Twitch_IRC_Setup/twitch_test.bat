@echo off
setlocal
title ZALiA - Twitch command test

rem ============================================================================
rem  Simulate a Twitch command WITHOUT live chat by dropping a command file into
rem  the game's drop folder. Proves the effect/verb side works even if IRC isn't
rem  connected. TWITCH REWARDS (or TWITCH IRC) must be ON in-game.
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

rem  Duration is left EMPTY so the game applies its own EFFECT LENGTH setting,
rem  exactly like a live chat command (a hardcoded 300 pinned tests at 5 s).
> "%DROP%\test_%RANDOM%%RANDOM%.txt" echo %VERB%^|%ARG%^|tester^|

echo Simulated trigger dropped:  %VERB%^|%ARG%^|tester^|
echo into:  %DROP%
echo(
echo (Twitch must be ON in-game: Options - TWITCH OPTIONS - TWITCH REWARDS or TWITCH IRC)
echo (Note: drop files skip the chat cooldown and the points economy.)
echo Usage:  twitch_test.bat ^<verb^> ^<arg^>    e.g.  twitch_test.bat spawn daira
echo(
pause
endlocal

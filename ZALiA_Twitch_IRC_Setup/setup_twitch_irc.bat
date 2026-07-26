@echo off
setlocal enabledelayedexpansion
title ZALiA - Twitch IRC setup

rem ============================================================================
rem  ZALiA - Twitch IRC (no-bot mode) config setup.
rem  Writes  %LOCALAPPDATA%\ZALiA\twitch_config.txt  which the game reads to
rem  connect to your Twitch chat. Self-contained: prompts for YOUR details, so
rem  nobody ships a real token. Safe to re-run any time to change settings.
rem ============================================================================

echo(
echo   ============================================
echo    ZALiA  -  Twitch IRC chat setup
echo   ============================================
echo(
echo   You need a Twitch CHAT OAuth token. Get one at:
echo       https://twitchtokengenerator.com/
echo   (pick the "chat:read" scope, authorise, copy the Access Token)
echo   NOTE: the old twitchapps.com/tmi generator is discontinued.
echo   It looks like:  oauth:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo   (the "oauth:" prefix is optional - either form works)
echo(

set "DST=%LOCALAPPDATA%\ZALiA"
set "CFG=%DST%\twitch_config.txt"

rem --- offer to open the token generator in the default browser ---
set "OPENIT="
set /p "OPENIT=Open the token page in your browser now? [Y/n]: "
if /i not "!OPENIT!"=="n" (
    start "" "https://twitchtokengenerator.com/"
    echo   ^> Opened https://twitchtokengenerator.com/  - pick "chat:read", authorise,
    echo     then copy the Access Token and paste it below.
    echo(
)

rem --- token (required) ---
:ASK_TOKEN
set "TOKEN="
set /p "TOKEN=Paste your OAuth token: "
if "!TOKEN!"=="" (
    echo   ^> Token can't be empty. Try again.
    goto ASK_TOKEN
)

rem --- user / nick (required) ---
:ASK_USER
set "USER="
set /p "USER=Your Twitch login name (lowercase): "
if "!USER!"=="" (
    echo   ^> Login name can't be empty. Try again.
    goto ASK_USER
)

rem --- channel (defaults to user) ---
set "CHANNEL="
set /p "CHANNEL=Channel to join [default: !USER!]: "
if "!CHANNEL!"=="" set "CHANNEL=!USER!"

rem --- cooldown in FRAMES (60 = 1 second), default 600 = 10s ---
set "COOLDOWN="
set /p "COOLDOWN=Command cooldown in frames, 60=1s [default: 600]: "
if "!COOLDOWN!"=="" set "COOLDOWN=600"

rem --- write it ---
if not exist "%DST%" mkdir "%DST%"
(
    echo token=!TOKEN!
    echo user=!USER!
    echo channel=!CHANNEL!
    echo cooldown=!COOLDOWN!
)> "%CFG%"

echo(
if exist "%CFG%" (
    echo   CONFIG WRITTEN:
    echo       %CFG%
    echo(
    echo       user=!USER!   channel=!CHANNEL!   cooldown=!COOLDOWN! frames
) else (
    echo   FAILED to write config to:
    echo       %CFG%
    echo   ^(check permissions / that %%LOCALAPPDATA%% is set^)
)

echo(
echo   Next, in-game:
echo     Options - DEV TOOLS - TEST/CAPTURE - TWITCH IRC   (turn ON)
echo   Watch the top-left status line:  TWITCH: connecting -^> connected
echo   Then type  !heal 4  in your Twitch chat to test.
echo(
echo   ^(Changed something? Re-run this, then toggle TWITCH IRC OFF then ON.^)
echo(
pause
endlocal

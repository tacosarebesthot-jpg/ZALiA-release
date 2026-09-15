# ZALiA 2.0 changelog

Version shows bottom-right of the title screen and answers `!version` in chat. Playtest zips are named after it. Dates are the day the build went out.

## 2.1.4 — 2026-09-14 (hotfix)

- **TWITCH page is back in the options menu.** Since 2.1.0 the in-game TWITCH page (CHAT JOKES, CHECKPOINTS, POINTS ECONOMY, ROCKET LEAGUE, cooldown, effect length) had no way in. Press O, pick **TWITCH OPTIONS**. The browser hub (jukebox, tracker, Twitch setup) is the COMPANION PAGES row on that page.
- **Downloads for 2.1.1, 2.1.2 and 2.1.3 ran old game code.** A packaging mistake shipped the 2026-09-10 game data next to the new music, so chat jokes, Rocket League quick-chat, the points economy, checkpoints and the reshuffler were missing from those zips. 2.1.4 ships the real build; the packager now refuses to zip a build that does not carry its own version number.
- **Version number** shows bottom-right of the title screen again.
- **Run timer** (top left) sits in the black HUD bar instead of hanging over gameplay.
- **LEVEL UP!** toast only pops on an actual level up, not every time the game starts.
- **Player options** on the TWITCH OPTIONS page, all saved: MUSIC TOASTS, CHAT TOASTS and GAME TOASTS (each OFF or 1 to 30 seconds on screen, your pick), MK2 SPLASH, ZELDA 1 JINGLE and BIG TIMER on/off. The Twitch status dot only shows while Twitch is on, and the timer is a bit smaller.

## 2.1.3 — 2026-09-12

- **Rocket League quick-chat.** ROCKET LEAGUE toggle on the TWITCH page (on by default). The game throws quick-chat plates on its own: WHAT A SAVE! when you survive at one heart, WHOOPS / SORRY / NOOOO on a death and GG or EZ on the game over screen when chat did it, CALCULATED. on a boss kill that cost you health, WHIFF after five swings that hit nothing, NICE BLOCK! on a shield deflect, BUMPING! on knockback, NICE DEMO! on a crush, NEED BOOST! at empty magic, ALL YOURS. on the fairy spell, ROTATE! when you walk straight back into the room you just left. Chat gets `!niceshot` `!whatasave` `!calculated` `!savage` `!closeone` `!okay` `!faking` `!gg` `!ez` `!wow` `!noproblem` `!thanks`, free, and three of the same one inside six seconds earns CHAT DISABLED FOR 4 SECONDS.
- **More town lines.** EverQuest, Ultima Online and 80s to 2000s pop culture jokes for the villagers (76 new lines, same rules: never a hint).

## 2.1.2 — 2026-09-12

- **Enemy reshuffler** (Lane's ask): `!reshuffle` in chat, or RESHUFFLE ENEMIES on the randomizer page, re-rolls the seed's enemy randomizer mid-run. Items, spells, palaces and towns stay where the seed put them; ground, flying and spawner slots keep their kind; the next screen uses the new roll and it survives a restart. Refuses with a reason on a seed without enemy randomization.

## 2.1.1 — 2026-09-12 (hotfix)

Ten fixes from a code review of the 2.1.0 rounds:

- `!stasis` ends on death or a room change; it used to teleport the respawned Link to the old spot every frame.
- Points are only charged when a command actually fires (not when it is refused for VS mode, challenge, no battle screen, no palace, unknown enemy), and a broke viewer's refused command no longer arms the cooldown for everyone.
- Checkpoints write their own file; the real save slot and the randomizer data/spoiler files are never touched.
- `!crush` is palaces only (a landed block writes palace tiles) and never kills hunt objects or a boss head.
- `!ghost` fades every enemy type, not just the few drawn through the generic path.
- `!shrink` / `!grow` hit boxes match for fire ropes and challenge triggers too.
- The Zelda 1 item jingle replaces the pickup fanfare instead of playing over the music; `loz_jingle=0` in `twitch_config.txt` restores the theme's own.
- Long toast titles wrap onto a second line instead of being cut.
- No blank "KILLED BY" plate in the first 90 seconds after launch.
- Version tag on the title screen, `!version` in chat, versioned zip names.

## 2.1.0 — 2026-09-12

The big one. Everything below is on top of 2.0.x.

**Chat jokes.** Every idle villager, sign, healer and story-recorder has alternate lines picked at random, with chatter names and the current boss dropped in. OPTIONS → TWITCH → CHAT JOKES: CLEAN (default), DIRTY, NORMAL. Hints and quest lines never change. Lines live in `dialogue_jokes.txt`; a copy in `%LOCALAPPDATA%\ZALiA\` overrides it.

**Toasts.** Console-style plates bottom-left replace the green text: chat verbs, NOW PLAYING, kills, link status. A command on cooldown answers with how long to wait. `!freeze` says how many it froze; the death plate says who killed you and who was healing you.

**Flawless boss kill.** The real Mortal Kombat II FLAWLESS VICTORY, then FATALITY or FRIENDSHIP, with the arcade announcer. `!finisher` tests it.

**New chat commands.** `!stasis` (Link frozen in place, mid-air included), `!challenge` (palace only: flipped until you leave, four hearts max, no helpful commands), `!disorient` (confuse plus up/down), `!tax` (a cut of your XP), `!dmgup`, `!attrition`, `!ghost`, `!crush` (drops a palace block; falling blocks now kill what is under them), `!meth` (moon + jump + speed), `!quantumentangle`, `!help` (the command card on screen), `!song`, `!link`. `!swarm` off a battle screen waits for the next one. `!dark` says when a room has no dark version. Aliases for every typo Lane's chat has actually typed.

**Checkpoints.** A copy of the live save every 60 seconds, every item and every level-up into `checkpoints\` next to the saves, newest 30 kept. CHECKPOINTS row on the TWITCH page.

**Points economy.** Off by default. Viewers earn 1 point per message (6 a minute max) and 5 every 5 minutes while chatting; every command has a price. `!points` shows a balance. POINTS ECONOMY row on the TWITCH page.

**Music.** 116 new tracks in the NES MIX pools: 84 NES and SNES (Ninja Gaiden II, Faxanadu, Crystalis, Shatterhand, Journey to Silius, Gimmick!, Batman, Little Samson, StarTropics, Guardian Legend, Castlevania III, Bucky O'Hare, Metal Storm, Super C, Kid Icarus, Chrono Trigger, Super Metroid, FF6, ActRaiser, Super Castlevania IV, Mega Man X, Demon's Crest) and 32 Mega Man (1 through 6). Kick Master's track with game sounds baked in is gone. Main items play the Zelda 1 treasure fanfare.

**Fixes from the 09-11 stream.** `!tiny` `!huge` `!filp` `!span` `!restore` `!gorilla` `!steal` work over chat; `!deny downstab` / `crouchstab` / `upstab` mean what they say; `!root` is 7 to 12 s; chat auto-connects on boot and reconnects on its own; `!arise` toggles, `!link` forces Link; typing into the key-4 note box no longer triggers dev hotkeys; bigger run timer; a warning before walking into the Maze Island palace without REFLECT.

**Credits.** HoverBat's patrons and thanks kept as his; the port's own supporters (LANEAGE, DOW_PY72O, MrB) as their own section, with the Patreon address.

**Tools.** `GRAB_LOGS.bat` in the game folder zips logs, saves and marked spots to the desktop for bug reports.

## 2.0.x — 2026-06 to 2026-09-11

The GameMaker 2026 port itself, plus (in order): 2-player co-op fairy, display modes and the CRT shader, the NES jukebox, gamepad calibration and rebinding, the stream tracker page, the in-game Twitch IRC client and the first ~50 chat verbs, channel-point redeems, the QOL and HUD additions, the room and overworld sweep harness, and the mark-and-replay bug capture keys. Full detail is in the commit history on the `source` branch.

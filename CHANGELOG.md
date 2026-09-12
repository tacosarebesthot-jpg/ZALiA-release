# ZALiA 2.0 changelog

Version shows bottom-right of the title screen and answers `!version` in chat. Playtest zips are named after it. Dates are the day the build went out.

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

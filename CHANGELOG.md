# ZALiA 2.0 changelog

Version shows bottom-right of the title screen and answers `!version` in chat. Playtest zips are named after it. Dates are the day the build went out.

## 2.1.9 — not shipped yet

Everything Lane asked for on air in the 2026-10-09 stream, plus one cap. Source only until the next build goes out.

- **COMMAND SOUND**: a short blip each time a chat command lands, at most one every two seconds. **If a busy chat makes it annoying, turn it OFF: OPTIONS → TWITCH OPTIONS → COMMAND SOUND**, or `cmd_sound=0` in `twitch_config.txt`. `cmd_sound_name=` picks a different sound.
- **First-use hint**: the first time each verb lands in a session, its `!help` line is toasted, so "I don't know what Cat Slap does" answers itself. `first_use_hint=0` turns it off.
- **`!1up` reminder**: after five minutes on your last life a toast reminds chat that `!1up` exists. `oneup_nudge=` sets the minutes, 0 turns it off. Silent in VS CHAT and `!challenge`, where 1up is refused anyway.
- **Swarm cap**: with mods skipping cooldowns, five `!swarm`s landed inside a minute. `!swarm` is now refused (no charge) once 14 enemies are on screen, and trimmed to fit below that. `swarm_cap=` changes the number.
- **Toasty**: after a flawless finisher, Dan Forden's head slides in bottom-right with the yell, timed like the MK2 cabinet. `toasty=` is the percent chance (100). Off with the rest of the MK2 splash (MK2 SPLASH row).
- **MK2 announcer pack**: FIGHT! when a boss has been up for a second, FINISH HIM when its bar hits a quarter, EXCELLENT when a chat `!swarm` is wiped out in one room without Link taking a hit. `announcer=0` turns the voice off; the MK2 SPLASH row off silences it too.
- **Babality**: a flawless boss kill while Link is `!shrink`-ed (or 15% of the time otherwise, `babality=`) ends with the Babality jingle and a baby-sized Link for three seconds instead of a fatality.
- **`!bet win 20`**: while a boss is on screen, stake points on `win` (2x), `flawless` (5x, also pays the win bettors) or `death` (3x). One bet per chatter per boss, 5 to 200 points, paid when the fight ends; a boss Link walks away from refunds everyone. Needs the points economy on. `bets=0` turns it off.
- **`!bounty moblin 30`**: points on the next Link kill of an enemy type (the `!spawn` names), pays 2x to whoever posted it. **Off by default**: `bounty=1` in `twitch_config.txt`.

## 2.1.8 — 2026-10-05

Rolls up 2.1.6 and 2.1.7, which only ever went out as source. The biggest round since 2.1.0: the Twitch side got a code review and a test harness that drives every chat verb through the real chat entry and grades the result, and everything the review turned up is fixed.

**New for chat**

- `!help <page>`: `!help hurt`, `chaos`, `mobs`, `fun`, `rl` or `mods` shows one page with what every verb on it does. Bare `!help` still shows the whole card and now ends with the page list.
- `!vote <x> <y> [secs]`: chat picks between two effects. Type `x` or `y` (or `1` / `2`) to vote; one ballot per chatter, last one counts; the winner fires when the clock runs out, a tie fires both. Starting a vote, voting and the winner are all free.
- `!catslap [n]`: three slaps from alternating sides, no damage. `!flashbang`: one white flash plus the smite hit on every non-boss enemy on screen. Both also run from the drop-file route, so a Tangia channel-point redeem can drive them through Streamer.bot.
- Death blame: the death plate names the verb and the chatter (KILLED BY name / !SWARM, KILLS: 3) and `!kills` shows the top three. `!top` shows the richest chatters when the points economy is on.
- `!undeny [what]` (or `!deny <what> off`) lifts a lock early. No FLAWLESS splash on a boss that killed you.
- `!ignore <name>` / `!unignore <name>`, mods and the broadcaster only: a muted chatter is dropped before commands, votes, points or joke pools see them. Survives a restart.
- `!kill` is gone (too strong, never used live). `!poison` stays.

**Cooldowns, mods, points**

- A per-chatter cooldown (30 seconds by default, CHATTER COOLDOWN row, `user_cooldown=`) on top of the shared one, with its own WAIT toast.
- Mods and the broadcaster skip both cooldowns (MODS SKIP COOLDOWN row, `mod_bypass=`), and a bypassed command does not arm the shared timer for everyone else.
- The points economy is **on by default** now; chat kept asking whether it was. An existing `points=0` in `twitch_config.txt` is still honoured.
- A refused command costs nothing and earns no kill credit. A `!swarm` queued off a battle screen is charged when queued and refunded if a death empties the queue. The game-over GG / EZ callout gets its credit back.

**On screen**

- EFFECT TIMERS: a top-right strip of the running effects with seconds left, plus the live vote tally. Row on the TWITCH OPTIONS page, `effects_hud=`.
- The MK2 FLAWLESS / FATALITY / FRIENDSHIP splash is arcade-sized and draws over the toasts and the help card; FRIENDSHIP's letters are no longer chopped at the bottom.
- `!heckler` / `!flame` show the chatter's name over the flame.
- A gamepad unplugged mid-run shows CONTROLLER LOST. An unreadable save slot says SAVE N UNREADABLE and points at the checkpoints folder. These system notices always show, whatever the toast settings.
- Death plate: KILL #1 lost its # (not in the font); it reads KILLS: 1 now. Four notice lines longer than the plate were being cut off.

**Options**

- OTHER → DEATH COUNTER is a saved player toggle (it was dev-only and never saved).
- OTHER → RESET ALL SETTINGS (press twice): audio, HUD, the OTHER page and the TWITCH OPTIONS page go back to defaults. Controls, the DISPLAY page, the audio set, randomizer options and the Twitch login are kept.
- The OTHER page scrolls; BACK no longer prints over the description text.
- Escape opens the quit menu in fullscreen too (it used to leave fullscreen first). Alt+Enter only toggles fullscreen.
- TWITCH OPTIONS: CHATTER COOLDOWN, MODS SKIP COOLDOWN and EFFECT TIMERS rows.
- ELIMINATION MODE on the file select wants START twice on a slot that holds a save; the armed slot flashes ERASE? START, and moving the cursor disarms.

**Fixed**

- Timed chat effects used to survive a death or a file load (the ice floor, the chicken). They end now. `!challenge` is the one that rides through a death; it ends on a game over or when you leave the palace.
- `!arise` gave a tier-2 player the tier-1 chicken.
- `!grow` / `!shrink` keep Link's feet on the floor. `!flip` / `!party` no longer crop the view in scrolled rooms.
- A chat chicken that wore off left Link 8 px inside the floor.
- `!invuln` lasted 105 seconds. `!deny jump 10` ignored the 10.
- Cucco form obeys `!speed` / `!slow` (2.1.6). `!steal` only takes items that are live-gated, so a steal is never invisible (2.1.6).
- A near-miss typo (`!stasus`, `!refil`) gets a did-you-mean toast; `!music` with no match and `!spell` with an unknown name say why (2.1.7).
- `!hurt` is capped at 1 to 8 quarter boxes and stops at 1 HP (it was lethal via `!hurt 999`). `!drain` is capped at four bars.
- Chat link: a dead connection is noticed and reconnected (this runtime never reports the far end closing); a bad token stops the reconnect loop instead of retrying forever; chat lines split across packets are reassembled (a split `!spawn moblin 6` used to run as `!spawn mob`); connecting no longer stalls a frame on a dead route; the game's own web server no longer answers the Twitch socket.
- Saves: every good save decoded to an empty map on this runtime; save slots, checkpoints, prefs and `twitch_config.txt` are written to a `.tmp` and swapped in, and a leftover `.tmp` is recovered; a save that could not be written (another program holding the file) says SAVE N NOT WRITTEN instead of claiming success; a corrupt prefs file no longer crashes every boot.
- `!steal` never bakes into a save or a checkpoint.
- Playtest builds no longer fire the bare debug hotkeys (a stray L, 2 or X).
- The tracker file is written at most twice a second during play (was 15 times).
- `tls=1` in `twitch_config.txt` connects over wss on port 443 so the token never crosses the wire in the clear. Opt-in.

## 2.1.5 — 2026-09-16

From the owner's own playtest stream:

- Toasts moved to the top-left, out of the way of the run timer and gameplay.
- Toasts no longer announce sound-effect and jingle names, only the music track playing.
- Removed the always-green pixel bottom-left (the old Twitch live dot).
- `!party` / `!flip` no longer break the viewport in wide rooms.
- Dropped a 2.5-second Wily boss loop from the random boss pool.
- ZELDA 1 JINGLE plays the real Zelda 1 item fanfare.

## 2.1.4 — 2026-09-15 (hotfix)

- **TWITCH page is back in the options menu.** Since 2.1.0 the in-game TWITCH page (CHAT JOKES, CHECKPOINTS, POINTS ECONOMY, ROCKET LEAGUE, cooldown, effect length) had no way in. Press O, pick **TWITCH OPTIONS**. The browser hub (jukebox, tracker, Twitch setup) is the COMPANION PAGES row on that page.
- **Downloads for 2.1.1, 2.1.2 and 2.1.3 ran old game code.** A packaging mistake shipped the 2026-09-10 game data next to the new music, so chat jokes, Rocket League quick-chat, the points economy, checkpoints and the reshuffler were missing from those zips. 2.1.4 ships the real build; the packager now refuses to zip a build that does not carry its own version number.
- **Version number** shows bottom-right of the title screen again.
- **Run timer** (top left) sits in the black HUD bar instead of hanging over gameplay.
- **LEVEL UP!** toast only pops on an actual level up, not every time the game starts.
- **Player options** on the TWITCH OPTIONS page, all saved: MUSIC TOASTS, CHAT TOASTS and GAME TOASTS (each OFF or 1 to 30 seconds on screen, your pick), MK2 SPLASH, ZELDA 1 JINGLE and BIG TIMER on/off. Music and game toasts are **off by default** (chat toasts stay on, 4 seconds); the MK2 lines and the easter eggs always show. The Twitch status dot only shows while Twitch is on, and the timer is a bit smaller.

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

# ZALiA chat commands

<!-- VERSION: 2.1.11 -->
**Current for ZALiA 2.1.11.** This page is checked against the game code before every
release (`_scripts/check_commands_doc.py`), so if the game has a command, it is on this page.
`!version` in chat tells you which build the streamer is running.

Type `!verb [arg]` in the streamer's Twitch chat. Aliases are in (brackets). A typo gets a
"did you mean" hint. Timed effects last the streamer's EFFECT LENGTH setting (5-60 s,
default 5) unless noted; most timed verbs take a number of seconds, capped at 60.
A shared cooldown throttles all of chat and each chatter also has their own (30 s default).
When the POINTS ECONOMY is on most verbs cost points and `!points` shows your balance.
Free for everyone: `!help` `!points` `!top` `!kills` `!song` `!version` `!suggest` `!link`
`!vote`, the joke plates and the Rocket League plates. `!help` puts a cheat sheet on stream;
`!help hurt` (or `chaos`, `mobs`, `fun`, `rl`, `mods`) shows one page.

**StreamElements grabs some of these on Lane's channel** (!bet !points !top !commands). Every verb also works
with a `z2` prefix, so type `!z2bet`, `!z2points`, `!z2top` (or `!z2anything`) and the game answers.

## Help the runner

- `!heal [n]` full HP, or n quarter-boxes. `!mp [n]` full MP, or n points. `!refill` (`!fairy` `!fary`) both.
- `!1up` +1 life. `!invuln [s]` invincible. `!link` (`!unchicken`) end a chat chicken early.
- `!protect` `!reflect` `!jump` `!life` `!fire` `!thunder` `!enigma` `!summon` cast that spell for real. Also `!spell <name>`.

## Hurt the runner

- `!hurt [n]` chip damage, 1-8 quarter-boxes, never lethal (stops at 1 HP). `!drain [n]` drain magic.
- `!poison` slow lethal HP drip (timed). `!curse` slow non-lethal drip (timed). `!attrition` (`!bleed` `!hunger`) life drips away, never kills (timed).
- `!tax [pct]` (`!xp` `!taxes`) take 10% of XP, or 1-50%. This one is permanent.
- `!dmgup` (`!doubledamage`) every hit on Link does double damage (timed). `!steal` (`!rob` `!thief` `!pickpocket`) borrow one item (timed).
- `!catslap [n]` three slaps that knock Link around, no damage. n = frames before the first slap (60 = 1 s, max 300).
- `!rust` the sword hits two attack levels lower (timed). `!adhd [s]` can't stop moving (timed).
- `!beef [s]` every mob on screen, bosses included, gets double HP, double damage and a 1.5x sprite. 40 points (timed).

## Chaos / screen (all timed)

- `!speed [s]` fast legs. `!slow` marsh-slow legs. `!shrink` (`!tiny` `!small`). `!grow` (`!huge`).
- `!flip` mirror the screen. `!confuse` swap LEFT/RIGHT. `!disorient` confuse plus swap UP/DOWN. `!party` disco plus flip.
- `!disco` color cycle. `!shake` screen shake. `!dark` darken the room: only in rooms with a dark version, anywhere else it waits for the next one.
- `!ice` (`!icefloor`) the floor is ice. `!moon` quarter gravity. `!root` can't walk or jump, can still swing.
- `!stasis [s]` (`!hold` `!freezelink`) freeze Link in place, 3 s default, max 10.
- `!deny <what> [s]` lock a move: spell / jump / stab / crouchstab / downstab / upstab / all. `!undeny [what]` (or `!deny <what> off`) lifts it.
- `!ghost` (`!invis`) enemies on screen turn nearly invisible.
- `!flashbang` (`!flash`) one white flash, every non-boss enemy on screen takes the smite hit.

## Mobs / dungeon master

- `!spawn <enemy> [n]` spawn up to 6. Roster: daira moblin grunt goriya zora stalfos stalfoon bat atta myu bot aneru aruroda bagin blooby boon bubble capper deeler doomknocker fokka fokkeru gellzem geru rockgeru girubokku guma ironknuckle lowder magnot mago mau megmat moby octorok ra tektite wizard wosu eyenocc.
  Chat spellings: knight/iron/darknut = ironknuckle, wiz = wizard, bird = fokka, lizard = daira, spider = deeler, slime = bot, eye = eyenocc, rock = rockgeru, octo = octorok. `!gorilla` = `!spawn goriya`.
  More spellings that work: dair, mobl/mob, gori, stal/skeleton, ache (bat), slimes, bubbles, eyeball, fokker, ironknuckles, lizalfos, rockthrower, wizzrobe.
  Add a colour word for the version: `!spawn blue goriya 2` (blue/strong = hard, red/orange = weak, v2 = version 2). `!spawn random` rolls enemy and version.
- `!slimed [rank] [s]` slime rain: Bots drop from the top for s seconds, rank 1-3 sets the pace.
- `!swarm [1-6]` a pack of random enemies (default 3). Typed on the overworld or in a cutscene it is queued (up to 3) for the next battle screen.
- `!ambush [1-6] [s]` (`!hunt` `!blobs`) OVERWORLD ONLY: encounter blobs appear around Link and hunt him (default 3 blobs, 20 s, max 60), and a 3-boulder wall drops in front of him (Lane's rule: ambush and boulder together). Add `weak` for small ones: `!ambush 4 30 weak`. 35 points.
- `!boulder [1-5]` (`!rocks` `!roadblock`) OVERWORLD ONLY: a wall of boulders in front of Link (default 3). The hammer breaks them; they vanish when he leaves the overworld.
- `!flute` (`!warp` `!tp`) warp Link to a random town he has already visited. Off the overworld it waits until he is back on the map. 10 min cooldown for all of chat.
- `!prison` (`!jail` `!lockdown`) the room's exits lock: 3 waves of 3 random mobs, harder each wave. Not in boss rooms; dying or falling down a pit ends it. 10 min cooldown for all of chat.
- `!flame` (`!heckler`) a jumping flame with your name over it.
- `!freeze` (`!stun`) freeze on-screen non-boss mobs (timed). `!smite` (`!clearscreen`) kill all on-screen non-boss mobs.
- `!crush` (`!drop` `!block`) a palace block falls from above Link (palaces only).
- `!arise` (`!chicken` `!cucco`) turn Link into a CHICKEN (timed). Needs CUCCO mode on that save.
- `!reshuffle` (`!reroll`) re-roll the seed's enemy randomizer mid-run (rando saves).
- `!challenge` (`!nomercy`) flipped screen, 4 hearts max, no helpful verbs until the runner leaves the palace. A death does not end it; a game over does. The streamer can switch it off (NO MERCY row).

## Fun / meta

- `!music <track>` play a jukebox track, part of the name is enough; `!music` alone shuffles. One song: the room's own music comes back when it ends.
- `!song` (`!np` `!nowplaying` `!track`) what's playing.
- `!meth` moon plus jump plus speed. `!quantumentangle` (`!qe`) a joke with a tiny side effect.
- `!fatality` `!friendship` `!flawless` `!finisher` `!babality` fire the MK2 splash, no gameplay effect (`!babality` = jingle plus baby Link, `!finisher` = random).
- `!toasty` the FLAWLESS splash with the Toasty pop guaranteed. 30 points. Refused if the streamer has Toasty off.
- `!trickortreat` Halloween week only (Oct 24-31): heads = full HP and MP, tails = two hearts gone and three Bubble skulls at the door. One knock per chatter per 5 min.
- `!haunt` 20 s of `!dark` plus `!ghost`, three skulls and the Castlevania boss track. Any day; free during Halloween week.
- `!suggest <idea>` log an idea for the dev. `!points` (`!bal` `!pts`) your balance. `!top` (`!leaderboard`) richest chatters. `!kills` (`!blame`) who has killed the runner most.
- `!vote <x> <y> [s]` (`!poll`) chat picks between two effects, 20 s default (10-60). While it runs type `x` or `y` (or 1 / 2). Free to start, free to vote, free for the winner. A tie fires both. Example: `!vote dark flip 30`.
- `!bet <win|flawless|death> <n>` wager on the boss on screen. Pays 2x / 5x / 3x. Needs POINTS on and the CHAT BETS row. Example: `!bet flawless 50`.
- `!bounty <enemy> <n>` (5-100) 2x back when the runner next kills that enemy. Any `!spawn` name. Needs POINTS on and the BOUNTIES row (off by default).
- `!help` (`!cmds`) cheat sheet on stream. `!version` (`!ver` `!build`) build info.
- `!donothing` `!rip` `!blip` `!coincidence` `!getfed` just toasts.

## Mods and the broadcaster

- `!ignore <name>` (`!mute`) that chatter is muted for the whole system: no commands, no votes, no points. Survives a restart.
- `!unignore <name>` (`!unmute`) let them play again.
- Mods skip both cooldowns when the MODS SKIP COOLDOWN row is on.

## Rocket League quick chat

Plates only, always free, needs the ROCKET LEAGUE row on:
`!niceshot` `!whatasave` `!calculated` `!savage` `!closeone` `!okay` `!faking` `!gg` `!ez` `!wow` `!noproblem` `!thanks`

## Notes

- Bosses are never affected by `!freeze` `!smite` `!flashbang` `!ghost`.
- Effects end on death and on loading a file. The streamer turning TWITCH IRC off ends everything chat started.
- Runtime effects never write to the save. `!tax` is permanent.

Examples: `!heal 4` `!spawn moblin 3` `!swarm 5` `!spell fire` `!music forest` `!party 20`

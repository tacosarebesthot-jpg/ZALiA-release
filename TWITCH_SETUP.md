# Twitch chat setup

Let your viewers reach into the game. This page covers both ways to connect,
which one you want, and every command chat can use.

**Read the account section first.** It is the part people get wrong, and it is the
part that matters.

---

## Which account should the game use?

You are giving the game a **token** — a key that lets it act on Twitch as
whichever account made it. There are two sensible choices, and the difference
matters.

### Option A — your own account (simplest)

The game logs into chat **as you**.

- ✅ Nothing else to set up. Two minutes.
- ⚠️ **If you grant the `chat:edit` scope, anything the game says in chat appears
  as you saying it.** Not "ZALiA bot" — *you*. Viewers cannot tell the difference.
- ⚠️ The token is as good as your account. Anyone who gets it can read and post
  in your chat as you.

**If you only grant `chat:read`, the game can listen and never speak.** That is
the safest version of this option, and it is all the game needs for chat commands
to work. Only add `chat:edit` if you want the game talking back in chat.

### Option B — a separate bot account (recommended if you stream regularly)

Make a second, free Twitch account — `YourNameBot` or similar — and generate the
token from **that** account instead.

- ✅ Anything the game posts appears as **the bot**, clearly not you
- ✅ If the token leaks, it is the bot that is compromised, not your channel
- ✅ You can mod the bot, name it whatever you like, and revoke it without
  touching your own account
- ➖ Five extra minutes: make the account, verify an email, mod it in your channel

**How to set one up:**

1. Sign out of Twitch, or open a private window
2. Make a new account — it needs its own email (a `+bot` alias on your existing
   address usually works: `you+bot@gmail.com`)
3. Verify the email
4. In **your** channel's chat, type `/mod YourNameBot` so it is not caught by
   slow-mode or follower-only restrictions
5. While signed in **as the bot**, generate the token (below)
6. Put the bot's token and login into the config, but set the **channel** to
   *your* channel — the bot joins your chat, not its own

> The single most common mistake: generating the token while signed in as
> yourself and *calling* it the bot. The token decides the identity, not the name
> you type. Whichever account is signed in when you click authorise is the account
> the game becomes.

---

## Getting connected

It is all on the **Twitch setup page** — open it from **OPTIONS → TWITCH OPTIONS → COMPANION
PAGES → Twitch**, or point a browser at `http://127.0.0.1:8777/twitch`.

**1. Connect your Twitch account.** Click **CONNECT WITH TWITCH**. This opens
Twitch's *own* login page in your normal browser — you sign in on twitch.tv, not
in the game, and the page never sees your password. Authorise the `chat:read` /
`chat:edit` scopes and Twitch hands back a chat token, stored locally in
`%LOCALAPPDATA%\ZALiA\twitch_config.txt` and never shown or sent anywhere else.
**FORGET TOKEN** clears it.

> Whichever account is **signed in to twitch.tv in that browser** when you click
> authorise is the account the game becomes. To use a bot account (Option B
> above), sign into twitch.tv as the bot first, *then* click CONNECT WITH TWITCH.

**2. Set the channel.** Enter **YOUR TWITCH USERNAME** (the account the token
belongs to) and the **CHANNEL TO JOIN** (usually the same), then **SAVE**.

**3. Connect to chat.** Click **CONNECT TO CHAT**. The game's top-left shows
`TWITCH: connecting` then `connected`, and hides itself after a few seconds so it
is not stuck on your stream. Type `!heal 4` in your chat to test.

**If CONNECT WITH TWITCH does nothing** it needs a Twitch application **Client
ID** (the OAuth handshake requires one). If the build shipped with an App ID this
is already handled; otherwise create a free app at
[dev.twitch.tv/console](https://dev.twitch.tv/console) → *Register Your
Application*, and paste its **Client ID** into the **APP ID** field on the page,
then connect. As a manual fallback you can instead grab a token from
[twitchtokengenerator.com](https://twitchtokengenerator.com/) (pick the
`chat:read`, add `chat:edit` only if you want the game to speak) and drop it into
the `token=` line of `twitch_config.txt` yourself.

Add `tls=1` to `twitch_config.txt` to connect over wss on port 443, so the token never
crosses the wire in the clear. Opt-in; the default is the plain IRC port.

### If it will not connect

| Symptom | Cause |
|---|---|
| Never reaches `connected` | token expired, or wrong scopes — reconnect |
| CONNECT WITH TWITCH does nothing | no App ID — see above |
| Connects, commands do nothing | joined the wrong channel, or CHAT EFFECTS is off |
| Nothing at all | the config was not saved |

Tokens expire. If it worked last month and not today, click CONNECT WITH TWITCH
again before debugging anything else.

---

## In-game options

Press **O** in game and pick **TWITCH OPTIONS**. Everything here is saved to `%LOCALAPPDATA%\ZALiA\twitch_config.txt`.

| Row | What it does | Key |
|---|---|---|
| CHAT JOKES | NORMAL / CLEAN / DIRTY town text | `jokes=0/1/2` |
| CHECKPOINTS | rolling save copies | `autosave=1/0` |
| POINTS ECONOMY | viewers pay points for commands (on by default) | `points=1/0` |
| ROCKET LEAGUE | quick-chat plates and verbs | `rl=1/0` |
| CHATTER COOLDOWN | each chatter's own cooldown, 0 to 120 s (default 30) | `user_cooldown=` (frames) |
| MODS SKIP COOLDOWN | mods and the broadcaster skip both cooldowns | `mod_bypass=1/0` |
| EFFECT TIMERS | top-right strip of running effects with seconds left, plus the live vote | `effects_hud=1/0` |
| COMMAND SOUND | a short blip each time a chat command lands, at most one every 2 s. **Turn it OFF here if a busy chat gets annoying.** | `cmd_sound=1/0` |
| CHAT EXTRAS | opens a second page with the rest of the chat switches (below) | |
| CHAT EXTRAS > FIRST-USE HINT | first time a verb hits you in a session, a toast says what it does (off by default) | `first_use_hint=1/0` |
| CHAT EXTRAS > 1UP REMINDER | minutes on your last life before a toast reminds chat that `!1up` exists: OFF (default) or 1-30 | `oneup_nudge=0-30` |
| CHAT EXTRAS > SWARM CAP | `!swarm` is refused once this many enemies are on screen, 4-40 (default 14) | `swarm_cap=4-40` |
| CHAT EXTRAS > TOASTY | chance the MK2 Toasty pops after a flawless: OFF or 10-100% (default 50) | `toasty=0-100` |
| CHAT EXTRAS > MK2 ANNOUNCER | FIGHT / FINISH HIM / EXCELLENT voice samples | `announcer=1/0` |
| CHAT EXTRAS > BABALITY | chance a flawless is a Babality when Link is not shrunk: OFF or 5-100% (default 15) | `babality=0-100` |
| CHAT EXTRAS > CHAT BETS | `!bet` on the boss fight (needs points on) | `bets=1/0` |
| CHAT EXTRAS > BOUNTIES | `!bounty <enemy> <points>` (needs points on, off by default) | `bounty=1/0` |
| MUSIC TOASTS | NOW PLAYING plate: OFF (default) or 1-30 seconds on screen | `toast_music=0-30` |
| CHAT TOASTS | plates for what chat did: OFF or 1-30 seconds (default 4) | `toast_chat=0-30` |
| GAME TOASTS | killed by, crushed, level up, hints: OFF (default) or 1-30 seconds | `toast_game=0-30` |
| MK2 SPLASH | arcade FLAWLESS / FATALITY animation on a hitless boss | `splash=1/0` |
| ZELDA 1 JINGLE | Zelda 1 treasure fanfare on main items | `loz_jingle=1/0` |
| BIG TIMER | larger run timer in the top bar | `bigtimer=1/0` |
| COMPANION PAGES | opens the jukebox, tracker and Twitch setup pages | |

The MK2 FLAWLESS / FATALITY lines and the easter eggs always show, whatever the toast settings.

A few more keys have no menu row and live only in `twitch_config.txt` (one per line, `key=value`):

| Key | Default | What it does |
|---|---|---|
| `cmd_sound_name=` | `snd_Cursor_Move_2a` | which sound the COMMAND SOUND blip uses; any sound asset name in the game |
| `first_use_hint=1/0` | 0 | the first time a verb lands in a session, its `!help` line is toasted so you know what just hit you |
| `oneup_nudge=` | 0 | minutes on your last life before a toast reminds chat that `!1up` exists; 0 turns it off |
| `swarm_cap=` | 14 | live enemies on screen at which `!swarm` is refused (mods skip cooldowns, so this is the real limit) |
| `toasty=` | 50 | percent chance the MK2 Toasty pops after a flawless finisher |
| `announcer=1/0` | 1 | the MK2 announcer: FIGHT! on a boss, FINISH HIM at a quarter bar, EXCELLENT for a clean `!swarm` wipe |
| `babality=` | 15 | percent chance a flawless ends in a Babality when Link is not shrunk; shrunk is always |
| `bets=1/0` | 1 | `!bet win / flawless / death N` on the boss on screen (2x / 5x / 3x) |
| `bounty=1/0` | 0 | `!bounty <enemy> N`, 2x on that enemy's next kill. Off until you turn it on |

## Tuning it

On the Twitch setup page (**OPTIONS → TWITCH OPTIONS → COMPANION PAGES**, or
`http://127.0.0.1:8777/twitch`):

- **CHAT COMMANDS on/off** — the master switch
- **Effect duration** — how long timed effects last
- **Cooldown** — a shared throttle across all of chat, so five viewers cannot
  stack five effects instantly
- **CHATTER COOLDOWN** (in-game, TWITCH OPTIONS) — a second throttle per chatter, on
  top of the shared one. Mods and the broadcaster skip both unless you turn
  **MODS SKIP COOLDOWN** off

Start with a long cooldown. You can always loosen it once you know how your chat
behaves.

---

## What chat can do

Syntax is `!verb [amount]`. Unknown commands are ignored. Every **timed** effect
takes an explicit duration in seconds — `!flip 100`, `!dark 45` — capped at 60s;
without one it runs for the duration you set. Typos auto-correct where it matters
(`!filp`, `!huge`, `!span`), stray invisible paste-characters are stripped, and
`!hurt4` works like `!hurt 4`.

### Help you

| Command | Effect |
|---|---|
| `!heal <n>` | restore `<n>` quarter-heart boxes (bare `!heal` = full) |
| `!mp <n>` | restore magic |
| `!refill` `!restore` | full health and magic |
| `!fairy` | full health and magic (the fairy heals you) |
| `!1up` | an extra life |
| `!invuln` | brief invincibility |
| `!protect` `!shield` `!reflect` | grant that spell's effect |
| `!jump` `!life` `!summon` | cast that spell |
| `!arise` `!cucco` `!chicken` | turn Link into a cucco |
| `!freeze` `!stun` | freeze every non-boss enemy on screen (the toast counts them) |
| `!smite` `!clearscreen` | kill every non-boss enemy on screen |
| `!link` `!unchicken` | back to Link form |

### Hurt you

| Command | Effect |
|---|---|
| `!hurt <n>` | `<n>` quarter-heart boxes of damage, 1 to 8; stops at 1 HP, never kills |
| `!drain <n>` | drain magic, up to four bars |
| `!poison` | ticking damage that can kill |
| `!curse` | slow health drip, stops at 1 HP |
| `!steal` `!rob` | takes one of your traversal/combat items (candle, glove, raft, boots, flute, hammer, bracelet, sword, shield, ring) and gives it back later |
| `!slow` | marsh-slow legs |
| `!root` | no walking, no jumping — swinging still works |
| `!spawn <enemy> <n>` | drop a named enemy next to you (daira, moblin, goriya, zora, stalfos, bat, atta, myu) |
| `!swarm <n>` | a pack of random enemies around you |
| `!flame` `!heckler` | a jumping flame tagged with the viewer's name |
| `!deny <what>` | temporarily blocks spell / jump / upstab / downstab / upthrust / downthrust / all. `!undeny [what]` or `!deny <what> off` lifts it early |
| `!catslap <n>` | three slaps from alternating sides that knock Link around, no damage. `<n>` is frames to wait before the first slap (60 = 1 s), so it can land with an overlay |
| `!tax <pct>` | takes a cut of your experience (bare `!tax` = 10%, up to 50) |
| `!dmgup <secs>` | every hit does double damage for a while |
| `!attrition <secs>` | life drips away slowly; stops short of killing |
| `!stasis <secs>` | Link freezes in place, mid-air included (1–10s) |
| `!challenge` | inside a palace only: screen stays flipped until you leave, life capped at 4 hearts, no helpful commands. A death does not end it; leaving the palace or a game over does |
| `!crush` | drops a palace block from above you. Falling blocks kill whatever they land on now, you included |

### Mess with your head

| Command | Effect |
|---|---|
| `!confuse` | swaps left and right — bare `!confuse` rolls a random 10–30s, good luck |
| `!disorient` | confuse, plus up and down |
| `!ghost <secs>` | every non-boss enemy on screen turns nearly invisible |
| `!flashbang` `!flash` | one white flash, plus the smite hit on every non-boss enemy on screen |
| `!flip` | mirrors the screen |
| `!dark` | kills the lights — you will need the candle (it actually works now) |
| `!ice` | the floor is ice; momentum is a lifestyle |
| `!moon` | quarter gravity. big floaty jumps |
| `!disco` | colour-cycling overlay |
| `!party` | disco and flip together |
| `!shrink` `!grow` | resize Link, hitbox and sword reach included |
| `!speed <secs>` | too fast to control |
| `!shake` | screen shake |
| `!spell <name>` | cast a named spell (`!fire` `!thunder` `!enigma` work too) |
| `!music` | reshuffle the soundtrack mid-run |
| `!song` `!np` | shows the current track's name (it also pops up on every new track) |
| `!meth` | moon + jump + speed at once |
| `!quantumentangle` | something small and random happens. or doesn't |
| `!help` `!cmds` | a one-screen card of all of this on stream. `!help hurt`, `chaos`, `mobs`, `fun`, `rl` or `mods` shows one page with what each verb does |
| `!niceshot` `!whatasave` `!calculated` `!savage` `!closeone` `!okay` `!faking` `!gg` `!ez` `!wow` `!noproblem` `!thanks` | Rocket League quick-chat plates, free. Three of the same inside six seconds: chat disabled for 4 seconds |
| `!points` | your balance, when the points economy is on (see below) |
| `!top` | the three richest chatters, when the points economy is on |
| `!kills` `!blame` | who has killed the runner most |
| `!vote <x> <y> [secs]` | chat picks between two effects (`!vote dark flip 30`). Type `x` or `y`, or `1` / `2`, to vote; one ballot each, last one counts; the winner fires when the clock runs out, a tie fires both. Free to start, free to vote, and the winner is free |
| `!suggest <idea>` | your idea goes in a file gainey reads |
| typos | a near-miss command (like `!stasus` or `!refil`) gets a "did you mean ?stasis" toast; pure nonsense stays silent |

### Mods and the broadcaster

| Command | Effect |
|---|---|
| `!ignore <name>` `!mute <name>` | mutes that chatter for the whole system: no commands, no votes, no points, no joke pools. Survives a restart (`ignored.txt` in `%LOCALAPPDATA%\ZALiA\`) |
| `!unignore <name>` `!unmute <name>` | lets them play again |

Mods and the broadcaster also skip both cooldowns while MODS SKIP COOLDOWN is on. The
broadcaster can never be ignored.

Clean out a boss fight without taking a hit and the game plays the real Mortal
Kombat II **FLAWLESS VICTORY** and **FATALITY** / **FRIENDSHIP** splash, announcer and
all. `!swarm` typed on the overworld waits for the next battle screen. A command on
cooldown answers with how long to wait. Small numbers like 69 and 420 get the respect
they deserve.

### Rocket League

**ROCKET LEAGUE** (OPTIONS → TWITCH OPTIONS, on by default) makes the game talk in quick-chat: WHAT A SAVE!
on a one-heart survival, CALCULATED. on a bloody boss kill, WHIFF after five empty swings,
NICE BLOCK!, BUMPING!, NICE DEMO!, NEED BOOST!, ALL YOURS., ROTATE!, and the death lines. Turn it
off and all of it, verbs included, goes quiet.

### Chat jokes

With **CHAT JOKES** on (OPTIONS → TWITCH OPTIONS), the town folk talk like chat: every idle
line, sign, healer and story-recorder has several alternates picked at random, with
your chatters' names and the boss you are fighting dropped in. **CLEAN** keeps the
cursing out, **DIRTY** lets it all through, **NORMAL** is the original text. Hints and
quest lines are never changed, so a randomizer run stays solvable. The lines live in
`dialogue_jokes.txt` next to the game; a copy in `%LOCALAPPDATA%\ZALiA\` overrides it,
so you can write your own.

### Points economy

**POINTS ECONOMY** (same page, on by default since 2.1.8) makes commands cost something. Viewers earn 1
point per chat message (up to 6 a minute) and 5 points every 5 minutes while they are
talking; every command has a price (a heal 20, a swarm 25, a flashbang 60). A refused command costs nothing. Too poor and the
game says so on screen. The broadcaster is always free. Balances persist between streams.

### Checkpoints

**CHECKPOINTS** (same page, on by default) drops a copy of your live save into
`%LOCALAPPDATA%\ZALiA\checkpoints\` every 60 seconds of play, on every item and on
every level-up, keeping the newest 30. Your real save file is never touched. To go
back in time: close the game, copy one over `SaveFile_N.txt`, start the game.

---

## VS CHAT mode

Turn this on and it stops being a favour economy. **Chat's goal is to kill you.**

Every helpful command is **blocked** — no healing, no magic, no extra lives, no
shields, no invulnerability, no cucco, no jump spell. Anyone who tries is told it
was blocked, so they know the rules rather than thinking the game is broken. Only
the things that hurt you still work.

**The game keeps score.** Every death is a point to chat — the stream toast calls
it out live ("CHAT KILL xN") and the tracker shows their running total. It does not
reset when you do — it stands for the session.

Blocking works as a *deny* list rather than an allow list, deliberately: any
hostile command added in a future version works in VS mode the day it ships,
rather than silently doing nothing until someone remembers to add it.

Turn it on from the Twitch setup page. It also switches chat commands on for you,
because a versus mode that silently ignores chat is the kind of thing you only
discover live.

---

## A note on trust

Chat commands hand strangers a lever on your game. That is the point, and it is
also the risk. The cooldowns are your main defence: the shared one throttles
*everyone* together, so a raid cannot chain effects faster than you set, and the
per-chatter one stops any single viewer from hogging it. `!ignore <name>` mutes
one chatter for good.

If it gets out of hand, the master switch is one click on the setup page, and
takes effect immediately.

---

**ZALiA 2.0** &middot; [Download](https://github.com/tacosarebesthot-jpg/ZALiA-release/releases/latest) &middot; [Manual](MANUAL.md) &middot; [What this port adds](FEATURES.md) &middot; [Discord](https://discord.gg/FSphHEsu8D) &middot; [Patreon](https://www.patreon.com/cw/gainey666) &middot; [Changelog](CHANGELOG.md)

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

The quick path — from the `ZALiA_Twitch_IRC_Setup` folder in the game directory:

1. Run **`setup_twitch_irc.bat`**
2. Say yes to open the token page. Pick **`chat:read`** (add `chat:edit` only if
   you want the game speaking in chat). Authorise, copy the token.
3. Paste the token, then type the login name **of the account the token belongs
   to**, and the channel to join — **your** channel.
4. In game: **OPTIONS → TWITCH → TWITCH IRC → ON**
5. Top-left shows `TWITCH: connecting` then `connected`, and hides itself after a
   few seconds so it is not stuck on your stream.
6. Type `!heal 4` in your chat to test.

Your config lives at `%LOCALAPPDATA%\ZALiA\twitch_config.txt`. Re-run setup any
time to change it, then toggle TWITCH IRC off and on.

**Testing without a live chat:** `twitch_test.bat heal 4` fires a command
directly, so you can check effects before going live.

### If it will not connect

The status line tells you which failure it is. The usual causes:

| Symptom | Cause |
|---|---|
| Never reaches `connected` | token expired, or wrong scopes — regenerate it |
| Connects, commands do nothing | joined the wrong channel; check the `channel=` line |
| Nothing at all | TWITCH IRC toggle is off, or the config was not saved |

Tokens expire. If it worked last month and not today, regenerate before debugging
anything else.

---

## Tuning it

On the Twitch setup page (**OPTIONS → COMPANION PAGES**, or
`http://127.0.0.1:8777/twitch`):

- **CHAT COMMANDS on/off** — the master switch
- **Effect duration** — how long timed effects last
- **Cooldown** — a shared throttle across all of chat, so five viewers cannot
  stack five effects instantly

Start with a long cooldown. You can always loosen it once you know how your chat
behaves.

---

## What chat can do

Syntax is `!verb [amount]`. Unknown commands are ignored. Timed effects run for
the duration you set.

### Help you

| Command | Effect |
|---|---|
| `!heal <n>` | restore health |
| `!mp <n>` | restore magic |
| `!refill` | full health and magic |
| `!1up` | an extra life |
| `!invuln` | brief invincibility |
| `!protect` `!shield` `!reflect` | grant that spell's effect |
| `!fairy` `!arise` `!cucco` `!chicken` | turn Link into a cucco |
| `!freeze` `!stun` | freeze every non-boss enemy on screen |
| `!smite` `!clearscreen` | kill every non-boss enemy on screen |

### Hurt you

| Command | Effect |
|---|---|
| `!hurt <n>` | chip damage, non-lethal |
| `!drain <n>` | drain magic |
| `!curse` | slow health drip, stops at 1 HP |
| `!steal` `!rob` | takes one of your items and gives it back later |
| `!slow` | marsh-slow legs |
| `!spawn <enemy> <n>` | drop a named enemy next to you |
| `!swarm <n>` | a pack of random enemies around you |
| `!flame` `!heckler` | a jumping flame tagged with the viewer's name |

### Mess with your head

| Command | Effect |
|---|---|
| `!confuse` | swaps left and right |
| `!flip` | mirrors the screen |
| `!dark` | kills the lights — you will need the candle |
| `!disco` | colour-cycling overlay |
| `!party` | disco and flip together |
| `!shrink` `!grow` | resize Link |
| `!speed <secs>` | too fast to control |
| `!shake` | screen shake |
| `!spell <name>` | cast a named spell |
| `!music` | reshuffle the soundtrack mid-run |

---

## VS CHAT mode

Turn this on and it stops being a favour economy. **Chat's goal is to kill you.**

Every helpful command is **blocked** — no healing, no magic, no extra lives, no
shields, no invulnerability, no cucco. Anyone who tries is told it was blocked, so
they know the rules rather than thinking the game is broken. Only the things that
hurt you still work.

**The game keeps score.** Every death is a point to chat, shown live on the stream
tracker as their running total. It does not reset when you do — it stands for the
session.

Blocking works as a *deny* list rather than an allow list, deliberately: any
hostile command added in a future version works in VS mode the day it ships,
rather than silently doing nothing until someone remembers to add it.

Turn it on from the Twitch setup page. It also switches chat commands on for you,
because a versus mode that silently ignores chat is the kind of thing you only
discover live.

---

## A note on trust

Chat commands hand strangers a lever on your game. That is the point, and it is
also the risk. The cooldown is your main defence — it throttles *everyone*
together, not per-viewer, so a raid cannot chain effects faster than you set.

If it gets out of hand, the master switch is one click on the setup page, and
takes effect immediately.

---

**ZALiA 2.0** &middot; [Download](https://github.com/tacosarebesthot-jpg/ZALiA-release/releases/latest) &middot; [Manual](MANUAL.md) &middot; [What this port adds](FEATURES.md) &middot; [Discord](https://discord.gg/FSphHEsu8D)

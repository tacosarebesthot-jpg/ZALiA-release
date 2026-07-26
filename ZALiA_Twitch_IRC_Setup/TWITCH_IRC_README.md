# ZALiA — Twitch **IRC** Integration (no-bot mode) — SETUP & LAUNCH

The game connects to Twitch chat **itself** over IRC and feeds chat `!commands`
straight into the existing `twitch_apply()` verb dispatcher. **No external bot
required.** Off by default.

> This is a **different** path from `TWITCH_INTEGRATION_README.md`, which documents the
> **bot → drop-folder** path (channel points / subs / votes). Both apply the **same
> verbs**. This file = the direct in-game IRC client (chat commands only).

Source of truth for everything below:
`scripts/twitch_irc_*`, `objects/obj_twitch_irc`, and the menu wiring in
`scripts/OptionsMenu_TestCap_update`. If code and doc ever disagree, the code wins.

---

## TL;DR — get it launching

1. Create `%LOCALAPPDATA%\ZALiA\twitch_config.txt` (run `setup_twitch_irc.bat`, or hand-write it — see §1).
2. Start the game.
3. **Options → TWITCH → TWITCH IRC**, press confirm to turn it **ON**.
4. Watch the **top-left status line**: `TWITCH: connecting` → `TWITCH: connected`.
5. Type `!heal 4` in your Twitch chat → effect fires + a bottom-centre toast shows `tester → heal`.

**If it won't connect, the top-left `TWITCH:` line tells you why** — read
[On-screen status](#on-screen-status-your-1-diagnostic) first, before anything else.

---

## 1. The config file

The game reads `working_directory + "twitch_config.txt"`, which on Windows is:

    %LOCALAPPDATA%\ZALiA\twitch_config.txt
    = C:\Users\<you>\AppData\Local\ZALiA\twitch_config.txt

Format — one `key=value` per line. Keys are **case-insensitive**. Lines starting with
`#` or `//` are comments. Whitespace/CRLF around keys and values is trimmed.

    token=oauth:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    user=gainey666
    channel=gainey666
    cooldown=600

| key | required | meaning | notes |
|-----|----------|---------|-------|
| `token`    | **yes** | Twitch **chat** OAuth token | `oauth:` prefix is **optional** — `oauth:xxxx` and bare `xxxx` both work (the loader strips it, the connector re-adds it). |
| `user`     | **yes** | login nick the token belongs to | lowercased automatically. Alias key: `nick`. |
| `channel`  | **yes** | channel to join | leading `#` optional; lowercased automatically. |
| `cooldown` | no | global anti-spam throttle, in **FRAMES** | **60 frames = 1 second.** Default `600` = **10 seconds**, *not* 10 minutes. One shared throttle for the whole chat. |

If `token`, `user`, or `channel` is missing/blank, the loader sets status to
`no config` and the client **refuses to connect**.

> **The token is never hardcoded** — you supply your own. Don't commit a real token to
> a public repo; regenerate it if it leaks.

## 2. Getting an OAuth chat token

The `token` is a Twitch **IRC chat** token. (`twitchapps.com/tmi` is **discontinued** —
don't use it.)

- Easiest: **https://twitchtokengenerator.com/** (swiftyspiffy's Twitch Token Generator).
  Pick the `chat:read` scope (add `chat:edit` too if you like), authorise, and copy the
  **Access Token**. In the config write it as `token=oauth:<that token>` (prefix optional).
- Official / CLI: install the **Twitch CLI** and run
  `twitch token --user-token --scopes "user:read:chat"` (or `chat:read` for IRC), then use
  the returned token. Docs: https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/

**These tokens expire / get revoked.** An expired or wrong token is the #1 reason it
"won't connect": the socket opens, Twitch never sends the `001` welcome (or drops you),
and the status shows `connecting` forever or flips to `error: disconnected`. If it used
to work and suddenly doesn't, **regenerate the token first.**

## 3. Turning it on in-game

Menu path:

    Options → TWITCH → TWITCH IRC

Press confirm (**A** / **START** on a pad, or the **H** key) to toggle.

- **ON**  → loads the config and connects (`tw_irc_enabled = true`, `twitch_irc_connect()`).
- **OFF** → disconnects (`twitch_irc_disconnect()`).

**To reconnect / re-read the config after any edit: toggle OFF then ON.** Connecting
also raises the shared master gate (`global.tw_enabled`) so accepted verbs actually fire.

> **Two different menu items — don't confuse them:**
> - **TWITCH** = flips the master gate (`global.tw_enabled`) only. Use it to test the
>   **file-drop / bot** path *without* IRC.
> - **TWITCH IRC** = the in-game IRC client (`global.tw_irc_enabled`). This is the one
>   you want for direct chat commands. It raises the master gate for you.

## 4. Using it (chat side)

Once `TWITCH: connected` shows, chat drives the game. Syntax is a bare bang-command:

    !<verb> [arg]

Examples:

    !heal 4         -> heal 4 HP
    !dark           -> darken the room (timed, ~5s default)
    !music forest   -> play the jukebox track matching "forest"
    !spawn moblin   -> drop a Moblin next to Link
    !swarm 5        -> spawn 5 weak Myu around Link
    !freeze         -> freeze on-screen non-boss mobs
    !refill         -> full HP + MP

- **Unknown commands are ignored** (and don't consume the cooldown).
- Timed effects default to **300 frames (5s)** when triggered from chat.
- Each accepted command shows a bottom-centre toast: `<chatter> → <verb>`.

**Recognised verbs** (aliases in parens):
`heal, hurt, mp, drain, 1up, invuln, shake, dark, music, shrink, grow, slow, spell,
speed, flame (heckler), spawn, swarm, flip, confuse, disco, freeze (stun),
smite (clearscreen), curse, party, refill, arise (chicken/cucco)`.
See the verb table in `TWITCH_INTEGRATION_README.md` for each verb's arg and effect.

## 5. Testing without live chat

You don't need viewers to prove the pipeline. `twitch_test.bat` drops a command into the
file-drop queue (the master gate must be up — which the IRC client does automatically, or
toggle plain **TWITCH** on):

    twitch_test.bat heal 4
    twitch_test.bat spawn daira

If `twitch_test.bat` fires effects but real chat doesn't, the **game side is fine** and
the problem is the **IRC connection** (token / channel / network) — check the status line.

---

## On-screen status (your #1 diagnostic)

While TWITCH IRC is enabled, a line is drawn **top-left** in aqua: `TWITCH: <status>`.
It reads `global.tw_irc_status`:

| status shown | meaning | what to do |
|--------------|---------|------------|
| *(nothing)* / `idle` | config valid, not connected, or `idle` (never drawn) | toggle ON to connect |
| `connecting` | socket opened, waiting for Twitch `001` welcome | if it never becomes `connected` → **bad/expired token** or wrong nick |
| `connected` | logged in and joined (auto-hides after ~4s so it's not stuck on your stream) | you're good — send a `!` command |
| `no config` | config file missing, or `token`/`user`/`channel` blank | fix `%LOCALAPPDATA%\ZALiA\twitch_config.txt`, toggle OFF→ON |
| `error: socket` | couldn't allocate the TCP socket | rare; network stack / VM build issue |
| `error: connect` | `network_connect_raw` to `irc.chat.twitch.tv:6667` failed | firewall / no network / port 6667 blocked |
| `error: disconnected` | Twitch dropped the socket after connecting | almost always a **bad token**; also network loss. Toggle OFF→ON to retry |

`connecting`, `no config`, and every `error:` are drawn **persistently** so you can't
miss them.

### Connection details (for reference)
- Raw **TCP** to `irc.chat.twitch.tv` port **6667** (plain, non-TLS).
- Handshake sent: `PASS oauth:<token>` → `NICK <user>` → `JOIN #<channel>`.
- `PING` from Twitch is auto-answered with `PONG` (keepalive) in `twitch_irc_handle_line`.
- Receive is event-driven in `obj_twitch_irc`'s Async-Networking event.

---

## Troubleshooting

| Symptom | Status line | Cause | Fix |
|---------|-------------|-------|-----|
| Toggled ON, nothing happens | `no config` | file missing / blank field | create `%LOCALAPPDATA%\ZALiA\twitch_config.txt` with token+user+channel; OFF→ON |
| Stuck on `connecting`, never `connected` | `connecting` | expired/invalid token, or wrong `user` | regenerate the OAuth token; verify `user` matches it; OFF→ON |
| Connects then drops | `error: disconnected` | bad token / network loss | regenerate token; OFF→ON |
| Can't reach Twitch at all | `error: connect` | firewall / port 6667 blocked / offline | allow the game through the firewall; check connection |
| First command works, then chat "dead" briefly | *(connected)* | `cooldown` throttle (default 10s) | it's **frames**; lower e.g. `cooldown=60` (1s) while testing; OFF→ON |
| A command does nothing, others work | *(connected)* | unknown verb (ignored) | check spelling vs the verb list; args like `!spawn moblin` |
| `twitch_test.bat` works, chat doesn't | any error | IRC side, not effects | fix per status line above |
| Config edits ignored | unchanged | didn't reconnect | toggle **OFF then ON** after every config change |

### "It won't launch" checklist
1. `%LOCALAPPDATA%\ZALiA\twitch_config.txt` exists with `token`, `user`, `channel`.
2. Token is **freshly generated** (chat scopes). Prefix optional.
3. `user`/`channel` are the correct lowercase login names.
4. `cooldown` is a small number of **frames** while testing (e.g. `60`).
5. In-game **TWITCH IRC** toggled ON; top-left says `TWITCH: connected`.
6. `!heal 4` in chat fires an effect + toast.

---

## Known limitations (from the code)
- `twitch_irc_send` has no send-failure handling / re-queue yet (see its TODO header).
- Partial IRC lines split across two TCP packets aren't reassembled (rare for the small
  command traffic here, but possible under heavy chat).
- One **global** cooldown for the whole chat — not per-user.
- Connection is plain **6667** (non-TLS). Fine for chat commands; no secure port yet.

## Files in this feature
| file | purpose |
|------|---------|
| `scripts/twitch_irc_load_config` | reads `twitch_config.txt` |
| `scripts/twitch_irc_connect` / `_disconnect` | open/close the socket + handshake |
| `scripts/twitch_irc_handle_line` | parse IRC lines, route `!verb` → `twitch_apply()` |
| `scripts/twitch_irc_step` / `_send` | per-frame tick / raw line send |
| `objects/obj_twitch_irc` | hosts the Async-Networking receive event |
| `scripts/OptionsMenu_Twitch_update` | the Options → TWITCH menu toggles |
| `scripts/Surface_Draw_GUI_End` | draws the top-left `TWITCH:` status line + verb toast |
| `setup_twitch_irc.bat` / `twitch_test.bat` | write the config / simulate a command |
| `TWITCH_INTEGRATION_README.md` | the **bot → drop-folder** path + full verb table |

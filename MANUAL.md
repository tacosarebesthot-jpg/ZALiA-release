# ZALiA — Instruction Manual

*Zelda Again: Link is Adventuresome* — GameMaker 2026 Port

---

## The Story

Link has awakened in a Hyrule he does not recognise. The crest on his hand burns
again, and the Great Palace stirs in the Valley of Death. Six palaces stand across
two continents, each holding a crystal, each crystal a lock on the seal that keeps
Ganon's servants from returning.

Set a crystal in each palace statue. Then descend into the Great Palace, and face
what waits beneath it.

---

## Getting Started

Run `ZALiA.exe`. Choose a save slot, name your file, and begin.

At the file screen you may start an ordinary quest, or turn on the **Randomizer** —
see [Randomizer](#randomizer) below.

Your progress saves automatically. Everything is written to `%LOCALAPPDATA%\ZALiA\`,
never to the game folder, so you can move or replace the game without losing a file.

---

## Controls

Keyboard and gamepad are both supported. Everything below can be rebound in
**OPTIONS → CONTROLS**, and gamepads get a calibration wizard.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move / climb / enter | Arrow keys | D-pad or stick |
| Attack | X | X |
| Jump | Z | A |
| Cast selected spell | C | B |
| Pause / inventory | Enter | Start |
| Select spell | Shift | Select |

**Down + Attack** while airborne is the **downward stab**. **Up + Attack** is the
**upward stab**. Both are techniques you learn, not items you find — and both are
essential. Many enemies cannot be beaten cleanly without them.

---

## The Screen

**Overworld.** You travel Hyrule from above. Stepping into tall grass, swamp, or
sand may drop you into a side-view encounter. Roads are safe.

**Side view.** Towns, caves, palaces and encounters. This is where you fight.

**LIFE** and **MAGIC** meters sit at the top left. Below them, your levels:
**ATTACK**, **MAGIC**, **LIFE**. Collect enough experience and you choose which to
raise. Choose carefully — the cost of the next level rises with every point spent.

---

## Life, Magic, and Death

**LIFE** is your health. Lose it all and you lose a life.

**MAGIC** is spent casting. Blue jars refill it; red jars refill more.

**Heart containers** raise your maximum life. **Magic containers** raise your
maximum magic. There are many of each hidden across both continents.

Lose all your lives and you return to the North Castle — but keep your levels,
your items, and your spells. Death costs you position, not progress.

---

## Spells

Each town holds a wise man who will teach you a spell, usually after you do
something for the town first.

| Spell | What it does |
|---|---|
| **PROTECT** | halves damage taken |
| **JUMP** | leap far higher |
| **HEAL** | spend magic to restore life |
| **CUCCO** | become a small creature that reaches places Link cannot |
| **FIRE** | your sword throws flame |
| **REFLECT** | your shield turns back magic, and breaks certain barriers |
| **SPELL** | reveals what is hidden |
| **THUNDER** | strikes every enemy on screen |

Press **Select** to change the active spell, **B** or **C** to cast.

---

## Items

Some open the way forward. Some make you stronger. A few are simply worth finding.

**CANDLE** lights caves · **GLOVE** breaks blocks · **RAFT** crosses water ·
**BOOTS** walk on water · **FLUTE** wakes what sleeps · **CROSS** reveals the
invisible · **HAMMER** clears boulders and trees · **BRACELET** for the deepest
doors · **MAGIC KEY** opens any palace lock

**Keys** open palace doors. Ordinary keys are spent when used; the magic key is not.

**Crystals** go into the statue at the end of each palace. Six crystals open the
Great Palace.

---

## Palaces

Each palace ends with a boss and a crystal statue. Between you and it: locked
doors, moving platforms, and the elevator shafts that connect the floors.

Some palaces contain **falling passages** — step into one and Link drops through
to another part of the palace. A few of them are one-way. Look before you leap,
and remember that not every fall is survivable.

The **Great Palace** in the Valley of Death opens only when all six crystals are
set. It is longer and harder than anything before it.

---

## Towns

Every town has people worth talking to. Some heal you. Some refill your magic.
Some teach a spell — usually only after you have done something for them.

Listen to everyone. In this game the townsfolk are not decoration: they tell you
where things are, and under the randomizer they are the only ones who know.

Beneath several towns are **basements** connecting distant parts of the map. Find
them and the journey gets much shorter.

---

## Randomizer

Turn it on at the file-creation screen and the world is rebuilt for that save.

You can randomize **items**, **spells**, **town locations**, **palace layouts**,
**enemy spawns**, **overworld biomes**, and more. Each save keeps its own settings,
so two files can be completely different quests.

**Start-with spells** let you begin holding spells you would normally earn. These
are per-seed choices — they do not carry between files.

**Hints.** Two separate systems will help you:

- **Boulder hints** — in every mode. Push the boulders in the circle in the right
  order and something opens. The towns tell you the order.
- **Item hints** — randomizer only. Villagers tell you where specific items went,
  in their own words. Turn these off at file creation if you would rather find
  everything yourself.

Signs keep their **original** town names even when town locations are shuffled, so
you always know which place you are standing in.

---

## Companion Pages

The game runs a small server on `127.0.0.1:8777` and serves three pages of its own.
It is **loopback only** — not reachable from your network, and nothing leaves your
machine. Open them from **OPTIONS → COMPANION PAGES**.

**Tracker** — every item, spell, container, key and crystal you hold, plus your
hints, live. Five themes. Built to be read at a glance across a room, so it works
as an OBS Browser Source at about 460 px wide. Add `?obs=1` to drop the background.

**Jukebox** — every track in the game, playable on demand. Play in order, shuffle,
or repeat one.

**Twitch** — connect your channel and let chat into your run.

---

## Twitch Chat

Connect your channel on the Twitch setup page and your viewers can reach into the
game. Each command has a cooldown and a duration you control, so chat can be a
light garnish or a constant problem — your call.

Your token is stored locally and is never shown or sent anywhere else.

### Why you'd turn it on

Because a run stops being a solo performance. Chat can bail you out of a bad fight
or push you into one, and either way they are *in* the run rather than watching it.
Viewers who type something and see it happen four frames later stay.

### What chat can do

**Help you**

`!heal` restore life · `!mp` restore magic · `!1up` an extra life ·
`!invuln` brief invulnerability · `!protect` `!shield` `!reflect` grant a spell
effect · `!fairy` `!cucco` `!arise` summon help · `!freeze` freeze every
non-boss enemy on screen · `!smite` kill every non-boss enemy on screen

**Hurt you**

`!hurt` damage · `!drain` drain magic · `!steal` takes one of your items and gives
it back later · `!curse` a slow non-lethal HP drain · `!slow` slow you to a walk ·
`!spawn <enemy> <n>` drop a named enemy next to you · `!swarm` a pack of random
enemies around you

**Mess with your head**

`!confuse` swaps left and right · `!flip` mirrors the screen · `!dark` kills the
lights · `!disco` colour-cycling overlay · `!party` disco and flip together ·
`!shrink` `!grow` resize Link · `!speed` make him too fast to control ·
`!flame` `!heckler` spawns a jumping flame tagged with the viewer's name ·
`!music` reshuffle the soundtrack mid-run

### VS CHAT mode

Turn this on and it stops being a favour economy. **Chat's goal is to kill you.**

Every helpful command is blocked — no healing, no magic, no extra lives, no
shields, no invulnerability, no summons. Anyone who tries gets told it was blocked.
Only the things that hurt you still work.

The game keeps score. Every death is a point **to chat**, shown on the stream
tracker as their running total. It does not reset when you do.

It is deliberately a *block* list rather than an allow list, so any hostile
command added later works in VS mode the day it ships.

---

## Options

**DISPLAY** — smooth, sharp, pixel-perfect, crisp-fill, CRT, or scanlines.
Fullscreen and window scale.

**AUDIO** — separate music and sound volume, and several music sets including a
mix of NES arrangements. Set music to RANDOM for a different soundtrack each time.

**CONTROLS** — rebind everything. Calibrate a gamepad.

---

## Two Players

A second player can join as a **fairy** — a helper who can reach what Link cannot
and lend a hand in a fight. Plug in a second controller and enable co-op in options.

---

## Dev Mode

The development tools ship present but switched off, so nobody wanders into a
palette editor by accident.

To turn them on: enter **B B A A UP DOWN UP DOWN**, or put an empty file named
`dev_unlock.txt` in `%LOCALAPPDATA%\ZALiA\`. Delete it to switch them back off.

Unsupported, and quite capable of breaking your own save. It is there for
debugging.

---

## Credits

Original game by **HoverBat** — [ZALiA](https://github.com/ZA-LiA/ZALiA).
GameMaker 2026 port and additional features by **GAINEY**, with design and
playtesting by **LANEAGE**.

*Zelda II: The Adventure of Link* and related marks are trademarks of **Nintendo**.
This is a non-commercial fan project, not affiliated with or endorsed by Nintendo,
and is not sold.

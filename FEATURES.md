# What this port adds

ZALiA is **HoverBat's** game. This page is only about what the GameMaker 2026
port changed or added on top of it — so you can tell the two apart, and so credit
lands where it belongs.

If you want the original, it is at https://github.com/ZA-LiA/ZALiA.

> **Not ours, to be clear:** the game itself, its design, its cast, the cucco spell
> replacing *Zelda II*'s fairy, the towns, the palaces, the story — all HoverBat.
> Everything below is the port layer on top. The [manual](MANUAL.md) documents the
> whole game, his work included, because it never had one.

---

## Randomizer

Every setting is **per save file**, chosen when you create it. Two files can be
completely different quests.

| What | Notes |
|---|---|
| **Item locations** | major items shuffled across the world |
| **Spell locations** | which wise man teaches what |
| **Town locations** | towns swap places on the overworld |
| **Palace locations** | which palace sits where |
| **Palace bosses** | bosses shuffled between palaces |
| **Dungeon tilesets** | palaces get each other's look |
| **Enemy spawns** | who shows up where, plus difficulty, HP and damage scaling |
| **Overworld biomes** | the terrain itself |
| **Key locations** | including whether keys can hide outside palaces |
| **Start-with spells** | begin holding spells you would normally earn |

### Two hint systems

**Boulder hints** — in *every* game mode, not just randomizer. The boulder circle
is a puzzle: push them in the right order and something opens. Townsfolk tell you
the order, one step each.

**Item hints** — randomizer only. Villagers tell you where specific items ended
up, **in their own words** — "the ring is in a seaside cave" rather than a
generated area label. The count of hints still out there is shown in-game and on
the tracker. Switch them off at file creation if you would rather find everything
yourself.

Town **signs keep their original names** even when towns move, so you always know
which location you are standing in.

---

## Stream tracker

A browser page the game serves itself, built to be read **at a glance, across a
room**, at about 460 px wide as an OBS Browser Source.

- Every item, spell, technique, container, key and crystal — lit or unlit
- **Palace ledger** — one cell per palace: crystal placed, keys found/held/total, cleared
- Heart and magic containers as notch bars, not a wall of pips
- **Live spell state** — which spell is selected, which are currently active
- Filled bottle, gold slime (kakusu) counter with the total *your* seed needs
- Your hints, with the item's own sprite and the villager's wording
- VS CHAT score, if chat is playing against you
- **Five themes**, and `?obs=1` to drop the background so it composites over gameplay

Item art is the real NES sprite set at the correct palette, not approximations.

---

## Twitch integration

Viewers affect your run directly. Roughly fifty commands across helping,
hindering, and pure chaos — plus **VS CHAT mode**, where chat's only goal is to
kill you and every helpful command is blocked.

Full list and setup: **[TWITCH_SETUP.md](TWITCH_SETUP.md)**.

---

## Jukebox

Every track in the game, playable on demand from a browser page.

- Five playlists, real per-zone assignment
- Play in order, shuffle, or repeat one track
- Seek, volume, and what is playing right now
- Assign tracks by name so a playlist survives the track list changing

## Music

Thirty-plus tracks imported on top of the original set, including an NES-mix
soundtrack and a **RANDOM** mode that gives every run a different score.

A **TUNNELS** zone was split out so the fast-travel basements get their own theme
rather than sharing the town music. Imported loops are cut on the *measured* loop
point of the recording, so they repeat without a seam or a fade.

---

## Two-player co-op

A second player joins as a **fairy** — reaching what Link cannot and helping in a
fight. Plug in a second controller and enable it in options.

---

## Presentation and controls

**Display** — smooth, sharp, pixel-perfect, crisp-fill, CRT, or scanlines.
Fullscreen and window scale.

**Controllers** — full gamepad support, a calibration wizard, and rebindable
controls. Analog triggers behave properly.

**Quality of life** — low-HP beep, death counter, hint-NPC markers on the map,
compass labels on the boulder circle, and a THUNDER cast that actually looks like
lightning.

---

## The port itself

Moving a GameMaker:Studio 1.4 project to GameMaker LTS 2026 is not a
recompile. What that involved:

- **All 793 scenes and 112 overworld pages load crash-free.** Eight separate
  1.4→2026 crashes were tracked down, plus a root spawn-table bug that was
  causing several of them.
- **The 9.9-second fall stall is gone.** Entering a falling passage rebuilt the
  tile layers with an accidentally quadratic delete. Fall-scene loads are now
  around a tenth of a second, and verified across 29 scenes at 11–106 ms with no
  degradation on repeat.
- Teleporting enemies no longer strand in mid-air on multi-tier rooms — one case
  of that could make a run **unwinnable**.
- Enemy stun behaviour restored to match 1.4 rather than the port's regression.
- Graphics-effects menu no longer creates and frees a GUI surface every frame.

## Development tools

The game ships with its debugging instruments present but **switched off**, so a
player cannot wander into a palette editor or start a 793-room sweep by accident.
See the manual for how to turn them on if you want them.

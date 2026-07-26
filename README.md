# ZALiA - GameMaker 2026 Port (unofficial)

This is an **unofficial fork** of [**ZALiA** (*Zelda Again: Link is Adventuresome*)](https://github.com/ZA-LiA/ZALiA),
a *Zelda II: The Adventure of Link* fan game created by **HoverBat**.

This fork ports the original GameMaker:Studio 1.4 project to **GameMaker LTS 2026** and adds
additional features on top of it. It is **not** an official release, and it is **not** endorsed
by or affiliated with HoverBat or the ZALiA project.

For the original project, and for the official builds, go to the upstream repository above.

---

## Credits

**Original game**
- **HoverBat** - creator of ZALiA. All of the original design, code, and the GML translation
  of *Zelda II*'s assembly are his work. See [LICENSE](LICENSE).

**This port**
- **GAINEY** - GameMaker 2026 port, additional features
- **LANEAGE** - design ideas and playtesting

The upstream project's own credits (patrons, additional music and sound, special thanks, and
the original *Zelda II* staff) are preserved in the in-game ending credits and are not
reproduced here.

---

## What this fork adds

Ported from GameMaker:Studio 1.4 to GameMaker LTS 2026, plus:

- 2-player co-op ("fairy" helper for player 2)
- Twitch chat integration - viewers can trigger in-game effects
- Display options (smooth / sharp / pixel-perfect / crisp-fill / CRT / scanlines, fullscreen, window scale)
- NES jukebox with per-zone music modes
- Full gamepad support with an in-game calibration wizard and rebindable controls
- QOL and HUD additions (low-HP beep, death counter, hint-NPC map markers, boulder compass labels)
- A companion stream tracker
- Developer tooling: room/overworld sweep harness, mark-and-replay bug capture, dev overlays

Plus a range of gameplay and 1.4 -> 2026 port fixes.

---

## License

This project inherits the license of the original ZALiA project. See [LICENSE](LICENSE) -
a 4-clause BSD license, **Copyright (c) 2024, ZALiA. All rights reserved to the original code
author: HoverBat.**

That notice is retained here as required. Modifications made in this fork are the work of the
contributors listed under "This port" above.

### Third-party components

- **GameMaker** (YoYo Games) - engine
- **Tiled** - map/level editor used for scene data
- **Palette swap shader** by Pixelated Pope
- **GMSched** by Skyfloogle
- **SDL_GameControllerDB** (`datafiles/gamecontrollerdb.txt`) - controller mapping database

Each is covered by its own license and its own terms.

### Audio

Music and sound assets are third-party copyrighted works owned by their respective rights
holders. They are not licensed under this project's LICENSE, and no rights in them are
granted here.

### Fan project notice

*Zelda II: The Adventure of Link*, The Legend of Zelda, and all related characters, assets,
and trademarks are the property of **Nintendo**. This is a non-commercial fan project, is not
sold, and is not affiliated with or endorsed by Nintendo. HoverBat's license covers his own
code only - it grants no rights in Nintendo's intellectual property.

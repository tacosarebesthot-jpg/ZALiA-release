# clean_state fixture

## Purpose

This directory will hold a **golden-clean snapshot** of the save + preferences
files GameMaker/ZALiA writes to `%LOCALAPPDATA%\ZALiA\` on a fresh cold start
(no save progress, no rando run started). `Invoke-ZaliaTest.ps1` (or a future
restore helper) will copy these files back into `%LOCALAPPDATA%\ZALiA\` before a
run so every test starts from the same deterministic state, instead of
inheriting whatever a previous manual play session or sweep left behind.

**Nothing has been copied into this folder yet.** A crash-sweep is currently
running and mutating live files under `%LOCALAPPDATA%\ZALiA\` on this machine --
touching that directory right now would race the sweep and corrupt its run.
Capture the snapshot later, from a genuinely clean cold start, once nothing
else is writing to that directory.

## How to capture the snapshot (later, NOT now)

1. Confirm no Igor/Runner process is active and no sweep/bugprobe flag file is
   pending (`_autosweep.flag` / `_bugprobe.flag` absent, or harness idle).
2. Either:
   - Delete `%LOCALAPPDATA%\ZALiA\Save*` and the rando/scene siblings to force a
     true cold start, then launch the game once and let it write fresh
     defaults, OR
   - Use a save slot that is already known-clean (no items, no rando run).
3. Copy the exact files listed below from `%LOCALAPPDATA%\ZALiA\` into this
   directory (flat, no subfolders needed).
4. Note the source slot number(s) actually captured (1, 2, and/or 3) in this
   README so future readers know which slot(s) are "golden."

## Exact filenames to snapshot

For each save slot `N` you want a golden copy of (slot 1 is the common case,
but capture whichever slot(s) the test harness is expected to use):

```
SaveFile_N.txt
SaveFile_N_RandoDungeonTilesetData.txt
SaveFile_N_Rando_Data.txt
SaveFile_N_Rando_Spoiler.txt
```

**A save file is meaningless without its rando siblings.** The randomizer
seeds dungeon layouts, item placement, and the spoiler log into the three
`*_Rando_*` / `*RandoDungeonTilesetData*` files alongside `SaveFile_N.txt`.
Restoring `SaveFile_N.txt` alone without its matching siblings will desync the
save from its own world layout. Always copy all four files for a slot
together, from the same capture moment, and never mix siblings from different
capture sessions.

Also snapshot (shared, not per-slot):

```
UserPreferences.txt
```

### Files intentionally NOT part of this fixture

`AppData01.txt`, `PaletteData01.txt`, `SceneData01.txt`, `SceneWallData01.txt`,
and the harness-owned `screen_check\`, `bugprobe\`, `problems\`,
`custom_dungeon_graphics\`, `custom_playercharacter_graphics\` directories are
either harness output (regenerated every run, not test input) or global engine
state not specific to a save slot. Do not snapshot these here unless a future
test scenario specifically needs one of them reproduced too -- if so, document
it in this file when added.

## CAVEAT: global palette leak in UserPreferences.txt

`UserPreferences.txt` is **not scoped per save slot** -- it holds a
cross-save palette flag (and likely other global display/options state) that
persists independently of which `SaveFile_N` is active. This means:

- Restoring a golden `UserPreferences.txt` can silently change palette/display
  state for ALL save slots, not just the one under test.
- If a test run (or a manual play session) changes the palette setting, that
  change leaks forward into the next run even if the save files themselves are
  reset to golden -- restoring only `SaveFile_N*` without also restoring
  `UserPreferences.txt` will NOT undo a palette change.
- When capturing the golden snapshot, capture `UserPreferences.txt` at the same
  moment as the save files so the pairing is consistent, and restore it
  together with the save files every time for true determinism.

## Planned layout once populated

```
test\fixtures\clean_state\
  README.md                              (this file)
  SaveFile_1.txt
  SaveFile_1_RandoDungeonTilesetData.txt
  SaveFile_1_Rando_Data.txt
  SaveFile_1_Rando_Spoiler.txt
  UserPreferences.txt
```

(Additional `SaveFile_2*` / `SaveFile_3*` sets may be added the same way if a
test scenario needs more than one golden slot.)

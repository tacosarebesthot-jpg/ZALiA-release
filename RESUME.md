# ZALiA — Resume Notes (2026-06-21)

Repo: https://github.com/gainey666/ZALiA (private), branch `main`, all work pushed as of this doc.
Local working copy on this machine: `C:\Users\imme\GameMakerProjects\ZALiA`. Build cache warm at `C:\temp\zalia_cache` (not portable to a new machine — first build on the VM will be a cold/full build).

## What's done (commits, newest first)

- `7b6ab4da` **feat: extend Dev_RmWarper sweep tooling to cover the overworld** — see "In progress" below, this is UNVALIDATED.
- `2095ce77` chore: Dev_RmWarper note-typing input guard (sweep note overlay swallows hotkeys while typing).
- `03d1c226` **fix: resolve root spawn-table bug and clear resulting GMS1.4->GMS2 crashes** — the big one. `RoomData_Create` was loading a stale GMS1.4-baked spawn cache instead of rebuilding from the name-based `rm_data_init_*` scripts, so locked doors/NPCs spawned in place of real enemies almost everywhere. Fixed at the source (`_REINITIALIZING=true`) plus a `data_spawn` fix (string modifier args were corrupting numeric data slots). Several dormant port bugs that the wrong spawns had been masking are also fixed here (missing `global.pc` existence guards in cutscene-only scenes, a zero-size `surface_create`, an out-of-bounds grid read, etc).
- `9a50802d` / `3755a094` (older session) — dev harness + the original 8 GM1.4->GMS2 crash fixes.

**Verified result:** the 793-scene Action-room sweep (all dungeons + towns: WestA, EastA, MazIs, PalcA–H, TownA, TownB, DthMt) completes 793/793 with **zero crashes**, using the *correct* spawn table. This was confirmed with a full headless Igor run before the overworld work started.

Not part of this work, left as-is: `scripts/PauseMenu_udp/PauseMenu_udp.gml` has an uncommitted `$1->$0` local edit — pre-existing, not mine, intentionally not committed.

## IDE state (Feather panel) — not a concern

GameMaker's Feather panel showed "27 [warnings], 906 suggestions" — looked alarming but isn't:
- **27 warnings** = all `GM1017`, deprecated tile functions (`layer_tile_destroy`, `tile_get_*`, etc.). Already known/deferred (see project memory `zalia_git_and_port_status`), non-breaking.
- **906 suggestions** = all `GM2047` "Unreachable code", lowest severity, informational only — dead code after early `exit;`/`break;` left over from the original GM1.4 source. Not bugs.
- **0 actual errors.**

## In progress / what to do next on the VM

The overworld (`room_type=="C"`, a single continuous 256x256-tile grid, completely separate from the dungeon/town "Action room" scenes) was **never covered by any sweep** — confirmed by reading the code (`g.dl_AREA_NAME` only lists the Action-room areas). Towns themselves WERE already covered (88 TownA + 10 TownB screenshots in the 793/793 clean run) — they just looked indistinguishable while watching because of the known black-screenshot capture bug (see below).

To close that gap I added an overworld page-sweep to `Dev_RmWarper` (commit `7b6ab4da`):
- `sweep_build_list_ow()` — scans `global.OVERWORLD.dg_tsrc` for the populated bounding box, tiles it into non-overlapping viewport-sized pages.
- `sweep_warp_to_ow()` — repositions within the already-loaded Overworld room (sets `pcrc` + calls `Overworld_refresh_tiles()` directly — no room reload needed page-to-page).
- `sweep_start_ow()` — chains in automatically after the RM (town/dungeon) sweep finishes: triggers one room transition into the Overworld via an exit name containing `"Ovrw"` (`area_is_ow()` routes it), then `Dev_RmWarper_Room_Start` positions page 0 once that room actually loads.
- `sweep_start_ow_manual()` — F9 while already standing in the overworld, no autosweep needed.
- `_DONE.txt` / `game_end()` now only fire after **both** the RM and OW passes complete.

**This is untested.** A validation run (headless Igor build+run with `_autosweep.flag` set) was kicked off and was still mid-RM-sweep (around the DthMt area) when I had to save and hand off. It had not yet reached the new overworld code path.

### First thing to do on the VM
1. Build the project once (cold cache, will be slow the first time).
2. Set `_autosweep.flag` in `%LOCALAPPDATA%\ZALiA\` (clear `screen_check/crashes.txt`, `_DONE.txt`, `_progress.txt` first), run headless via Igor (see `zalia_screencheck_tool` memory for the exact command — same pattern as `Igor --project=...ZALiA.yyp --rp=<runtime> -r=VM -- Windows Run`).
3. Watch `_progress.txt` — once it shows lines like `try OW_00xx` you're in the new code. Check `crashes.txt` and `_DONE.txt` when it finishes.
4. If it crashes in the OW code itself (not in-game GML), most likely suspects: `Exit_construct`/`area_is_ow` routing not actually landing in `rmC_Overworld_A` as expected, or `global.OVERWORLD.dg_tsrc` not yet populated when `sweep_build_list_ow()` runs (would return 0 pages and just finalize — check `_DONE.txt` for `"DONE OW 0/0"` as the tell).
5. Once it runs clean, the deliverable is the same as the dungeon sweep: `screen_check/_OW_XXXX.png` files you (or I) can visually review for port glitches, and a `crashes.txt` to iterate on if anything broke.

### Known separate issue (lower priority, not started)
`screen_check/*.png` screenshots are HUD-only/black — world isn't composited into the screenshot during the sweep (camera/surface-blit timing issue, not a load failure — `scene_report.txt` proves content loads fine everywhere). Affects both the RM and now presumably the OW screenshots too. See `zalia_screencheck_tool` memory for details (`SWEEP_SETTLE_FRAMES` tuning, `g.surf` blit timing) — needs its own fix before a real visual-glitch QA pass is possible.

## Quick reference
- Real project dir: `C:\Users\imme\GameMakerProjects\ZALiA` (NOT `C:\dev_stack\ZALiA`, which is the old GMS1.4 `.gmx` source kept for reference only).
- Igor.exe: `C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23\bin\igor\windows\x64\Igor.exe`
- Sweep output: `%LOCALAPPDATA%\ZALiA\screen_check\` (+ `problems\` for F10-flagged manual notes)
- Full harness details, hotkeys, and crash-hunt history: project memory files `zalia_screencheck_tool`, `zalia_object_index_remap`, `zalia_git_and_port_status`.

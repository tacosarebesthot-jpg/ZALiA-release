# ZALiA — Resume Notes (2026-06-21)

Repo: https://github.com/gainey666/ZALiA (private), branch `main`, all work pushed as of this doc.
Working copy is now the VM clone at `C:\Users\osrs-lab\GameMakerProjects\ZALiA` (GameMaker LTS 2026 + runtime-2026.0.0.23 installed; Igor builds fine without signing in — user folder is `unknownUser`). The old `C:\Users\imme\...` copy is gone.

> **UPDATE 2026-06-21 (VM session):** the overworld sweep is now **VALIDATED** — full headless run is **RM 793/793 + OW 112/112, zero crashes**. Three real bugs were found and fixed getting there (commits `ecf6e975`, `6e4f5693`, below). See "Overworld sweep — VALIDATED" below.

## What's done (commits, newest first)

- `6e4f5693` **fix: two crashes in the overworld page-sweep tooling** — (1) `Dev_RmWarper_Draw` status label concatenated an int OW page-anchor as a string (`DoAdd`); (2) `sweep_warp_to_ow` edge pages read `dg_tsrc` past the 256-wide grid → undefined → `DoConv` in `Overworld_refresh_tiles`. Now formats per mode + clamps the page origin to the grid.
- `ecf6e975` **fix: destroy half-initialized GOB1 instances on spawn bail-out** — REAL gameplay bug (not just harness). `GameObject_create` creates the instance + runs generic init1 (`can_draw_self=true`) before `scr_init2`; the two early `return noone` paths (quest-num not qualified; GOB1 update-list full / fairy encounter) left a drawable zombie whose `init2` never ran. The corrected spawn table (`03d1c226`) overflowed the GOB1 list in PalcG_1C → a never-init2'd `Bot_A` → `Bot_draw` read unset `eyes_yoff` → fatal crash that had stalled the sweep at PalcG_1C. Now destroys the instance on bail (Destroy event suppressed). Systemic — protects every GOB1 enemy.
- `7b6ab4da` **feat: extend Dev_RmWarper sweep tooling to cover the overworld** — now VALIDATED (was untested at hand-off); the two crashes above were in this code/this code's interaction with the OW renderer.
- `2095ce77` chore: Dev_RmWarper note-typing input guard (sweep note overlay swallows hotkeys while typing).
- `03d1c226` **fix: resolve root spawn-table bug and clear resulting GMS1.4->GMS2 crashes** — the big one. `RoomData_Create` was loading a stale GMS1.4-baked spawn cache instead of rebuilding from the name-based `rm_data_init_*` scripts, so locked doors/NPCs spawned in place of real enemies almost everywhere. Fixed at the source (`_REINITIALIZING=true`) plus a `data_spawn` fix (string modifier args were corrupting numeric data slots). Several dormant port bugs that the wrong spawns had been masking are also fixed here (missing `global.pc` existence guards in cutscene-only scenes, a zero-size `surface_create`, an out-of-bounds grid read, etc).
- `9a50802d` / `3755a094` (older session) — dev harness + the original 8 GM1.4->GMS2 crash fixes.

**Verified result (VM, 2026-06-21):** a full headless Igor run completes **RM 793/793 + OW 112/112 with zero crashes** (`_DONE.txt` = `DONE OW 112/112`, no `crashes.txt`). RM covers all dungeons + towns (WestA, EastA, MazIs, PalcA–H, TownA, TownB, DthMt); OW covers the 256×256 overworld tiled into 112 viewport pages.

Note: `scripts/PauseMenu_udp/PauseMenu_udp.gml` had an uncommitted `$1->$0` edit on the old machine — it is NOT in the VM clone (was never committed), so it's effectively gone. Re-apply from the old machine if it mattered.

## IDE state (Feather panel) — not a concern

GameMaker's Feather panel showed "27 [warnings], 906 suggestions" — looked alarming but isn't:
- **27 warnings** = all `GM1017`, deprecated tile functions (`layer_tile_destroy`, `tile_get_*`, etc.). Already known/deferred (see project memory `zalia_git_and_port_status`), non-breaking.
- **906 suggestions** = all `GM2047` "Unreachable code", lowest severity, informational only — dead code after early `exit;`/`break;` left over from the original GM1.4 source. Not bugs.
- **0 actual errors.**

## Overworld sweep — VALIDATED (2026-06-21)

The overworld (`room_type=="C"`, a single continuous 256x256-tile grid, completely separate from the dungeon/town "Action room" scenes) was **never covered by any sweep** — confirmed by reading the code (`g.dl_AREA_NAME` only lists the Action-room areas). Towns themselves WERE already covered (88 TownA + 10 TownB screenshots in the 793/793 clean run) — they just looked indistinguishable while watching because of the known black-screenshot capture bug (see below).

To close that gap I added an overworld page-sweep to `Dev_RmWarper` (commit `7b6ab4da`):
- `sweep_build_list_ow()` — scans `global.OVERWORLD.dg_tsrc` for the populated bounding box, tiles it into non-overlapping viewport-sized pages.
- `sweep_warp_to_ow()` — repositions within the already-loaded Overworld room (sets `pcrc` + calls `Overworld_refresh_tiles()` directly — no room reload needed page-to-page).
- `sweep_start_ow()` — chains in automatically after the RM (town/dungeon) sweep finishes: triggers one room transition into the Overworld via an exit name containing `"Ovrw"` (`area_is_ow()` routes it), then `Dev_RmWarper_Room_Start` positions page 0 once that room actually loads.
- `sweep_start_ow_manual()` — F9 while already standing in the overworld, no autosweep needed.
- `_DONE.txt` / `game_end()` now only fire after **both** the RM and OW passes complete.

**Now validated** (see the three fix commits above). A full headless Igor run completed `DONE OW 112/112` with no `crashes.txt`. The OW pass chains in automatically after RM, transitions into `rmC_Overworld_A`, and tiles the populated bounding box into 112 pages, capturing `screen_check/_OW_<anchor>.png` per page.

### Exact run procedure (reproducible on the VM)
```
# 1. set the dev flag + clear stale output in the save dir
SC="$LOCALAPPDATA/ZALiA/screen_check"
del "$LOCALAPPDATA/ZALiA/screen_check/crashes.txt" _DONE.txt _progress.txt scene_report.txt   # clear first
type nul > "$LOCALAPPDATA/ZALiA/_autosweep.flag"                                                # arm autosweep

# 2. headless build+run (Igor). DEV macro must be true (it is: scripts/macros/macros.gml).
Igor.exe /project=...\ZALiA.yyp /rp=...\runtime-2026.0.0.23 -v -- Windows Run
```
- Igor.exe: `C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23\bin\igor\windows\x64\Igor.exe`
- Watch `screen_check/_progress.txt`: `try _<Area>_<rm>` lines = RM pass, `try OW_<hex>` lines = OW pass. Done when `_DONE.txt` shows `DONE OW <n>/<n>` and there is no `crashes.txt`.
- If `_DONE.txt` says `DONE OW 0/0`, `global.OVERWORLD.dg_tsrc` wasn't populated when `sweep_build_list_ow()` ran — the OW didn't load.

### Next: the screenshot black-capture bug (now the blocker for real visual QA)
The sweep runs clean, but the deliverable PNGs are still HUD-only/black (see below), so a visual port-glitch pass isn't possible yet. That's the next thing to fix.

### Known separate issue (lower priority, not started)
`screen_check/*.png` screenshots are HUD-only/black — world isn't composited into the screenshot during the sweep (camera/surface-blit timing issue, not a load failure — `scene_report.txt` proves content loads fine everywhere). Affects both the RM and now presumably the OW screenshots too. See `zalia_screencheck_tool` memory for details (`SWEEP_SETTLE_FRAMES` tuning, `g.surf` blit timing) — needs its own fix before a real visual-glitch QA pass is possible.

## Quick reference
- Real project dir (VM): `C:\Users\osrs-lab\GameMakerProjects\ZALiA` (cloned from the fork). NOT `Z:\dev_stack\ZALiA` / `Z:\dev_stack\zelda 2 shit`, which are old GMS1.4 `.gmx` source kept for reference only and are NOT the latest — the fork's `main` is canonical.
- Igor.exe: `C:\ProgramData\GameMakerStudio2-LTS2026\Cache\runtimes\runtime-2026.0.0.23\bin\igor\windows\x64\Igor.exe`
- Sweep output: `%LOCALAPPDATA%\ZALiA\screen_check\` (+ `problems\` for F10-flagged manual notes)
- Full harness details, hotkeys, and crash-hunt history: project memory files `zalia_screencheck_tool`, `zalia_object_index_remap`, `zalia_git_and_port_status`.

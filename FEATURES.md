# What this port adds

**ZALiA is HoverBat's game.** This page separates his work from the port layer on
top of it, so credit lands where it belongs.

**Version 2.0** — based on upstream ZALiA 1.7.12.02.

It is not written from memory. It is a **file-level diff against
[HoverBat's repository](https://github.com/ZA-LiA/ZALiA)** — anything present
upstream is his, and only what is genuinely new here is claimed below.

| | Upstream (HoverBat) | This port | New |
|---|---|---|---|
| Scripts | 1,901 | 2,025 | **124** |
| Objects | 313 | 317 | **4** |
| Sounds | 498 | 592 | **94** |

**Nothing was removed.** All 1,901 of his scripts are still here.

---

## His, not ours

Worth stating plainly, because these are the parts people notice:

**The randomizer** — every setting, the logic, the item and spell shuffling, the
hint system. **The cucco spell** replacing *Zelda II*'s fairy. **The gold slimes
(kakusu).** **The palette editor**, **the room warper**, **the graphics effects
system**. The towns, the palaces, the enemies, the story, the art, and the GML
translation of *Zelda II*'s assembly that the whole thing rests on.

If you enjoy ZALiA, that is HoverBat's game you are enjoying.

---

## Ours

### Twitch chat integration
`twitch_apply`, `twitch_irc_*`, `twitch_poll`, `twitch_tick`, `twitch_config_save`,
`obj_twitch_irc`, `obj_twitch_fairy`, `OptionsMenu_Twitch_*`

Around fifty chat commands, plus **VS CHAT mode** where chat's goal is to kill the
runner and every helpful command is blocked, with a death scoreboard.
See **[TWITCH_SETUP.md](TWITCH_SETUP.md)**.

### The web companion server
`obj_zalia_web`, `zweb_open_page`, `tracker_state_write`, `icon_export`

The game serves its own pages on `127.0.0.1:8777`, loopback only — the **stream
tracker** built for OBS in five themes, the **jukebox**, and the **Twitch setup**
page.

### The in-game tracker window
`TrackerWin_init/_fill/_put/_draw/_step/_extern`

### Jukebox
`jukebox_init`, `_play`, `_build_playlist`, `_build_playlist_external`,
`_build_set_map`, `_assign`, `_assign_zone`, `_zone_themes`, `_export_list`,
`_poll_cmd`, `_playlist_name`

Five playlists with real per-zone assignment, order/shuffle/repeat-one. **Playlist
five plays your own `.ogg` files** from `%LOCALAPPDATA%\ZALiA\music\` with no
importing at all.

### Two-player co-op
`Input_update_p2`, `obj_fairy_p2`, `spawn_fairy_proj`, `Dev_CoopTest_Step`

A second player joins as a fairy.

### Options menus
`OptionsMenu_Display_*`, `_Color_*`, `_Misc_*`, `_Overlays_*`, `_Cheats_*`,
`_Sweeps_*`, `_TestCap_*`, `apply_display_mode`

Display filters (smooth / sharp / pixel-perfect / crisp-fill / CRT / scanlines),
fullscreen and window scale, colour options, and the menus behind them.

### Music
**94 new sound assets** — an NES-mix soundtrack, a RANDOM mode that scores every
run differently, and a **TUNNELS** zone split out so the fast-travel basements no
longer share the town theme. Imported loops are cut on the measured loop point of
the recording, so they repeat without a seam.

### Dev-tool gating
`dev_avail`, `konami_check`

HoverBat's development tools are excellent and stay in the build — but a player
could previously wander into the palette editor or start a 793-room sweep by
accident. They are now behind an unlock.

### Testing and diagnostics
`tas_rec_*`, `tas_apply_held`, `tas_draw_overlay`, `mark_dump_replay`,
`mark_replay_load`, `playlog_write`, `gp_diag_overlay`, `Dev_Bugprobe_*`,
`test_exit_automation`, `test_startup_exit_audit`, `debug_exit_audit_traversal`

Input recording and replay, a bug-marking system that captures a screenshot plus
scene, coordinates and recent inputs, gamepad diagnostics, and automated sweeps
that walk every room in the game looking for crashes.

### Odds and ends
`thunderbolt_draw` / `thunderbolt_spawn` — a THUNDER cast that draws real
lightning. `mob_teleport_ground_y` — the fix for a mid-air teleport that could make
a run unwinnable. `walktune_panel` / `walktune_save`, `Overworld_refresh_edge`.

---

## The port itself

Most of the effort, and the least visible. GameMaker removed a large part of the
1.4 API, so a chunk of those 124 scripts are **reimplementations of functions that
no longer exist**:

`tile_add`, `tile_delete`, `tile_layer_*`, `tile_get_*`, `tile_set_*`,
`background_add`, `background_assign`, `background_get_*`, `draw_background*`,
`__init_view`, `__view_get/_set`, `__init_background`, `__background_*`,
`instance_create`, `object_get_depth`, `sound_get_name`, `room_set_view`,
`room_tile_clear`, `__global_object_depths`, `__init_global`

On top of that:

- **All 793 scenes and 112 overworld pages load crash-free** — eight separate
  1.4→2026 crashes, plus a root spawn-table bug behind several of them
- **The 9.9-second fall stall is gone.** Entering a falling passage rebuilt tile
  layers with an accidentally quadratic delete. Now 11–106 ms, measured across 29
  scenes with no degradation on repeat
- Enemy stun behaviour restored to match 1.4 rather than the port's regression
- Item-pickup invulnerability scoped correctly to held-over-head items
- Graphics-effects menu no longer rebuilds a GUI surface every frame

---

## Documentation

The [manual](MANUAL.md), this page and the [Twitch guide](TWITCH_SETUP.md) are
new. They document the **whole game**, HoverBat's work included, because it never
shipped with a manual.

---

*Miscredited something? That is a bug worth reporting. Verify any claim here by
diffing this repository against https://github.com/ZA-LiA/ZALiA yourself.*

---

**ZALiA 2.0** &middot; [Download](https://github.com/tacosarebesthot-jpg/ZALiA-release/releases/latest) &middot; [Manual](MANUAL.md) &middot; [Twitch setup](TWITCH_SETUP.md) &middot; [Discord](https://discord.gg/FSphHEsu8D)

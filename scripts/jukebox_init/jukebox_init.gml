/// @description  jukebox_init()
// ============================================================================
// NES-MUSIC JUKEBOX: one-time model init. Called from g_Create() near the
// other globals. Play-safe (NOT DEV-gated) -- the whole jukebox is gated on
// its OWN state (global.jukebox_on), never on DEV.
//
// Reversible: delete this script (+ its yyp/.yy entry), the call in
// g_Create(), and the jukebox blocks in Surface_Draw_GUI_End().
//
// Builds:
//   global.jukebox_on        - is jukebox MODE active (overrides area music)
//   global.jukebox_idx       - current track index 0..count-1
//   global.jukebox_count     - 56
//   global.jukebox_names[]   - display names (built by jukebox_build_playlist)
//   global.jukebox_assets[]  - resolved sound asset indices (-1 if missing)
//   global.jukebox_inst      - currently-playing jukebox audio instance (0=none)
//   global.jukebox_assignments - ds_map of theme -> "track | name" (assign log)
//   global.jukebox_msg / _timer - brief on-screen confirmation line
// ============================================================================
function jukebox_init() {

	global.jukebox_on    = false; // jukebox MODE off by default (normal area music plays)
	global.jukebox_idx   = 0;     // selected track 0..count-1
	global.jukebox_count = 0;     // real count comes from jukebox_build_playlist() below
	global.jukebox_inst  = 0;     // last audio instance we started (0 = none)

	global.jukebox_names  = [];
	global.jukebox_assets = [];

	// Populate from the actual audiogroup rather than the old hard-coded
	// mus_NESJUKE_001..056 scan (those assets were byte-identical re-imports of tracks
	// already present under readable names, and have been removed). Building here rather
	// than only on the F-toggle keeps jukebox_count > 0 from game start, which the
	// twitch "!music" verb relies on before the player ever opens the jukebox.
	jukebox_build_playlist();

	// assignment log (theme -> "asset | friendly")
	global.jukebox_assignments = ds_map_create();

	// brief on-screen confirmation message ("ASSIGNED ..." etc.)
	global.jukebox_msg       = "";
	global.jukebox_msg_timer = 0;

	if (DEV) show_debug_message("[JUKEBOX] init: " + string(global.jukebox_count) + " tracks");

}

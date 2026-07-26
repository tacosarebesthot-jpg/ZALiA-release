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
// PLAYLISTS (2026-07-26). The jukebox listed every music asset in one flat list;
// with ~283 registered tracks plus the player's own imports that is unusable. These
// five views slice the same audiogroup by SET, except EXTERNAL which reads loose
// .ogg files off disk and never touches the project at all.
//
// Order matters: it is the cycle order on the playlist key, so it runs from the most
// familiar (HoverBat's original soundtrack) to the most personal.
enum JukeboxPL
{
    HOVERBAT_OG,   // set == _Default -- HoverBat's original soundtrack
    REMIXED_NES,   // every other HoverBat set (SteelCrescent, Wyng, Nikos, Isabelle, FDS, Zelda1...)
    MY_NESMIX,     // the player's own imports, registered under _NESmix
    EVERYTHING,    // all of the above plus unregistered standalones
    EXTERNAL,      // loose .ogg files in <working_directory>\music\ -- see jukebox_build_playlist_external
    COUNT
}

function jukebox_init() {

	global.jukebox_on    = false; // jukebox MODE off by default (normal area music plays)

	// Which playlist view is active. Cycled with the playlist key; rebuilding the
	// list is cheap enough to do on every change.
	global.jukebox_playlist = JukeboxPL.EVERYTHING;

	// Runtime streams owned by the EXTERNAL playlist. Held here so a playlist
	// switch can destroy them -- audio_create_stream leaks otherwise.
	global.jukebox_streams  = [];

	// name -> set lookup, rebuilt by jukebox_build_set_map() on each playlist build.
	global.jukebox_set_of   = -1;
	global.jukebox_idx   = 0;     // selected track 0..count-1
	global.jukebox_count = 0;     // real count comes from jukebox_build_playlist() below
	global.jukebox_inst  = 0;     // last audio instance we started (0 = none)

	global.jukebox_names  = [];
	global.jukebox_assets = [];

	// AUTO-ADVANCE (2026-07-26): the jukebox used to play ONE track on loop forever. The
	// user wants it to behave like a real player -- play a track, then move to the next.
	// When true, jukebox_play() starts tracks NON-looping and the per-frame poll in
	// Surface_Draw_GUI_End advances when the instance stops. Set false for single-track
	// repeat. Safe by construction: Audio_update_2's room-music and boss-music restarts are
	// both gated on !global.jukebox_on (Audio_update_2.gml:42-45, 84-88), so the gap between
	// one track ending and the next starting can never let area music grab the channel.
	global.jukebox_autoadvance = true;

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

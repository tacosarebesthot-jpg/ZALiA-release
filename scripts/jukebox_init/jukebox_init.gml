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
//   global.jukebox_names[]   - friendly display names (jukebox_init_names)
//   global.jukebox_assets[]  - resolved sound asset indices (-1 if missing)
//   global.jukebox_inst      - currently-playing jukebox audio instance (0=none)
//   global.jukebox_assignments - ds_map of theme -> "track | name" (assign log)
//   global.jukebox_msg / _timer - brief on-screen confirmation line
// ============================================================================
function jukebox_init() {

	global.jukebox_on    = false; // jukebox MODE off by default (normal area music plays)
	global.jukebox_idx   = 0;     // selected track 0..count-1
	global.jukebox_count = 56;
	global.jukebox_inst  = 0;     // last audio instance we started (0 = none)

	// friendly-name lookup (hard-coded from the manifest)
	global.jukebox_names = array_create(global.jukebox_count, "");
	jukebox_init_names();

	// resolve the 56 sound asset indices; guard -1 (missing/not-yet-imported asset)
	global.jukebox_assets = array_create(global.jukebox_count, -1);
	var _i = 0;
	var _missing = 0;
	repeat(global.jukebox_count)
	{
	    var _nnn = string(_i + 1);
	    if (_i + 1 < 100) _nnn = "0" + _nnn;
	    if (_i + 1 < 10)  _nnn = "0" + _nnn;
	    var _name = "mus_NESJUKE_" + _nnn;
	    var _idx  = asset_get_index(_name);
	    global.jukebox_assets[_i] = _idx; // asset_get_index returns -1 if the asset doesn't exist
	    if (_idx == -1) _missing++;
	    _i++;
	}

	// assignment log (theme -> "mus_NESJUKE_NNN | friendly")
	global.jukebox_assignments = ds_map_create();

	// brief on-screen confirmation message ("ASSIGNED ..." etc.)
	global.jukebox_msg       = "";
	global.jukebox_msg_timer = 0;

	if (DEV) show_debug_message("[JUKEBOX] init: " + string(global.jukebox_count) + " tracks, " + string(_missing) + " missing asset(s)");

}

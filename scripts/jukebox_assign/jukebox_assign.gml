/// @description  jukebox_assign()
// ============================================================================
// NES-MUSIC JUKEBOX: record "current area/theme -> current track" and APPEND
// it to <working_directory>jukebox_assignments.txt (working_directory =
// %LOCALAPPDATA%\ZALiA\). The dev reads/copies that file (e.g. via EXPORT_LOGS).
//
// Captures the live music context (Audio.rm_music_theme) + the selected track's
// asset name + friendly name. Stores into global.jukebox_assignments (ds_map,
// theme -> "asset | friendly") for in-session reference, and writes the log line.
//
// Fully guarded + try/catch wrapped (a file error can never throw). Shows a
// brief "ASSIGNED" confirmation. Play-safe + reversible.
// ============================================================================
function jukebox_assign() {

	// guard: model must be initialised
	if (!variable_global_exists("jukebox_idx"))   return;
	if (!variable_global_exists("jukebox_count")) return;
	if (!variable_global_exists("jukebox_names")) return;

	var _i = global.jukebox_idx;
	if (_i < 0 || _i >= global.jukebox_count) return;

	// resolve the current track's asset name from the live playlist slot
	var _asset_name = "?";
	if (variable_global_exists("jukebox_assets") && array_length(global.jukebox_assets) > _i)
	{
	    var _aid = global.jukebox_assets[_i];
	    if (_aid >= 0) _asset_name = audio_get_name(_aid);
	}

	var _friendly = "";
	if (array_length(global.jukebox_names) > _i) _friendly = string(global.jukebox_names[_i]);

	// capture the current music theme/context from the Audio object (guarded)
	var _theme = "?";
	if (instance_exists(Audio) && variable_instance_exists(Audio, "rm_music_theme"))
	{
	    _theme = string(Audio.rm_music_theme);
	}

	// store into the in-session assignment map (theme -> "asset | friendly")
	if (variable_global_exists("jukebox_assignments")
	&&  ds_exists(global.jukebox_assignments, ds_type_map))
	{
	    global.jukebox_assignments[? _theme] = _asset_name + " | " + _friendly;
	}

	// APPEND a log line to working_directory + jukebox_assignments.txt
	var _ts   = string(date_datetime_string(date_current_datetime()));
	var _line = "ASSIGN theme=" + _theme + " track=" + _asset_name + " name=" + _friendly + " ts=" + _ts;
	var _ok   = false;
	try
	{
	    var _f = file_text_open_append(working_directory + "jukebox_assignments.txt");
	    file_text_write_string(_f, _line);
	    file_text_writeln(_f);
	    file_text_close(_f);
	    _ok = true;
	}
	catch (_e) { _ok = false; }

	// brief on-screen confirmation
	if (variable_global_exists("jukebox_msg"))
	{
	    if (_ok) global.jukebox_msg = "ASSIGNED " + _theme + " <- #" + string(_i + 1);
	    else     global.jukebox_msg = "ASSIGN SAVE FAILED";
	    global.jukebox_msg_timer = 150;
	}

	if (DEV) show_debug_message("[JUKEBOX] " + _line + "  (ok=" + string(_ok) + ")");

}

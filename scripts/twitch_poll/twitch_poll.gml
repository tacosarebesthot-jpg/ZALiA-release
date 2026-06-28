/// @description  twitch_poll() -- drain the chat drop-queue and dispatch each command once.
// ============================================================================
// TWITCH integration -- PHASE A queue reader.
//
// The external bot writes one file per command into:
//     working_directory + "twitch_drop\\"   (== %LOCALAPPDATA%\ZALiA\twitch_drop\)
// each containing a single "verb|arg|who|dur" line. We read every pending file,
// dispatch it through twitch_apply(), and delete it (fire-once). Filenames are
// gathered BEFORE deleting so we never delete while the file_find iterator is
// open. Capped per poll so a flood can't stall the frame.
//
// No-op (single bool check) while global.tw_enabled is false.
// Dir-scan mirrors the custom-tileset scan in g_Create.gml:1770-1816.
// ============================================================================
function twitch_poll() {

	if (!variable_global_exists("tw_enabled") || !global.tw_enabled) return;

	var _PATH = working_directory + "twitch_drop\\";
	if (!directory_exists(_PATH))
	{
		directory_create(_PATH); // first run: create it, nothing to read this frame
		return;
	}

	// gather filenames first (don't mutate the dir while file_find is iterating)
	var _files = [];
	var _file  = file_find_first(_PATH + "*", 0);
	while (_file != "" && array_length(_files) < 16) // cap per-poll work
	{
		array_push(_files, _file);
		_file = file_find_next();
	}
	file_find_close();

	for (var _i = 0; _i < array_length(_files); _i++)
	{
		var _name = _files[_i];
		var _full = _PATH + _name;

		var _fh = file_text_open_read(_full);
		if (_fh == -1) continue;
		var _line = "";
		if (!file_text_eof(_fh)) _line = file_text_read_string(_fh);
		file_text_close(_fh);

		file_delete(_full); // fire-once: remove regardless of parse result

		if (_line == "") continue;

		var _parts = string_split(_line, "|");
		var _n     = array_length(_parts);
		if (_n < 1) continue;

		var _verb = _parts[0];
		var _arg  = (_n > 1) ? _parts[1] : "";
		var _who  = (_n > 2) ? _parts[2] : "";
		var _dur  = (_n > 3) ? _parts[3] : "";

		twitch_apply(_verb, _arg, _who, _dur);
	}
}

/// @description  playlog_write(_line)
/// @param _line
function playlog_write(_line) {


	// ============================================================
	// PLAYLOG -- "watch-me-play" text session logger  (added 2026-06-23)
	//   Cheap human-readable TEXT log of a normal play session so another
	//   engineer can "watch" what happened without screenshots. Default OFF;
	//   enabled by either the "_playlog.flag" file (checked once in g_Create)
	//   or the F3 key at runtime (Surface_Draw_GUI_End.gml). MUST work in a
	//   PLAY build where DEV==false -- gated ONLY on global.playlog_active,
	//   never on DEV. Mirrors the bugprobe harness's file-write idiom
	//   (Dev_Bugprobe_Step.gml's _bp_log) but as a REAL named script instead
	//   of an anonymous function-var, since anonymous function-vars in GML
	//   do NOT capture sibling locals and throw at call time (see that
	//   file's own comment on the lesson learned).
	//
	//   Robust by design: every external call (directory_create/file_text_*)
	//   is wrapped so a write failure (e.g. locked file, full disk, sandboxed
	//   working_directory) can never throw back into normal gameplay code.
	// ============================================================
	if (!variable_global_exists("playlog_active") || !global.playlog_active) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	try
	{
		directory_create(working_directory + "playlog");
		var _f = file_text_open_append(working_directory + "playlog/session.txt");
		file_text_write_string(_f, string(_line));
		file_text_writeln(_f);
		file_text_close(_f);
	}
	catch (_e)
	{
		// Never let a logging failure affect gameplay. Nothing else to do here.
	}


}

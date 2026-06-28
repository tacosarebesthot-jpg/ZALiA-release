/// @description  dev_bugprobe_quit_sink_log(_name)
function dev_bugprobe_quit_sink_log(_name) {


	// ============================================================
	// DEV BUG PROBE HARNESS -- PROBE STARTQUIT quit-sink logger  (added 2026-06-22)
	//   Called unconditionally (no DEV/flag check needed at call sites) from every
	//   sink that can end gameplay or return to the title: update_QuitAppMenu()'s
	//   two game_end() calls + its continuesave branch, ContinueSaveScreen_step()'s
	//   Option_SAVE/Option_QUIT branches, goto_title_rm(), and PauseMenu_GameEnd().
	//   No-ops entirely unless DEV is true AND the bugprobe flag is active, so it is
	//   inert in any normal/ship build or autosweep-only run.
	//
	//   Deliberately does NOT assume self==g (several call sites run as with(...)
	//   some other instance, e.g. with(g.QUIT_APP_MENU) inside update_QuitAppMenu,
	//   or self==PauseMenu inside PauseMenu_GameEnd) -- reads room/gui_state off the
	//   global "g" instance explicitly, same convention goto_title_rm() already uses.
	// ============================================================
	if (!(DEV && global.bugprobe)) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	directory_create(working_directory + "bugprobe");
	var _f = file_text_open_append(working_directory + "bugprobe/report.txt");
	file_text_write_string(_f, "QUIT_SINK " + _name + " room=" + room_get_name(room) + " gui_state=" + string(g.gui_state));
	file_text_writeln(_f);
	file_text_close(_f);


}

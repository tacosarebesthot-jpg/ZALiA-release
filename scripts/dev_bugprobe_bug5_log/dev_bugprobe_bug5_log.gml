/// @description  dev_bugprobe_bug5_log(_src_room, _exit_name, _target_room, _reen, _going_to_ow)
/// @param _src_room
/// @param _exit_name
/// @param _target_room
/// @param _reen
/// @param _going_to_ow
function dev_bugprobe_bug5_log(_src_room, _exit_name, _target_room, _reen, _going_to_ow) {


	// ============================================================
	// DEV BUG PROBE HARNESS -- PROBE BUG5 room-exit logger  (added 2026-06-22)
	//   Called from update_change_room_1a() (self==g there) right after the
	//   existing show_debug_message() lines (~line 320-321), one line per
	//   actual room change. Captures exactly the inputs that decide where a
	//   room exit sends the player, to chase the "2nd right-exit from
	//   _WestA_03 lands at North Castle instead of overworld" bug.
	//   No-ops entirely unless DEV is true AND the bugprobe flag is active
	//   (same gate as dev_bugprobe_quit_sink_log), so it's inert in any
	//   normal/ship build or autosweep-only run. LOGGING ONLY -- does not
	//   change any transition behavior.
	//
	//   Deliberately does NOT assume self==g (mirrors dev_bugprobe_quit_sink_log's
	//   convention) -- reads global.OVERWORLD.pcrc explicitly rather than via g.
	// ============================================================
	if (!(DEV && global.bugprobe)) exit; // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	var _pcrc_str = "n/a (not computed this transition)";
	if (_going_to_ow && instance_exists(global.OVERWORLD))
	{
		_pcrc_str = "$" + hex_str(global.OVERWORLD.pcrc);
	}

	directory_create(working_directory + "bugprobe");
	var _f = file_text_open_append(working_directory + "bugprobe/report.txt");
	file_text_write_string(_f, "PROBE BUG5: src_room=" + string(_src_room)
	      + "  exitName=" + string(_exit_name)
	      + "  target_room=" + string(_target_room)
	      + "  f.reen=" + string(_reen)
	      + "  GOING_TO_OW=" + string(_going_to_ow)
	      + "  OW.pcrc=" + _pcrc_str);
	file_text_writeln(_f);
	file_text_close(_f);


}

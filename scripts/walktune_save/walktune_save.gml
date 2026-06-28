/// @description  walktune_save()
function walktune_save() {

	// ============================================================================
	// WALKTUNE SAVE -- write the dialled-in values to <working_directory>walktune.txt
	// (== %LOCALAPPDATA%\ZALiA\walktune.txt, where the dev reads it from the VM).
	// Overwrites; one line; try/catch-wrapped so a file error can NEVER throw and
	// crash a play session. Sets global.walktune_msg + walktune_msg_timer so the
	// panel shows a brief "SAVED" / "ERR" confirmation. Called from the panel's
	// SAVE button and from the F11 shortcut. Reversible: delete with the panel.
	//
	// Line format:
	//   WALKTUNE smooth_pct=<0-100> speed=<n.nn> ts=<datetime>
	// ============================================================================

	// guarded reads of the tunables (defaults = shipping behaviour)
	var _pct = 100;
	if (variable_global_exists("ow_smooth_pct")) _pct = global.ow_smooth_pct;
	_pct = clamp(round(_pct), 0, 100);

	var _spd = 1.00;
	if (variable_global_exists("ow_speed_mult")) _spd = global.ow_speed_mult;

	var _ts   = string(date_datetime_string(date_current_datetime()));
	var _line = "WALKTUNE smooth_pct=" + string(_pct)
	          + " speed=" + string_format(_spd, 1, 2)
	          + " ts=" + _ts;

	var _ok = false;
	try
	{
		var _f = file_text_open_write(working_directory + "walktune.txt"); // overwrite
		file_text_write_string(_f, _line);
		file_text_writeln(_f);
		file_text_close(_f);
		_ok = true;
	}
	catch (_e)
	{
		_ok = false;
	}

	// confirmation message for the panel (guarded so it can't crash if globals absent)
	if (!variable_global_exists("walktune_msg"))       global.walktune_msg = "";
	if (!variable_global_exists("walktune_msg_timer")) global.walktune_msg_timer = 0;
	if (_ok) global.walktune_msg = "SAVED walktune.txt";
	else     global.walktune_msg = "SAVE FAILED";
	global.walktune_msg_timer = 150;

	return _ok;
}

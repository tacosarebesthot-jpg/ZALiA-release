/// @description  tas_rec_start()
function tas_rec_start()
{
	if (global.tas_pb_state == 1)
	{
	    show_debug_message("[TAS] refuse rec: playback active");
	    exit;
	}
	var _path = working_directory + "TAS_recording.txt";
	global.tas_rec_file = file_text_open_write(_path);
	if (global.tas_rec_file < 0)
	{
	    show_debug_message("[TAS] rec open FAILED: " + _path);
	    global.tas_rec_state = 0;
	    exit;
	}
	file_text_write_string(global.tas_rec_file, "ZTAS1");
	file_text_writeln(global.tas_rec_file);
	global.tas_rec_count = 0;
	global.tas_rec_state = 1;
	show_debug_message("[TAS] REC start -> " + _path);
}

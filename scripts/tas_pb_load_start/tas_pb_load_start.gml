/// @description  tas_pb_load_start()
function tas_pb_load_start()
{
	if (global.tas_rec_state == 1)
	{
	    show_debug_message("[TAS] refuse playback: recording active");
	    exit;
	}
	var _path = working_directory + "TAS_recording.txt";
	if (!file_exists(_path))
	{
	    show_debug_message("[TAS] playback: file missing " + _path);
	    exit;
	}
	if (ds_exists(global.dl_tas_pb, ds_type_list))
	{
	    ds_list_destroy(global.dl_tas_pb);
	}
	global.dl_tas_pb = ds_list_create();
	var _f = file_text_open_read(_path);
	if (_f < 0)
	{
	    show_debug_message("[TAS] playback open FAILED " + _path);
	    exit;
	}
	if (!file_text_eof(_f))
	{
	    var _hdr = file_text_read_string(_f);
	    file_text_readln(_f);
	}
	while (!file_text_eof(_f))
	{
	    var _s = file_text_read_string(_f);
	    file_text_readln(_f);
	    if (string_length(_s) > 0)
	    {
	        ds_list_add(global.dl_tas_pb, real(_s));
	    }
	}
	file_text_close(_f);
	global.tas_pb_count = ds_list_size(global.dl_tas_pb);
	global.tas_pb_index = 0;
	global.tas_pb_state = 1;
	show_debug_message("[TAS] PB start frames=" + string(global.tas_pb_count));
}

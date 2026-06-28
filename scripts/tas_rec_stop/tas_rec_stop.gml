/// @description  tas_rec_stop()
function tas_rec_stop()
{
	if (global.tas_rec_file >= 0)
	{
	    try
	    {
	        file_text_close(global.tas_rec_file);
	    }
	    catch (_e)
	    {
	    }
	}
	global.tas_rec_file = -1;
	global.tas_rec_state = 0;
	show_debug_message("[TAS] REC stop, frames=" + string(global.tas_rec_count));
}

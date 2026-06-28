/// @description  tas_rec_append(_packed)
function tas_rec_append(_packed)
{
	if (global.tas_rec_file < 0)
	{
	    exit;
	}
	file_text_write_string(global.tas_rec_file, string(_packed));
	file_text_writeln(global.tas_rec_file);
	global.tas_rec_count++;
}

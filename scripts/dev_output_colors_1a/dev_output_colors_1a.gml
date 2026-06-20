/// @description  dev_output_colors_1a()
function dev_output_colors_1a() {

	// output all dl_color values in hex


	var _i, _str, _count;


	repeat(4) sdm("");
	_count = ds_list_size(p.dl_COLOR);
	for(_i=0; _i<_count; _i++) // each possible color
	{
	    _str  = color_str(p.dl_COLOR[|_i]);
	    _str  = "dl_COLOR[|$"+hex_str(_i)+"] = $"+_str+", ";
	    _str += "Luminosity: $"+hex_str(colour_get_value(p.dl_COLOR[|_i]));
	    _str += ", Brightness $"+hex_str(get_color_brightness(p.dl_COLOR[|_i]));
	    _str += ";      // ";
	    if!(_i&$F) sdm("");
	    sdm(_str);
	}




	repeat(4) sdm("");
	_count = ds_list_size(global.dl_COLOR01);
	for(_i=0; _i<_count; _i++) // each possible color
	{
	    _str  = color_str(global.dl_COLOR01[|_i]);
	    _str  = "global.dl_COLOR01[|$"+hex_str(_i)+"] = $"+_str+", ";
	    _str += "Luminosity: $"+hex_str(colour_get_value(global.dl_COLOR01[|_i]));
	    _str += ", Brightness $"+hex_str(get_color_brightness(global.dl_COLOR01[|_i]));
	    _str += ";      // ";
	    if!(_i&$F) sdm("");
	    sdm(_str);
	}


	repeat(4) sdm("");







}

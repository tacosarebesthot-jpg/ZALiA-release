/// @description  color_str(color)
/// @param color
function color_str(argument0) {


	if (is_string(argument0))
	{
	    return string_repeat("0", 6-string_length(argument0)) + argument0;
	}


	var _i, _byte;
	var _return = "";

	for(_i=2; _i>=0; _i--)
	{
	    _byte  = argument0>>(_i<<3);
	    _byte &= $FF;
	    _return += hex_str(_byte);
	}


	return _return;







}

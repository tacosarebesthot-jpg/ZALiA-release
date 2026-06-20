/// @description  hexStr(number, *number..)
/// @param number
/// @param  *number..
function hexStr() {
	// Takes a number & returns it as a hex string

	var _return = "";

	for(var _i=0; _i<argument_count; _i++)
	{
	    _return += hex_str(argument[_i]);
	}


	return _return;




}

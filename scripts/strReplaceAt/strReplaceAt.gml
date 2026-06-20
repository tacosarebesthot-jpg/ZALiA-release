/// @description  strReplaceAt(str, position, delete count, insert str)
/// @param str
/// @param  position
/// @param  delete count
/// @param  insert str
function strReplaceAt(argument0, argument1, argument2, argument3) {

	// str          = argument0;
	// position     = argument1;
	// delete count = argument2;
	// insert str   = argument3;


	var _LEN1 = string_length(argument0);
	if(!_LEN1) return argument0;

	argument1 = min(argument1, _LEN1);              // position
	argument2 = min(argument2,(_LEN1+1)-argument1); // delete count
	return string_insert(argument3, string_delete(argument0,argument1,argument2), argument1);







}

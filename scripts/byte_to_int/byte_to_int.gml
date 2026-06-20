/// @description  byte_to_int(byte)
/// @param byte
function byte_to_int(argument0) {


	return (argument0&$FF) - ((argument0&$80)<<1);







}

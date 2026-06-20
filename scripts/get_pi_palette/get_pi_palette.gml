/// @description  get_pi_palette(palette data, palette index of palette data)
/// @param palette data
/// @param  palette index of palette data
function get_pi_palette() {


	return string_copy(argument[0], (global.PAL_CHAR_PER_PAL*argument[1])+1, global.PAL_CHAR_PER_PAL);







}

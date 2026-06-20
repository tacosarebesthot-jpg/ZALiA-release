/// @description  TrackerWin_put(dc, x, y, text, color)
function TrackerWin_put() {
	// Draws text at (x,y) with given COLORREF color.

	var _dc  = argument[0];
	var _x   = argument[1];
	var _y   = argument[2];
	var _txt = argument[3];
	var _c   = argument[4];

	// If window is disabled, just log to the debug console and bail
	if (!global.TW_ENABLED) { show_debug_message("[TW] " + string(_x) + "," + string(_y) + " " + _txt); exit; }
	external_call(global.TW_fn_SetTextClr, _dc, _c);
	var _len = string_byte_length(_txt);
	var _buf = buffer_create(_len + 1, buffer_fixed, 1);
	buffer_write(_buf, buffer_text, _txt);
	buffer_write(_buf, buffer_u8, 0);
	external_call(global.TW_fn_TextOut, _dc, _x, _y, buffer_get_address(_buf), _len);
	buffer_delete(_buf);



}

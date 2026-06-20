/// @description  TrackerWin_fill(dc, left, top, right, bottom, color)
function TrackerWin_fill() {
	// Fills a rectangle with a solid color.

	var _dc = argument[0];
	var _l  = argument[1];
	var _t  = argument[2];
	var _r  = argument[3];
	var _b  = argument[4];
	var _c  = argument[5];

	var _br = external_call(global.TW_fn_CreateBrush, _c);
	var _ob = external_call(global.TW_fn_SelectObj, _dc, _br);
	external_call(global.TW_fn_Rect, _dc, _l, _t, _r, _b);
	external_call(global.TW_fn_SelectObj, _dc, _ob);
	external_call(global.TW_fn_DeleteObj, _br);



}

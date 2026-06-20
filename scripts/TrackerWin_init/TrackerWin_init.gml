/// @description  TrackerWin_init()
function TrackerWin_init() {
	// Creates the tracker OS window and GDI resources.
	// Call once after TrackerWin_extern().
	// Set global.TW_ENABLED = false before calling to skip the window and log instead.
	if (!global.TW_ENABLED) { global.TW_hwnd = 0; exit; }

	// ── window style ──────────────────────────────────────────────────────────
	var _WS_OVERLAPPEDWINDOW = 0x00CF0000;
	var _WS_VISIBLE          = 0x10000000;

	// Place to the right of the game window
	var _gx = window_get_x();
	var _gy = window_get_y();
	var _gw = window_get_width();

	global.TW_W = 340;
	global.TW_H = 680;  // extra height for hint text replay rows

	// GMS2 64-bit: pass strings as buffer pointers (ty_real) instead of ty_string
	// 0x0082 = STATIC predefined window class atom (no string needed)
	var _title_buf = buffer_create(32, buffer_fixed, 1);
	buffer_write(_title_buf, buffer_text, "ZALiA Tracker");
	buffer_write(_title_buf, buffer_u8, 0);
	var _title_ptr = buffer_get_address(_title_buf);

	global.TW_hwnd = external_call(global.TW_fn_CreateWindow,
	    0,
	    0x0082,           // STATIC class atom — no string needed
	    _title_ptr,
	    _WS_OVERLAPPEDWINDOW | _WS_VISIBLE,
	    _gx + _gw + 6,
	    _gy,
	    global.TW_W,
	    global.TW_H,
	    0, 0, 0, 0);
	buffer_delete(_title_buf);

	if (!global.TW_hwnd) { global.TW_hwnd = 0; exit; }

	// ── GDI font ──────────────────────────────────────────────────────────────
	// CreateFontA(h, w, esc, ori, weight, ital, under, strike,
	//             charset, outprec, clipprec, qual, pitchfam, face)
	// 49 = FIXED_PITCH(1) | FF_MODERN(0x30)
	var _font_buf = buffer_create(32, buffer_fixed, 1);
	buffer_write(_font_buf, buffer_text, "Courier New");
	buffer_write(_font_buf, buffer_u8, 0);
	var _font_ptr = buffer_get_address(_font_buf);

	global.TW_font = external_call(global.TW_fn_CreateFont,
	    14,0,0,0, 400, 0,0,0, 0,0,0, 2, 49, _font_ptr);

	global.TW_font_bold = external_call(global.TW_fn_CreateFont,
	    14,0,0,0, 700, 0,0,0, 0,0,0, 2, 49, _font_ptr);
	buffer_delete(_font_buf);

	// NULL_PEN (stock index 8) prevents Rectangle() from drawing outlines
	global.TW_null_pen = external_call(global.TW_fn_GetStock, 8);



}

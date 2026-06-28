/// @description  TrackerWin_init()
function TrackerWin_init() {
	// Creates the tracker OS window and GDI resources.
	// Call once after TrackerWin_extern().
	// Set global.TW_ENABLED = false before calling to skip the window and log instead.
	if (!global.TW_ENABLED) { global.TW_hwnd = 0; exit; }

	// ── window style ──────────────────────────────────────────────────────────
	var _WS_OVERLAPPEDWINDOW = 0x00CF0000;
	var _WS_VISIBLE          = 0x10000000;
	var _WS_POPUP            = 0x80000000;

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

	var _cls_buf = buffer_create(8, buffer_fixed, 1);
	buffer_write(_cls_buf, buffer_text, "STATIC");
	buffer_write(_cls_buf, buffer_u8, 0);
	var _cls_ptr = buffer_get_address(_cls_buf);

	// TWDIAG: log the exact args going into CreateWindowExA so a headless run can
	// confirm class name / style / geometry. (lpClassName = "STATIC" string pointer.)
	show_debug_message("TWDIAG CreateWindow.in clsPtr=" + string(_cls_ptr) + " style=0x"
	    + string(_WS_OVERLAPPEDWINDOW | _WS_VISIBLE)
	    + " x=" + string(_gx + _gw + 6) + " y=" + string(_gy)
	    + " w=" + string(global.TW_W) + " h=" + string(global.TW_H)
	    + " titlePtr=" + string(_title_ptr));

	// ════════════════════════════════════════════════════════════════════════════
	// EMPIRICAL DIAGNOSTIC SEQUENCE — isolate why CreateWindowExA returns hwnd=0.
	// Each step logs its result so a headless Igor run reveals the working path.
	// ════════════════════════════════════════════════════════════════════════════

	// SANITY: proves external_call returns a real handle at all.
	var _desk = external_call(global.TW_fn_GetDesktopWindow);
	show_debug_message("TWDIAG SANITY GetDesktopWindow=" + string(_desk));   // MUST be nonzero if external_call works
	show_debug_message("TWDIAG SANITY2 GetTickCount=" + string(external_call(global.TW_fn_GetTickCount))); // nonzero => int-returns work

	// Real hInstance for the running exe (GetModuleHandleA(0)).
	var _hinst = external_call(global.TW_fn_GetModuleHandle, 0);
	show_debug_message("TWDIAG hInstance=" + string(_hinst));

	// V1: baseline — "STATIC", overlapped, hInstance=0  (current behavior).
	var _v1 = external_call(global.TW_fn_CreateWindow,
	    0, _cls_ptr, _title_ptr, _WS_OVERLAPPEDWINDOW | _WS_VISIBLE,
	    _gx + _gw + 6, _gy, global.TW_W, global.TW_H, 0, 0, 0, 0);
	show_debug_message("TWDIAG V1_static_overlapped_hinst0 hwnd=" + string(_v1)
	    + " err=" + string(external_call(global.TW_fn_GetLastError)));

	// V2: "STATIC", overlapped, real hInstance.
	var _v2 = external_call(global.TW_fn_CreateWindow,
	    0, _cls_ptr, _title_ptr, _WS_OVERLAPPEDWINDOW | _WS_VISIBLE,
	    _gx + _gw + 6, _gy, global.TW_W, global.TW_H, 0, 0, _hinst, 0);
	show_debug_message("TWDIAG V2_static_overlapped_hinst hwnd=" + string(_v2)
	    + " err=" + string(external_call(global.TW_fn_GetLastError)));

	// V3: register a REAL window class, then create from it.
	var _v3 = 0;

	// DefWindowProcA address = GetProcAddress(GetModuleHandleA("user32.dll"), "DefWindowProcA")
	var _u32name_buf = buffer_create(16, buffer_fixed, 1);
	buffer_write(_u32name_buf, buffer_text, "user32.dll");
	buffer_write(_u32name_buf, buffer_u8, 0);
	var _u32name_ptr = buffer_get_address(_u32name_buf);

	var _defwp_name_buf = buffer_create(16, buffer_fixed, 1);
	buffer_write(_defwp_name_buf, buffer_text, "DefWindowProcA");
	buffer_write(_defwp_name_buf, buffer_u8, 0);
	var _defwp_name_ptr = buffer_get_address(_defwp_name_buf);

	var _u32mod     = external_call(global.TW_fn_GetModuleHandle, _u32name_ptr);
	var _defwndproc = external_call(global.TW_fn_GetProcAddress, _u32mod, _defwp_name_ptr);
	show_debug_message("TWDIAG V3 u32mod=" + string(_u32mod)
	    + " DefWindowProcA=" + string(_defwndproc));

	// classname string "ZALiATrackerCls" in its own buffer.
	var _v3cls_buf = buffer_create(32, buffer_fixed, 1);
	buffer_write(_v3cls_buf, buffer_text, "ZALiATrackerCls");
	buffer_write(_v3cls_buf, buffer_u8, 0);
	var _v3cls_ptr = buffer_get_address(_v3cls_buf);

	// WNDCLASSEXA (x64, 80 bytes). Pointer values are reals < 2^52 → exact as u64.
	var _wc_buf = buffer_create(80, buffer_fixed, 1);
	buffer_poke(_wc_buf,  0, buffer_u32, 80);           // cbSize
	buffer_poke(_wc_buf,  4, buffer_u32, 0);            // style
	buffer_poke(_wc_buf,  8, buffer_u64, _defwndproc);  // lpfnWndProc
	buffer_poke(_wc_buf, 16, buffer_u32, 0);            // cbClsExtra
	buffer_poke(_wc_buf, 20, buffer_u32, 0);            // cbWndExtra
	buffer_poke(_wc_buf, 24, buffer_u64, _hinst);       // hInstance
	buffer_poke(_wc_buf, 32, buffer_u64, 0);            // hIcon
	buffer_poke(_wc_buf, 40, buffer_u64, 0);            // hCursor
	buffer_poke(_wc_buf, 48, buffer_u64, 0);            // hbrBackground
	buffer_poke(_wc_buf, 56, buffer_u64, 0);            // lpszMenuName
	buffer_poke(_wc_buf, 64, buffer_u64, _v3cls_ptr);   // lpszClassName
	buffer_poke(_wc_buf, 72, buffer_u64, 0);            // hIconSm
	var _wc_ptr = buffer_get_address(_wc_buf);

	var _atom = external_call(global.TW_fn_RegisterClassEx, _wc_ptr);
	show_debug_message("TWDIAG V3_registerclass atom=" + string(_atom)
	    + " err=" + string(external_call(global.TW_fn_GetLastError)));

	if (_atom != 0) {
	    _v3 = external_call(global.TW_fn_CreateWindow,
	        0, _v3cls_ptr, _title_ptr, _WS_OVERLAPPEDWINDOW | _WS_VISIBLE,
	        _gx + _gw + 6, _gy, global.TW_W, global.TW_H, 0, 0, _hinst, 0);
	    show_debug_message("TWDIAG V3_registerclass hwnd=" + string(_v3)
	        + " err=" + string(external_call(global.TW_fn_GetLastError)));
	}

	buffer_delete(_u32name_buf);
	buffer_delete(_defwp_name_buf);
	buffer_delete(_v3cls_buf);
	buffer_delete(_wc_buf);

	// Pick first nonzero handle as the real window.
	global.TW_hwnd = (_v1 != 0) ? _v1 : ((_v2 != 0) ? _v2 : _v3);
	show_debug_message("TWDIAG chosen hwnd=" + string(global.TW_hwnd));

	buffer_delete(_title_buf);
	buffer_delete(_cls_buf);

	if (!global.TW_hwnd) {
	    // TWDIAG: pull the OS error code so we know *why* creation failed.
	    // 1407 = ERROR_CANNOT_FIND_WND_CLASS, 1411 = ERROR_CLASS_DOES_NOT_EXIST,
	    // 0 = no error recorded (call likely never reached the OS).
	    if (variable_global_exists("TW_fn_GetLastError")) {
	        show_debug_message("TWDIAG GetLastError="
	            + string(external_call(global.TW_fn_GetLastError)));
	    }
	    show_debug_message("TWDIAG CreateWindow FAILED (hwnd=0) — bailing, window not shown");
	    global.TW_hwnd = 0; exit;
	}

	show_debug_message("TWDIAG CreateWindow OK hwnd=" + string(global.TW_hwnd));

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

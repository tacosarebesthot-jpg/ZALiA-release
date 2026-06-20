/// @description  TrackerWin_extern()
function TrackerWin_extern() {
	// One-time setup of all Win32 function handles needed by the tracker window.
	// Call this ONCE at game start before any other TrackerWin_* script.
	// Stores handles in global.TW_fn_* variables.

	// ── user32.dll ──────────────────────────────────────────────────────────────

	// CreateWindowExA(dwExStyle, lpClassName, lpWindowName, dwStyle,
	//                 X, Y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam)
	// GMS2 (64-bit): >4 args can't use ty_string — pass string ptrs via buffer_get_address()
	global.TW_fn_CreateWindow = external_define(
	    "user32.dll","CreateWindowExA", dll_stdcall, ty_real, 12,
	    ty_real,ty_real,ty_real,ty_real,
	    ty_real,ty_real,ty_real,ty_real,
	    ty_real,ty_real,ty_real,ty_real);

	// ShowWindow(hWnd, nCmdShow)
	global.TW_fn_ShowWindow = external_define(
	    "user32.dll","ShowWindow", dll_stdcall, ty_real, 2,
	    ty_real,ty_real);

	// IsWindow(hWnd)
	global.TW_fn_IsWindow = external_define(
	    "user32.dll","IsWindow", dll_stdcall, ty_real, 1,
	    ty_real);

	// GetDC(hWnd)
	global.TW_fn_GetDC = external_define(
	    "user32.dll","GetDC", dll_stdcall, ty_real, 1,
	    ty_real);

	// ReleaseDC(hWnd, hDC)
	global.TW_fn_ReleaseDC = external_define(
	    "user32.dll","ReleaseDC", dll_stdcall, ty_real, 2,
	    ty_real,ty_real);

	// DestroyWindow(hWnd)
	global.TW_fn_DestroyWindow = external_define(
	    "user32.dll","DestroyWindow", dll_stdcall, ty_real, 1,
	    ty_real);

	// SetWindowTextA(hWnd, lpString)
	global.TW_fn_SetTitle = external_define(
	    "user32.dll","SetWindowTextA", dll_stdcall, ty_real, 2,
	    ty_real,ty_string);

	// MoveWindow(hWnd, X, Y, nWidth, nHeight, bRepaint)
	global.TW_fn_MoveWindow = external_define(
	    "user32.dll","MoveWindow", dll_stdcall, ty_real, 6,
	    ty_real,ty_real,ty_real,ty_real,ty_real,ty_real);

	// ── gdi32.dll ───────────────────────────────────────────────────────────────

	// CreateFontA(cHeight, cWidth, cEscapement, cOrientation, cWeight,
	//             bItalic, bUnderline, bStrikeOut, iCharSet,
	//             iOutPrecision, iClipPrecision, iQuality, iPitchAndFamily, pszFaceName)
	global.TW_fn_CreateFont = external_define(
	    "gdi32.dll","CreateFontA", dll_stdcall, ty_real, 14,
	    ty_real,ty_real,ty_real,ty_real,ty_real,
	    ty_real,ty_real,ty_real,ty_real,ty_real,
	    ty_real,ty_real,ty_real,ty_real); // face name passed as buffer ptr

	// GetStockObject(fnObject)  — we use 8=NULL_PEN, 4=DKGRAY_BRUSH
	global.TW_fn_GetStock = external_define(
	    "gdi32.dll","GetStockObject", dll_stdcall, ty_real, 1,
	    ty_real);

	// SelectObject(hdc, hgdiobj)
	global.TW_fn_SelectObj = external_define(
	    "gdi32.dll","SelectObject", dll_stdcall, ty_real, 2,
	    ty_real,ty_real);

	// DeleteObject(hObject)
	global.TW_fn_DeleteObj = external_define(
	    "gdi32.dll","DeleteObject", dll_stdcall, ty_real, 1,
	    ty_real);

	// CreateSolidBrush(color)
	global.TW_fn_CreateBrush = external_define(
	    "gdi32.dll","CreateSolidBrush", dll_stdcall, ty_real, 1,
	    ty_real);

	// CreatePen(iStyle, cWidth, color)   style 5 = PS_NULL
	global.TW_fn_CreatePen = external_define(
	    "gdi32.dll","CreatePen", dll_stdcall, ty_real, 3,
	    ty_real,ty_real,ty_real);

	// Rectangle(hdc, left, top, right, bottom)
	global.TW_fn_Rect = external_define(
	    "gdi32.dll","Rectangle", dll_stdcall, ty_real, 5,
	    ty_real,ty_real,ty_real,ty_real,ty_real);

	// SetTextColor(hdc, color)
	global.TW_fn_SetTextClr = external_define(
	    "gdi32.dll","SetTextColor", dll_stdcall, ty_real, 2,
	    ty_real,ty_real);

	// SetBkColor(hdc, color)
	global.TW_fn_SetBkClr = external_define(
	    "gdi32.dll","SetBkColor", dll_stdcall, ty_real, 2,
	    ty_real,ty_real);

	// SetBkMode(hdc, mode)   1=TRANSPARENT  2=OPAQUE
	global.TW_fn_SetBkMode = external_define(
	    "gdi32.dll","SetBkMode", dll_stdcall, ty_real, 2,
	    ty_real,ty_real);

	// TextOutA(hdc, x, y, lpString, c)
	global.TW_fn_TextOut = external_define(
	    "gdi32.dll","TextOutA", dll_stdcall, ty_real, 5,
	    ty_real,ty_real,ty_real,ty_real,ty_real); // string passed as buffer ptr



}

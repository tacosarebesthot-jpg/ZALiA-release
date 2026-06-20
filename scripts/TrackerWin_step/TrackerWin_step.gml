/// @description  TrackerWin_step()
function TrackerWin_step() {
	// Call from obj_TrackerWin Step event every game frame.
	// Throttles redraws to once every 4 frames to limit GDI overhead.

	if (!variable_global_exists("TW_ENABLED")) exit; // GMS2: g_Create not yet run
	if (!global.TW_ENABLED) exit;                   // GMS2: TW disabled, skip entirely
	if (!variable_global_exists("TW_hwnd"))   exit; // extern not called yet
	if (!variable_global_exists("TW_fn_IsWindow")) exit;

	// Recreate the window if the user closed it
	if (!global.TW_hwnd
	||  !external_call(global.TW_fn_IsWindow, global.TW_hwnd))
	{
	    TrackerWin_init();
	}

	// Throttle: redraw every 4 frames
	if (!variable_global_exists("TW_tick")) global.TW_tick = 0;
	global.TW_tick++;
	if (global.TW_tick mod 4 != 0) exit;

	TrackerWin_draw();



}

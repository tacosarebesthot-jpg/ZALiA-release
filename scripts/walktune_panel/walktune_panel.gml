/// @description  walktune_panel()
function walktune_panel() {

	// ============================================================================
	// WALKTUNE PANEL -- mouse-draggable slider tool for overworld walk-feel tuning.
	//
	// Replaces the old key-based ("\" / "[" / "]") text overlay. Play-safe (NOT
	// DEV-gated): gated entirely on global.walktune_on so it can be used in a normal
	// play build. Self-contained + reversible -- delete this script, its .yy, its
	// .yyp entry, the WALKTUNE globals block in g_Create, and the single call in
	// Surface_Draw_GUI_End to fully remove it. The movement files only READ the
	// globals (ow_smooth_pct / ow_speed_mult), so they keep working with defaults.
	//
	// Two tunables, each its own horizontal slider:
	//   SMOOTHING  global.ow_smooth_pct   0..100  (0 = faithful NES tile-snap, 100 = fully smooth)
	//   SPEED      global.ow_speed_mult   0.25..1.00 (1.00 = shipping cadence)
	//
	// Keys (handled here, mouse does everything else):
	//   toggle ... open/close via Dev Tools menu (handled by the CALLER in Surface_Draw_GUI_End)
	// The old "\" / "[" / "]" keys are NO LONGER consumed by this tool, so the
	// music jukebox is free to use "[" / "]" for track skip.
	//
	// MUST be called from a Draw GUI event (Surface_Draw_GUI_End) so device_mouse_*_to_gui
	// returns GUI-space coordinates that line up with what we draw.
	// ============================================================================

	// Bail unless the panel is toggled on. Guarded so a missing global never crashes.
	if (!variable_global_exists("walktune_on")) return;
	if (!global.walktune_on)                    return;

	// --- ensure every global we touch exists (defaults = shipping behaviour) ---
	if (!variable_global_exists("ow_smooth_pct")) global.ow_smooth_pct = 100;
	if (!variable_global_exists("ow_speed_mult")) global.ow_speed_mult = 1.00;
	if (!variable_global_exists("walktune_drag")) global.walktune_drag = -1;
	if (!variable_global_exists("walktune_msg")) global.walktune_msg = "";
	if (!variable_global_exists("walktune_msg_timer")) global.walktune_msg_timer = 0;

	// speed clamp range (guarded reads, with the documented safe defaults).
	var _sp_lo = 0.25;
	if (variable_global_exists("ow_speed_MIN")) _sp_lo = global.ow_speed_MIN;
	var _sp_hi = 1.00;
	if (variable_global_exists("ow_speed_MAX")) _sp_hi = global.ow_speed_MAX;

	// ----------------------------------------------------------------------------
	// LAYOUT (all in GUI space). Anchored top-left under the F4/REC HUDs but pushed
	// down enough to clear them. Fixed pixel layout so the hit-zones below match the
	// drawn rectangles exactly -- this is what makes the dragging actually work.
	// ----------------------------------------------------------------------------
	var _pad      = 10;   // inner padding
	var _panel_x  = 8;    // panel left
	var _panel_y  = 60;   // panel top  (below the F4 depth-debug HUD region)
	var _panel_w  = 230;  // panel width
	var _row_h    = 34;   // vertical space per slider row
	var _track_x  = _panel_x + _pad;             // slider track left edge
	var _track_w  = _panel_w - (_pad * 2);       // slider track width
	var _track_h  = 6;                           // track bar thickness
	var _handle_w = 9;                           // handle half-handled below
	var _handle_h = 16;                          // handle height
	var _hit_pad  = 10;                          // extra vertical grab tolerance around a track

	// row baselines: label sits above each track; the track Y is what we map against.
	var _title_y  = _panel_y + _pad;
	var _row0_y   = _title_y + 22;               // SMOOTHING row top
	var _row1_y   = _row0_y + _row_h;            // SPEED row top
	var _smooth_track_y = _row0_y + 16;          // y of the smoothing track bar
	var _speed_track_y  = _row1_y + 16;          // y of the speed track bar

	// buttons row (SAVE + CLOSE) below the two sliders
	var _btn_y    = _row1_y + _row_h;
	var _btn_h    = 18;
	var _save_x   = _track_x;
	var _save_w   = 88;
	var _close_x  = _save_x + _save_w + 12;
	var _close_w  = 88;

	var _panel_h  = (_btn_y + _btn_h + _pad) - _panel_y;

	// ----------------------------------------------------------------------------
	// MOUSE INPUT (GUI space). device_mouse_*_to_gui(0) returns the cursor in the
	// SAME coordinate space we draw in, so it tracks correctly even when the window
	// is resized/scaled (the GUI layer is scaled by the engine, and this conversion
	// accounts for that). We track which slider is grabbed in global.walktune_drag
	// so a drag stays locked to ONE slider even if the cursor wanders vertically.
	// ----------------------------------------------------------------------------
	var _mx = device_mouse_x_to_gui(0);
	var _my = device_mouse_y_to_gui(0);
	var _mheld    = mouse_check_button(mb_left);
	var _mpressed = mouse_check_button_pressed(mb_left);

	// helper: is the cursor over a slider's grab zone (whole track band + handle)?
	// (inlined per-slider below -- GML has no nested closures handy here.)
	var _over_smooth = (_mx >= _track_x - _handle_w && _mx <= _track_x + _track_w + _handle_w
	                 && _my >= _smooth_track_y - _hit_pad && _my <= _smooth_track_y + _track_h + _hit_pad);
	var _over_speed  = (_mx >= _track_x - _handle_w && _mx <= _track_x + _track_w + _handle_w
	                 && _my >= _speed_track_y - _hit_pad && _my <= _speed_track_y + _track_h + _hit_pad);

	// button hit-zones
	var _over_save  = (_mx >= _save_x  && _mx <= _save_x  + _save_w
	                && _my >= _btn_y   && _my <= _btn_y + _btn_h);
	var _over_close = (_mx >= _close_x && _mx <= _close_x + _close_w
	                && _my >= _btn_y   && _my <= _btn_y + _btn_h);

	// 1) BEGIN a drag on press (only one slider can be grabbed; pick the one under cursor).
	if (_mpressed)
	{
		if (_over_smooth)     global.walktune_drag = 0;
		else if (_over_speed) global.walktune_drag = 1;
		else                  global.walktune_drag = -1;
	}

	// 2) END the drag when the button is no longer held.
	if (!_mheld) global.walktune_drag = -1;

	// 3) WHILE dragging, map cursor-x along the track to the value range and update LIVE.
	//    t = how far along the track the cursor is, clamped to 0..1.
	if (_mheld && global.walktune_drag == 0)
	{
		// SMOOTHING -> 0..100 integer percent
		var _t = (_mx - _track_x) / max(1, _track_w);
		_t = clamp(_t, 0, 1);
		global.ow_smooth_pct = round(_t * 100);
		global.ow_smooth_pct = clamp(global.ow_smooth_pct, 0, 100);
		// keep the legacy bool in sync for any other reader (derived convenience).
		if (variable_global_exists("ow_smooth_on")) global.ow_smooth_on = (global.ow_smooth_pct > 0);
	}
	if (_mheld && global.walktune_drag == 1)
	{
		// SPEED -> _sp_lo.._sp_hi, quantised to 0.01 for clean readout / file value.
		var _t2 = (_mx - _track_x) / max(1, _track_w);
		_t2 = clamp(_t2, 0, 1);
		var _v = _sp_lo + _t2 * (_sp_hi - _sp_lo);
		_v = round(_v * 100) / 100;          // 0.01 granularity (no ?: used)
		_v = clamp(_v, _sp_lo, _sp_hi);
		// snap to exactly 1.00 near the top so the shipping cadence (move_SYS==1) is reachable.
		if (abs(_v - 1.00) < 0.02) _v = 1.00;
		global.ow_speed_mult = _v;
	}

	// 4) BUTTONS act on a fresh press only (so a click doesn't repeat while held).
	if (_mpressed && _over_save)
	{
		walktune_save();   // writes the file + sets the SAVED/ERR confirmation message
	}
	if (_mpressed && _over_close)
	{
		global.walktune_on  = false;
		global.walktune_drag = -1;
		return; // panel just closed -- nothing left to draw this frame
	}


	// ----------------------------------------------------------------------------
	// DRAW the panel. GUI space. Default font (-1) like the project's other HUDs.
	// ----------------------------------------------------------------------------
	var _pf = draw_get_font();
	draw_set_font(-1);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_alpha(1);

	// panel backdrop (semi-transparent dark box + light border for readability)
	draw_set_alpha(0.78);
	draw_set_colour(c_black);
	draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, false);
	draw_set_alpha(1);
	draw_set_colour(c_white);
	draw_rectangle(_panel_x, _panel_y, _panel_x + _panel_w, _panel_y + _panel_h, true); // outline

	// title
	draw_set_colour(c_yellow);
	draw_text(_panel_x + _pad, _title_y, "WALKTUNE  (Dev Tools menu)");

	// ---- SMOOTHING slider ----
	var _smooth_pct = global.ow_smooth_pct;
	var _smooth_t   = _smooth_pct / 100;
	var _smooth_hx  = _track_x + round(_smooth_t * _track_w); // handle center x
	draw_set_colour(c_white);
	draw_text(_track_x, _row0_y, "SMOOTHING");
	draw_set_colour(c_aqua);
	draw_text(_track_x + _track_w - 40, _row0_y, string(_smooth_pct) + "%");
	// track
	draw_set_colour(c_gray);
	draw_rectangle(_track_x, _smooth_track_y, _track_x + _track_w, _smooth_track_y + _track_h, false);
	// filled portion (left of handle)
	draw_set_colour(c_aqua);
	draw_rectangle(_track_x, _smooth_track_y, _smooth_hx, _smooth_track_y + _track_h, false);
	// handle
	var _sh_hl = c_white;
	if (global.walktune_drag == 0) _sh_hl = c_yellow;
	draw_set_colour(_sh_hl);
	draw_rectangle(_smooth_hx - _handle_w, _smooth_track_y - ((_handle_h - _track_h) div 2),
	               _smooth_hx + _handle_w, _smooth_track_y + _track_h + ((_handle_h - _track_h) div 2), false);

	// ---- SPEED slider ----
	var _speed_v = global.ow_speed_mult;
	var _speed_t = 0;
	if ((_sp_hi - _sp_lo) != 0) _speed_t = (_speed_v - _sp_lo) / (_sp_hi - _sp_lo);
	_speed_t = clamp(_speed_t, 0, 1);
	var _speed_hx = _track_x + round(_speed_t * _track_w);
	draw_set_colour(c_white);
	draw_text(_track_x, _row1_y, "SPEED");
	draw_set_colour(c_aqua);
	draw_text(_track_x + _track_w - 40, _row1_y, string_format(_speed_v, 1, 2));
	// track
	draw_set_colour(c_gray);
	draw_rectangle(_track_x, _speed_track_y, _track_x + _track_w, _speed_track_y + _track_h, false);
	// filled portion
	draw_set_colour(c_aqua);
	draw_rectangle(_track_x, _speed_track_y, _speed_hx, _speed_track_y + _track_h, false);
	// handle
	var _sp_hl = c_white;
	if (global.walktune_drag == 1) _sp_hl = c_yellow;
	draw_set_colour(_sp_hl);
	draw_rectangle(_speed_hx - _handle_w, _speed_track_y - ((_handle_h - _track_h) div 2),
	               _speed_hx + _handle_w, _speed_track_y + _track_h + ((_handle_h - _track_h) div 2), false);

	// ---- SAVE + CLOSE buttons ----
	// SAVE
	var _save_bg = c_navy;
	if (_over_save) _save_bg = c_blue;
	draw_set_colour(_save_bg);
	draw_rectangle(_save_x, _btn_y, _save_x + _save_w, _btn_y + _btn_h, false);
	draw_set_colour(c_white);
	draw_rectangle(_save_x, _btn_y, _save_x + _save_w, _btn_y + _btn_h, true);
	draw_set_halign(fa_center);
	draw_text(_save_x + (_save_w div 2), _btn_y + 3, "[ SAVE ]");
	// CLOSE
	var _close_bg = c_maroon;
	if (_over_close) _close_bg = c_red;
	draw_set_colour(_close_bg);
	draw_rectangle(_close_x, _btn_y, _close_x + _close_w, _btn_y + _btn_h, false);
	draw_set_colour(c_white);
	draw_rectangle(_close_x, _btn_y, _close_x + _close_w, _btn_y + _btn_h, true);
	draw_text(_close_x + (_close_w div 2), _btn_y + 3, "[ DONE ]");
	draw_set_halign(fa_left);

	// ---- brief SAVED / ERR confirmation, just under the panel ----
	if (variable_global_exists("walktune_msg_timer") && global.walktune_msg_timer > 0)
	{
		global.walktune_msg_timer--;
		var _msg = "";
		if (variable_global_exists("walktune_msg")) _msg = string(global.walktune_msg);
		draw_set_colour(c_black); draw_text(_panel_x + _pad + 1, _panel_y + _panel_h + 5, _msg);
		draw_set_colour(c_lime);  draw_text(_panel_x + _pad,     _panel_y + _panel_h + 4, _msg);
	}

	// restore draw state we touched
	draw_set_alpha(1);
	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_font(_pf);
}

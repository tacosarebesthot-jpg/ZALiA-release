/// @description  gp_diag_overlay()
/// CONTROLLER DIAGNOSTIC overlay. Toggled by global.gp_diag_on (AUTOMATED TEST > CONTROLLER DIAG).
/// Draws, for the active gamepad slot, the LIVE state of every standard button
/// (gamepad_button_check), the analog trigger values (gamepad_button_value on gp_shoulderlb/rb),
/// every standard axis (gamepad_axis_value), and a RAW scan of every button/axis index the pad
/// reports. Built to debug a non-DS4 pad whose triggers (L2/R2) + L1 do nothing: if the triggers
/// light up ONLY in the RAW AXIS scan while the gp_shoulderlb/rb button cells + "TRIG VAL" stay
/// dark, they report as AXES not buttons -> the button-based jukebox skip (Input_update1 reads
/// gp_shoulderlb/rb via gamepad_button_check) can't see them. That is the likely cause + the fix
/// direction (add an axis-based trigger read, or a gamecontrollerdb mapping for this pad's guid).
/// Style mirrors tas_draw_overlay / the other Surface_Draw_GUI_End HUDs: GUI space, default font
/// (-1), ASCII-only, black shadow + coloured text, lit = bright / idle = gray. No F-keys: gated
/// purely on the menu-toggled global flag.
function gp_diag_overlay()
{
	if (!variable_global_exists("gp_diag_on") || !global.gp_diag_on)
	{
	    exit;
	}

	// ---- find the active gamepad slot (prefer the one the Input system is using) ----
	// Input.gamepad_slot is created in Input_Create and is the slot the game actually reads
	// (set/cleared in Input_System on "gamepad discovered"/"lost"); accessed directly here the
	// same way OptionsMenu_InputConfig_update reads it.
	var _slot = -1;
	if (instance_exists(Input))
	{
	    _slot = Input.gamepad_slot;
	}
	if (_slot < 0 || !gamepad_is_connected(_slot))
	{
	    _slot = -1;
	    for (var _s = 0; _s < 12; _s++)
	    {
	        if (gamepad_is_connected(_s)) { _slot = _s; break; }
	    }
	}

	// ---- font + style setup ----
	var _pf = draw_get_font();
	var _ph = draw_get_halign();
	var _pv = draw_get_valign();
	draw_set_font(-1);
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);

	var _x  = 8;
	var _y  = 8;
	var _lh = 11; // line height

	// ---- no pad connected ----
	if (_slot < 0)
	{
	    draw_set_alpha(0.72);
	    draw_set_colour(c_black);
	    draw_rectangle(_x - 4, _y - 4, _x - 4 + 260, _y - 4 + 20, false);
	    draw_set_alpha(1);
	    draw_set_colour(c_black); draw_text(_x + 1, _y + 1, "CONTROLLER DIAG: NO GAMEPAD CONNECTED");
	    draw_set_colour(c_red);   draw_text(_x,     _y,     "CONTROLLER DIAG: NO GAMEPAD CONNECTED");
	    draw_set_colour(c_white);
	    draw_set_font(_pf);
	    draw_set_halign(_ph);
	    draw_set_valign(_pv);
	    exit;
	}

	var _desc   = string(gamepad_get_description(_slot));
	var _guid   = string(gamepad_get_guid(_slot));
	var _bcount = gamepad_button_count(_slot);
	var _acount = gamepad_axis_count(_slot);

	// ---- backing panel for readability ----
	draw_set_alpha(0.72);
	draw_set_colour(c_black);
	draw_rectangle(_x - 4, _y - 4, _x - 4 + 300, _y - 4 + 248, false);
	draw_set_alpha(1);

	// ---- header ----
	draw_set_colour(c_black);  draw_text(_x + 1, _y + 1, "CONTROLLER DIAG  slot " + string(_slot));
	draw_set_colour(c_yellow); draw_text(_x,     _y,     "CONTROLLER DIAG  slot " + string(_slot));
	_y += _lh;
	draw_set_colour(c_black); draw_text(_x + 1, _y + 1, "desc: " + _desc);
	draw_set_colour(c_white); draw_text(_x,     _y,     "desc: " + _desc);
	_y += _lh;
	draw_set_colour(c_black); draw_text(_x + 1, _y + 1, "guid: " + _guid);
	draw_set_colour(c_white); draw_text(_x,     _y,     "guid: " + _guid);
	_y += _lh;
	draw_set_colour(c_black); draw_text(_x + 1, _y + 1, "buttons:" + string(_bcount) + "  axes:" + string(_acount));
	draw_set_colour(c_white); draw_text(_x,     _y,     "buttons:" + string(_bcount) + "  axes:" + string(_acount));
	_y += _lh + 3;

	// ---- standard buttons (gamepad_button_check) ----
	// L1/R1 = gp_shoulderl/r (bumpers), L2/R2 = gp_shoulderlb/rb (triggers AS BUTTONS).
	var _btn_const = [gp_face1, gp_face2, gp_face3, gp_face4,
	                  gp_shoulderl, gp_shoulderr, gp_shoulderlb, gp_shoulderrb,
	                  gp_select, gp_start, gp_stickl, gp_stickr,
	                  gp_padu, gp_padd, gp_padl, gp_padr];
	var _btn_label = ["F1", "F2", "F3", "F4",
	                  "L1", "R1", "L2", "R2",
	                  "SEL", "STA", "LS", "RS",
	                  "DU", "DD", "DL", "DR"];

	draw_set_colour(c_black); draw_text(_x + 1, _y + 1, "BUTTONS (button_check):");
	draw_set_colour(c_aqua);  draw_text(_x,     _y,     "BUTTONS (button_check):");
	_y += _lh;

	var _col   = 0;
	var _cellw = 36;
	for (var _i = 0; _i < array_length(_btn_const); _i++)
	{
	    var _pressed = gamepad_button_check(_slot, _btn_const[_i]);
	    var _cx = _x + _col * _cellw;
	    var _c  = c_gray;
	    if (_pressed) _c = c_lime;
	    draw_set_colour(c_black); draw_text(_cx + 1, _y + 1, _btn_label[_i]);
	    draw_set_colour(_c);      draw_text(_cx,     _y,     _btn_label[_i]);
	    _col++;
	    if (_col >= 8) { _col = 0; _y += _lh; }
	}
	if (_col != 0) _y += _lh;
	_y += 3;

	// ---- TRIGGERS as ANALOG values (THE KEY DIAGNOSTIC) ----
	// gamepad_button_value returns 0..1 for an analog trigger that IS mapped to gp_shoulderlb/rb.
	// If these stay 0.00 while the raw-axis scan below shows movement, the triggers are AXES the
	// SDL mapping never bound to the trigger buttons -> that is exactly why L2/R2 do nothing.
	var _lt_val = gamepad_button_value(_slot, gp_shoulderlb);
	var _rt_val = gamepad_button_value(_slot, gp_shoulderrb);
	var _trig_line = "TRIG VAL (button_value): L2=" + string_format(_lt_val, 1, 2)
	               + "  R2=" + string_format(_rt_val, 1, 2);
	var _trig_col = c_white;
	if (_lt_val > 0.05 || _rt_val > 0.05) _trig_col = c_lime;
	draw_set_colour(c_black);   draw_text(_x + 1, _y + 1, _trig_line);
	draw_set_colour(_trig_col); draw_text(_x,     _y,     _trig_line);
	_y += _lh + 3;

	// ---- standard axes (gamepad_axis_value) ----
	var _ax_const = [gp_axislh, gp_axislv, gp_axisrh, gp_axisrv];
	var _ax_label = ["LX", "LY", "RX", "RY"];
	draw_set_colour(c_black); draw_text(_x + 1, _y + 1, "AXES (axis_value):");
	draw_set_colour(c_aqua);  draw_text(_x,     _y,     "AXES (axis_value):");
	_y += _lh;
	for (var _i = 0; _i < array_length(_ax_const); _i++)
	{
	    var _av   = gamepad_axis_value(_slot, _ax_const[_i]);
	    var _line = _ax_label[_i] + "=" + string_format(_av, 1, 2);
	    var _c    = c_gray;
	    if (abs(_av) > 0.15) _c = c_yellow;
	    var _cx = _x + (_i mod 2) * 120;
	    var _cy = _y + (_i div 2) * _lh;
	    draw_set_colour(c_black); draw_text(_cx + 1, _cy + 1, _line);
	    draw_set_colour(_c);      draw_text(_cx,     _cy,     _line);
	}
	_y += _lh * 2 + 3;

	// ---- RAW button scan: list every pressed raw index (catches non-standard mappings) ----
	// Raw idiom: indices run from gp_face1 .. gp_face1 + gamepad_button_count - 1.
	draw_set_colour(c_black); draw_text(_x + 1, _y + 1, "RAW BTN ON:");
	draw_set_colour(c_aqua);  draw_text(_x,     _y,     "RAW BTN ON:");
	var _rawb = "";
	for (var _i = 0; _i < _bcount; _i++)
	{
	    if (gamepad_button_check(_slot, gp_face1 + _i)) _rawb += string(_i) + " ";
	}
	if (_rawb == "") _rawb = "-";
	draw_set_colour(c_black); draw_text(_x + 1 + 78, _y + 1, _rawb);
	draw_set_colour(c_lime);  draw_text(_x + 78,     _y,     _rawb);
	_y += _lh + 1;

	// ---- RAW axis scan: every axis index + value (TRIGGERS SHOW HERE if they are axes) ----
	// Raw idiom: indices run from gp_axislh .. gp_axislh + gamepad_axis_count - 1. Pads that send
	// L2/R2 as axes expose them as a4/a5 (or a shared Z axis) -> they move here, not in BUTTONS.
	draw_set_colour(c_black); draw_text(_x + 1, _y + 1, "RAW AXIS:");
	draw_set_colour(c_aqua);  draw_text(_x,     _y,     "RAW AXIS:");
	_y += _lh;
	for (var _i = 0; _i < _acount; _i++)
	{
	    var _rv   = gamepad_axis_value(_slot, gp_axislh + _i);
	    var _line = "a" + string(_i) + "=" + string_format(_rv, 1, 2);
	    var _c    = c_gray;
	    if (abs(_rv) > 0.15) _c = c_yellow;
	    var _cx = _x + (_i mod 4) * 64;
	    var _cy = _y + (_i div 4) * _lh;
	    draw_set_colour(c_black); draw_text(_cx + 1, _cy + 1, _line);
	    draw_set_colour(_c);      draw_text(_cx,     _cy,     _line);
	}

	// ---- restore state ----
	draw_set_alpha(1);
	draw_set_colour(c_white);
	draw_set_font(_pf);
	draw_set_halign(_ph);
	draw_set_valign(_pv);
}

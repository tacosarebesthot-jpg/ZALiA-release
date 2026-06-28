/// @description  tas_draw_overlay()
/// Emulator-style input display HUD. Anchored bottom-right, same style as the jukebox overlay.
/// Shows two rows of NES buttons LIT (bright) when held, DIM otherwise.
/// Also shows a small "REC" or "PB" tag when active.
function tas_draw_overlay()
{
	if (!global.tas_overlay_on)
	{
	    exit;
	}

	// ---- copy held state from the Input instance ----
	var _r_h  = false;
	var _l_h  = false;
	var _d_h  = false;
	var _u_h  = false;
	var _s_h  = false; // Start  (Pause)
	var _e_h  = false; // Select (Magic)
	var _b_h  = false; // B      (Attack)
	var _a_h  = false; // A      (Jump)
	var _sn_h = false; // Spell Next
	var _sp_h = false; // Spell Prev

	if (instance_exists(Input))
	{
	    _r_h  = Input.Right_held;
	    _l_h  = Input.Left_held;
	    _d_h  = Input.Down_held;
	    _u_h  = Input.Up_held;
	    _s_h  = Input.Pause_held;
	    _e_h  = Input.Magic_held;
	    _b_h  = Input.Attack_held;
	    _a_h  = Input.Jump_held;
	    _sn_h = Input.Spell_Next_held;
	    _sp_h = Input.Spell_Prev_held;
	}

	// ---- screen anchors ----
	var _gw = display_get_gui_width();
	if (_gw <= 0) _gw = 320;
	var _gh = display_get_gui_height();
	if (_gh <= 0) _gh = 240;

	// ---- layout constants ----
	// Each button label is 14px wide; 4 labels per row = ~56px; 2 rows = ~26px high.
	// Anchor right-edge at _gw - 8 (same as jukebox), bottom at _gh - 44 so it sits
	// above the jukebox line.
	var _pad   = 4;
	var _bw    = 14; // per-button cell width
	var _bh    = 12; // per-button cell height
	var _cols  = 4;
	var _total_w = _bw * _cols + _pad * 2;
	var _total_h = _bh * 2 + _pad * 2 + 10; // 2 rows + tag line

	var _rx = _gw - 8 - _total_w; // rect left
	var _ry = _gh - 44 - _total_h; // rect top

	// ---- backing rect (translucent, same style as other HUD rects in this file) ----
	var _pf = draw_get_font();
	draw_set_font(-1);
	draw_set_halign(fa_left);

	draw_set_alpha(0.7);
	draw_set_colour(c_black);
	draw_rectangle(_rx, _ry, _rx + _total_w, _ry + _total_h, false);
	draw_set_alpha(1);

	// ---- helper: draw one button label, lit or dim ----
	// rows: row0 = SE ST B A   (top),  row1 = U D L R  (bottom)
	// x positions within the backing rect
	var _x0 = _rx + _pad;
	var _y0 = _ry + _pad;

	// row 0: SE  ST  B  A  (left to right)
	// SE = Select = Magic_held
	var _c_se = c_gray;
	if (_e_h)
	{
	    _c_se = c_white;
	}
	draw_set_colour(c_black); draw_text(_x0 + _bw * 0 + 1, _y0 + 1, "SE");
	draw_set_colour(_c_se);   draw_text(_x0 + _bw * 0,     _y0,     "SE");

	// ST = Start = Pause_held
	var _c_st = c_gray;
	if (_s_h)
	{
	    _c_st = c_white;
	}
	draw_set_colour(c_black); draw_text(_x0 + _bw * 1 + 1, _y0 + 1, "ST");
	draw_set_colour(_c_st);   draw_text(_x0 + _bw * 1,     _y0,     "ST");

	// B = Attack_held
	var _c_b = c_gray;
	if (_b_h)
	{
	    _c_b = c_yellow;
	}
	draw_set_colour(c_black); draw_text(_x0 + _bw * 2 + 1, _y0 + 1, "B");
	draw_set_colour(_c_b);    draw_text(_x0 + _bw * 2,     _y0,     "B");

	// A = Jump_held
	var _c_a = c_gray;
	if (_a_h)
	{
	    _c_a = c_yellow;
	}
	draw_set_colour(c_black); draw_text(_x0 + _bw * 3 + 1, _y0 + 1, "A");
	draw_set_colour(_c_a);    draw_text(_x0 + _bw * 3,     _y0,     "A");

	// row 1: U  D  L  R
	var _y1 = _y0 + _bh;

	// U = Up_held
	var _c_u = c_gray;
	if (_u_h)
	{
	    _c_u = c_lime;
	}
	draw_set_colour(c_black); draw_text(_x0 + _bw * 0 + 1, _y1 + 1, "U");
	draw_set_colour(_c_u);    draw_text(_x0 + _bw * 0,     _y1,     "U");

	// D = Down_held
	var _c_d = c_gray;
	if (_d_h)
	{
	    _c_d = c_lime;
	}
	draw_set_colour(c_black); draw_text(_x0 + _bw * 1 + 1, _y1 + 1, "D");
	draw_set_colour(_c_d);    draw_text(_x0 + _bw * 1,     _y1,     "D");

	// L = Left_held
	var _c_l = c_gray;
	if (_l_h)
	{
	    _c_l = c_lime;
	}
	draw_set_colour(c_black); draw_text(_x0 + _bw * 2 + 1, _y1 + 1, "L");
	draw_set_colour(_c_l);    draw_text(_x0 + _bw * 2,     _y1,     "L");

	// R = Right_held
	var _c_r = c_gray;
	if (_r_h)
	{
	    _c_r = c_lime;
	}
	draw_set_colour(c_black); draw_text(_x0 + _bw * 3 + 1, _y1 + 1, "R");
	draw_set_colour(_c_r);    draw_text(_x0 + _bw * 3,     _y1,     "R");

	// ---- status tag: REC / PB / frame counter ----
	var _y2 = _y1 + _bh + 2;
	var _tag = "";
	if (global.tas_rec_state == 1)
	{
	    _tag = "* REC " + string(global.tas_rec_count);
	    draw_set_colour(c_black); draw_text(_x0 + 1, _y2 + 1, _tag);
	    draw_set_colour(c_red);   draw_text(_x0,     _y2,     _tag);
	}
	else if (global.tas_pb_state == 1)
	{
	    _tag = "> PB " + string(global.tas_pb_index) + "/" + string(global.tas_pb_count);
	    draw_set_colour(c_black);  draw_text(_x0 + 1, _y2 + 1, _tag);
	    draw_set_colour(c_aqua);   draw_text(_x0,     _y2,     _tag);
	}

	// ---- restore state ----
	draw_set_colour(c_white);
	draw_set_halign(fa_left);
	draw_set_font(_pf);
}

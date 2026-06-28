/// @description  OptionsMenu_Draw_Sweeps(YT)
/// @param YT
function OptionsMenu_Draw_Sweeps() {

	// DEV TOOLS sub-folder draw: SWEEPS. Rows are actions (start a sweep) with no
	// on/off state, so there is no right-column marker -- label + cursor + info only.

	var _YT0 = argument[0];

	var _i, _x,_y, _xl,_yt, _yt1;
	var _DIST1 = $4;
	var _pi;
	var _text, _font, _font_w,_font_h;
	var _enum;
	var _vis_N, _top_index, _draw_end, _cursor_vis_pos, _top_max, _vis_rows;


	_font   = Sweeps_dg[#0,1];
	_font_h = sprite_get_height(_font);
	_font_w = sprite_get_width( _font);

	var _ROW_H = _font_h + _DIST1;

	var _ScrollArea_YT = _YT0 + _DIST1;
	var _ScrollArea_YB = Info_Divider_yt;
	var _ScrollArea_H  = _ScrollArea_YB - _ScrollArea_YT;
	_vis_rows = _ScrollArea_H div _ROW_H;
	if (_vis_rows < 1) _vis_rows = 1;


	_vis_N = 0;
	var _vis_enum = array_create(Sweeps.COUNT, 0);
	for (_i = 0; _i < Sweeps.COUNT; _i++)
	{
	    if (OptionsMenu_option_is_avail(menu_state_SWEEPS, _i)) { _vis_enum[_vis_N] = _i; _vis_N++; }
	}


	_cursor_vis_pos = 0;
	for (_i = 0; _i < _vis_N; _i++) { if (_vis_enum[_i] == Sweeps_cursor) { _cursor_vis_pos = _i; break; } }

	_top_max   = max(0, _vis_N - _vis_rows);
	_top_index = _cursor_vis_pos - (_vis_rows >> 1);
	if (_top_index < 0)        _top_index = 0;
	if (_top_index > _top_max) _top_index = _top_max;


	_draw_end = _top_index + _vis_rows;
	if (_draw_end > _vis_N) _draw_end = _vis_N;

	for (_i = _top_index; _i < _draw_end; _i++)
	{
	    _yt1 = _ScrollArea_YT + (_i - _top_index) * _ROW_H;

	    _enum = _vis_enum[_i];
	    _text = Sweeps_dg[#_enum,0];

	    if (_enum==Sweeps_cursor) _pi = PI_MENU1;
	    else                      _pi = PI_MENU2;
	    _xl = TextArea1_xl;
	    draw_text_(_xl,_yt1, _text, _font, _pi);


	    if (_enum == Sweeps_cursor)
	    {
	        _x = Cursor_xl + (Cursor_W>>1);
	        _y = _yt1 + (_font_h>>1);
	        draw_sprite_(Cursor_SPRITE,0, _x,_y, PI_MENU1);
	    }
	}


	// OPTION INFO -----------------------------------------------------------
	_yt1 = Info_yt;
	if (_yt1+Info_FONT_H < MenuWindow_yb)
	{
	    _text = Sweeps_dg[#Sweeps_cursor,2];
	    if (is_string(_text))
	    {
	        _xl = TextArea1_xl;
	        _yt = _yt1;
	        pal_swap_set(global.palette_image, PI_MENU1);
	        draw_text_plus(_xl,Info_xr, _yt, _text, Info_FONT);
	        pal_swap_reset();
	    }
	}

}

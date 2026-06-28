/// @description  OptionsMenu_Draw_Display(YT)
/// @param YT
function OptionsMenu_Draw_Display() {


	var _YT0 = argument[0];

	var _i, _x,_y, _xl,_yt, _yt1;
	var _DIST1 = $4; // line spacing
	var _pi;
	var _text, _font, _font_w,_font_h;
	var _enum;
	var _vis_N, _top_index, _draw_end, _cursor_vis_pos, _top_max, _vis_rows;


	_font   = Display_dg[#0,1];
	_font_h = sprite_get_height(_font);
	_font_w = sprite_get_width( _font);

	var _ROW_H = _font_h + _DIST1;

	var _ScrollArea_YT = _YT0 + _DIST1;
	var _ScrollArea_YB = Info_Divider_yt; // cap list above the info divider
	var _ScrollArea_H  = _ScrollArea_YB - _ScrollArea_YT;
	_vis_rows = _ScrollArea_H div _ROW_H;
	if (_vis_rows < 1) _vis_rows = 1;


	// -----------------------------------------------------------------------
	// Build visible items list (one row per available mode, then BACK).
	// -----------------------------------------------------------------------
	_vis_N = 0;
	var _vis_enum = array_create(Display.COUNT, 0);
	for (_i = 0; _i < Display.COUNT; _i++)
	{
	    if (OptionsMenu_option_is_avail(menu_state_DISPLAY, _i))
	    {
	        _vis_enum[_vis_N] = _i;
	        _vis_N++;
	    }
	}


	// -----------------------------------------------------------------------
	// Find the visual position of the currently highlighted cursor row.
	// -----------------------------------------------------------------------
	_cursor_vis_pos = 0;
	for (_i = 0; _i < _vis_N; _i++)
	{
	    if (_vis_enum[_i] == Display_cursor)
	    {
	        _cursor_vis_pos = _i;
	        break;//_i
	    }
	}

	_top_max   = max(0, _vis_N - _vis_rows);
	_top_index = _cursor_vis_pos - (_vis_rows >> 1);
	if (_top_index < 0)        _top_index = 0;
	if (_top_index > _top_max) _top_index = _top_max;


	// -----------------------------------------------------------------------
	// Draw visible rows.
	// -----------------------------------------------------------------------
	_draw_end = _top_index + _vis_rows;
	if (_draw_end > _vis_N) _draw_end = _vis_N;

	for (_i = _top_index; _i < _draw_end; _i++)
	{
	    _yt1 = _ScrollArea_YT + (_i - _top_index) * _ROW_H;

	    _enum = _vis_enum[_i];
	    _text = Display_dg[#_enum,0];

	    if (_enum==Display_cursor) _pi = PI_MENU1;
	    else                       _pi = PI_MENU2;
	    _xl = TextArea1_xl;
	    draw_text_(_xl,_yt1, _text, _font, _pi);


	    // Right-column value/marker per row (always bright PI_MENU1 so it's unmistakable):
	    //   FULLSCREEN   -> live "ON"/"OFF" from window_get_fullscreen()
	    //   WINDOW SCALE -> live "<n>X"     from window_get_scale()
	    //   mode rows    -> "ON" on the ONE active mode; mode rows sit at enum offset
	    //                   Display.SMOOTH, so the active row is global.DisplayMode+Display.SMOOTH
	    //   BACK         -> nothing
	    var _marker = "";
	    if (_enum==Display.FULLSCREEN)
	    {
	        _marker = window_get_fullscreen() ? "ON" : "OFF";
	    }
	    else if (_enum==Display.WINDOW_SCALE)
	    {
	        _marker = string(window_get_scale()) + "X";
	    }
	    else if (_enum!=Display.BACK
	         &&  _enum==global.DisplayMode + Display.SMOOTH )
	    {
	        _marker = "ON";
	    }
	    if (_marker != "")
	    {
	        _xl  = TextArea2_xr;
	        _xl -= string_length(_marker) * _font_w;
	        draw_text_(_xl,_yt1, _marker, _font, PI_MENU1);
	    }


	    if (_enum == Display_cursor)
	    {
	        _x = Cursor_xl + (Cursor_W>>1);
	        _y = _yt1 + (_font_h>>1); // text yc
	        draw_sprite_(Cursor_SPRITE,0, _x,_y, PI_MENU1);
	    }
	}


	// OPTION INFO -----------------------------------------------------------
	_yt1 = Info_yt;
	if (_yt1+Info_FONT_H < MenuWindow_yb)
	{
	    _text = Display_dg[#Display_cursor,2];
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
